import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "ClockModel.js" as ClockModel
import "CityDatabase.js" as CityDatabase

Item {
  id: root

  property var clockService: null
  property var bar: null
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  property bool showSearchModal: false
  property string searchQuery: ""

  // Drag & drop state (Manual pointer tracking, zero window grab leakage)
  property int draggingIndex: -1
  property real dragOffsetY: 0
  property int targetDropIndex: -1

  // Reactive live clock ticker (updates every second)
  property double currentTimestamp: Date.now()
  Timer {
    interval: 1000
    repeat: true
    running: true
    onTriggered: root.currentTimestamp = Date.now()
  }

  function openSearchModal() {
    root.searchQuery = ""
    root.showSearchModal = true
    Qt.callLater(function() {
      if (searchInput) searchInput.forceActiveFocus()
    })
  }

  // Background event shield to prevent clicks bubbling to panel dismissal
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onPressed: function(mouse) { mouse.accepted = true }
    onReleased: function(mouse) { mouse.accepted = true }
    onClicked: function(mouse) { mouse.accepted = true }
  }

  // ----------------------------------------------------
  // Clean World Cities List with Drag Reordering
  // ----------------------------------------------------
  ListView {
    id: citiesList
    anchors.top: parent.top
    anchors.topMargin: Style.space(4)
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    clip: true
    spacing: Style.space(8)
    boundsBehavior: Flickable.StopAtBounds
    model: root.clockService ? root.clockService.worldCities : []

    onCountChanged: {
      Qt.callLater(function() {
        citiesList.positionViewAtEnd()
      })
    }

    delegate: Item {
      id: delegateRoot
      required property var modelData
      required property int index

      readonly property bool isBeingDragged: root.draggingIndex === index
      readonly property bool isDropTarget: root.targetDropIndex === index && !isBeingDragged
      readonly property var timeInfo: ClockModel.getCityTimeInfo(modelData, 0, root.currentTimestamp)

      width: citiesList.width
      height: Style.space(78)
      z: isBeingDragged ? 300 : (isDropTarget ? 100 : 1)

      Rectangle {
        id: cityCard
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(78)
        radius: Style.cornerRadius > 0 ? Style.space(14) : Style.space(8)
        color: isBeingDragged
          ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
          : (isDropTarget
              ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.08)
              : (cardHover.hovered ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.035)))
        border.width: isBeingDragged || isDropTarget ? 1.5 : 1
        border.color: isBeingDragged
          ? Color.accent
          : (isDropTarget
              ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.4)
              : (cardHover.hovered ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)))
        scale: isBeingDragged ? 1.03 : 1.0

        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

        // Non-destructive visual translation during drag
        transform: Translate {
          y: delegateRoot.isBeingDragged ? root.dragOffsetY : 0
        }

        HoverHandler { id: cardHover }

        // 1. Drag MouseArea (Placed below card content)
        MouseArea {
          id: cardDragArea
          anchors.fill: parent
          z: 1
          preventStealing: true
          cursorShape: root.draggingIndex === index ? Qt.ClosedHandCursor : Qt.OpenHandCursor

          property real initialMouseY: 0

          onPressed: function(mouse) {
            mouse.accepted = true
            initialMouseY = mouse.y
            root.draggingIndex = index
            root.targetDropIndex = index
            root.dragOffsetY = 0
          }

          onPositionChanged: function(mouse) {
            mouse.accepted = true
            if (root.draggingIndex !== index) return

            var delta = mouse.y - initialMouseY
            root.dragOffsetY += delta

            var itemSpan = delegateRoot.height + citiesList.spacing
            var movedUnits = Math.round(root.dragOffsetY / itemSpan)
            var targetIdx = Math.max(0, Math.min(citiesList.count - 1, index + movedUnits))
            root.targetDropIndex = targetIdx
          }

          onReleased: function(mouse) {
            mouse.accepted = true
            if (root.draggingIndex === index) {
              var fromIdx = index
              var toIdx = root.targetDropIndex

              root.draggingIndex = -1
              root.targetDropIndex = -1
              root.dragOffsetY = 0

              if (toIdx !== fromIdx && toIdx >= 0 && root.clockService) {
                root.clockService.moveCity(fromIdx, toIdx)
              }
            }
          }

          onCanceled: {
            root.draggingIndex = -1
            root.targetDropIndex = -1
            root.dragOffsetY = 0
          }
        }

        // 2. Card Content Row (Placed above drag area)
        Row {
          anchors.fill: parent
          anchors.leftMargin: Style.space(16)
          anchors.rightMargin: Style.space(16)
          anchors.topMargin: Style.space(12)
          anchors.bottomMargin: Style.space(12)
          z: 2

          // Left Section: Location & Contextual Offset
          Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Style.space(140)
            spacing: Style.space(4)

            // City Name (Bold, High Readability)
            Text {
              text: modelData.city
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }

            // Contextual Time-Offset Indicator & Country
            Row {
              spacing: Style.space(6)

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: Style.space(18)
                width: offsetText.implicitWidth + Style.space(10)
                radius: Style.space(4)
                color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12)

                Text {
                  id: offsetText
                  anchors.centerIn: parent
                  text: timeInfo.offsetFull
                  color: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "• " + modelData.country
                color: Color.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
              }
            }
          }

          // Right Section: Digital Time & Hover Delete Control
          Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            spacing: Style.space(8)

            // Digital Time Readout
            Row {
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(4)

              Text {
                text: timeInfo.digital12
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.titleLarge * 1.15
                font.bold: true
              }

              Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Style.space(3)
                text: timeInfo.ampm
                color: Color.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }

            // Monoline Delete Button (Higher Z, on top of everything)
            Item {
              z: 10
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(26)
              height: Style.space(26)
              visible: cardHover.hovered || delCityHover.hovered
              opacity: (cardHover.hovered || delCityHover.hovered) ? 1.0 : 0.0

              Behavior on opacity {
                NumberAnimation { duration: 150 }
              }

              Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: delCityHover.hovered ? Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.16) : "transparent"
              }

              // Monoline Cross Lines (1.5px stroke)
              Rectangle {
                anchors.centerIn: parent
                width: Style.space(12)
                height: 1.5
                radius: 0.75
                rotation: 45
                color: delCityHover.hovered ? Color.urgent : Color.muted
              }
              Rectangle {
                anchors.centerIn: parent
                width: Style.space(12)
                height: 1.5
                radius: 0.75
                rotation: -45
                color: delCityHover.hovered ? Color.urgent : Color.muted
              }

              HoverHandler { id: delCityHover }

              MouseArea {
                anchors.fill: parent
                z: 20
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) { mouse.accepted = true }
                onReleased: function(mouse) { mouse.accepted = true }
                onClicked: function(mouse) {
                  mouse.accepted = true
                  if (root.clockService) {
                    root.clockService.removeCity(modelData.id)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // ----------------------------------------------------
  // Minimalist City Search Modal Sheet
  // ----------------------------------------------------
  Rectangle {
    id: searchModal
    anchors.fill: parent
    z: 500
    visible: root.showSearchModal
    color: Color.popups.background
    radius: Style.cornerRadius > 0 ? Style.space(14) : 0
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

      // Header row
      Item {
        id: modalHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(30)

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Add City"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }

        // Monoline Close Button
        Item {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(24)
          height: Style.space(24)

          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: closeSearchHover.hovered ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08) : "transparent"
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

          HoverHandler { id: closeSearchHover }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) { mouse.accepted = true }
            onReleased: function(mouse) { mouse.accepted = true }
            onClicked: function(mouse) {
              mouse.accepted = true
              root.showSearchModal = false
            }
          }
        }
      }

      // Search Field Input
      Rectangle {
        id: searchFieldBox
        anchors.top: modalHeader.bottom
        anchors.topMargin: Style.space(8)
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(36)
        radius: Style.cornerRadius > 0 ? Style.space(6) : 0
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
        border.width: 1
        border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.3)

        TextInput {
          id: searchInput
          anchors.fill: parent
          anchors.margins: Style.space(8)
          text: root.searchQuery
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          onTextChanged: root.searchQuery = text
        }
      }

      // Results List
      ListView {
        id: searchResultsList
        anchors.top: searchFieldBox.bottom
        anchors.topMargin: Style.space(8)
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        spacing: Style.space(4)
        boundsBehavior: Flickable.StopAtBounds
        model: CityDatabase.search(root.searchQuery)

        delegate: Rectangle {
          required property var modelData
          required property int index

          readonly property var cTime: ClockModel.getCityTimeInfo(modelData, 0, root.currentTimestamp)

          width: searchResultsList.width
          height: Style.space(46)
          radius: Style.cornerRadius > 0 ? Style.space(8) : 0
          color: sHover.hovered ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.12) : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.025)

          Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space(12)
            anchors.rightMargin: Style.space(12)
            spacing: Style.space(10)

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - Style.space(110)
              spacing: Style.space(2)

              Text {
                text: modelData.city
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }

              Text {
                text: modelData.country + " • " + cTime.offsetShort
                color: Color.muted
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.right: parent.right
              text: cTime.digital12 + " " + cTime.ampm
              color: Color.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }

          HoverHandler { id: sHover }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) { mouse.accepted = true }
            onReleased: function(mouse) { mouse.accepted = true }
            onClicked: function(mouse) {
              mouse.accepted = true
              if (root.clockService) {
                root.clockService.addCity(modelData)
              }
              root.showSearchModal = false
            }
          }
        }
      }
    }
  }
}
