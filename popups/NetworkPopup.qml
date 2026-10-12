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

    component SectionLabel: StyledText {
        Layout.topMargin: 2
        font.pixelSize: Theme.smallFontSize
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        color: Theme.overlay2
    }

    component VpnRow: MouseArea {
        id: vrow

        required property var modelData
        readonly property bool on: modelData.state === "on"
        readonly property bool busy: modelData.state === "connecting" || modelData.state === "disconnecting"
        readonly property string error: Vpn.errors[modelData.id] ?? ""

        Layout.fillWidth: true
        implicitHeight: 44
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Vpn.toggle(modelData.id)

        Rectangle {
            anchors.fill: parent
            radius: Theme.innerRadius
            color: vrow.on ? Qt.alpha(Theme.accent, 0.15) : vrow.containsMouse ? Theme.hover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

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

    RowLayout {
        Layout.preferredWidth: 340
        Layout.fillWidth: true

        StyledText {
            Layout.fillWidth: true
            text: "Network"
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        // Wi-Fi radio toggle.
        MouseArea {
            id: toggle

            visible: Net.hasWifi
            implicitWidth: 40
            implicitHeight: 22
            cursorShape: Qt.PointingHandCursor
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Networking.wifiEnabled ? Theme.accent : Theme.surface1

                Rectangle {
                    x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    radius: 8
                    color: Networking.wifiEnabled ? Theme.onAccent : Theme.overlay1

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.anim
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    // Wired devices.
    Repeater {
        model: Net.devices.filter(d => d.type === DeviceType.Wired)

        RowLayout {
            id: wired

            required property var modelData

            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: 18
                color: wired.modelData.connected ? Qt.alpha(Theme.accent, 0.18) : Theme.surface0

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

    SectionLabel {
        visible: Vpn.connections.length > 0
        text: "VPN"
    }

    Repeater {
        model: Vpn.connections

        VpnRow {}
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        visible: Net.hasWifi
        color: Theme.surface0
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
                implicitHeight: 36
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
                    radius: Theme.innerRadius
                    color: net.modelData.connected ? Qt.alpha(Theme.accent, 0.15) : row.containsMouse || net.joining ? Theme.hover : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 4
                    spacing: 10

                    Icon {
                        text: Icons.wifi(net.modelData.signalStrength)
                        color: net.modelData.connected ? Theme.accent : Theme.text
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: net.armed ? "Click again to forget" : net.modelData.name
                        color: net.armed ? Theme.red : net.modelData.connected ? Theme.accent : Theme.text
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
        implicitHeight: 32
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.joinTarget = root.joinTarget === "add" ? null : "add"

        Rectangle {
            anchors.fill: parent
            radius: Theme.innerRadius
            color: addRow.containsMouse ? Theme.hover : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
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
