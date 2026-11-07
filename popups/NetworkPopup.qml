import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config
import qs.components
import qs.services

BarPopup {
    id: root

    // Wi-Fi network whose join form is open, "add" for "Add network", or null.
    property var joinTarget: null

    onVisibleChanged: {
        if (Net.wifiDevice)
            Net.wifiDevice.scannerEnabled = visible;
        if (visible)
            Vpn.refresh();
        else {
            joinTarget = null;
            Vpn.clearPrompts();
        }
    }

    PanelHeader {
        Layout.preferredWidth: 360
        icon: Net.wired ? Icons.ethernet : Net.wifi ? Icons.wifi(Net.wifi.signalStrength) : Icons.networkOff
        lit: Net.connected
        title: Net.wired ? "Wired" : Net.wifi ? Net.wifi.name : "Offline"
        subtitle: {
            const vpn = Vpn.active.length > 0 ? " · VPN on" : "";
            if (Net.wired)
                return `${Net.wired.name}${vpn}`;
            if (Net.wifi)
                return `Wi-Fi · ${Net.wifi.signalStrength >= 0 ? Math.round(Net.wifi.signalStrength * 100) + "%" : "connected"}${vpn}`;
            return Net.hasWifi && !Networking.wifiEnabled ? "Wi-Fi is off" : "Not connected";
        }

        // Wi-Fi radio.
        Toggle {
            visible: Net.hasWifi
            checked: Networking.wifiEnabled
            onToggled: v => Networking.wifiEnabled = v
        }
    }

    // Wired devices.
    Repeater {
        model: Net.devices.filter(d => d.type === DeviceType.Wired)

        WiredCard {}
    }

    SectionLabel {
        visible: Vpn.connections.length > 0
        text: "VPN"
    }

    Repeater {
        model: Vpn.connections

        VpnRow {}
    }

    SectionLabel {
        visible: Net.hasWifi
        text: "Wi-Fi"

        IconButton {
            visible: Networking.wifiEnabled
            size: 26
            iconSize: 14
            icon: Icons.refresh
            color: Theme.subtext0
            onClicked: {
                if (Net.wifiDevice) {
                    Net.wifiDevice.scannerEnabled = false;
                    Net.wifiDevice.scannerEnabled = true;
                }
            }
        }
    }

    StyledText {
        visible: Net.hasWifi && !Networking.wifiEnabled
        text: "Wi-Fi is off"
        color: Theme.overlay1
    }

    // Wi-Fi networks.
    Repeater {
        model: Net.hasWifi && Networking.wifiEnabled ? Net.wifiNetworks.slice(0, 8) : []

        WifiNetworkRow {
            joining: root.joinTarget === modelData
            onJoinRequested: open => root.joinTarget = open ? modelData : null
        }
    }

    // Hidden networks, or anything that needs settings up front.
    MouseArea {
        id: addRow

        Layout.fillWidth: true
        visible: Net.hasWifi && Networking.wifiEnabled
        implicitHeight: 38
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.joinTarget = root.joinTarget === "add" ? null : "add"

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: addRow.containsMouse ? Theme.hover : "transparent"
            border.width: 1
            border.color: Theme.rim
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            spacing: 10

            Icon {
                text: Icons.plus
                color: Theme.subtext0
            }

            StyledText {
                Layout.fillWidth: true
                text: "Add network…"
                color: Theme.subtext0
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: root.joinTarget === "add"
        visible: active

        sourceComponent: WifiJoinForm {
            onFinished: root.joinTarget = null
        }
    }

    StyledText {
        visible: Networking.connectivity !== NetworkConnectivity.Full && Networking.connectivity !== NetworkConnectivity.Unknown
        text: `Connectivity: ${NetworkConnectivity.toString(Networking.connectivity)}`
        color: Theme.peach
        font.pixelSize: Theme.smallFontSize
    }
}
