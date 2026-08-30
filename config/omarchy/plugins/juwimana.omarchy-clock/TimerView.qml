import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "ClockModel.js" as ClockModel

Item {
  id: root

  property var clockService: null
  property var bar: null
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property bool isRunning: root.clockService ? root.clockService.timerRunning : false
  readonly property bool isPaused: root.clockService ? root.clockService.timerPaused : false
  readonly property int remainingSecs: root.clockService ? root.clockService.timerRemainingSeconds : 300
  readonly property int totalSecs: root.clockService ? root.clockService.timerTotalSeconds : 300
  readonly property var timeObj: ClockModel.formatTimer(remainingSecs)
  readonly property real progressFraction: totalSecs > 0 ? (remainingSecs / totalSecs) : 0

  property int inputHours: 0
  property int inputMinutes: 5
  property int inputSeconds: 0

  // ----------------------------------------------------
  // Samsung Circular Countdown Progress Arc Frame
  // ----------------------------------------------------
  Item {
    id: gaugeFrame
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: Style.space(210)
    height: Style.space(210)

    Canvas {
      id: timerCanvas
      anchors.centerIn: parent
      width: Style.space(190)
      height: Style.space(190)

      property real fraction: root.progressFraction
      onFractionChanged: requestPaint()

      onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var cx = width / 2
        var cy = height / 2
        var r = (width / 2) - 8

        // Background Track Arc
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
        ctx.lineWidth = 6
        ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
        ctx.stroke()

        // Active Countdown Arc
        var startAngle = -Math.PI / 2
        var endAngle = startAngle + (2 * Math.PI * fraction)
        ctx.beginPath()
        ctx.arc(cx, cy, r, startAngle, endAngle)
        ctx.lineWidth = 7
        ctx.strokeStyle = Color.accent
        ctx.lineCap = "round"
        ctx.stroke()
      }
    }

    // Digital Readout inside circular arc
    Column {
      anchors.centerIn: parent
      spacing: Style.space(4)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.timeObj.formatted
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.titleLarge * 1.5
        font.bold: true
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.isRunning ? (root.isPaused ? "PAUSED" : "COUNTING DOWN") : "TIMER"
        color: root.isRunning ? (root.isPaused ? Color.muted : Color.accent) : Color.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }
  }

  // ----------------------------------------------------
  // Preset Duration Chips (One UI Style)
  // ----------------------------------------------------
  Row {
    id: presetChipsRow
    anchors.top: gaugeFrame.bottom
    anchors.topMargin: Style.space(10)
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(6)

    readonly property var presets: [
      { label: "+1m", secs: 60 },
      { label: "+5m", secs: 300 },
      { label: "+10m", secs: 600 },
      { label: "+15m", secs: 900 },
      { label: "+30m", secs: 1800 },
      { label: "+1h", secs: 3600 }
    ]

    Repeater {
      model: parent.presets
      Rectangle {
        required property var modelData
        width: Style.space(48)
        height: Style.space(28)
        radius: Style.space(14)
        color: chipHover.hovered
          ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22)
          : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)

        Text {
          anchors.centerIn: parent
          text: modelData.label
          color: Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        HoverHandler { id: chipHover }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (root.isRunning) {
              if (root.clockService) root.clockService.addTimerSeconds(modelData.secs)
            } else {
              root.inputHours = Math.floor(modelData.secs / 3600)
              root.inputMinutes = Math.floor((modelData.secs % 3600) / 60)
              root.inputSeconds = modelData.secs % 60
              if (root.clockService) root.clockService.startTimer(modelData.secs)
            }
          }
        }
      }
    }
  }

  // ----------------------------------------------------
  // Custom Time Adjusters (When Idle)
  // ----------------------------------------------------
  Item {
    id: adjustersBox
    anchors.top: presetChipsRow.bottom
    anchors.topMargin: Style.space(14)
    anchors.bottom: timerButtonsRow.top
    anchors.bottomMargin: Style.space(14)
    anchors.left: parent.left
    anchors.right: parent.right
    visible: !root.isRunning

    Row {
      anchors.centerIn: parent
      spacing: Style.space(14)

      // Hours
      Column {
        spacing: Style.space(4)
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Hours"; color: Color.muted; font.pixelSize: Style.font.caption }
        Row {
          spacing: Style.space(4)
          Rectangle {
            width: Style.space(28); height: Style.space(28); radius: 6
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
            Text { anchors.centerIn: parent; text: "−"; color: root.foreground; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: root.inputHours = Math.max(0, root.inputHours - 1) }
          }
          Rectangle {
            width: Style.space(38); height: Style.space(28); radius: 6
            color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15)
            Text { anchors.centerIn: parent; text: ClockModel.pad2(root.inputHours); color: Color.accent; font.bold: true; font.pixelSize: Style.font.bodyLarge }
          }
          Rectangle {
            width: Style.space(28); height: Style.space(28); radius: 6
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
            Text { anchors.centerIn: parent; text: "+"; color: root.foreground; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: root.inputHours = Math.min(23, root.inputHours + 1) }
          }
        }
      }

      // Minutes
      Column {
        spacing: Style.space(4)
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Mins"; color: Color.muted; font.pixelSize: Style.font.caption }
        Row {
          spacing: Style.space(4)
          Rectangle {
            width: Style.space(28); height: Style.space(28); radius: 6
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
            Text { anchors.centerIn: parent; text: "−"; color: root.foreground; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: root.inputMinutes = Math.max(0, root.inputMinutes - 1) }
          }
          Rectangle {
            width: Style.space(38); height: Style.space(28); radius: 6
            color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15)
            Text { anchors.centerIn: parent; text: ClockModel.pad2(root.inputMinutes); color: Color.accent; font.bold: true; font.pixelSize: Style.font.bodyLarge }
          }
          Rectangle {
            width: Style.space(28); height: Style.space(28); radius: 6
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
            Text { anchors.centerIn: parent; text: "+"; color: root.foreground; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: root.inputMinutes = Math.min(59, root.inputMinutes + 1) }
          }
        }
      }

      // Seconds
      Column {
        spacing: Style.space(4)
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Secs"; color: Color.muted; font.pixelSize: Style.font.caption }
        Row {
          spacing: Style.space(4)
          Rectangle {
            width: Style.space(28); height: Style.space(28); radius: 6
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
            Text { anchors.centerIn: parent; text: "−"; color: root.foreground; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: root.inputSeconds = Math.max(0, root.inputSeconds - 5) }
          }
          Rectangle {
            width: Style.space(38); height: Style.space(28); radius: 6
            color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15)
            Text { anchors.centerIn: parent; text: ClockModel.pad2(root.inputSeconds); color: Color.accent; font.bold: true; font.pixelSize: Style.font.bodyLarge }
          }
          Rectangle {
            width: Style.space(28); height: Style.space(28); radius: 6
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
            Text { anchors.centerIn: parent; text: "+"; color: root.foreground; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: root.inputSeconds = Math.min(59, root.inputSeconds + 5) }
          }
        }
      }
    }
  }

  // ----------------------------------------------------
  // Action Buttons (Samsung Style)
  // ----------------------------------------------------
  Row {
    id: timerButtonsRow
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(16)

    // Cancel Button (visible when running)
    Rectangle {
      width: Style.space(120)
      height: Style.space(44)
      radius: Style.cornerRadius > 0 ? Style.space(22) : 0
      visible: root.isRunning
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)

      Text {
        anchors.centerIn: parent
        text: "Cancel"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodyLarge
        font.bold: true
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.clockService) root.clockService.cancelTimer()
      }
    }

    // Start / Pause / Resume Button
    Rectangle {
      width: root.isRunning ? Style.space(120) : Style.space(180)
      height: Style.space(44)
      radius: Style.cornerRadius > 0 ? Style.space(22) : 0
      color: (root.isRunning && !root.isPaused) ? Color.urgent : Color.accent

      Text {
        anchors.centerIn: parent
        text: root.isRunning ? (root.isPaused ? "Resume" : "Pause") : "Start"
        color: Color.background
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodyLarge
        font.bold: true
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (!root.clockService) return
          if (!root.isRunning) {
            var secs = (root.inputHours * 3600) + (root.inputMinutes * 60) + root.inputSeconds
            if (secs <= 0) secs = 300
            root.clockService.startTimer(secs)
          } else if (root.isPaused) {
            root.clockService.resumeTimer()
          } else {
            root.clockService.pauseTimer()
          }
        }
      }
    }
  }
}
