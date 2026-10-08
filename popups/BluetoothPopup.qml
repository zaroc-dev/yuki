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
    readonly property var paired: devices.filter(d => d.paired && !d.connected)
    // Unpaired devices with a real name (skip bare MAC addresses).
    readonly property var nearby: devices.filter(d => !d.paired && d.name && d.name.replace(/-/g, ":") !== d.address)

    onVisibleChanged: {
        if (!visible && adapter?.discovering)
            adapter.discovering = false;
    }

    component SectionLabel: StyledText {
        Layout.topMargin: 2
        font.pixelSize: Theme.smallFontSize
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        color: Theme.overlay2
    }

    component DeviceRow: MouseArea {
        id: row

        required property var modelData
        readonly property var dev: modelData
        readonly property bool busy: dev.state === BluetoothDeviceState.Connecting || dev.state === BluetoothDeviceState.Disconnecting || dev.pairing

        Layout.fillWidth: true
        implicitHeight: 48
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            if (e.button === Qt.RightButton) {
                if (dev.paired)
                    dev.forget();
                return;
            }
            if (dev.connected)
                dev.disconnect();
            else if (dev.paired)
                dev.connect();
            else
                dev.pair();
        }

        // Once paired, trust and connect right away.
        Connections {
            target: row.dev

            function onPairedChanged(): void {
                if (row.dev.paired) {
                    row.dev.trusted = true;
                    row.dev.connect();
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.innerRadius + 2
            color: row.dev.connected ? Qt.alpha(Theme.accent, 0.14) : row.containsMouse ? Theme.hover : "transparent"

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
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: row.dev.connected ? Theme.accent : Qt.alpha(Theme.surface1, 0.8)

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
                    color: Theme.subtext0
                    text: {
                        if (row.dev.pairing)
                            return "Pairing…";
                        if (row.dev.state === BluetoothDeviceState.Connecting)
                            return "Connecting…";
                        if (row.dev.state === BluetoothDeviceState.Disconnecting)
                            return "Disconnecting…";
                        if (row.dev.connected)
                            return row.dev.batteryAvailable ? `Connected · ${Math.round(row.dev.battery * 100)}% battery` : "Connected";
                        return row.dev.paired ? "Paired · click to connect" : "Click to pair";
                    }
                }
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
    RowLayout {
        Layout.preferredWidth: 340
        Layout.fillWidth: true
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: "Bluetooth"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: root.adapter?.name ?? "No adapter"
                font.pixelSize: Theme.smallFontSize
                color: Theme.subtext0
            }
        }

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

    StyledText {
        visible: !root.on
        text: "Bluetooth is off"
        color: Theme.overlay1
    }

    SectionLabel {
        visible: root.on && root.connected.length > 0
        text: "CONNECTED"
    }

    Repeater {
        model: root.on ? root.connected : []

        DeviceRow {}
    }

    SectionLabel {
        visible: root.on && root.paired.length > 0
        text: "PAIRED"
    }

    Repeater {
        model: root.on ? root.paired : []

        DeviceRow {}
    }

    SectionLabel {
        visible: root.on && (root.adapter?.discovering ?? false)
        text: root.nearby.length > 0 ? "NEARBY" : "SEARCHING…"
    }

    Repeater {
        model: root.on && root.adapter?.discovering ? root.nearby : []

        DeviceRow {}
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.on
        text: "Right-click a paired device to forget it"
        font.pixelSize: Theme.smallFontSize
        color: Theme.overlay0
        horizontalAlignment: Text.AlignHCenter
    }
}

