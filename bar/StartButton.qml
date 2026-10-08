import QtQuick
import qs.config
import qs.components
import qs.popups

BarButton {
    id: root

    hPadding: 9
    active: popup.visible
    onClicked: e => {
        if (e.button === Qt.RightButton)
            Theme.cycleFlavor();
        else
            popup.toggle();
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.nixos
        size: 18
        color: Theme.accent
        rotation: root.active ? 60 : 0

        Behavior on rotation {
            NumberAnimation {
                duration: Theme.animSlow
                easing.type: Easing.OutBack
            }
        }
    }

    StartMenu {
        id: popup

        name: "start"
        target: root
    }
}
