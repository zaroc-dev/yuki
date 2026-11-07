import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config
import qs.components
import qs.services

// Wired, Wi-Fi (with the same join form as the popup, 802.1X included), saved
// Wi-Fi profiles and VPNs (toggle, password prompt, import).
Page {
    id: root

    // Wi-Fi network whose join form is open, "add" for "Add network", or null.
    property var joinTarget: null
    readonly property var wiredDevices: Net.devices.filter(d => d.type === DeviceType.Wired)

    Component.onCompleted: {
        if (Net.wifiDevice)
            Net.wifiDevice.scannerEnabled = true;
        Net.refreshSaved();
        Vpn.refresh();
    }
    Component.onDestruction: {
        if (Net.wifiDevice)
            Net.wifiDevice.scannerEnabled = false;
        Vpn.clearPrompts();
    }

    // Rows with their own card background, grouped under a label.
    component Group: ColumnLayout {
        id: group

        property string title
        default property alias content: rows.data

        Layout.fillWidth: true
        spacing: 8

        SectionLabel {
            text: group.title
        }

        ColumnLayout {
            id: rows

            Layout.fillWidth: true
            spacing: 6
        }
    }

    component SavedWifiRow: SettingRow {
        id: saved

        required property var modelData
        property bool armed: false

        icon: modelData.enterprise ? Icons.shieldLock : Icons.lock
        label: modelData.ssid
        description: {
            if (armed)
                return "Click the bin again to forget this network";
            const parts = [modelData.enterprise ? "Enterprise (802.1X)" : "Password"];
            if (modelData.active)
                parts.push("connected");
            else if (modelData.lastUsed > 0)
                parts.push(`last used ${new Date(modelData.lastUsed * 1000).toLocaleDateString(Qt.locale(), Locale.ShortFormat)}`);
            return parts.join(" · ");
        }

        Timer {
            running: saved.armed
            interval: 4000
            onTriggered: saved.armed = false
        }

        Row {
            spacing: 10

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Auto-join"
                font.pixelSize: Theme.smallFontSize
                color: Theme.subtext0
            }

            Toggle {
                anchors.verticalCenter: parent.verticalCenter
                checked: saved.modelData.autoconnect
                onToggled: v => Net.setAutoconnect(saved.modelData.uuid, v)
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                iconSize: 15
                icon: Icons.trash
                color: saved.armed ? Theme.red : Theme.overlay1
                onClicked: {
                    if (!saved.armed) {
                        saved.armed = true;
                        return;
                    }
                    saved.armed = false;
                    Net.deleteProfile(saved.modelData.uuid);
                }
            }
        }
    }

    Section {
        title: "Status"

        SettingRow {
            icon: Net.wired ? Icons.ethernet : Net.wifi ? Icons.wifi(Net.wifi.signalStrength) : Icons.networkOff
            label: Net.wired ? "Wired" : Net.wifi ? Net.wifi.name : "Offline"
            description: {
                const vpn = Vpn.active.length > 0 ? ` · VPN: ${Vpn.active.map(c => c.name).join(", ")}` : "";
                switch (Networking.connectivity) {
                case NetworkConnectivity.Full:
                    return `Online${vpn}`;
                case NetworkConnectivity.Portal:
                    return `Sign-in page (captive portal) in the way${vpn}`;
                case NetworkConnectivity.Limited:
                    return `Connected, but no internet${vpn}`;
                case NetworkConnectivity.None:
                    return "Not connected";
                default:
                    return Net.connected ? `Connected${vpn}` : "Not connected";
                }
            }

            IconButton {
                icon: Icons.refresh
                color: Theme.subtext0
                visible: Networking.canCheckConnectivity
                onClicked: Networking.checkConnectivity()
            }
        }

        SettingRow {
            visible: Net.hasEditor
            icon: Icons.tune
            label: "Advanced settings"
            description: "IP addresses, DNS, proxies and everything else in NetworkManager's editor"

            PillButton {
                text: "Open editor"
                onClicked: {
                    Ui.settingsOpen = false;
                    Net.openEditor();
                }
            }
        }
    }

    Group {
        visible: root.wiredDevices.length > 0
        title: "Wired"

        Repeater {
            model: root.wiredDevices

            WiredCard {
                details: true
            }
        }
    }

    Group {
        visible: Net.hasWifi
        title: "Wi-Fi"

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: wifiHead.implicitHeight + 20
            radius: Theme.radius + 2
            color: Theme.card

            ColumnLayout {
                id: wifiHead

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 12
                        color: Net.wifi ? Qt.alpha(Theme.accent, 0.18) : Theme.well

                        Icon {
                            anchors.centerIn: parent
                            text: Networking.wifiEnabled ? Icons.wifi(Net.wifi?.signalStrength ?? 1) : Icons.wifiOff
                            color: Net.wifi ? Theme.accent : Theme.overlay1
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: Net.wifi ? Net.wifi.name : "Wi-Fi"
                        }

                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Theme.smallFontSize
                            color: Theme.subtext0
                            text: {
                                if (!Networking.wifiHardwareEnabled)
                                    return "Turned off by a hardware switch";
                                if (!Networking.wifiEnabled)
                                    return "Off";
                                if (Net.wifi)
                                    return `Connected · ${Math.round(Net.wifi.signalStrength * 100)}% · ${WifiSecurityType.toString(Net.wifi.security)} · ${Net.wifiDevice.name}`;
                                return `Not connected · ${Net.wifiDevice?.name ?? ""}`;
                            }
                        }
                    }

                    IconButton {
                        visible: Networking.wifiEnabled
                        size: 30
                        iconSize: 15
                        icon: Icons.refresh
                        color: Theme.subtext0
                        onClicked: {
                            Net.wifiDevice.scannerEnabled = false;
                            Net.wifiDevice.scannerEnabled = true;
                        }
                    }

                    Toggle {
                        checked: Networking.wifiEnabled
                        onToggled: v => Networking.wifiEnabled = v
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.leftMargin: 48
                    active: Net.wifi !== null && Net.wifiDevice !== null
                    visible: active

                    sourceComponent: NetworkDetails {
                        iface: Net.wifiDevice.name
                        mac: Net.wifiDevice.address
                    }
                }
            }
        }

        Repeater {
            model: Networking.wifiEnabled ? Net.wifiNetworks : []

            WifiNetworkRow {
                joining: root.joinTarget === modelData
                onJoinRequested: open => root.joinTarget = open ? modelData : null
            }
        }

        // Hidden networks, or anything that needs settings up front
        // (802.1X with a certificate, a specific CA, …).
        MouseArea {
            id: addRow

            Layout.fillWidth: true
            visible: Networking.wifiEnabled
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
                    text: "Add network… (hidden, enterprise / 802.1X)"
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
    }

    Section {
        visible: Net.savedWifi.length > 0
        title: "Saved Wi-Fi networks"
        subtitle: "Also the ones out of range. Auto-join connects to them when they're around."

        Repeater {
            model: Net.savedWifi

            SavedWifiRow {}
        }
    }

    Group {
        visible: Vpn.hasNmcli || Vpn.hasMullvad
        title: "VPN"

        StyledText {
            Layout.fillWidth: true
            visible: Vpn.connections.length === 0
            text: "No VPN profiles yet. Import one below."
            color: Theme.overlay1
        }

        Repeater {
            model: Vpn.connections

            VpnRow {
                manage: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Vpn.hasNmcli
            implicitHeight: importBody.implicitHeight + 24
            radius: Theme.radius + 2
            color: Theme.card

            ColumnLayout {
                id: importBody

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: importPath

                        Layout.fillWidth: true
                        icon: Icons.fileImport
                        placeholder: "~/Downloads/wg0.conf or company.ovpn"
                        readOnly: Vpn.importing !== ""
                        onAccepted: Vpn.importFile(text)
                    }

                    Spinner {
                        visible: Vpn.importing !== ""
                    }

                    PillButton {
                        visible: Vpn.importing === ""
                        text: "Import"
                        primary: importPath.text.trim() !== ""
                        onClicked: Vpn.importFile(importPath.text)
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Vpn.importError || "WireGuard (.conf), OpenVPN (.ovpn) or Cisco (.pcf). Imported profiles stay off until you switch them on."
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.smallFontSize
                    color: Vpn.importError ? Theme.red : Theme.subtext0
                }
            }

            Connections {
                target: Vpn

                function onImported(name): void {
                    importPath.text = "";
                }
            }
        }
    }
}
