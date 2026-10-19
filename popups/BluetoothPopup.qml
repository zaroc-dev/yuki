import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.config
import qs.components

BarPopup {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var devices: Bluetooth.devices.values.filter(d => d.adapter === adapter)
    readonly property var connected: devices.filter(d => d.connected)
    // Trusted but unpaired = paired here before and the pairing got lost; keep
    // it listed so it can be paired again or forgotten.
    readonly property var paired: devices.filter(d => (d.paired || d.trusted) && !d.connected)
    // Unknown devices with a real name (skip bare MAC addresses).
    readonly property var nearby: devices.filter(d => !d.paired && !d.trusted && d.name && d.name.replace(/-/g, ":") !== d.address)

    // BlueZ only bonds (stores the link keys) while the adapter is pairable, and
    // with no pairing agent registered it keeps switching that off. An unbonded
    // pairing is dropped on disconnect, so the device can't reconnect.
    function pair(dev) {
        if (adapter && !adapter.pairable)
            adapter.pairable = true;
        dev.pair();
    }

    onVisibleChanged: {
        if (!visible && adapter?.discovering)
            adapter.discovering = false;
    }

    component DeviceRow: MouseArea {
        id: row

        required property var modelData
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
                root.pair(dev);
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

                StyledText {
                    Layout.fillWidth: true
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
                            return "Paired · click to connect";
                        return row.dev.trusted ? "Pairing lost · click to pair again" : "Click to pair";
                    }
                }
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

            Icon {
                id: spinner

                visible: row.busy
                text: Icons.loading
                color: Theme.accent

                RotationAnimation on rotation {
                    running: spinner.visible
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 900
                }
            }
        }
    }

    // ---------- header ----------
    PanelHeader {
        Layout.preferredWidth: 360
        icon: !root.on ? Icons.bluetoothOff : root.connected.length > 0 ? Icons.bluetoothConnected : Icons.bluetooth
        lit: root.on
        title: "Bluetooth"
        subtitle: !root.on ? "Off" : root.connected.length > 0 ? `${root.connected.length} connected · ${root.adapter?.name ?? ""}` : root.adapter?.name ?? "No adapter"

        IconButton {
            id: scanBtn

            visible: root.on
            icon: Icons.scan
            color: root.adapter?.discovering ? Theme.accent : Theme.subtext0
            onClicked: root.adapter.discovering = !root.adapter.discovering

            SequentialAnimation on opacity {
                running: root.adapter?.discovering ?? false
                loops: Animation.Infinite
                onRunningChanged: if (!running) scanBtn.opacity = 1
                NumberAnimation {
                    to: 0.4
                    duration: 600
                }
                NumberAnimation {
                    to: 1
                    duration: 600
                }
            }
        }

        Toggle {
            checked: root.on
            onToggled: v => root.adapter.enabled = v
        }
    }

    SectionLabel {
        visible: root.on && root.connected.length > 0
        text: "Connected"
    }

    Repeater {
        model: root.on ? root.connected : []

        DeviceRow {}
    }

    SectionLabel {
        visible: root.on && root.paired.length > 0
        text: "Paired"
    }

    Repeater {
        model: root.on ? root.paired : []

        DeviceRow {}
    }

    SectionLabel {
        visible: root.on && (root.adapter?.discovering ?? false)
        text: root.nearby.length > 0 ? "Nearby" : "Searching…"
    }

    Repeater {
        model: root.on && root.adapter?.discovering ? root.nearby : []

        DeviceRow {}
    }
}

