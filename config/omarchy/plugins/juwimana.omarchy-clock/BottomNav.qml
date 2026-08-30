import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property int currentTab: 0 // 0: Alarm, 1: World clock, 2: Stopwatch, 3: Timer
  property var bar: null
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  signal tabSelected(int index)

  implicitHeight: Style.space(46)

  Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
  }

  Row {
    anchors.fill: parent
    anchors.topMargin: 1

    readonly property real itemWidth: width / 4
    readonly property var tabNames: ["Alarm", "World clock", "Stopwatch", "Timer"]

    Repeater {
      model: 4

      Item {
        required property int index
        width: parent.itemWidth
        height: parent.height

        readonly property bool isSelected: root.currentTab === index
        readonly property color activeColor: isSelected ? Color.accent : (navHover.hovered ? root.foreground : Color.muted)

        Rectangle {
          anchors.centerIn: parent
          width: parent.width - Style.space(12)
          height: parent.height - Style.space(12)
          radius: Style.cornerRadius > 0 ? Style.space(10) : 0
          color: isSelected
            ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.14)
            : (navHover.hovered ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04) : "transparent")
        }

        Text {
          anchors.centerIn: parent
          text: parent.parent.tabNames[index]
          color: activeColor
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: isSelected
        }

        HoverHandler { id: navHover }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.tabSelected(index)
        }
      }
    }
  }
}
