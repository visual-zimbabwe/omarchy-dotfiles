import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "juwimana.omarchy-clock"
  ipcTarget: "juwimana.omarchy-clock"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var clockService: null
  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property int currentTab: 1 // default to World clock

  onClockServiceChanged: {
    if (clockService && clockService.activeTab !== undefined) {
      root.currentTab = clockService.activeTab
    }
  }

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function tabTitle() {
    if (root.currentTab === 0) return "Alarm"
    if (root.currentTab === 1) return "World clock"
    if (root.currentTab === 2) return "Stopwatch"
    if (root.currentTab === 3) return "Timer"
    return "Clock"
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(Style.space(620))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Item {
        anchors.fill: parent

        // Click shield so internal mouse events never bubble to layer-shell dismissArea
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onPressed: function(mouse) { mouse.accepted = true }
          onReleased: function(mouse) { mouse.accepted = true }
          onClicked: function(mouse) { mouse.accepted = true }
        }

        // ----------------------------------------------------
        // Top Header
        // ----------------------------------------------------
        Item {
          id: headerItem
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          height: Style.space(52)

          Row {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Text {
              text: root.tabTitle()
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.titleLarge
              font.bold: true
            }
          }

          // Top right contextual action buttons (Monoline)
          Row {
            anchors.right: parent.right
            anchors.rightMargin: Style.space(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            // Monoline + Add Button (Alarm / World Clock)
            Item {
              width: Style.space(32)
              height: Style.space(32)
              visible: root.currentTab === 0 || root.currentTab === 1

              Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: addHeaderHover.hovered
                  ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.16)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
              }

              // Monoline Plus Lines (1.5px stroke)
              Rectangle {
                anchors.centerIn: parent
                width: Style.space(12)
                height: 1.5
                radius: 0.75
                color: Color.accent
              }
              Rectangle {
                anchors.centerIn: parent
                width: 1.5
                height: Style.space(12)
                radius: 0.75
                color: Color.accent
              }

              HoverHandler { id: addHeaderHover }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) { mouse.accepted = true }
                onClicked: function(mouse) {
                  mouse.accepted = true
                  if (root.currentTab === 0) {
                    alarmView.openAddModal()
                  } else if (root.currentTab === 1) {
                    worldClockView.openSearchModal()
                  }
                }
              }
            }

            // Monoline Close Button
            Item {
              width: Style.space(32)
              height: Style.space(32)

              Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: closeHeaderHover.hovered
                  ? Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.16)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
              }

              // Monoline Cross Lines (1.5px stroke)
              Rectangle {
                anchors.centerIn: parent
                width: Style.space(12)
                height: 1.5
                radius: 0.75
                rotation: 45
                color: closeHeaderHover.hovered ? Color.urgent : Color.muted
              }
              Rectangle {
                anchors.centerIn: parent
                width: Style.space(12)
                height: 1.5
                radius: 0.75
                rotation: -45
                color: closeHeaderHover.hovered ? Color.urgent : Color.muted
              }

              HoverHandler { id: closeHeaderHover }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) { mouse.accepted = true }
                onClicked: function(mouse) {
                  mouse.accepted = true
                  root.close()
                }
              }
            }
          }
        }

        // ----------------------------------------------------
        // Tab Content Area
        // ----------------------------------------------------
        Item {
          id: tabContainer
          anchors.top: headerItem.bottom
          anchors.bottom: bottomNavItem.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: Style.space(10)
          clip: true

          // Tab 0: Alarm View
          AlarmView {
            id: alarmView
            anchors.fill: parent
            visible: root.currentTab === 0
            clockService: root.clockService
            bar: root.bar
          }

          // Tab 1: World Clock View
          WorldClockView {
            id: worldClockView
            anchors.fill: parent
            visible: root.currentTab === 1
            clockService: root.clockService
            bar: root.bar
          }

          // Tab 2: Stopwatch View
          StopwatchView {
            id: stopwatchView
            anchors.fill: parent
            visible: root.currentTab === 2
            clockService: root.clockService
            bar: root.bar
          }

          // Tab 3: Timer View
          TimerView {
            id: timerView
            anchors.fill: parent
            visible: root.currentTab === 3
            clockService: root.clockService
            bar: root.bar
          }
        }

        // ----------------------------------------------------
        // Clean Bottom Navigation Bar
        // ----------------------------------------------------
        BottomNav {
          id: bottomNavItem
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          bar: root.bar
          currentTab: root.currentTab
          onTabSelected: function(tabIdx) {
            root.currentTab = tabIdx
            if (root.clockService) root.clockService.activeTab = tabIdx
          }
        }
      }
    }
  }
}
