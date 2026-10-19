import QtQuick
import qs.config
import qs.components
import qs.popups

// Aurora badge with the distro glyph; spins a sixth of a turn while open.
MouseArea {
    id: root

    implicitWidth: height + 2
    implicitHeight: parent?.height ?? 30
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: e => {
        if (e.button === Qt.RightButton)
            Theme.cycleFlavor();
        else
            popup.toggle();
    }

    Rectangle {
        id: badge

        anchors.centerIn: parent
        width: parent.height
        height: width
        radius: popup.visible ? width / 2 : 10
        rotation: root.containsMouse && !popup.visible ? -6 : 0
        scale: root.pressed ? 0.9 : 1
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

        Behavior on radius {
            NumberAnimation {
                duration: Theme.animSlow
                easing.type: Easing.OutBack
            }
        }
        Behavior on rotation {
            NumberAnimation {
                duration: Theme.animSlow
                easing.type: Easing.OutBack
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
            }
        }

        // Glass highlight across the top half.
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.alpha("white", 0.28)
                }
                GradientStop {
                    position: 0.55
                    color: "transparent"
                }
            }
        }

        Icon {
            anchors.centerIn: parent
            text: Icons.nixos
            size: 17
            color: Theme.onAccent
            rotation: popup.visible ? 60 : 0

            Behavior on rotation {
                NumberAnimation {
                    duration: Theme.animGrow
                    easing.type: Easing.OutBack
                }
            }
        }
    }

    StartMenu {
        id: popup

        name: "start"
        target: root
    }
}
