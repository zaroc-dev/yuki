pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth devices of the default adapter, grouped like the popup and the
// settings page show them.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
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

    function setDiscovering(on) {
        if (adapter && adapter.discovering !== on)
            adapter.discovering = on;
    }
}
