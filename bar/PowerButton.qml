import QtQuick
import qs.config
import qs.components
import qs.popups

BarButton {
    id: root

    hPadding: 8
    active: popup.visible
    onClicked: popup.toggle()

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.power
        color: root.containsMouse || popup.visible ? Theme.red : Theme.text
    }

    PowerMenu {
        id: popup

        name: "power"
        target: root
    }
}
