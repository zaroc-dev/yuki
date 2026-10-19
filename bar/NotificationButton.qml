import QtQuick
import qs.config
import qs.components
import qs.services
import qs.popups

BarButton {
    id: root

    hPadding: 8
    active: popup.visible
    onClicked: e => {
        if (e.button === Qt.RightButton)
            Notifs.toggleDnd();
        else
            popup.toggle();
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: bell.implicitWidth
        height: bell.implicitHeight

        Icon {
            id: bell

            anchors.centerIn: parent
            text: Notifs.dnd ? Icons.bellOff : Icons.bellOutline
            color: Notifs.dnd ? Theme.overlay1 : Theme.text
        }

        // Count badge, popping in on the bell's shoulder.
        Rectangle {
            x: parent.width - width / 2 - 1
            y: -5
            width: Math.max(height, badgeCount.implicitWidth + 7)
            height: 14
            radius: 7
            visible: scale > 0
            scale: Notifs.count > 0 && !Notifs.dnd ? 1 : 0
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
            border.width: 2
            border.color: Theme.base

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animSlow
                    easing.type: Easing.OutBack
                }
            }

            StyledText {
                id: badgeCount

                anchors.centerIn: parent
                text: Notifs.count > 99 ? "99+" : Notifs.count
                font.family: Theme.displayFont
                font.pixelSize: 9
                font.weight: Font.Black
                color: Theme.onAccent
            }
        }
    }

    NotificationCenter {
        id: popup

        name: "notifications"
        target: root
    }
}
