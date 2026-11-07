import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config
import qs.services

// One Wi-Fi network: click to connect/disconnect, the join form underneath
// for networks that need a password or 802.1X settings, forget for known ones.
ColumnLayout {
    id: root

    required property var modelData
    // The join form under this row is open.
    property bool joining: false
    // Forget takes a second click, like Bluetooth devices.
    property bool armed: false

    signal joinRequested(bool open)

    Layout.fillWidth: true
    spacing: 4

    Timer {
        running: root.armed
        interval: 4000
        onTriggered: root.armed = false
    }

    MouseArea {
        id: row

        Layout.fillWidth: true
        implicitHeight: 40
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const n = root.modelData;
            if (n.connected)
                n.disconnect();
            else if (n.known || !Net.isSecure(n))
                n.connect();
            else
                root.joinRequested(!root.joining);
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: root.modelData.connected ? Qt.alpha(Theme.accent, 0.16) : row.containsMouse || root.joining ? Theme.hover : "transparent"
            border.width: root.modelData.connected ? 1 : 0
            border.color: Qt.alpha(Theme.accent, 0.35)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            spacing: 10

            Icon {
                text: Icons.wifi(root.modelData.signalStrength)
                color: root.modelData.connected ? Theme.accent : Theme.text
            }

            StyledText {
                Layout.fillWidth: true
                text: root.armed ? "Click again to forget" : root.modelData.name
                color: root.armed ? Theme.red : root.modelData.connected ? Theme.accent : Theme.text
                font.weight: root.modelData.connected ? Font.DemiBold : Font.Normal
            }

            StyledText {
                visible: root.modelData.known && !root.modelData.connected && !root.armed
                text: "Saved"
                font.pixelSize: Theme.smallFontSize
                color: Theme.overlay1
            }

            StyledText {
                visible: root.modelData.stateChanging
                text: "…"
                color: Theme.subtext0
            }

            Icon {
                visible: Net.isSecure(root.modelData)
                text: Net.isEnterprise(root.modelData) ? Icons.shieldLock : Icons.lock
                size: 13
                color: Theme.overlay1
            }

            IconButton {
                visible: root.modelData.known
                size: 28
                iconSize: 15
                icon: Icons.trash
                color: root.armed ? Theme.red : Theme.overlay1
                onClicked: {
                    if (!root.armed) {
                        root.armed = true;
                        return;
                    }
                    root.armed = false;
                    root.modelData.forget();
                }
            }

            Item {
                visible: !root.modelData.known
                implicitWidth: 6
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: root.joining
        visible: active

        sourceComponent: WifiJoinForm {
            network: root.modelData
            onFinished: root.joinRequested(false)
        }
    }
}
