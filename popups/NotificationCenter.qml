import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

BarPopup {
    id: root

    // Everything is listed here, so drop the toasts.
    onVisibleChanged: {
        if (visible)
            Notifs.popups = [];
    }

    RowLayout {
        Layout.preferredWidth: 380
        Layout.fillWidth: true
        spacing: 4

        StyledText {
            Layout.fillWidth: true
            text: "Notifications"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        IconButton {
            icon: Notifs.dnd ? Icons.bellOff : Icons.bell
            color: Notifs.dnd ? Theme.accent : Theme.subtext0
            onClicked: Notifs.toggleDnd()
        }

        IconButton {
            icon: Icons.clearAll
            color: Theme.subtext0
            enabled: Notifs.count > 0
            onClicked: Notifs.clearAll()
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: Notifs.dnd
        text: "Do not disturb is on. Only critical notifications pop up."
        font.pixelSize: Theme.smallFontSize
        color: Theme.subtext0
        wrapMode: Text.Wrap
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        visible: Notifs.count === 0

        Column {
            anchors.centerIn: parent
            spacing: 6

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Icons.bellOutline
                size: 32
                color: Theme.surface2
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "All caught up"
                color: Theme.overlay1
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 520)
        visible: Notifs.count > 0
        clip: true
        spacing: 8
        // ScriptModel diffs the array, so add/remove transitions can run.
        model: ScriptModel {
            values: Notifs.list
        }
        boundsBehavior: Flickable.StopAtBounds

        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 220
            }
            NumberAnimation {
                property: "x"
                from: 24
                duration: 260
                easing.type: Easing.OutCubic
            }
        }
        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 160
            }
            NumberAnimation {
                property: "x"
                to: 40
                duration: 200
                easing.type: Easing.InCubic
            }
        }
        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        delegate: NotificationCard {
            required property var modelData

            width: ListView.view.width
            notif: modelData
        }
    }
}
