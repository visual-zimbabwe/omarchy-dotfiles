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
  property var rawData: null
  property string currentSourceKey: "economist"
  property int selectedCoverIndex: 0

  readonly property var activeSource: {
    if (root.rawData && root.rawData.sources && root.rawData.sources[root.currentSourceKey]) {
      return root.rawData.sources[root.currentSourceKey]
    }
    return { name: "The Economist", color: "#E51C1C", covers: [] }
  }

  readonly property var coversList: (root.activeSource && root.activeSource.covers) ? root.activeSource.covers : []

  readonly property var activeCover: {
    if (root.coversList && root.coversList.length > root.selectedCoverIndex) {
      return root.coversList[root.selectedCoverIndex]
    }
    return null
  }

  property bool isFetching: false
  property string statusMessage: ""
  readonly property string runnerPath: Qt.resolvedUrl("economist-fetch").toString().replace(/^file:\/\//, "")

  // UI Theme styling
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color accentColor: (root.activeSource && root.activeSource.color) ? root.activeSource.color : Color.accent
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
    root.statusMessage = force ? "Refreshing covers..." : ""
    fetchProcess.command = force ? [root.runnerPath, "refresh"] : [root.runnerPath, "json"]
    fetchProcess.running = true
  }

  function postDiscord() {
    if (discordProcess.running) return
    root.statusMessage = "Posting cover to Discord..."
    discordProcess.command = [root.runnerPath, "discord", "--source", root.currentSourceKey, "--index", String(root.selectedCoverIndex)]
    discordProcess.running = true
  }

  function selectSource(key) {
    root.currentSourceKey = key
    root.selectedCoverIndex = 0
  }

  function nextCover() {
    if (root.selectedCoverIndex < root.coversList.length - 1) {
      root.selectedCoverIndex++
    } else {
      root.selectedCoverIndex = 0
    }
  }

  function prevCover() {
    if (root.selectedCoverIndex > 0) {
      root.selectedCoverIndex--
    } else {
      root.selectedCoverIndex = Math.max(0, root.coversList.length - 1)
    }
  }

  function parseData(raw) {
    try {
      var data = JSON.parse((raw || "").trim())
      if (data && data.sources) {
        root.rawData = data
        if (data.active_source && (!root.rawData || root.currentSourceKey === "economist")) {
          root.currentSourceKey = data.active_source
        }
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

  Timer {
    id: autoRefreshTimer
    interval: 7200000 // 2 hours
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
      if (root.activeCover && root.activeCover.label) {
        var prefix = root.currentSourceKey === "economist" ? "Economist" :
                     (root.currentSourceKey === "newyorker" ? "New Yorker" :
                     (root.currentSourceKey === "barrons" ? "Barron's" : "Newsweek"))
        return "\uf1ea " + prefix + " · " + root.activeCover.label
      }
      return "\uf1ea Magazine Covers"
    }
    fontSize: Style.bar.iconFont
    foreground: bar ? bar.barForeground : Color.foreground
    tooltipText: root.activeCover ? (root.activeSource.name + " · " + root.activeCover.formatted_date) : "Magazine Cover Viewer"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) {
        root.toggle()
      } else if (buttonCode === Qt.MiddleButton) {
        root.fetchData(true)
      }
    }
  }

  // -------------------------------------------------------------
  // POPUP KEYBOARD PANEL (COVER-FOCUSED VIEWER)
  // -------------------------------------------------------------
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.panelWidth)
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight, Style.space(620))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onCloseRequested: root.close()
      onTabRequested: function(direction) {
        var keys = ["economist", "newyorker", "barrons", "newsweek"]
        var idx = keys.indexOf(root.currentSourceKey)
        if (direction > 0) {
          idx = (idx + 1) % keys.length
        } else {
          idx = (idx - 1 + keys.length) % keys.length
        }
        root.selectSource(keys[idx])
      }
      onMoveRequested: function(dx, dy) {
        if (dx < 0 || dy < 0) root.prevCover()
        else if (dx > 0 || dy > 0) root.nextCover()
      }

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_R && !event.isAutoRepeat) {
          root.fetchData(true)
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_O) {
          if (root.activeCover && (root.activeCover.source_url || root.activeCover.image_url)) {
            root.openUrl(root.activeCover.source_url || root.activeCover.image_url)
            event.accepted = true
          }
        } else if (event.key === Qt.Key_D) {
          root.postDiscord()
          event.accepted = true
        } else if (event.key === Qt.Key_1) {
          root.selectSource("economist")
          event.accepted = true
        } else if (event.key === Qt.Key_2) {
          root.selectSource("newyorker")
          event.accepted = true
        } else if (event.key === Qt.Key_3) {
          root.selectSource("barrons")
          event.accepted = true
        } else if (event.key === Qt.Key_4) {
          root.selectSource("newsweek")
          event.accepted = true
        }
      }
    }

    Item {
      anchors.fill: parent

      Column {
        id: mainColumn
        width: parent.width
        spacing: Style.space(10)
        topPadding: Style.space(14)
        bottomPadding: Style.space(14)
        leftPadding: Style.space(16)
        rightPadding: Style.space(16)

        // --------------------------------------------------------
        // 1. MAGAZINE SOURCE TABS (Economist, New Yorker, Barron's, Newsweek)
        // --------------------------------------------------------
        RowLayout {
          width: parent.width
          spacing: Style.space(4)

          Repeater {
            model: [
              { id: "economist", name: "The Economist", color: "#E51C1C" },
              { id: "newyorker", name: "New Yorker", color: "#333333" },
              { id: "barrons", name: "Barron's", color: "#0F4C81" },
              { id: "newsweek", name: "Newsweek", color: "#E10600" }
            ]

            Rectangle {
              Layout.fillWidth: true
              height: Style.space(26)
              radius: Style.space(4)
              color: root.currentSourceKey === modelData.id ?
                     Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) :
                     Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.03)
              border.color: root.currentSourceKey === modelData.id ? modelData.color : "transparent"
              border.width: root.currentSourceKey === modelData.id ? 1.5 : 0

              Text {
                anchors.centerIn: parent
                text: modelData.name
                color: root.currentSourceKey === modelData.id ? root.fg : root.mutedColor
                font.family: root.fontFamily
                font.bold: root.currentSourceKey === modelData.id
                font.pixelSize: Math.max(10, Style.font.caption)
                textFormat: Text.PlainText
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectSource(modelData.id)
              }
            }
          }
        }

        // --------------------------------------------------------
        // 2. MAIN COVER ARTWORK HERO DISPLAY (LARGE & CLEAN)
        // --------------------------------------------------------
        Rectangle {
          width: parent.width
          height: Style.space(330)
          radius: Style.space(6)
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.03)
          border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
          border.width: 1
          clip: true

          Image {
            id: mainCoverImage
            anchors.centerIn: parent
            height: parent.height - Style.space(12)
            width: parent.width - Style.space(12)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            source: {
              if (!root.activeCover) return ""
              if (root.activeCover.local_image && root.activeCover.local_image.indexOf("/") === 0) {
                return "file://" + root.activeCover.local_image
              }
              return root.activeCover.image_url || ""
            }

            Rectangle {
              anchors.fill: parent
              visible: mainCoverImage.status !== Image.Ready
              color: "transparent"
              Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: mainCoverImage.status === Image.Loading ? "Loading cover art..." : "Cover art unavailable"
                color: root.mutedColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }

          // Subtle publication logo or pill badge in top-left
          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Style.space(8)
            height: Style.space(20)
            width: magBadgeText.implicitWidth + Style.space(12)
            radius: Style.space(3)
            color: root.accentColor

            Text {
              id: magBadgeText
              anchors.centerIn: parent
              text: root.activeSource ? root.activeSource.name.toUpperCase() : ""
              color: "#FFFFFF"
              font.bold: true
              font.pixelSize: Math.max(9, Style.font.caption - 2)
              font.family: root.fontFamily
              textFormat: Text.PlainText
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.activeCover && (root.activeCover.source_url || root.activeCover.image_url)) {
                root.openUrl(root.activeCover.source_url || root.activeCover.image_url)
              }
            }
          }
        }

        // Status banner if present
        Text {
          visible: root.statusMessage !== ""
          textFormat: Text.PlainText
          text: root.statusMessage
          color: Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          width: parent.width
        }

        // --------------------------------------------------------
        // 3. CAPTION: Date & Title of Active Cover
        // --------------------------------------------------------
        Column {
          width: parent.width
          spacing: Style.space(2)

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: (root.activeCover && root.activeCover.title) ? root.activeCover.title : ""
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            text: (root.activeCover && root.activeCover.formatted_date) ? root.activeCover.formatted_date : ""
            color: root.mutedColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        // --------------------------------------------------------
        // 4. THE LAST FIVE COVERS (INTERACTIVE THUMBNAIL STRIP)
        // --------------------------------------------------------
        RowLayout {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.coversList

            Rectangle {
              Layout.fillWidth: true
              height: Style.space(80)
              radius: Style.space(4)
              color: root.selectedCoverIndex === index ?
                     Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1) :
                     Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.03)
              border.color: root.selectedCoverIndex === index ? root.accentColor : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)
              border.width: root.selectedCoverIndex === index ? 2 : 1
              clip: true

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(4)
                spacing: Style.space(3)

                Image {
                  width: parent.width
                  height: Style.space(52)
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  source: {
                    if (modelData.local_image && modelData.local_image.indexOf("/") === 0) {
                      return "file://" + modelData.local_image
                    }
                    return modelData.image_url || ""
                  }
                }

                Text {
                  width: parent.width
                  horizontalAlignment: Text.AlignHCenter
                  text: modelData.label || ("#" + (index + 1))
                  color: root.selectedCoverIndex === index ? root.fg : root.mutedColor
                  font.family: root.fontFamily
                  font.pixelSize: Math.max(9, Style.font.caption - 2)
                  font.bold: root.selectedCoverIndex === index
                  textFormat: Text.PlainText
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.selectedCoverIndex = index
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // 5. MINIMAL BOTTOM ACTION CONTROLS
        // --------------------------------------------------------
        RowLayout {
          width: parent.width
          spacing: Style.space(8)

          // Open Full Cover Link
          Rectangle {
            Layout.fillWidth: true
            height: Style.space(30)
            radius: Style.space(4)
            color: openHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)

            Row {
              anchors.centerIn: parent
              spacing: Style.space(6)

              Text {
                text: "\uf08e"
                font.family: root.fontFamily
                color: root.fg
                font.pixelSize: Style.font.caption
              }

              Text {
                textFormat: Text.PlainText
                text: "Open Full Issue"
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }

            MouseArea {
              id: openHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.activeCover && (root.activeCover.source_url || root.activeCover.image_url)) {
                  root.openUrl(root.activeCover.source_url || root.activeCover.image_url)
                }
              }
            }
          }

          // Discord Share
          Rectangle {
            width: Style.space(36)
            height: Style.space(30)
            radius: Style.space(4)
            color: discordHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)

            Text {
              anchors.centerIn: parent
              text: "\uf392"
              font.family: root.fontFamily
              color: root.fg
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: discordHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.postDiscord()
            }
          }

          // Refresh
          Rectangle {
            width: Style.space(36)
            height: Style.space(30)
            radius: Style.space(4)
            color: refHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)

            Text {
              anchors.centerIn: parent
              text: root.isFetching ? "..." : "\uf021"
              font.family: root.fontFamily
              color: root.fg
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: refHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.fetchData(true)
            }
          }

          // Close
          Rectangle {
            width: Style.space(36)
            height: Style.space(30)
            radius: Style.space(4)
            color: closeHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)

            Text {
              anchors.centerIn: parent
              text: "\uf00d"
              font.family: root.fontFamily
              color: root.mutedColor
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: closeHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.close()
            }
          }
        }
      }
    }
  }
}
