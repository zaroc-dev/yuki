import QtQuick
import qs.config

// Hoverable, clickable chunk of the bar. Put content inside; it is laid out in a row.
MouseArea {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property int hPadding: 9
    property bool active: false

    implicitWidth: row.implicitWidth + hPadding * 2
    implicitHeight: parent?.height ?? Theme.barHeight - 10
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    // Capsule behind the content; the open panel's button glows faintly.
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.pressed ? Theme.pressed : root.containsMouse ? Theme.hover : "transparent"
        scale: root.pressed ? 0.94 : 1

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        opacity: root.active ? 1 : 0
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.alpha(Theme.accent, 0.26)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(Theme.accent2, 0.18)
            }
        }

        Behavior on opacity {
            NumberAnimation {
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
