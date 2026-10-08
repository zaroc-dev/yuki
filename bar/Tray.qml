import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config
import qs.popups

Row {
    id: root

    visible: SystemTray.items.values.length > 0
    anchors.verticalCenter: parent?.verticalCenter
    spacing: 2

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            width: 26
            height: 24
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            onClicked: e => {
                if ((e.button === Qt.RightButton || (e.button === Qt.LeftButton && modelData.onlyMenu)) && modelData.hasMenu)
                    menu.openFor(item, modelData.menu);
                else if (e.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else
                    modelData.activate();
            }
            onWheel: e => modelData.scroll(e.angleDelta.y / 120, false)

            Rectangle {
                anchors.fill: parent
                radius: Theme.innerRadius
                color: menu.visible && menu.target === item ? Qt.alpha(Theme.accent, 0.18) : item.containsMouse ? Theme.hover : "transparent"
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: item.modelData.icon
                asynchronous: true
            }
        }
    }

    TrayMenu {
        id: menu

        target: root
    }
}
