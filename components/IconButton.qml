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
        color: root.pressed ? Theme.pressed : root.containsMouse ? Theme.hover : "transparent"
        opacity: root.enabled ? 1 : 0.4
        scale: root.pressed ? 0.92 : 1

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
            }
        }
    }

    // Primary: aurora-filled, with a glassy top light.
    Rectangle {
        anchors.fill: parent
        visible: root.filled
        radius: height / 2
        opacity: root.enabled ? 1 : 0.4
        scale: root.pressed ? 0.92 : root.containsMouse ? 1.05 : 1
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.accent
            }
            GradientStop {
                position: 1
                color: Theme.accent2
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.anim
                easing.type: Easing.OutBack
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.alpha("white", 0.25)
                }
                GradientStop {
                    position: 0.5
                    color: "transparent"
                }
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
