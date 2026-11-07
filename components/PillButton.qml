import QtQuick
import qs.config

// Text button for forms (Connect / Cancel). `primary` is the accent-filled one.
MouseArea {
    id: root

    property string text
    property bool primary: false
    property bool danger: false

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 30
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.primary ? (root.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent) : root.pressed ? Theme.pressed : root.containsMouse ? Theme.hover : Qt.alpha(Theme.surface1, 0.6)

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }
    }

    StyledText {
        id: label

        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Theme.smallFontSize + 1
        font.weight: root.primary ? Font.DemiBold : Font.Normal
        color: root.primary ? Theme.onAccent : root.danger ? Theme.red : Theme.text
    }
}
