import QtQuick
import qs.config

// On/off switch: the thumb grows and carries a check when on.
MouseArea {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 26
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: toggled(!checked)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.well
        border.width: root.checked ? 0 : 1.5
        border.color: Theme.overlay0

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            opacity: root.checked ? 1 : 0
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Theme.accent
                }
                GradientStop {
                    position: 1
                    color: Theme.accent2
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim
                }
            }
        }

        Rectangle {
            id: thumb

            readonly property real size: root.pressed ? 22 : root.checked ? 20 : 14

            x: root.checked ? parent.width - width - 3 : 6 - (size - 14) / 2
            anchors.verticalCenter: parent.verticalCenter
            width: root.pressed ? size + 4 : size
            height: size
            radius: height / 2
            color: root.checked ? Theme.onAccent : Theme.overlay1

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animSlow
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.4
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: Theme.anim
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: Theme.anim
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }

            Icon {
                anchors.centerIn: parent
                text: Icons.check
                size: 12
                color: Theme.accent
                opacity: root.checked ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }
            }
        }
    }
}
