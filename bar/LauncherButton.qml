import QtQuick
import qs.config
import qs.components
import qs.services

BarButton {
    hPadding: 8
    active: Ui.launcherOpen
    onClicked: Ui.launcherOpen = !Ui.launcherOpen

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.apps
        size: 17
    }
}
