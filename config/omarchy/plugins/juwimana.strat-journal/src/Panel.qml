import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
    id: root
    moduleName: "juwimana.strat-journal"
    ipcTarget: "juwimana.strat-journal"

    property var anchorItem: null
    property var hostWidget: null
    readonly property var barIdentity: hostWidget || root

    // View state: "session" | "analytics" | "history"
    property string activeTab: "session"

    // Market & Trade Data
    property var marketData: ({ symbol: "GOOGL", price: 182.50, change: 1.25, change_pct: 0.69, daily_scenario: "2U", daily_color: "green", month_color: "green", week_color: "green", day_color: "green", hour_color: "green" })
    property var tradesList: []
    property var stats: Model.computeStatistics(tradesList)
    readonly property var activeTrade: {
        for (var i = 0; i < tradesList.length; i++) {
            if (tradesList[i].status === "open") return tradesList[i]
        }
        return null
    }

    // Form inputs for new entry
    property string formDirection: "Long"
    property string formCombo: "60m 2-1-2 Bull"
    property string formTimeframe: "60m"
    property string formTriggerPrice: "182.50"
    property string formStopLoss: "181.90"
    property string formTargetPrice: "184.10"
    property string formRiskDollars: "100"
    property string formGrade: "A"
    property string formScreenshot: ""
    property string formNotes: ""

    // Form inputs for closing trade
    property string closeExitPrice: "183.95"
    property string closeGrade: "A"
    property string closeMistake: "None"
    property string closeNotes: ""
    property string closeScreenshot: ""

    // UI constants
    readonly property color fg: bar ? bar.foreground : Color.foreground
    readonly property color accentColor: Color.accent
    readonly property color mutedColor: Color.muted
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
    readonly property int panelWidth: Style.space(480)

    readonly property string scriptDir: Qt.resolvedUrl("../scripts/").toString().replace(/^file:\/\//, "")

    function fetchMarketData() {
        if (quoteProcess.running) return
        quoteProcess.command = [scriptDir + "fetch-quote.sh", "GOOGL"]
        quoteProcess.running = true
    }

    function fetchTrades() {
        if (storageProcess.running) return
        storageProcess.command = [scriptDir + "storage-helper.sh", "list"]
        storageProcess.running = true
    }

    function captureScreenshot(isExit) {
        screenshotProcess.isExit = isExit === true
        screenshotProcess.command = [scriptDir + "capture-chart.sh"]
        screenshotProcess.running = true
    }

    function submitNewTrade() {
        var now = new Date()
        var timeStr = now.toLocaleDateString() + " " + now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        var trig = Number(root.formTriggerPrice) || (root.marketData ? root.marketData.price : 182.50)
        var stop = Number(root.formStopLoss) || (trig - 0.60)
        var target = Number(root.formTargetPrice) || (trig + 1.20)
        var sizing = Model.calculatePositionSize(root.formRiskDollars, trig, stop)

        var newTrade = {
            id: "trade_" + Date.now(),
            date: timeStr,
            symbol: "GOOGL",
            direction: root.formDirection,
            combo: root.formCombo,
            timeframe: root.formTimeframe,
            trigger_price: trig,
            stop_loss: stop,
            target_price: target,
            risk_dollars: Number(root.formRiskDollars) || 100,
            shares: sizing.shares,
            risk_per_share: sizing.riskPerShare,
            entry_screenshot: root.formScreenshot,
            exit_screenshot: "",
            grade: root.formGrade,
            notes: root.formNotes,
            status: "open",
            realized_r: 0.0
        }

        addTradeProcess.payload = JSON.stringify(newTrade)
        addTradeProcess.command = ["bash", "-c", "echo '" + JSON.stringify(newTrade).replace(/'/g, "'\\''") + "' | " + scriptDir + "storage-helper.sh add"]
        addTradeProcess.running = true
        root.formScreenshot = ""
        root.formNotes = ""
    }

    function submitCloseTrade() {
        if (!root.activeTrade) return
        var now = new Date()
        var timeStr = now.toLocaleDateString() + " " + now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        var exitP = Number(root.closeExitPrice) || (root.marketData ? root.marketData.price : root.activeTrade.trigger_price)
        var rVal = Model.computeR(root.activeTrade.direction, root.activeTrade.trigger_price, root.activeTrade.stop_loss, exitP)

        var closeData = {
            id: root.activeTrade.id,
            exit_price: exitP,
            exit_time: timeStr,
            exit_screenshot: root.closeScreenshot,
            realized_r: Number(rVal.toFixed(2)),
            grade: root.closeGrade,
            mistake: root.closeMistake,
            notes: root.closeNotes
        }

        closeTradeProcess.command = ["bash", "-c", "echo '" + JSON.stringify(closeData).replace(/'/g, "'\\''") + "' | " + scriptDir + "storage-helper.sh close"]
        closeTradeProcess.running = true
        root.closeScreenshot = ""
        root.closeNotes = ""
    }

    function openFile(path) {
        if (!path || path === "") return
        openProc.command = ["xdg-open", path]
        openProc.running = true
    }

    Component.onCompleted: {
        root.fetchMarketData()
        root.fetchTrades()
    }

    Timer {
        interval: root.opened ? 6000 : 20000
        running: true
        repeat: true
        onTriggered: {
            root.fetchMarketData()
            root.fetchTrades()
        }
    }

    // Processes
    Process {
        id: quoteProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    var parsed = JSON.parse((text || "").trim())
                    if (parsed && parsed.price) root.marketData = parsed
                } catch (e) {}
            }
        }
    }

    Process {
        id: storageProcess
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    var list = JSON.parse((text || "").trim())
                    if (Array.isArray(list)) root.tradesList = list
                } catch (e) {}
            }
        }
    }

    Process {
        id: addTradeProcess
        property string payload: ""
        onExited: root.fetchTrades()
    }

    Process {
        id: closeTradeProcess
        onExited: root.fetchTrades()
    }

    Process {
        id: screenshotProcess
        property bool isExit: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var p = (text || "").trim()
                if (screenshotProcess.isExit) {
                    root.closeScreenshot = p
                } else {
                    root.formScreenshot = p
                }
            }
        }
    }

    Process { id: openProc }

    // -------------------------------------------------------------
    // POPUP KEYBOARD PANEL
    // -------------------------------------------------------------
    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(root.panelWidth)
        contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight, Style.space(680))

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) { root.switchPanel(direction) }

            Column {
                id: mainColumn
                width: parent.width
                spacing: Style.space(10)

                // HEADER HERO
                PanelHero {
                    width: parent.width
                    title: "GOOGL Strat Journal"
                    meta: {
                        var p = root.marketData ? root.marketData.price.toFixed(2) : "182.50"
                        var chg = root.marketData ? root.marketData.change_pct.toFixed(2) : "0.00"
                        return "GOOGL $" + p + " (" + (chg >= 0 ? "+" : "") + chg + "%) | Strat Discipline"
                    }
                    foreground: root.fg
                    fontFamily: root.fontFamily

                    trailingControl: Component {
                        Row {
                            spacing: Style.space(4)
                            Repeater {
                                model: [
                                    { id: "session", label: "Session" },
                                    { id: "analytics", label: "Analytics" },
                                    { id: "history", label: "History" }
                                ]
                                delegate: Rectangle {
                                    height: Style.space(26)
                                    width: tabText.implicitWidth + Style.space(12)
                                    radius: Style.space(4)
                                    color: root.activeTab === modelData.id ? Color.accent : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05))

                                    Text {
                                        id: tabText
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: root.activeTab === modelData.id ? Color.background : root.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.caption
                                        font.bold: root.activeTab === modelData.id
                                    }

                                    MouseArea {
                                        id: tabMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.activeTab = modelData.id
                                    }
                                }
                            }
                        }
                    }
                }

                // FTFC MATRIX BAR
                Rectangle {
                    width: parent.width
                    height: Style.space(30)
                    radius: Style.space(4)
                    color: Qt.rgba(1, 1, 1, 0.04)

                    Row {
                        anchors.centerIn: parent
                        spacing: Style.space(12)

                        Text {
                            text: "FTFC:"
                            color: root.mutedColor
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            font.bold: true
                        }

                        Repeater {
                            model: [
                                { frame: "Month", val: "2U", color: root.marketData.month_color },
                                { frame: "Week", val: "2U", color: root.marketData.week_color },
                                { frame: "Day", val: root.marketData.daily_scenario || "2U", color: root.marketData.day_color },
                                { frame: "60m", val: "2U", color: root.marketData.hour_color }
                            ]
                            delegate: Row {
                                spacing: Style.space(4)
                                Text {
                                    text: modelData.frame + ":"
                                    color: root.mutedColor
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.caption
                                }
                                Text {
                                    text: modelData.val
                                    color: modelData.color === "green" ? Qt.rgba(0.3, 0.9, 0.5, 1.0) : Qt.rgba(1.0, 0.4, 0.4, 1.0)
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.caption
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                // =========================================================
                // TAB 1: SESSION LOGGER / ACTIVE TRADE
                // =========================================================
                Column {
                    visible: root.activeTab === "session"
                    width: parent.width
                    spacing: Style.space(10)

                    // ACTIVE TRADE PRESENT -> SHOW MANAGEMENT / EXIT PANEL
                    Rectangle {
                        visible: root.activeTrade !== null
                        width: parent.width
                        implicitHeight: activeCol.implicitHeight + Style.space(20)
                        radius: Style.space(6)
                        color: Qt.rgba(0.2, 0.6, 1.0, 0.08)
                        border.color: Color.accent
                        border.width: 1

                        Column {
                            id: activeCol
                            anchors.fill: parent
                            anchors.margins: Style.space(12)
                            spacing: Style.space(8)

                            Row {
                                width: parent.width
                                Text {
                                    text: "ACTIVE POSITION: " + (root.activeTrade ? root.activeTrade.symbol + " " + root.activeTrade.direction.toUpperCase() : "")
                                    color: Color.accent
                                    font.bold: true
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.body
                                }
                                Item { Layout.fillWidth: true; width: 1; height: 1 }
                                Text {
                                    text: root.activeTrade ? root.activeTrade.combo : ""
                                    color: root.fg
                                    font.family: root.fontFamily
                                    font.pixelSize: Style.font.caption
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: Style.space(16)
                                Text {
                                    text: "Trigger: $" + (root.activeTrade ? root.activeTrade.trigger_price.toFixed(2) : "0")
                                    color: root.mutedColor
                                    font.pixelSize: Style.font.caption
                                }
                                Text {
                                    text: "Stop: $" + (root.activeTrade ? root.activeTrade.stop_loss.toFixed(2) : "0")
                                    color: Qt.rgba(1.0, 0.4, 0.4, 1.0)
                                    font.pixelSize: Style.font.caption
                                }
                                Text {
                                    text: "Target: $" + (root.activeTrade ? root.activeTrade.target_price.toFixed(2) : "0")
                                    color: Qt.rgba(0.3, 0.9, 0.5, 1.0)
                                    font.pixelSize: Style.font.caption
                                }
                                Text {
                                    text: "Size: " + (root.activeTrade ? root.activeTrade.shares : "0") + " Shs"
                                    color: root.fg
                                    font.pixelSize: Style.font.caption
                                }
                            }

                            // Close Form
                            Row {
                                width: parent.width
                                spacing: Style.space(8)
                                Text {
                                    text: "Exit Price:"
                                    color: root.fg
                                    font.pixelSize: Style.font.caption
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: Style.space(70)
                                    height: Style.space(26)
                                    radius: Style.space(4)
                                    color: Qt.rgba(1, 1, 1, 0.1)
                                    TextInput {
                                        id: exitInput
                                        anchors.centerIn: parent
                                        text: root.closeExitPrice
                                        color: root.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.caption
                                        onTextChanged: root.closeExitPrice = text
                                    }
                                }

                                Text {
                                    text: "Grade:"
                                    color: root.fg
                                    font.pixelSize: Style.font.caption
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Row {
                                    spacing: Style.space(4)
                                    Repeater {
                                        model: ["A", "B", "C", "F"]
                                        delegate: Rectangle {
                                            width: Style.space(24)
                                            height: Style.space(24)
                                            radius: Style.space(4)
                                            color: root.closeGrade === modelData ? Color.accent : Qt.rgba(1, 1, 1, 0.08)
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: root.closeGrade === modelData ? Color.background : root.fg
                                                font.pixelSize: Style.font.caption
                                                font.bold: true
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.closeGrade = modelData
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true; width: 1; height: 1 }

                                Rectangle {
                                    height: Style.space(26)
                                    width: Style.space(110)
                                    radius: Style.space(4)
                                    color: Qt.rgba(0.3, 0.8, 0.4, 0.9)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Realize & Close"
                                        color: Color.background
                                        font.bold: true
                                        font.pixelSize: Style.font.caption
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.submitCloseTrade()
                                    }
                                }
                            }
                        }
                    }

                    // NO ACTIVE TRADE -> SHOW FAST ENTRY FORM
                    Column {
                        visible: root.activeTrade === null
                        width: parent.width
                        spacing: Style.space(8)

                        // 1. DIRECTION & COMBO SELECTION
                        Row {
                            width: parent.width
                            spacing: Style.space(6)
                            // Direction toggles
                            Repeater {
                                model: ["Long", "Short"]
                                delegate: Rectangle {
                                    height: Style.space(24)
                                    width: Style.space(60)
                                    radius: Style.space(4)
                                    color: root.formDirection === modelData ? (modelData === "Long" ? Qt.rgba(0.2, 0.7, 0.3, 0.8) : Qt.rgba(0.8, 0.2, 0.2, 0.8)) : Qt.rgba(1, 1, 1, 0.08)
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.toUpperCase()
                                        color: root.formDirection === modelData ? "#ffffff" : root.fg
                                        font.pixelSize: Style.font.caption
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formDirection = modelData
                                    }
                                }
                            }

                            // Quick Combos
                            Repeater {
                                model: ["60m 2-1-2 Bull", "15m 2-2 Rev", "Daily 3-1-2", "1-2-2 Cont"]
                                delegate: Rectangle {
                                    height: Style.space(24)
                                    width: comboLbl.implicitWidth + Style.space(10)
                                    radius: Style.space(4)
                                    color: root.formCombo === modelData ? Color.accent : Qt.rgba(1, 1, 1, 0.06)
                                    Text {
                                        id: comboLbl
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: root.formCombo === modelData ? Color.background : root.fg
                                        font.pixelSize: Style.font.caption
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.formCombo = modelData
                                    }
                                }
                            }
                        }

                        // 2. LEVELS ROW (Trigger, Stop, Target)
                        Row {
                            width: parent.width
                            spacing: Style.space(8)

                            Column {
                                spacing: Style.space(2)
                                Text { text: "Trigger ($):"; color: root.mutedColor; font.pixelSize: Style.font.caption }
                                Rectangle {
                                    width: Style.space(90)
                                    height: Style.space(26)
                                    radius: Style.space(4)
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    TextInput {
                                        anchors.centerIn: parent
                                        text: root.formTriggerPrice
                                        color: root.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.caption
                                        onTextChanged: root.formTriggerPrice = text
                                    }
                                }
                            }

                            Column {
                                spacing: Style.space(2)
                                Text { text: "Stop Loss ($):"; color: root.mutedColor; font.pixelSize: Style.font.caption }
                                Rectangle {
                                    width: Style.space(90)
                                    height: Style.space(26)
                                    radius: Style.space(4)
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    TextInput {
                                        anchors.centerIn: parent
                                        text: root.formStopLoss
                                        color: root.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.caption
                                        onTextChanged: root.formStopLoss = text
                                    }
                                }
                            }

                            Column {
                                spacing: Style.space(2)
                                Text { text: "Target ($):"; color: root.mutedColor; font.pixelSize: Style.font.caption }
                                Rectangle {
                                    width: Style.space(90)
                                    height: Style.space(26)
                                    radius: Style.space(4)
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    TextInput {
                                        anchors.centerIn: parent
                                        text: root.formTargetPrice
                                        color: root.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.caption
                                        onTextChanged: root.formTargetPrice = text
                                    }
                                }
                            }

                            Column {
                                spacing: Style.space(2)
                                Text { text: "Risk ($1R):"; color: root.mutedColor; font.pixelSize: Style.font.caption }
                                Rectangle {
                                    width: Style.space(80)
                                    height: Style.space(26)
                                    radius: Style.space(4)
                                    color: Qt.rgba(1, 1, 1, 0.08)
                                    TextInput {
                                        anchors.centerIn: parent
                                        text: root.formRiskDollars
                                        color: root.fg
                                        font.family: root.fontFamily
                                        font.pixelSize: Style.font.caption
                                        onTextChanged: root.formRiskDollars = text
                                    }
                                }
                            }
                        }

                        // 3. EXECUTION DISCIPLINE & SCREENSHOT
                        Row {
                            width: parent.width
                            spacing: Style.space(8)

                            Rectangle {
                                height: Style.space(26)
                                width: Style.space(160)
                                radius: Style.space(4)
                                color: root.formScreenshot !== "" ? Qt.rgba(0.3, 0.8, 0.4, 0.3) : Qt.rgba(1, 1, 1, 0.08)
                                Text {
                                    anchors.centerIn: parent
                                    text: root.formScreenshot !== "" ? "Chart Attached" : "Capture Chart (Grim)"
                                    color: root.formScreenshot !== "" ? Qt.rgba(0.3, 0.9, 0.5, 1.0) : root.fg
                                    font.pixelSize: Style.font.caption
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.captureScreenshot(false)
                                }
                            }

                            Item { Layout.fillWidth: true; width: 1; height: 1 }

                            Rectangle {
                                height: Style.space(28)
                                width: Style.space(140)
                                radius: Style.space(4)
                                color: Color.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: "Log Strat Entry"
                                    color: Color.background
                                    font.bold: true
                                    font.pixelSize: Style.font.caption
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.submitNewTrade()
                                }
                            }
                        }
                    }
                }

                // =========================================================
                // TAB 2: ANALYTICS & REVIEW STATION
                // =========================================================
                Column {
                    visible: root.activeTab === "analytics"
                    width: parent.width
                    spacing: Style.space(10)

                    // TOP KPI STATS
                    Row {
                        width: parent.width
                        spacing: Style.space(8)

                        Rectangle {
                            width: (parent.width - Style.space(16)) / 3
                            height: Style.space(50)
                            radius: Style.space(4)
                            color: Qt.rgba(1, 1, 1, 0.05)
                            Column {
                                anchors.centerIn: parent
                                Text { text: "Net Realized R"; color: root.mutedColor; font.pixelSize: Style.font.caption }
                                Text {
                                    text: (root.stats.totalR >= 0 ? "+" : "") + root.stats.totalR + "R"
                                    color: root.stats.totalR >= 0 ? Qt.rgba(0.3, 0.9, 0.5, 1.0) : Qt.rgba(1.0, 0.4, 0.4, 1.0)
                                    font.bold: true
                                    font.pixelSize: Style.font.title
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - Style.space(16)) / 3
                            height: Style.space(50)
                            radius: Style.space(4)
                            color: Qt.rgba(1, 1, 1, 0.05)
                            Column {
                                anchors.centerIn: parent
                                Text { text: "Win Rate"; color: root.mutedColor; font.pixelSize: Style.font.caption }
                                Text {
                                    text: root.stats.winRate + "% (" + root.stats.wins + "W / " + root.stats.losses + "L)"
                                    color: root.fg
                                    font.bold: true
                                    font.pixelSize: Style.font.title
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - Style.space(16)) / 3
                            height: Style.space(50)
                            radius: Style.space(4)
                            color: Qt.rgba(1, 1, 1, 0.05)
                            Column {
                                anchors.centerIn: parent
                                Text { text: "Profit Factor"; color: root.mutedColor; font.pixelSize: Style.font.caption }
                                Text {
                                    text: String(root.stats.profitFactor)
                                    color: Color.accent
                                    font.bold: true
                                    font.pixelSize: Style.font.title
                                }
                            }
                        }
                    }

                    // STRAT COMBO BREAKDOWN
                    Text {
                        text: "PERFORMANCE BY STRAT SETUP"
                        color: root.mutedColor
                        font.pixelSize: Style.font.caption
                        font.bold: true
                    }

                    Column {
                        width: parent.width
                        spacing: Style.space(4)
                        Repeater {
                            model: root.stats.comboStats
                            delegate: Rectangle {
                                width: parent.width
                                height: Style.space(26)
                                radius: Style.space(4)
                                color: Qt.rgba(1, 1, 1, 0.04)

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: Style.space(8)
                                    anchors.rightMargin: Style.space(8)
                                    Text {
                                        text: modelData.name
                                        color: root.fg
                                        font.pixelSize: Style.font.caption
                                        width: Style.space(160)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.count + " Trades"
                                        color: root.mutedColor
                                        font.pixelSize: Style.font.caption
                                        width: Style.space(80)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.winRate + "% Win"
                                        color: root.fg
                                        font.pixelSize: Style.font.caption
                                        width: Style.space(80)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Item { Layout.fillWidth: true; width: 1; height: 1 }
                                    Text {
                                        text: (modelData.totalR >= 0 ? "+" : "") + modelData.totalR + "R"
                                        color: modelData.totalR >= 0 ? Qt.rgba(0.3, 0.9, 0.5, 1.0) : Qt.rgba(1.0, 0.4, 0.4, 1.0)
                                        font.bold: true
                                        font.pixelSize: Style.font.caption
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }

                // =========================================================
                // TAB 3: TRADE HISTORY / REPLAY
                // =========================================================
                Column {
                    visible: root.activeTab === "history"
                    width: parent.width
                    spacing: Style.space(6)

                    Repeater {
                        model: root.tradesList
                        delegate: Rectangle {
                            width: parent.width
                            height: Style.space(40)
                            radius: Style.space(4)
                            color: Qt.rgba(1, 1, 1, 0.04)

                            Row {
                                anchors.fill: parent
                                anchors.margins: Style.space(8)
                                spacing: Style.space(8)

                                Text {
                                    text: modelData.date ? modelData.date.slice(0, 10) : ""
                                    color: root.mutedColor
                                    font.pixelSize: Style.font.caption
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Style.space(70)
                                }

                                Text {
                                    text: modelData.direction.toUpperCase() + " " + modelData.combo
                                    color: root.fg
                                    font.bold: true
                                    font.pixelSize: Style.font.caption
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Style.space(160)
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "Grade: " + (modelData.grade || "A")
                                    color: root.mutedColor
                                    font.pixelSize: Style.font.caption
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Style.space(60)
                                }

                                Item { Layout.fillWidth: true; width: 1; height: 1 }

                                Text {
                                    text: modelData.status === "open" ? "OPEN" : ((modelData.realized_r >= 0 ? "+" : "") + modelData.realized_r + "R")
                                    color: modelData.status === "open" ? Color.accent : (modelData.realized_r >= 0 ? Qt.rgba(0.3, 0.9, 0.5, 1.0) : Qt.rgba(1.0, 0.4, 0.4, 1.0))
                                    font.bold: true
                                    font.pixelSize: Style.font.caption
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    visible: modelData.entry_screenshot !== ""
                                    height: Style.space(20)
                                    width: Style.space(44)
                                    radius: Style.space(3)
                                    color: Qt.rgba(1, 1, 1, 0.1)
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Chart"
                                        color: Color.accent
                                        font.pixelSize: Style.font.caption
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.openFile(modelData.entry_screenshot)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
