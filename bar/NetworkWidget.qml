import QtQuick
import qs.config
import qs.components
import qs.services
import qs.popups

BarButton {
    id: root

    hPadding: 7
    active: popup.visible
    onClicked: popup.toggle()

    spacing: 0

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: Net.wired ? Icons.ethernet : Net.wifi ? Icons.wifi(Net.wifi.signalStrength) : Net.hasWifi ? Icons.wifiOff : Icons.networkOff
        color: Net.connected ? Theme.text : Theme.overlay1
    }

    // Interface (or Wi-Fi network) name slides out on hover.
    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: root.containsMouse || popup.visible ? label.implicitWidth + 7 : 0
        height: label.implicitHeight
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        StyledText {
            id: label

            x: 7
            text: Net.wired ? Net.wired.name : Net.wifi ? Net.wifi.name : "Offline"
            font.pixelSize: Theme.smallFontSize + 1
            color: Theme.subtext1
        }
    }

    NetworkPopup {
        id: popup

        name: "network"
        target: root
    }
}
