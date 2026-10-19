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
        else
            joinTarget = null;
    }

    component VpnRow: MouseArea {
        id: vrow

        required property var modelData
        readonly property bool on: modelData.state === "on"
        readonly property bool busy: modelData.state === "connecting" || modelData.state === "disconnecting"
        readonly property string error: Vpn.errors[modelData.id] ?? ""

        Layout.fillWidth: true
        implicitHeight: 52
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Vpn.toggle(modelData.id)

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius + 2
            color: vrow.on ? Qt.alpha(Theme.accent, 0.16) : vrow.containsMouse ? Theme.cardHover : Theme.card

            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 12

            Icon {
                text: Icons.vpn
                color: vrow.on ? Theme.accent : vrow.modelData.state === "error" ? Theme.red : Theme.text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: vrow.modelData.name
                    color: vrow.on ? Theme.accent : Theme.text
                }

                StyledText {
                    Layout.fillWidth: true
                    text: vrow.error || vrow.modelData.detail
                    font.pixelSize: Theme.smallFontSize
                    color: vrow.error || vrow.modelData.state === "error" ? Theme.red : Theme.subtext0
                }
            }

            Icon {
                id: vspin

                visible: vrow.busy
                text: Icons.loading
                color: Theme.accent

                RotationAnimation on rotation {
                    running: vspin.visible
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 900
                }
            }

            Toggle {
                checked: vrow.on || vrow.modelData.state === "connecting"
                onToggled: v => Vpn.setActive(vrow.modelData.id, v)
            }
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

        Rectangle {
            id: wired

            required property var modelData

            Layout.fillWidth: true
            implicitHeight: wiredRow.implicitHeight + 20
            radius: Theme.radius + 2
            color: Theme.card

            RowLayout {
            id: wiredRow

            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: 12
                color: wired.modelData.connected ? Qt.alpha(Theme.accent, 0.18) : Theme.well

                Icon {
                    anchors.centerIn: parent
                    text: Icons.ethernet
                    color: wired.modelData.connected ? Theme.accent : Theme.overlay1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: wired.modelData.network?.name || wired.modelData.name
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Theme.smallFontSize
                    color: Theme.subtext0
                    text: {
                        const d = wired.modelData;
                        if (!d.connected)
                            return d.hasLink ? ConnectionState.toString(d.state) : "Cable unplugged";
                        const speed = d.linkSpeed > 0 ? ` · ${d.linkSpeed >= 1000 ? d.linkSpeed / 1000 + " Gb/s" : d.linkSpeed + " Mb/s"}` : "";
                        return `Connected${speed}`;
                    }
                }
            }
            }
        }
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

        ColumnLayout {
            id: net

            required property var modelData
            readonly property bool joining: root.joinTarget === modelData
            // Forget takes a second click, like Bluetooth devices.
            property bool armed: false

            Layout.fillWidth: true
            spacing: 4

            Timer {
                running: net.armed
                interval: 4000
                onTriggered: net.armed = false
            }

            MouseArea {
                id: row

                Layout.fillWidth: true
                implicitHeight: 40
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const n = net.modelData;
                    if (n.connected)
                        n.disconnect();
                    else if (n.known || !Net.isSecure(n))
                        n.connect();
                    else
                        root.joinTarget = net.joining ? null : n;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: net.modelData.connected ? Qt.alpha(Theme.accent, 0.16) : row.containsMouse || net.joining ? Theme.hover : "transparent"
                    border.width: net.modelData.connected ? 1 : 0
                    border.color: Qt.alpha(Theme.accent, 0.35)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 10

                    Icon {
                        text: Icons.wifi(net.modelData.signalStrength)
                        color: net.modelData.connected ? Theme.accent : Theme.text
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: net.armed ? "Click again to forget" : net.modelData.name
                        color: net.armed ? Theme.red : net.modelData.connected ? Theme.accent : Theme.text
                        font.weight: net.modelData.connected ? Font.DemiBold : Font.Normal
                    }

                    StyledText {
                        visible: net.modelData.stateChanging
                        text: "…"
                        color: Theme.subtext0
                    }

                    Icon {
                        visible: Net.isSecure(net.modelData)
                        text: Net.isEnterprise(net.modelData) ? Icons.shieldLock : Icons.lock
                        size: 13
                        color: Theme.overlay1
                    }

                    IconButton {
                        visible: net.modelData.known
                        size: 28
                        iconSize: 15
                        icon: Icons.trash
                        color: net.armed ? Theme.red : Theme.overlay1
                        onClicked: {
                            if (!net.armed) {
                                net.armed = true;
                                return;
                            }
                            net.armed = false;
                            net.modelData.forget();
                        }
                    }

                    Item {
                        visible: !net.modelData.known
                        implicitWidth: 6
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                active: net.joining
                visible: active

                sourceComponent: WifiJoinForm {
                    network: net.modelData
                    onFinished: root.joinTarget = null
                }
            }
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
