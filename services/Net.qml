pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
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

    // SSID of the profile join() is setting up, "" when idle.
    readonly property string joining: joinProc.running ? joinProc.ssid : ""

    // $1 = SSID, then the `nmcli connection add` settings; the secret line on stdin.
    readonly property string joinScript: `
ssid=$1; shift
out=$(nmcli connection add type wifi ifname '*' con-name "$ssid" ssid "$ssid" "$@" 2>&1) || { echo "$out" >&2; exit 1; }
uuid=$(printf '%s' "$out" | sed -n 's/.*(\\([0-9a-f-]\\{36\\}\\)).*/\\1/p')
[ -n "$uuid" ] || { echo "$out" >&2; exit 1; }
IFS= read -r secret
if [ -n "$secret" ]; then
    printf 'set %s\\nsave persistent\\nquit\\n' "$secret" | nmcli connection edit uuid "$uuid" >/dev/null 2>&1 || {
        nmcli connection delete uuid "$uuid" >/dev/null 2>&1
        echo "Couldn't save the password" >&2
        exit 1
    }
fi
err=$(nmcli --wait 60 connection up uuid "$uuid" 2>&1 >/dev/null) || {
    nmcli connection delete uuid "$uuid" >/dev/null 2>&1
    echo "$err" >&2
    exit 1
}
`

    signal joined(string ssid)
    signal joinFailed(string ssid, string message)

    function isSecure(network) {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Unknown;
    }

    // 802.1X networks need identity etc., not just a PSK.
    function isEnterprise(network) {
        return [WifiSecurityType.Wpa2Eap, WifiSecurityType.WpaEap, WifiSecurityType.Wpa3SuiteB192].includes(network.security);
    }

    // Creates a Wi-Fi profile with nmcli and activates it. `settings` is a flat
    // [key, value, ...] list for `nmcli connection add`; `secret` ("<setting>
    // <value>", e.g. "802-1x.password hunter2") goes through stdin into nmcli's
    // editor so it never shows up in a command line or log. A profile that
    // fails to activate is deleted again, so retrying starts clean.
    function join(ssid, settings, secret) {
        if (joinProc.running)
            return;
        joinProc.ssid = ssid;
        joinProc.secret = secret ?? "";
        joinProc.command = ["sh", "-c", joinScript, "join", ssid].concat(settings);
        joinProc.running = true;
    }

    Process {
        id: joinProc

        property string ssid
        property string secret

        stdinEnabled: true
        stderr: StdioCollector {
            id: joinErr
        }
        onStarted: {
            write(secret + "\n");
            secret = "";
        }
        onExited: code => {
            if (code === 0) {
                root.joined(ssid);
                return;
            }
            // nmcli: "Error: Connection activation failed: Secrets were required, but not provided."
            const msg = joinErr.text.trim().split("\n").pop().replace(/^Error:\s*/, "").replace(/^Connection activation failed:\s*/, "").replace(/\s*\(.*\)\.?$/, "");
            root.joinFailed(ssid, msg || "Couldn't connect");
        }
    }
}
