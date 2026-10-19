import QtQuick
import qs.config

// Single-line input for popups and forms. `password` hides the text and adds a
// show/hide toggle. Escape is handled here (cancelled) so it doesn't also close
// the surrounding popup.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder
    property string icon
    property bool password: false
    property bool reveal: false
    property bool readOnly: false
    readonly property bool hasFocus: input.activeFocus

    signal accepted
    signal cancelled

    function focusInput() {
        input.forceActiveFocus();
    }

    function selectAll() {
        input.selectAll();
    }

    implicitWidth: 240
    implicitHeight: 40
    radius: height / 2
    color: Theme.well
    border.width: input.activeFocus ? 1.5 : 1
    border.color: input.activeFocus ? Theme.accent : Theme.rim

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.anim
        }
    }

    Icon {
        id: leading

        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        visible: root.icon !== ""
        text: root.icon
        size: 15
        color: input.activeFocus ? Theme.accent : Theme.overlay1
    }

    TextInput {
        id: input

        anchors.left: root.icon !== "" ? leading.right : parent.left
        anchors.right: eye.visible ? eye.left : parent.right
        anchors.leftMargin: root.icon !== "" ? 9 : 16
        anchors.rightMargin: eye.visible ? 2 : 16
        anchors.verticalCenter: parent.verticalCenter
        echoMode: root.password && !root.reveal ? TextInput.Password : TextInput.Normal
        readOnly: root.readOnly
        color: Theme.text
        selectionColor: Qt.alpha(Theme.accent, 0.4)
        selectedTextColor: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        clip: true
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: root.cancelled()
    }

    StyledText {
        anchors.left: input.left
        anchors.right: input.right
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === ""
        text: root.placeholder
        color: Theme.overlay0
    }

    IconButton {
        id: eye

        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: root.password
        size: 28
        iconSize: 15
        icon: root.reveal ? Icons.eyeOff : Icons.eye
        color: Theme.overlay1
        onClicked: root.reveal = !root.reveal
    }
}
