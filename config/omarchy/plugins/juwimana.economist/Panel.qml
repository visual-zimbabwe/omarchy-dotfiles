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
  readonly property int panelWidth: Style.space(660)

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

  function openLocalImage(path) {
    if (!path || path === "") return
    Quickshell.execDetached(["xdg-open", path])
  }

  function fetchData(force) {
    if (fetchProcess.running || root.isFetching) return
    root.isFetching = true
    root.statusMessage = force ? "Refreshing..." : ""
    fetchProcess.command = force ? [root.runnerPath, "refresh"] : [root.runnerPath, "json"]
    fetchProcess.running = true
  }

  function postDiscord() {
    if (discordProcess.running) return
    root.statusMessage = "Posting to Discord..."
    discordProcess.command = [root.runnerPath, "discord", "--source", root.currentSourceKey, "--index", String(root.selectedCoverIndex)]
    discordProcess.running = true
  }

  function selectSource(key) {
    root.currentSourceKey = key
    root.selectedCoverIndex = 0
  }

  function nextCover() {
    if (root.coversList.length <= 1) return
    if (root.selectedCoverIndex < root.coversList.length - 1) {
      root.selectedCoverIndex++
    } else {
      root.selectedCoverIndex = 0
    }
  }

  function prevCover() {
    if (root.coversList.length <= 1) return
    if (root.selectedCoverIndex > 0) {
      root.selectedCoverIndex--
    } else {
      root.selectedCoverIndex = root.coversList.length - 1
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
      root.statusMessage = "Data error"
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
  // POPUP KEYBOARD PANEL (POLISHED MAGAZINE VIEWER)
  // -------------------------------------------------------------
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.panelWidth)
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight)

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
        } else if (event.key === Qt.Key_V || event.key === Qt.Key_Space) {
          if (root.activeCover) {
            if (root.activeCover.local_image) root.openLocalImage(root.activeCover.local_image)
            else root.openUrl(root.activeCover.image_url)
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
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
          root.prevCover()
          event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
          root.nextCover()
          event.accepted = true
        }
      }

      ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(8)

        // --------------------------------------------------------
        // 1. SOURCE SELECTOR TABS (Economist, New Yorker, Barron's, Newsweek)
        // --------------------------------------------------------
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(36)
          implicitHeight: Style.space(36)

          RowLayout {
            anchors.fill: parent
            spacing: Style.space(4)

            Repeater {
              model: [
                { id: "economist", name: "The Economist", color: "#E51C1C" },
                { id: "newyorker", name: "The New Yorker", color: "#D97706" },
                { id: "barrons", name: "Barron's", color: "#2563EB" },
                { id: "newsweek", name: "Newsweek", color: "#E10600" }
              ]

              Rectangle {
                id: tabRect
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.space(4)

                readonly property bool isCurrent: root.currentSourceKey === modelData.id
                readonly property bool isHovered: tabMouse.containsMouse

                color: isCurrent ?
                       Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.16) :
                       (isHovered ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04))

                border.color: isCurrent ? modelData.color : "transparent"
                border.width: isCurrent ? 1.5 : 0

                Row {
                  anchors.centerIn: parent
                  spacing: Style.space(5)

                  // Accent dot for active source
                  Rectangle {
                    width: Style.space(5)
                    height: Style.space(5)
                    radius: Style.space(2.5)
                    color: modelData.color
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tabRect.isCurrent
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: tabRect.isCurrent ? root.fg : root.mutedColor
                    font.family: root.fontFamily
                    font.bold: tabRect.isCurrent
                    font.pixelSize: Math.max(10, Style.font.caption)
                    textFormat: Text.PlainText
                  }
                }

                MouseArea {
                  id: tabMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.selectSource(modelData.id)
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // 2. HERO COVER ART DISPLAY (LARGE, CRISP & INTERACTIVE)
        // --------------------------------------------------------
        Rectangle {
          id: heroFrame
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(500)
          implicitHeight: Style.space(500)
          radius: Style.space(6)
          color: Qt.rgba(0, 0, 0, 0.24)
          border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
          border.width: 1
          clip: true

          // Main High-Res Cover Artwork
          Image {
            id: mainCoverImage
            anchors.centerIn: parent
            height: parent.height - Style.space(12)
            width: parent.width - Style.space(12)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: true
            cache: true
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

          // Publication Brand Pill (Top-Left)
          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Style.space(8)
            height: Style.space(22)
            width: magBadgeText.implicitWidth + Style.space(14)
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

          // Issue Index Pill (Top-Right: e.g. "Cover 1 of 5")
          Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Style.space(8)
            height: Style.space(22)
            width: idxBadgeText.implicitWidth + Style.space(14)
            radius: Style.space(3)
            color: Qt.rgba(0, 0, 0, 0.6)
            border.color: Qt.rgba(255, 255, 255, 0.15)
            border.width: 1

            Text {
              id: idxBadgeText
              anchors.centerIn: parent
              text: {
                if (root.coversList.length > 0) {
                  return root.selectedCoverIndex === 0 ? "Latest Issue" : ((root.selectedCoverIndex + 1) + " of " + root.coversList.length)
                }
                return ""
              }
              color: "#FFFFFF"
              font.pixelSize: Math.max(9, Style.font.caption - 2)
              font.family: root.fontFamily
              textFormat: Text.PlainText
            }
          }

          // Left Arrow Button (Previous Cover)
          Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(32)
            height: Style.space(32)
            radius: Style.space(16)
            color: leftArrowMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.25)
            border.width: 1
            visible: heroMouse.containsMouse || leftArrowMouse.containsMouse
            z: 2

            Text {
              anchors.centerIn: parent
              text: "\uf053"
              color: "#FFFFFF"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: leftArrowMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.prevCover()
            }
          }

          // Right Arrow Button (Next Cover)
          Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(32)
            height: Style.space(32)
            radius: Style.space(16)
            color: rightArrowMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.45)
            border.color: Qt.rgba(255, 255, 255, 0.25)
            border.width: 1
            visible: heroMouse.containsMouse || rightArrowMouse.containsMouse
            z: 2

            Text {
              anchors.centerIn: parent
              text: "\uf054"
              color: "#FFFFFF"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: rightArrowMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.nextCover()
            }
          }

          // Bottom Hover Hint Badge
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: Style.space(10)
            height: Style.space(24)
            width: zoomHintText.implicitWidth + Style.space(18)
            radius: Style.space(4)
            color: Qt.rgba(0, 0, 0, 0.75)
            border.color: Qt.rgba(255, 255, 255, 0.2)
            border.width: 1
            visible: heroMouse.containsMouse
            z: 2

            Row {
              anchors.centerIn: parent
              spacing: Style.space(5)
              Text {
                text: "\uf00e"
                color: "#FFFFFF"
                font.family: root.fontFamily
                font.pixelSize: Math.max(9, Style.font.caption - 1)
              }
              Text {
                id: zoomHintText
                text: "Click to open full size"
                color: "#FFFFFF"
                font.family: root.fontFamily
                font.pixelSize: Math.max(9, Style.font.caption - 1)
                textFormat: Text.PlainText
              }
            }
          }

          // Cover Click Area: open full image
          MouseArea {
            id: heroMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.activeCover) {
                if (root.activeCover.local_image) {
                  root.openLocalImage(root.activeCover.local_image)
                } else if (root.activeCover.source_url || root.activeCover.image_url) {
                  root.openUrl(root.activeCover.source_url || root.activeCover.image_url)
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // 3. CAPTION: Headline & Date of Active Cover
        // --------------------------------------------------------
        ColumnLayout {
          id: captionCol
          Layout.fillWidth: true
          spacing: Style.space(2)

          Text {
            id: titleLabel
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            textFormat: Text.PlainText
            text: (root.activeCover && root.activeCover.title) ? root.activeCover.title : ""
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            id: dateLabel
            Layout.fillWidth: true
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
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(92)
          implicitHeight: Style.space(92)

          RowLayout {
            anchors.fill: parent
            spacing: Style.space(6)

            Repeater {
              model: root.coversList

              Rectangle {
                id: thumbCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.space(4)

                readonly property bool isSelected: root.selectedCoverIndex === index
                readonly property bool isHovered: thumbMouse.containsMouse

                color: isSelected ?
                       Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16) :
                       (isHovered ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.03))

                border.color: isSelected ? root.accentColor : (isHovered ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.25) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1))
                border.width: isSelected ? 2 : 1
                clip: true

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: Style.space(4)
                  spacing: Style.space(2)

                  Image {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    asynchronous: true
                    cache: true
                    source: {
                      if (modelData.local_image && modelData.local_image.indexOf("/") === 0) {
                        return "file://" + modelData.local_image
                      }
                      return modelData.image_url || ""
                    }
                  }

                  Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData.label || ("#" + (index + 1))
                    color: thumbCard.isSelected ? root.fg : root.mutedColor
                    font.family: root.fontFamily
                    font.pixelSize: Math.max(9, Style.font.caption - 2)
                    font.bold: thumbCard.isSelected
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: thumbMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.selectedCoverIndex = index
                  }
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // 5. BOTTOM ACTION CONTROLS BAR
        // --------------------------------------------------------
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(40)
          implicitHeight: Style.space(40)

          RowLayout {
            anchors.fill: parent
            spacing: Style.space(6)

            // "Open Issue" Action Button (Web Article)
            Rectangle {
              Layout.preferredHeight: Style.space(32)
              Layout.preferredWidth: openRow.implicitWidth + Style.space(18)
              radius: Style.space(4)
              color: openHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

              Row {
                id: openRow
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
                  text: "Open Issue"
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

            // "High-Res" Action Button (Viewer)
            Rectangle {
              Layout.preferredHeight: Style.space(32)
              Layout.preferredWidth: highResRow.implicitWidth + Style.space(18)
              radius: Style.space(4)
              color: highResHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

              Row {
                id: highResRow
                anchors.centerIn: parent
                spacing: Style.space(6)

                Text {
                  text: "\uf00e"
                  font.family: root.fontFamily
                  color: root.fg
                  font.pixelSize: Style.font.caption
                }

                Text {
                  textFormat: Text.PlainText
                  text: "Full Res"
                  color: root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }

              MouseArea {
                id: highResHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.activeCover) {
                    if (root.activeCover.local_image) {
                      root.openLocalImage(root.activeCover.local_image)
                    } else {
                      root.openUrl(root.activeCover.image_url)
                    }
                  }
                }
              }
            }

            // Status message in center
            Text {
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
              textFormat: Text.PlainText
              text: root.statusMessage
              color: root.accentColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              visible: root.statusMessage !== ""
            }

            Item {
              Layout.fillWidth: true
              visible: root.statusMessage === ""
            }

            // Discord Share
            Rectangle {
              Layout.preferredWidth: Style.space(36)
              Layout.preferredHeight: Style.space(32)
              radius: Style.space(4)
              color: discordHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.14) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)

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
              Layout.preferredWidth: Style.space(36)
              Layout.preferredHeight: Style.space(32)
              radius: Style.space(4)
              color: refHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.14) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)

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
            Layout.preferredWidth: Style.space(36)
            Layout.preferredHeight: Style.space(32)
            radius: Style.space(4)
            color: closeHover.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.14) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05)

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
}
