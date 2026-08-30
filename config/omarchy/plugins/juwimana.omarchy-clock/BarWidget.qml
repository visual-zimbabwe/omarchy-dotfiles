import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "ClockModel.js" as ClockModel

BarWidget {
  id: root
  moduleName: "juwimana.omarchy-clock"

  readonly property var clockService: bar && bar.shell
    ? bar.shell.serviceFor(moduleName)
    : null

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false
  readonly property real openPanelIndicatorWidth: button.implicitWidth
  readonly property real openPanelIndicatorHeight: Math.max(Style.space(10), Math.round(Style.bar.iconSlot * 0.55))

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("clockService" in target) target.clockService = root.clockService
  }

  function open() {
    root.injectPanel()
    if (panelLoader.item) panelLoader.item.open()
  }
  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }
  function toggle() {
    root.injectPanel()
    if (panelLoader.item) panelLoader.item.toggle()
  }
  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: { root.injectPanel(); Qt.callLater(root.injectPanel); }
  onSettingsChanged: { root.injectPanel(); Qt.callLater(root.injectPanel); }
  onClockServiceChanged: { root.injectPanel(); Qt.callLater(root.injectPanel); }
  Component.onCompleted: { root.injectPanel(); Qt.callLater(root.injectPanel); }

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

  IpcHandler {
    target: "juwimana.omarchy-clock"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.opened
    labelVisible: false
    hasVisualContent: true
    tooltipText: root.clockService && root.clockService.timerRunning
      ? "Timer: " + ClockModel.formatTimer(root.clockService.timerRemainingSeconds).formatted
      : "Omarchy Clock"

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }

    Row {
      anchors.centerIn: parent
      spacing: Style.space(4)

      // Monoline Clock Icon Face
      Item {
        width: Style.bar.iconCanvas
        height: Style.bar.iconCanvas
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
          anchors.fill: parent
          anchors.margins: 1
          radius: width / 2
          color: "transparent"
          border.width: 1.5
          border.color: button.foreground

          // Clock Hands
          Rectangle {
            anchors.centerIn: parent
            width: 1.5
            height: parent.height * 0.32
            radius: 1
            color: button.foreground
            transformOrigin: Item.Bottom
            y: parent.height * 0.18
            rotation: 45
          }

          Rectangle {
            anchors.centerIn: parent
            width: 1.5
            height: parent.height * 0.42
            radius: 1
            color: Color.accent
            transformOrigin: Item.Bottom
            y: parent.height * 0.08
            rotation: 180
          }

          Rectangle {
            anchors.centerIn: parent
            width: 3
            height: 3
            radius: 1.5
            color: button.foreground
          }
        }
      }

      // Active state badge (e.g. Timer or Stopwatch active)
      Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.clockService && (root.clockService.timerRunning || root.clockService.stopwatchRunning)
        text: root.clockService && root.clockService.timerRunning
          ? ClockModel.formatTimer(root.clockService.timerRemainingSeconds).formatted
          : (root.clockService && root.clockService.stopwatchRunning
              ? ClockModel.formatStopwatch(root.clockService.stopwatchElapsedMs).formatted
              : "")
        color: root.clockService && root.clockService.timerRunning ? Color.urgent : Color.accent
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }
  }
}
