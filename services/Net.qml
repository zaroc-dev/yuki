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

    property bool hasNmcli: false
    // nm-connection-editor, for anything the pages don't cover.
    property bool hasEditor: false
    // Saved Wi-Fi profiles, also those out of range:
    // [{ uuid, name, ssid, autoconnect, active, enterprise, lastUsed }]
    property var savedWifi: []
    // interface -> { connection, ip4, gateway, dns, ip6 } from `nmcli device show`
    property var details: ({})

    signal joined(string ssid)
    signal joinFailed(string ssid, string message)
    // Something in NetworkManager changed (debounced `nmcli monitor`).
    signal changed

    // nmcli -t escapes ':' and '\' with a backslash.
    function splitTerse(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (ch === "\\" && i + 1 < line.length)
                cur += line[++i];
            else if (ch === ":") {
                out.push(cur);
                cur = "";
            } else
                cur += ch;
        }
        out.push(cur);
        return out;
    }

    function refreshSaved() {
        if (hasNmcli && !savedProc.running)
            savedProc.running = true;
    }

    // Addresses for one interface; the page asks for the devices it shows.
    function refreshDetails(iface) {
        if (!hasNmcli || !iface)
            return;
        detailsProc.createObject(root, {
            iface
        }).running = true;
    }

    function setAutoconnect(uuid, on) {
        modify.createObject(root, {
            command: ["nmcli", "connection", "modify", "uuid", uuid, "connection.autoconnect", on ? "yes" : "no"]
        }).running = true;
    }

    function deleteProfile(uuid) {
        modify.createObject(root, {
            command: ["nmcli", "connection", "delete", "uuid", uuid]
        }).running = true;
    }

    function openEditor() {
        if (hasEditor)
            Quickshell.execDetached(["nm-connection-editor"]);
    }

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
        running: true
        command: ["sh", "-c", "command -v nmcli >/dev/null && echo nmcli; command -v nm-connection-editor >/dev/null && echo editor"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.split("\n");
                root.hasNmcli = found.includes("nmcli");
                root.hasEditor = found.includes("editor");
                if (root.hasNmcli) {
                    monitor.running = true;
                    root.refreshSaved();
                }
            }
        }
    }

    // Any NetworkManager change re-reads what's listed (debounced).
    Process {
        id: monitor

        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce

        interval: 400
        onTriggered: {
            root.refreshSaved();
            root.changed();
        }
    }

    // Two queries: the profiles, then SSID and key management per Wi-Fi profile
    // (`connection show` can't print per-type fields for several at once).
    Process {
        id: savedProc

        command: ["sh", "-c", `nmcli -t -f NAME,UUID,TYPE,AUTOCONNECT,ACTIVE,TIMESTAMP connection show | while IFS= read -r line; do
    case "$line" in
    *:802-11-wireless:*)
        uuid=$(printf '%s' "$line" | sed 's/.*:\\([0-9a-f-]\\{36\\}\\):802-11-wireless:.*/\\1/')
        printf '%s\\t%s\\n' "$line" "$(nmcli -t -g 802-11-wireless.ssid,802-11-wireless-security.key-mgmt connection show uuid "$uuid" | paste -sd '\\t')"
        ;;
    esac
done`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedWifi = text.split("\n").filter(l => l).map(l => {
                    const [line, ssid, keyMgmt] = l.split("\t");
                    const f = root.splitTerse(line);
                    return {
                        name: f[0],
                        uuid: f[1],
                        autoconnect: f[3] === "yes",
                        active: f[4] === "yes",
                        lastUsed: Number(f[5]) || 0,
                        ssid: ssid || f[0],
                        enterprise: (keyMgmt ?? "").includes("eap")
                    };
                }).sort((a, b) => b.active - a.active || b.lastUsed - a.lastUsed);
            }
        }
    }

    // Addresses of one interface (refreshDetails).
    Component {
        id: detailsProc

        Process {
            id: q

            required property string iface

            command: ["nmcli", "-t", "-f", "GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS", "device", "show", iface]
            stdout: StdioCollector {
                onStreamFinished: {
                    const d = {
                        connection: "",
                        ip4: [],
                        gateway: "",
                        dns: [],
                        ip6: []
                    };
                    for (const l of text.split("\n")) {
                        const i = l.indexOf(":");
                        if (i < 0)
                            continue;
                        const key = l.slice(0, i);
                        const value = l.slice(i + 1).replace(/\\:/g, ":");
                        if (!value)
                            continue;
                        if (key === "GENERAL.CONNECTION")
                            d.connection = value;
                        else if (key.startsWith("IP4.ADDRESS"))
                            d.ip4.push(value);
                        else if (key === "IP4.GATEWAY")
                            d.gateway = value;
                        else if (key.startsWith("IP4.DNS"))
                            d.dns.push(value);
                        else if (key.startsWith("IP6.ADDRESS") && !value.startsWith("fe80"))
                            d.ip6.push(value);
                    }
                    const all = Object.assign({}, root.details);
                    all[q.iface] = d;
                    root.details = all;
                    q.destroy();
                }
            }
        }
    }

    // One-off nmcli call that cleans up after itself.
    Component {
        id: modify

        Process {
            id: m

            onExited: m.destroy()
        }
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
