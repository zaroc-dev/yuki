import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config
import qs.components
import qs.services

BarPopup {
    id: root

    property var pskTarget: null

    onVisibleChanged: {
        if (Net.wifiDevice)
            Net.wifiDevice.scannerEnabled = visible;
        if (!visible)
            pskTarget = null;
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
            readonly property bool asking: root.pskTarget === modelData

            Layout.fillWidth: true
            spacing: 4

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
                        root.pskTarget = net.asking ? null : n;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.innerRadius
                    color: net.modelData.connected ? Qt.alpha(Theme.accent, 0.15) : row.containsMouse ? Theme.hover : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Icon {
                        text: Icons.wifi(net.modelData.signalStrength)
                        color: net.modelData.connected ? Theme.accent : Theme.text
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: net.modelData.name
                        color: net.modelData.connected ? Theme.accent : Theme.text
                    }

                    StyledText {
                        visible: net.modelData.stateChanging
                        text: "…"
                        color: Theme.subtext0
                    }

                    Icon {
                        visible: Net.isSecure(net.modelData)
                        text: Icons.lock
                        size: 13
                        color: Theme.overlay1
                    }
                }
            }

            // Password prompt for unknown secured networks.
            Rectangle {
                Layout.fillWidth: true
                visible: net.asking
                implicitHeight: 34
                radius: Theme.innerRadius
                color: Theme.surface0
                border.width: 1
                border.color: psk.activeFocus ? Theme.accent : "transparent"

                TextInput {
                    id: psk

                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    focus: net.asking
                    onVisibleChanged: if (visible) forceActiveFocus()
                    onAccepted: {
                        net.modelData.connectWithPsk(text);
                        root.pskTarget = null;
                    }

                    StyledText {
                        visible: !psk.text
                        text: "Password"
                        color: Theme.overlay0
                    }
                }
            }
        }
    }

    StyledText {
        visible: Networking.connectivity !== NetworkConnectivity.Full && Networking.connectivity !== NetworkConnectivity.Unknown
        text: `Connectivity: ${NetworkConnectivity.toString(Networking.connectivity)}`
        color: Theme.peach
        font.pixelSize: Theme.smallFontSize
    }
}
