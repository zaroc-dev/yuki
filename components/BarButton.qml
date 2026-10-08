import QtQuick
import qs.config

// Hoverable, clickable chunk of a pill. Put content inside; it is laid out in a row.
MouseArea {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property int hPadding: 8
    property bool active: false

    implicitWidth: row.implicitWidth + hPadding * 2
    implicitHeight: parent?.height ?? Theme.barHeight - Theme.padding * 2
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    Rectangle {
        anchors.fill: parent
        radius: Theme.innerRadius
        color: root.active ? Qt.alpha(Theme.accent, 0.18) : root.pressed ? Theme.pressed : root.containsMouse ? Theme.hover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        height: parent.height
        spacing: 6
    }
}
