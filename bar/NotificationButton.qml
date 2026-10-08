import QtQuick
import qs.config
import qs.components
import qs.services
import qs.popups

BarButton {
    id: root

    hPadding: 7
    spacing: 4
    active: popup.visible
    onClicked: e => {
        if (e.button === Qt.RightButton)
            Notifs.toggleDnd();
        else
            popup.toggle();
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: Notifs.dnd ? Icons.bellOff : Notifs.count > 0 ? Icons.bellBadge : Icons.bellOutline
        color: Notifs.dnd ? Theme.overlay1 : Notifs.count > 0 ? Theme.accent : Theme.text
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        visible: Notifs.count > 0
        text: Notifs.count
        font.pixelSize: Theme.smallFontSize
        font.weight: Font.DemiBold
        color: Theme.subtext1
    }

    NotificationCenter {
        id: popup

        name: "notifications"
        target: root
    }
}
