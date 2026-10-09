import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
    id: root
    moduleName: "juwimana.strat-journal"

    // Shape contract for Omarchy bar-widget lifecycle
    readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
    readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

    function open() { if (panelLoader.item) panelLoader.item.open() }
    function close() { if (panelLoader.item) panelLoader.item.close() }
    function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
    function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

    function injectPanel() {
        if (!panelLoader.item) return
        panelLoader.item.bar = root.bar
        panelLoader.item.settings = root.settings
        panelLoader.item.anchorItem = button
        panelLoader.item.hostWidget = root
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    onBarChanged: injectPanel()
    onSettingsChanged: injectPanel()

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("Panel.qml")
        visible: false
        onLoaded: {
            root.injectPanel()
            Qt.callLater(root.injectPanel)
        }
    }

    // Bar button representation
    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        
        text: {
            if (!panelLoader.item) return "STRAT"
            var item = panelLoader.item
            if (item.activeTrade) {
                var t = item.activeTrade
                return "GOOGL " + t.direction.toUpperCase() + " | " + t.combo
            }
            if (item.marketData && item.marketData.price > 0) {
                return "GOOGL " + item.marketData.price.toFixed(2) + " | FTFC: " + (item.marketData.daily_color === "green" ? "Bull" : "Bear")
            }
            return "STRAT JOURNAL"
        }

        fontSize: Style.font.caption
        useActiveColor: false
        foreground: {
            if (panelLoader.item && panelLoader.item.activeTrade) return Color.accent
            return bar ? bar.barForeground : Color.foreground
        }

        tooltipText: {
            if (panelLoader.item && panelLoader.item.stats) {
                var s = panelLoader.item.stats
                return "Strat Journal · Closed: " + s.closedTrades + " · Net: " + (s.totalR >= 0 ? "+" : "") + s.totalR + "R · Win: " + s.winRate + "%"
            }
            return "Strat Trading Journal & Review Station"
        }

        onPressed: function(buttonCode) {
            if (buttonCode === Qt.LeftButton) {
                root.toggle()
            } else if (buttonCode === Qt.MiddleButton) {
                if (panelLoader.item) panelLoader.item.captureScreenshot()
            }
        }
    }
}
