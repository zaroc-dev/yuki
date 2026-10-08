import QtQuick
import qs.config

// On/off switch.
MouseArea {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: 40
    implicitHeight: 22
    cursorShape: Qt.PointingHandCursor
    onClicked: toggled(!checked)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.surface1

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }

        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: root.checked ? Theme.onAccent : Theme.overlay1

            Behavior on x {
                NumberAnimation {
                    duration: Theme.anim
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
