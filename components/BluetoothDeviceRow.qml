import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.config
import qs.services

// One Bluetooth device: click to connect/disconnect/pair, forget with a second
// click. `manage` (settings page) adds rename and trust.
MouseArea {
    id: row

    required property var modelData
    // Settings page: rename and trust as well.
    property bool manage: false
    property bool renaming: false
    readonly property var dev: modelData
    readonly property bool busy: dev.state === BluetoothDeviceState.Connecting || dev.state === BluetoothDeviceState.Disconnecting || dev.pairing
    // Forget takes a second click, like the power buttons on the lock screen.
    property bool armed: false

    Layout.fillWidth: true
    implicitHeight: 56
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
        if (dev.connected)
            dev.disconnect();
        else if (dev.paired)
            dev.connect();
        else
            Bt.pair(dev);
    }

    Timer {
        running: row.armed
        interval: 4000
        onTriggered: row.armed = false
    }

    // Once paired, trust and connect right away.
    Connections {
        target: row.dev

        function onPairedChanged(): void {
            if (row.dev.paired) {
                row.dev.trusted = true;
                // Headphones often connect on their own once paired.
                if (!row.dev.connected)
                    row.dev.connect();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: row.dev.connected ? Qt.alpha(Theme.accent, 0.14) : row.containsMouse ? Theme.cardHover : Theme.card
        border.width: row.dev.connected ? 1 : 0
        border.color: Qt.alpha(Theme.accent, 0.35)

        Behavior on color {
            ColorAnimation {
                duration: Theme.anim
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 12

        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: 13
            color: Theme.well
            gradient: row.dev.connected ? aurora : null

            Gradient {
                id: aurora

                GradientStop {
                    position: 0
                    color: Theme.accent
                }
                GradientStop {
                    position: 1
                    color: Theme.accent2
                }
            }

            Icon {
                anchors.centerIn: parent
                text: Icons.device(row.dev.icon)
                color: row.dev.connected ? Theme.onAccent : Theme.subtext1
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            TextField {
                id: nameField

                Layout.fillWidth: true
                visible: row.renaming
                implicitHeight: 32
                text: row.dev.name
                onAccepted: {
                    if (text.trim())
                        row.dev.name = text.trim();
                    row.renaming = false;
                }
                onCancelled: row.renaming = false
                onVisibleChanged: if (visible) {
                    text = row.dev.name;
                    focusInput();
                    selectAll();
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !row.renaming
                text: row.dev.name || row.dev.address
                color: row.dev.connected ? Theme.text : Theme.subtext1
                font.weight: row.dev.connected ? Font.DemiBold : Font.Normal
            }

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Theme.smallFontSize
                color: row.armed ? Theme.red : Theme.subtext0
                text: {
                    if (row.armed)
                        return "Click again to forget";
                    if (row.dev.pairing)
                        return "Pairing…";
                    if (row.dev.state === BluetoothDeviceState.Connecting)
                        return "Connecting…";
                    if (row.dev.state === BluetoothDeviceState.Disconnecting)
                        return "Disconnecting…";
                    if (row.dev.connected)
                        return row.dev.batteryAvailable ? `Connected · ${Math.round(row.dev.battery * 100)}% battery` : "Connected";
                    if (row.dev.paired)
                        return row.manage && row.dev.trusted ? "Paired · trusted · click to connect" : "Paired · click to connect";
                    return row.dev.trusted ? "Pairing lost · click to pair again" : "Click to pair";
                }
            }
        }

        IconButton {
            visible: row.manage && !row.renaming && (row.dev.paired || row.dev.trusted)
            size: 28
            icon: Icons.pencil
            color: Theme.subtext0
            onClicked: row.renaming = true
        }

        // Trusted devices may connect on their own (headphones turning on).
        IconButton {
            visible: row.manage && (row.dev.paired || row.dev.trusted)
            size: 28
            icon: row.dev.trusted ? Icons.shieldLock : Icons.lockOpen
            color: row.dev.trusted ? Theme.accent : Theme.overlay1
            onClicked: row.dev.trusted = !row.dev.trusted
        }

        IconButton {
            visible: row.dev.connected && !row.busy
            size: 28
            icon: Icons.linkOff
            color: Theme.subtext0
            onClicked: row.dev.disconnect()
        }

        // Also clears stale pairings (forget disconnects first).
        IconButton {
            visible: (row.dev.paired || row.dev.trusted) && !row.dev.pairing
            size: 28
            icon: Icons.trash
            color: row.armed ? Theme.red : Theme.subtext0
            onClicked: {
                if (!row.armed) {
                    row.armed = true;
                    return;
                }
                row.armed = false;
                row.dev.forget();
            }
        }

        IconButton {
            visible: row.dev.pairing
            size: 28
            icon: Icons.close
            color: Theme.subtext0
            onClicked: row.dev.cancelPair()
        }

        Spinner {
            visible: row.busy
        }
    }
}
