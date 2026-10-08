import QtQuick
import qs.config

// Round icon-only button used inside popups.
MouseArea {
    id: root

    property string icon
    property real size: 32
    property real iconSize: Theme.iconSize
    property color color: Theme.text
    property bool filled: false

    implicitWidth: size
    implicitHeight: size
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.filled ? Theme.accent : root.pressed ? Theme.pressed : root.containsMouse ? Theme.hover : "transparent"
        opacity: root.enabled ? 1 : 0.4

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }
    }

    Icon {
        anchors.centerIn: parent
        text: root.icon
        size: root.iconSize
        color: root.filled ? Theme.onAccent : root.color
        opacity: root.enabled ? 1 : 0.4
    }
}
