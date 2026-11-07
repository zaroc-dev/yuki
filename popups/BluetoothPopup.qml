import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

BarPopup {
    id: root

    readonly property var adapter: Bt.adapter
    readonly property bool on: Bt.on
    readonly property var connected: Bt.connected
    readonly property var paired: Bt.paired
    readonly property var nearby: Bt.nearby

    onVisibleChanged: {
        if (!visible)
            Bt.setDiscovering(false);
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

        BluetoothDeviceRow {}
    }

    SectionLabel {
        visible: root.on && root.paired.length > 0
        text: "Paired"
    }

    Repeater {
        model: root.on ? root.paired : []

        BluetoothDeviceRow {}
    }

    SectionLabel {
        visible: root.on && (root.adapter?.discovering ?? false)
        text: root.nearby.length > 0 ? "Nearby" : "Searching…"
    }

    Repeater {
        model: root.on && root.adapter?.discovering ? root.nearby : []

        BluetoothDeviceRow {}
    }
}

