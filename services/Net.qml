pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values.slice().sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength) : []
    readonly property var wifi: wifiNetworks.find(n => n.connected) ?? null

    readonly property bool connected: wired !== null || wifi !== null
    readonly property bool hasWifi: wifiDevice !== null

    readonly property string label: wired ? (wired.network?.name || "Wired") : wifi ? wifi.name : "Disconnected"

    function isSecure(network) {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Unknown;
    }
}
