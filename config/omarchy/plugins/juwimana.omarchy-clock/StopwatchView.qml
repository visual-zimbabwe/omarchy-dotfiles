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

  readonly property double elapsed: root.clockService ? root.clockService.stopwatchElapsedMs : 0
  readonly property bool isRunning: root.clockService ? root.clockService.stopwatchRunning : false
  readonly property var laps: root.clockService ? root.clockService.stopwatchLaps : []
  readonly property var timeObj: ClockModel.formatStopwatch(elapsed)

  // Compute best and worst lap indices
  readonly property int bestLapIndex: {
    if (!laps || laps.length < 2) return -1
    var bestIdx = 0
    var bestDur = laps[0].durationMs
    for (var i = 1; i < laps.length; i++) {
      if (laps[i].durationMs < bestDur) {
        bestDur = laps[i].durationMs
        bestIdx = i
      }
    }
    return bestIdx
  }

  readonly property int worstLapIndex: {
    if (!laps || laps.length < 2) return -1
    var worstIdx = 0
    var worstDur = laps[0].durationMs
    for (var i = 1; i < laps.length; i++) {
      if (laps[i].durationMs > worstDur) {
        worstDur = laps[i].durationMs
        worstIdx = i
      }
    }
    return worstIdx
  }

  // ----------------------------------------------------
  // Stopwatch Digital Gauge Header
  // ----------------------------------------------------
  Rectangle {
    id: gaugeHeader
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: Style.space(150)
    radius: Style.cornerRadius > 0 ? Style.space(16) : 0
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)

    // Circular gauge circle in background
    Rectangle {
      anchors.centerIn: parent
      width: Style.space(130)
      height: Style.space(130)
      radius: width / 2
      color: "transparent"
      border.width: 3
      border.color: isRunning ? Color.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
      opacity: 0.8
    }

    Column {
      anchors.centerIn: parent
      spacing: Style.space(2)

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(2)

        Text {
          text: root.timeObj.mins + ":" + root.timeObj.secs
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.titleLarge * 1.4
          font.bold: true
        }

        Text {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(3)
          text: "." + root.timeObj.hundredths
          color: Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: isRunning ? "RECORDING" : (elapsed > 0 ? "PAUSED" : "STOPWATCH")
        color: Color.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }
  }

  // ----------------------------------------------------
  // Laps Table View (Anchored cleanly)
  // ----------------------------------------------------
  Rectangle {
    id: lapsContainer
    anchors.top: gaugeHeader.bottom
    anchors.topMargin: Style.space(10)
    anchors.bottom: actionButtonsRow.top
    anchors.bottomMargin: Style.space(10)
    anchors.left: parent.left
    anchors.right: parent.right
    radius: Style.cornerRadius > 0 ? Style.space(14) : 0
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.02)
    border.width: 1
    border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)

    Item {
      anchors.fill: parent
      anchors.margins: Style.space(8)

      // Table Header
      Item {
        id: tableHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(22)

        Row {
          anchors.fill: parent

          Text {
            width: parent.width * 0.25
            text: "Lap"
            color: Color.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            width: parent.width * 0.4
            text: "Lap time"
            color: Color.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            width: parent.width * 0.35
            text: "Overall time"
            color: Color.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
      }

      // Laps List
      ListView {
        id: lapsList
        anchors.top: tableHeader.bottom
        anchors.topMargin: Style.space(4)
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        spacing: Style.space(4)
        boundsBehavior: Flickable.StopAtBounds
        model: root.laps

        delegate: Rectangle {
          required property var modelData
          required property int index

          readonly property bool isBest: index === root.bestLapIndex
          readonly property bool isWorst: index === root.worstLapIndex
          readonly property var lapTimeObj: ClockModel.formatStopwatch(modelData.durationMs)
          readonly property var totalTimeObj: ClockModel.formatStopwatch(modelData.totalMs)

          width: lapsList.width
          height: Style.space(30)
          radius: Style.cornerRadius > 0 ? Style.space(6) : 0
          color: isBest
            ? Qt.rgba(0.2, 0.8, 0.2, 0.12)
            : (isWorst ? Qt.rgba(0.9, 0.2, 0.2, 0.12) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04))

          Row {
            anchors.fill: parent
            anchors.margins: Style.space(6)

            Row {
              width: parent.width * 0.25
              spacing: Style.space(4)
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ClockModel.pad2(modelData.lapNumber)
                color: parent.parent.isBest ? "#4ade80" : (parent.parent.isWorst ? "#f87171" : root.foreground)
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }
            }

            Text {
              width: parent.width * 0.4
              anchors.verticalCenter: parent.verticalCenter
              text: lapTimeObj.formatted
              color: parent.isBest ? "#4ade80" : (parent.isWorst ? "#f87171" : root.foreground)
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            Text {
              width: parent.width * 0.35
              anchors.verticalCenter: parent.verticalCenter
              text: totalTimeObj.formatted
              color: Color.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }
      }
    }
  }

  // ----------------------------------------------------
  // Samsung Dual Action Buttons
  // ----------------------------------------------------
  Row {
    id: actionButtonsRow
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Style.space(16)

    // Left Button (Lap / Reset)
    Rectangle {
      width: Style.space(130)
      height: Style.space(44)
      radius: Style.cornerRadius > 0 ? Style.space(22) : 0
      visible: root.elapsed > 0
      color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)

      Text {
        anchors.centerIn: parent
        text: root.isRunning ? "Lap" : "Reset"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodyLarge
        font.bold: true
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (!root.clockService) return
          if (root.isRunning) root.clockService.lapStopwatch()
          else root.clockService.resetStopwatch()
        }
      }
    }

    // Right Button (Start / Stop / Resume)
    Rectangle {
      width: root.elapsed > 0 ? Style.space(130) : Style.space(180)
      height: Style.space(44)
      radius: Style.cornerRadius > 0 ? Style.space(22) : 0
      color: root.isRunning ? Color.urgent : Color.accent

      Text {
        anchors.centerIn: parent
        text: root.isRunning ? "Stop" : (root.elapsed > 0 ? "Resume" : "Start")
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
          if (root.isRunning) root.clockService.pauseStopwatch()
          else if (root.elapsed > 0) root.clockService.resumeStopwatch()
          else root.clockService.startStopwatch()
        }
      }
    }
  }
}
