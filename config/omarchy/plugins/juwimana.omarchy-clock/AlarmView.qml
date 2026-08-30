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

  property bool showAddModal: false
  property int newHour: 7
  property int newMinute: 0
  property string newAmpm: "AM"
  property string newLabel: "Alarm"
  property var newDays: [1, 2, 3, 4, 5]

  function openAddModal() {
    var now = new Date()
    var h = now.getHours()
    root.newHour = h % 12 || 12
    root.newMinute = now.getMinutes()
    root.newAmpm = h >= 12 ? "PM" : "AM"
    root.newLabel = "Alarm"
    root.newDays = [1, 2, 3, 4, 5]
    root.showAddModal = true
  }

  // ----------------------------------------------------
  // Minimalist Summary Banner
  // ----------------------------------------------------
  Rectangle {
    id: summaryBanner
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: Style.space(38)
    radius: Style.cornerRadius > 0 ? Style.space(8) : 0
    color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.08)
    border.width: 1
    border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15)

    Row {
      anchors.centerIn: parent
      spacing: Style.space(8)

      Text {
        text: root.clockService ? ClockModel.getNextAlarmSummary(root.clockService.alarms) : "No active alarms"
        color: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }
  }

  // ----------------------------------------------------
  // Alarms List View
  // ----------------------------------------------------
  ListView {
    id: alarmsList
    anchors.top: summaryBanner.bottom
    anchors.topMargin: Style.space(8)
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    clip: true
    spacing: Style.space(8)
    boundsBehavior: Flickable.StopAtBounds
    model: root.clockService ? root.clockService.alarms : []

    delegate: Rectangle {
      id: alarmCard
      required property var modelData
      required property int index

      width: alarmsList.width
      height: Style.space(76)
      radius: Style.cornerRadius > 0 ? Style.space(12) : Style.space(8)
      color: cardHover.hovered
        ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055)
        : (modelData.enabled ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.02))
      border.width: 1
      border.color: cardHover.hovered
        ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.2)
        : (modelData.enabled ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.16) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06))

      HoverHandler { id: cardHover }

      Row {
        anchors.fill: parent
        anchors.margins: Style.space(12)
        spacing: Style.space(12)

        // Time & Label column
        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - Style.space(90)
          spacing: Style.space(3)

          Row {
            spacing: Style.space(6)

            Text {
              readonly property int h12: modelData.hour % 12 || 12
              text: ClockModel.pad2(h12) + ":" + ClockModel.pad2(modelData.minute)
              color: modelData.enabled ? root.foreground : Color.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.titleLarge
              font.bold: true
            }

            Text {
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Style.space(3)
              text: modelData.hour >= 12 ? "PM" : "AM"
              color: modelData.enabled ? Color.accent : Color.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }

          Row {
            spacing: Style.space(8)

            Text {
              text: modelData.label || "Alarm"
              color: modelData.enabled ? root.foreground : Color.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              text: "•"
              color: Color.muted
              font.pixelSize: Style.font.caption
            }

            // Days indicator
            Row {
              spacing: Style.space(3)
              readonly property var dayLetters: ["S", "M", "T", "W", "T", "F", "S"]
              Repeater {
                model: 7
                Text {
                  required property int index
                  text: parent.parent.dayLetters[index]
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: modelData.days && modelData.days.indexOf(index) !== -1
                  color: (modelData.days && modelData.days.indexOf(index) !== -1)
                    ? (modelData.enabled ? Color.accent : root.foreground)
                    : Color.muted
                  opacity: (modelData.days && modelData.days.indexOf(index) !== -1) ? 1.0 : 0.4
                }
              }
            }
          }
        }

        // Actions Column (Hover-Only Monoline Delete + Toggle Switch)
        Row {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)

          // Monoline Delete Icon (Visible only on hover)
          Item {
            z: 10
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(26)
            height: Style.space(26)
            visible: cardHover.hovered || delHover.hovered
            opacity: (cardHover.hovered || delHover.hovered) ? 1.0 : 0.0

            Behavior on opacity {
              NumberAnimation { duration: 150 }
            }

            Rectangle {
              anchors.fill: parent
              radius: width / 2
              color: delHover.hovered ? Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.16) : "transparent"
            }

            Rectangle {
              anchors.centerIn: parent
              width: Style.space(12)
              height: 1.5
              radius: 0.75
              rotation: 45
              color: delHover.hovered ? Color.urgent : Color.muted
            }
            Rectangle {
              anchors.centerIn: parent
              width: Style.space(12)
              height: 1.5
              radius: 0.75
              rotation: -45
              color: delHover.hovered ? Color.urgent : Color.muted
            }

            HoverHandler { id: delHover }
            MouseArea {
              anchors.fill: parent
              z: 20
              preventStealing: true
              cursorShape: Qt.PointingHandCursor
              onPressed: function(mouse) { mouse.accepted = true }
              onReleased: function(mouse) { mouse.accepted = true }
              onClicked: function(mouse) {
                mouse.accepted = true
                if (root.clockService) root.clockService.deleteAlarm(modelData.id)
              }
            }
          }

          // Samsung Toggle Switch
          Rectangle {
            width: Style.space(40)
            height: Style.space(22)
            radius: height / 2
            color: modelData.enabled ? Color.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              x: modelData.enabled ? parent.width - width - 2 : 2
              width: Style.space(18)
              height: Style.space(18)
              radius: width / 2
              color: Color.background

              Behavior on x {
                NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onPressed: function(mouse) { mouse.accepted = true }
              onReleased: function(mouse) { mouse.accepted = true }
              onClicked: function(mouse) {
                mouse.accepted = true
                if (root.clockService) root.clockService.toggleAlarm(modelData.id)
              }
            }
          }
        }
      }
    }
  }

  // ----------------------------------------------------
  // Add Alarm Modal Sheet
  // ----------------------------------------------------
  Rectangle {
    id: modalOverlay
    anchors.fill: parent
    z: 100
    visible: root.showAddModal
    color: Color.popups.background
    radius: Style.cornerRadius > 0 ? Style.space(12) : 0
    border.width: 1
    border.color: Color.popups.border

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      onPressed: function(mouse) { mouse.accepted = true }
      onReleased: function(mouse) { mouse.accepted = true }
      onClicked: function(mouse) { mouse.accepted = true }
    }

    Item {
      anchors.fill: parent
      anchors.margins: Style.space(14)

      Item {
        id: alarmModalHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(30)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Add Alarm"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }

        // Monoline Close
        Item {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(24)
          height: Style.space(24)

          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: closeAlarmModalHover.hovered ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08) : "transparent"
          }

          Rectangle {
            anchors.centerIn: parent
            width: Style.space(12)
            height: 1.5
            radius: 0.75
            rotation: 45
            color: root.foreground
          }
          Rectangle {
            anchors.centerIn: parent
            width: Style.space(12)
            height: 1.5
            radius: 0.75
            rotation: -45
            color: root.foreground
          }

          HoverHandler { id: closeAlarmModalHover }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) { mouse.accepted = true }
            onReleased: function(mouse) { mouse.accepted = true }
            onClicked: function(mouse) {
              mouse.accepted = true
              root.showAddModal = false
            }
          }
        }
      }

      Column {
        anchors.top: alarmModalHeader.bottom
        anchors.topMargin: Style.space(12)
        anchors.bottom: modalButtonsRow.top
        anchors.bottomMargin: Style.space(12)
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Style.space(12)

        // Time Selectors (Hour, Minute, AM/PM)
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(12)

          // Hours selector
          Column {
            spacing: Style.space(4)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Hour"
              color: Color.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            Row {
              spacing: Style.space(4)
              Rectangle {
                width: Style.space(26); height: Style.space(26); radius: Style.space(4)
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
                Text { anchors.centerIn: parent; text: "−"; color: root.foreground; font.bold: true }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.newHour = (root.newHour <= 1) ? 12 : root.newHour - 1
                }
              }
              Rectangle {
                width: Style.space(40); height: Style.space(26); radius: Style.space(4)
                color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15)
                Text {
                  anchors.centerIn: parent
                  text: ClockModel.pad2(root.newHour)
                  color: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodyLarge
                  font.bold: true
                }
              }
              Rectangle {
                width: Style.space(26); height: Style.space(26); radius: Style.space(4)
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
                Text { anchors.centerIn: parent; text: "+"; color: root.foreground; font.bold: true }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.newHour = (root.newHour >= 12) ? 1 : root.newHour + 1
                }
              }
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ":"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.titleLarge
            font.bold: true
          }

          // Minutes selector
          Column {
            spacing: Style.space(4)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Minute"
              color: Color.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            Row {
              spacing: Style.space(4)
              Rectangle {
                width: Style.space(26); height: Style.space(26); radius: Style.space(4)
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
                Text { anchors.centerIn: parent; text: "−"; color: root.foreground; font.bold: true }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.newMinute = (root.newMinute <= 0) ? 59 : root.newMinute - 1
                }
              }
              Rectangle {
                width: Style.space(40); height: Style.space(26); radius: Style.space(4)
                color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15)
                Text {
                  anchors.centerIn: parent
                  text: ClockModel.pad2(root.newMinute)
                  color: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodyLarge
                  font.bold: true
                }
              }
              Rectangle {
                width: Style.space(26); height: Style.space(26); radius: Style.space(4)
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
                Text { anchors.centerIn: parent; text: "+"; color: root.foreground; font.bold: true }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.newMinute = (root.newMinute >= 59) ? 0 : root.newMinute + 1
                }
              }
            }
          }

          // AM/PM Toggle
          Column {
            spacing: Style.space(4)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Period"
              color: Color.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
            Rectangle {
              width: Style.space(50); height: Style.space(26); radius: Style.space(4)
              color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
              Text {
                anchors.centerIn: parent
                text: root.newAmpm
                color: Color.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodyLarge
                font.bold: true
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.newAmpm = (root.newAmpm === "AM" ? "PM" : "AM")
              }
            }
          }
        }

        // Days of Week Selection
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "Repeat"
            color: Color.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(6)
            readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

            Repeater {
              model: 7
              Rectangle {
                required property int index
                readonly property bool isSelected: root.newDays.indexOf(index) !== -1

                width: Style.space(34)
                height: Style.space(34)
                radius: width / 2
                color: isSelected
                  ? Color.accent
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)

                Text {
                  anchors.centerIn: parent
                  text: parent.parent.dayNames[index]
                  color: parent.isSelected ? Color.background : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: parent.isSelected
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    var arr = root.newDays.slice(0)
                    var idx = arr.indexOf(index)
                    if (idx !== -1) arr.splice(idx, 1)
                    else arr.push(index)
                    root.newDays = arr
                  }
                }
              }
            }
          }
        }

        // Label Input
        Column {
          width: parent.width
          spacing: Style.space(4)

          Text {
            text: "Alarm name"
            color: Color.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Rectangle {
            width: parent.width
            height: Style.space(34)
            radius: Style.cornerRadius > 0 ? Style.space(6) : 0
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
            border.width: 1
            border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)

            TextInput {
              id: labelInput
              anchors.fill: parent
              anchors.margins: Style.space(6)
              text: root.newLabel
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              onTextChanged: root.newLabel = text
            }
          }
        }
      }

      // Modal Bottom Buttons (Cancel & Save)
      Row {
        id: modalButtonsRow
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(16)

        // Cancel
        Rectangle {
          width: Style.space(110)
          height: Style.space(36)
          radius: Style.cornerRadius > 0 ? Style.space(18) : 0
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)

          Text {
            anchors.centerIn: parent
            text: "Cancel"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showAddModal = false
          }
        }

        // Save
        Rectangle {
          width: Style.space(110)
          height: Style.space(36)
          radius: Style.cornerRadius > 0 ? Style.space(18) : 0
          color: Color.accent

          Text {
            anchors.centerIn: parent
            text: "Save"
            color: Color.background
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var h24 = root.newHour % 12
              if (root.newAmpm === "PM") h24 += 12
              var newAlarmObj = {
                id: "alarm_" + Date.now(),
                label: root.newLabel || "Alarm",
                hour: h24,
                minute: root.newMinute,
                enabled: true,
                days: root.newDays.length > 0 ? root.newDays : [0, 1, 2, 3, 4, 5, 6],
                sound: "default",
                snoozeMins: 5
              }
              if (root.clockService) root.clockService.saveAlarm(newAlarmObj)
              root.showAddModal = false
            }
          }
        }
      }
    }
  }
}
