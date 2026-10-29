import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "juwimana.economist"
  ipcTarget: "juwimana.economist"

  // Data State
  property var issueData: null
  property var currentIssue: issueData ? issueData.current_issue : null
  property var archive: (issueData && issueData.archive) ? issueData.archive : []
  property var articles: (issueData && issueData.articles) ? issueData.articles : []
  property int selectedArchiveIndex: 0

  readonly property var activeIssue: {
    if (root.archive && root.archive.length > root.selectedArchiveIndex) {
      return root.archive[root.selectedArchiveIndex]
    }
    return root.currentIssue
  }

  property bool isFetching: false
  property string statusMessage: ""
  property string lastUpdated: ""
  readonly property string runnerPath: Qt.resolvedUrl("economist-fetch").toString().replace(/^file:\/\//, "")

  // UI Theme styling
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color accentColor: "#E51C1C" // Iconic Economist Crimson
  readonly property color mutedColor: Color.muted
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int panelWidth: Style.space(440)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function openUrl(url) {
    if (!url || url === "") return
    var opened = false
    try {
      opened = Qt.openUrlExternally(url)
    } catch (e) {
      opened = false
    }
    if (!opened) {
      Quickshell.execDetached(["xdg-open", url])
    }
  }

  function fetchData(force) {
    if (fetchProcess.running || root.isFetching) return
    root.isFetching = true
    root.statusMessage = force ? "Refreshing latest issue..." : "Checking feed..."
    if (force) {
      fetchProcess.command = [root.runnerPath, "refresh"]
    } else {
      fetchProcess.command = [root.runnerPath, "json"]
    }
    fetchProcess.running = true
  }

  function postDiscord() {
    if (discordProcess.running) return
    root.statusMessage = "Posting cover to Discord..."
    discordProcess.running = true
  }

  function nextIssue() {
    if (root.selectedArchiveIndex > 0) {
      root.selectedArchiveIndex--
    }
  }

  function prevIssue() {
    if (root.selectedArchiveIndex < root.archive.length - 1) {
      root.selectedArchiveIndex++
      // Ensure image is downloaded
      var item = root.archive[root.selectedArchiveIndex]
      if (item && (!item.local_image || item.local_image === "")) {
        cacheCoverProcess.command = [root.runnerPath, "cache-cover", "--date", item.date]
        cacheCoverProcess.running = true
      }
    }
  }

  function parseData(raw) {
    try {
      var data = JSON.parse((raw || "").trim())
      if (data && data.current_issue) {
        root.issueData = data
        var now = new Date()
        root.lastUpdated = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        root.statusMessage = ""
      }
    } catch (e) {
      root.statusMessage = "Parse error"
    }
  }

  Component.onCompleted: {
    root.fetchData(false)
  }

  // -------------------------------------------------------------
  // PROCESSES
  // -------------------------------------------------------------
  Process {
    id: fetchProcess
    command: [root.runnerPath, "json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.isFetching = false
        root.parseData(text)
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.isFetching = false
        if (text && text.trim() !== "") {
          console.warn("[economist] fetch stderr:", text.trim())
        }
      }
    }
  }

  Process {
    id: discordProcess
    command: [root.runnerPath, "discord"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var res = JSON.parse(text || "{}")
          if (res.success) {
            root.statusMessage = "Posted to Discord!"
          } else {
            root.statusMessage = "Discord webhook failed"
          }
        } catch (e) {
          root.statusMessage = "Discord error"
        }
      }
    }
  }

  Process {
    id: cacheCoverProcess
    command: [root.runnerPath, "cache-cover"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var res = JSON.parse(text || "{}")
          if (res.success && res.path) {
            var arc = root.archive.slice(0)
            if (arc[root.selectedArchiveIndex]) {
              arc[root.selectedArchiveIndex].local_image = res.path
              root.archive = arc
            }
          }
        } catch (e) {}
      }
    }
  }

  Timer {
    id: autoRefreshTimer
    interval: 3600000 // 1 hour
    running: true
    repeat: true
    onTriggered: root.fetchData(false)
  }

  // -------------------------------------------------------------
  // BAR WIDGET BUTTON
  // -------------------------------------------------------------
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: {
      if (root.currentIssue && root.currentIssue.short_date) {
        return "\uf1ea " + root.currentIssue.short_date
      }
      return "\uf1ea Economist"
    }
    fontSize: Style.bar.iconFont
    foreground: bar ? bar.barForeground : Color.foreground
    tooltipText: {
      if (root.currentIssue && root.currentIssue.title) {
        return "The Economist · " + root.currentIssue.title + " (" + root.currentIssue.formatted_date + ")"
      }
      return "The Economist · Weekly Edition"
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) {
        root.toggle()
      } else if (buttonCode === Qt.MiddleButton) {
        root.fetchData(true)
      }
    }
  }

  // -------------------------------------------------------------
  // POPUP KEYBOARD PANEL
  // -------------------------------------------------------------
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.panelWidth)
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight, Style.space(660))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (dx < 0) root.prevIssue()
        else if (dx > 0) root.nextIssue()
      }

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_R && !event.isAutoRepeat) {
          root.fetchData(true)
          event.accepted = true
        } else if (event.key === Qt.Key_O || event.key === Qt.Key_Return) {
          if (root.activeIssue && root.activeIssue.link) {
            root.openUrl(root.activeIssue.link)
            event.accepted = true
          }
        } else if (event.key === Qt.Key_D) {
          root.postDiscord()
          event.accepted = true
        }
      }
    }

    Flickable {
      id: scroller
      anchors.fill: parent
      contentWidth: width
      contentHeight: mainColumn.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: mainColumn
        width: parent.width
        spacing: Style.space(12)
        topPadding: Style.space(14)
        bottomPadding: Style.space(16)
        leftPadding: Style.space(16)
        rightPadding: Style.space(16)

        // --------------------------------------------------------
        // HEADER ROW: Red Branding + Controls
        // --------------------------------------------------------
        RowLayout {
          width: parent.width

          Row {
            spacing: Style.space(8)
            Layout.alignment: Qt.AlignVCenter

            // Red Economist Tag
            Rectangle {
              height: Style.space(22)
              width: tagText.implicitWidth + Style.space(14)
              radius: Style.space(3)
              color: root.accentColor
              anchors.verticalCenter: parent.verticalCenter

              Text {
                id: tagText
                anchors.centerIn: parent
                text: "THE ECONOMIST"
                color: "#FFFFFF"
                font.bold: true
                font.pixelSize: Style.font.caption
                font.family: root.fontFamily
                textFormat: Text.PlainText
              }
            }

            Text {
              textFormat: Text.PlainText
              text: root.activeIssue ? root.activeIssue.formatted_date : "Weekly Edition"
              color: root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Item { Layout.fillWidth: true }

          // Action Buttons: Discord, Refresh, Close
          Row {
            spacing: Style.space(6)
            Layout.alignment: Qt.AlignVCenter

            // Discord Share Button
            Rectangle {
              width: Style.space(26)
              height: Style.space(24)
              radius: Style.space(4)
              color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

              Text {
                anchors.centerIn: parent
                text: "\uf392" // Discord logo
                font.family: root.fontFamily
                color: root.fg
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.postDiscord()
              }
            }

            // Refresh Button
            Rectangle {
              width: Style.space(26)
              height: Style.space(24)
              radius: Style.space(4)
              color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

              Text {
                anchors.centerIn: parent
                text: root.isFetching ? "..." : "\uf021" // Refresh
                font.family: root.fontFamily
                color: root.fg
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.fetchData(true)
              }
            }

            // Close
            Rectangle {
              width: Style.space(26)
              height: Style.space(24)
              radius: Style.space(4)
              color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

              Text {
                anchors.centerIn: parent
                text: "\uf00d" // Close 'X'
                font.family: root.fontFamily
                color: root.mutedColor
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
              }
            }
          }
        }

        // Status / notification alert if present
        Text {
          visible: root.statusMessage !== ""
          textFormat: Text.PlainText
          text: root.statusMessage
          color: root.accentColor
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        // --------------------------------------------------------
        // COVER ARTWORK HERO DISPLAY
        // --------------------------------------------------------
        Rectangle {
          width: parent.width
          height: Style.space(250)
          radius: Style.space(6)
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.03)
          border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
          border.width: 1
          clip: true

          Image {
            id: coverImage
            anchors.centerIn: parent
            height: parent.height - Style.space(8)
            width: parent.width - Style.space(8)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            source: {
              if (!root.activeIssue) return ""
              if (root.activeIssue.local_image && root.activeIssue.local_image.indexOf("/") === 0) {
                return "file://" + root.activeIssue.local_image
              }
              return root.activeIssue.image_url || ""
            }

            // Fallback placeholder while loading
            Rectangle {
              anchors.fill: parent
              visible: coverImage.status !== Image.Ready
              color: "transparent"
              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: coverImage.status === Image.Loading ? "Loading cover art..." : "Cover artwork unavailable"
                color: root.mutedColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
              if (root.activeIssue && root.activeIssue.link) {
                root.openUrl(root.activeIssue.link)
              }
            }
          }
        }

        // --------------------------------------------------------
        // ARCHIVE NAVIGATION (< Previous | Next >)
        // --------------------------------------------------------
        RowLayout {
          width: parent.width

          Rectangle {
            width: Style.space(80)
            height: Style.space(26)
            radius: Style.space(4)
            color: root.selectedArchiveIndex < root.archive.length - 1 ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06) : "transparent"
            opacity: root.selectedArchiveIndex < root.archive.length - 1 ? 1.0 : 0.3

            Row {
              anchors.centerIn: parent
              spacing: Style.space(4)
              Text { text: "\uf053"; color: root.fg; font.family: root.fontFamily; font.pixelSize: Style.font.caption; textFormat: Text.PlainText }
              Text { text: "Prev"; color: root.fg; font.family: root.fontFamily; font.pixelSize: Style.font.caption; textFormat: Text.PlainText }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: root.selectedArchiveIndex < root.archive.length - 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: root.prevIssue()
            }
          }

          Item { Layout.fillWidth: true }

          Text {
            textFormat: Text.PlainText
            text: (root.selectedArchiveIndex === 0) ? "Latest Issue" : ("Issue " + (root.selectedArchiveIndex + 1) + " of " + root.archive.length)
            color: root.selectedArchiveIndex === 0 ? root.accentColor : root.mutedColor
            font.family: root.fontFamily
            font.bold: root.selectedArchiveIndex === 0
            font.pixelSize: Style.font.caption
          }

          Item { Layout.fillWidth: true }

          Rectangle {
            width: Style.space(80)
            height: Style.space(26)
            radius: Style.space(4)
            color: root.selectedArchiveIndex > 0 ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06) : "transparent"
            opacity: root.selectedArchiveIndex > 0 ? 1.0 : 0.3

            Row {
              anchors.centerIn: parent
              spacing: Style.space(4)
              Text { text: "Next"; color: root.fg; font.family: root.fontFamily; font.pixelSize: Style.font.caption; textFormat: Text.PlainText }
              Text { text: "\uf054"; color: root.fg; font.family: root.fontFamily; font.pixelSize: Style.font.caption; textFormat: Text.PlainText }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: root.selectedArchiveIndex > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: root.nextIssue()
            }
          }
        }

        // --------------------------------------------------------
        // COVER STORY HEADLINE
        // --------------------------------------------------------
        Rectangle {
          width: parent.width
          implicitHeight: coverStoryCol.implicitHeight + Style.space(16)
          radius: Style.space(6)
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04)
          border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
          border.width: 1

          Column {
            id: coverStoryCol
            anchors.fill: parent
            anchors.margins: Style.space(10)
            spacing: Style.space(4)

            Text {
              textFormat: Text.PlainText
              text: "COVER STORY"
              color: root.accentColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              width: parent.width
              wrapMode: Text.WordWrap
              textFormat: Text.PlainText
              text: (root.activeIssue && root.activeIssue.title) ? root.activeIssue.title : "Weekly Cover Edition"
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.activeIssue && root.activeIssue.link) {
                root.openUrl(root.activeIssue.link)
              }
            }
          }
        }

        // --------------------------------------------------------
        // EDITORIAL LEADERS & TOP STORIES
        // --------------------------------------------------------
        Text {
          textFormat: Text.PlainText
          text: "WEEKLY LEADERS & BRIEFINGS"
          color: root.mutedColor
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          topPadding: Style.space(4)
        }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.articles

            Rectangle {
              width: parent.width
              implicitHeight: articleCol.implicitHeight + Style.space(12)
              radius: Style.space(4)
              color: articleHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.02)
              border.color: articleHover.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.3) : "transparent"
              border.width: 1

              Column {
                id: articleCol
                anchors.fill: parent
                anchors.margins: Style.space(8)
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  wrapMode: Text.WordWrap
                  textFormat: Text.PlainText
                  text: modelData.title || ""
                  color: articleHover.containsMouse ? root.accentColor : root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                Text {
                  visible: modelData.description && modelData.description !== ""
                  width: parent.width
                  wrapMode: Text.WordWrap
                  textFormat: Text.PlainText
                  text: modelData.description || ""
                  color: root.mutedColor
                  font.family: root.fontFamily
                  font.pixelSize: Math.max(9, Style.font.caption - 1)
                  maximumLineCount: 2
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: articleHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (modelData.link) {
                    root.openUrl(modelData.link)
                  }
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // FOOTER BUTTON: Read Full Edition
        // --------------------------------------------------------
        Rectangle {
          width: parent.width
          height: Style.space(34)
          radius: Style.space(4)
          color: footerHover.containsMouse ? Qt.darker(root.accentColor, 1.15) : root.accentColor

          Row {
            anchors.centerIn: parent
            spacing: Style.space(8)

            Text {
              text: "\uf08e" // External link
              font.family: root.fontFamily
              color: "#FFFFFF"
              font.pixelSize: Style.font.caption
            }

            Text {
              textFormat: Text.PlainText
              text: "Read Complete Edition on Economist.com"
              color: "#FFFFFF"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }

          MouseArea {
            id: footerHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.activeIssue && root.activeIssue.link) {
                root.openUrl(root.activeIssue.link)
              }
            }
          }
        }
      }
    }
  }
}
