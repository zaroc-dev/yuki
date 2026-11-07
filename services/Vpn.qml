pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// VPN connections. Quickshell.Networking has no VPN support, so this talks to
// the Mullvad daemon (its own tunnel, invisible to NetworkManager) through its
// CLI and to NetworkManager VPN/WireGuard profiles through nmcli. Profiles
// that don't store their password (e.g. OpenVPN with password-flags=2, the
// `nmcli --ask` case) get an inline prompt; the password goes to nmcli on
// stdin and is never kept here.
Singleton {
    id: root

    property bool hasMullvad: false
    readonly property bool hasNmcli: Net.hasNmcli
    // Last JSON from `mullvad status --json`.
    property var mullvad: null
    // [{ uuid, name, type, service, active, autoconnect }]
    property var profiles: []
    // id -> connecting|disconnecting while an operation runs
    property var pending: ({})
    // Keep the activation process so a second toggle can cancel browser login.
    property var operations: ({})
    // id -> error text from the last toggle
    property var errors: ({})
    // id -> true while the profile waits for a password from the user
    property var secretNeeded: ({})
    // Path being imported, "" when idle.
    property string importing: ""
    property string importError: ""

    signal imported(string name)

    // [{ id, name, state: off|connecting|on|disconnecting|error, detail }]
    readonly property var connections: {
        const list = [];
        if (hasMullvad)
            list.push(mullvadEntry());
        for (const p of profiles) {
            const busy = pending[p.uuid];
            list.push({
                id: p.uuid,
                name: p.name,
                state: busy || (p.active ? "on" : errors[p.uuid] ? "error" : "off"),
                kind: kindName(p),
                autoconnect: p.autoconnect,
                needsSecret: secretNeeded[p.uuid] ?? false,
                detail: busy === "connecting" ? "Connecting… · click to cancel" : busy === "disconnecting" ? "Disconnecting…" : secretNeeded[p.uuid] ? `Needs your password · ${kindName(p)}` : `${p.active ? "Connected" : "Off"} · ${kindName(p)}`
            });
        }
        return list;
    }
    readonly property var active: connections.filter(c => c.state === "on")

    function mullvadEntry() {
        const s = mullvad?.state ?? "unknown";
        const loc = mullvad?.details?.location;
        const place = loc ? [loc.city, loc.country].filter(x => x).join(", ") : "";
        const lockdown = mullvad?.details?.locked_down ?? false;
        let state = "off";
        let detail = lockdown ? "Off · lockdown blocks traffic" : "Off";
        if (s === "connected") {
            state = "on";
            detail = place ? `Connected · ${place}` : "Connected";
        } else if (s === "connecting") {
            state = "connecting";
            detail = "Connecting…";
        } else if (s === "disconnecting") {
            state = "disconnecting";
            detail = "Disconnecting…";
        } else if (s === "error") {
            state = "error";
            detail = "Error · blocking traffic";
        } else if (s === "unknown") {
            detail = "Daemon not running";
        }
        return {
            id: "mullvad",
            name: "Mullvad VPN",
            state,
            kind: "Mullvad",
            autoconnect: false,
            needsSecret: false,
            detail
        };
    }

    function kindName(p) {
        if (p.type === "wireguard")
            return "WireGuard";
        const service = p.service.replace(/^org\.freedesktop\.NetworkManager\./, "");
        return ({
                openvpn: "OpenVPN",
                openconnect: "OpenConnect",
                vpnc: "Cisco VPNC",
                l2tp: "L2TP",
                pptp: "PPTP",
                fortisslvpn: "Fortinet SSL",
                sstp: "SSTP",
                strongswan: "IPsec"
            })[service] ?? "VPN";
    }

    // File types `nmcli connection import` understands, by extension.
    function importType(path) {
        const ext = path.toLowerCase().split(".").pop();
        return ({
                conf: "wireguard",
                ovpn: "openvpn",
                pcf: "vpnc"
            })[ext] ?? "";
    }

    // Imports a WireGuard .conf or OpenVPN .ovpn as a NetworkManager profile.
    // Imported profiles don't autoconnect: a WireGuard config with
    // AllowedIPs 0.0.0.0/0 would otherwise reroute everything right away.
    function importFile(path) {
        if (importProc.running)
            return;
        importError = "";
        const file = Settings.expand(path.trim());
        const type = importType(file);
        if (!type) {
            importError = "Pick a WireGuard .conf, OpenVPN .ovpn or Cisco .pcf file";
            return;
        }
        importing = file;
        importProc.command = ["sh", "-c", importScript, "import", file, type];
        importProc.running = true;
    }

    function remove(id) {
        if (id === "mullvad")
            return;
        setError(id, "");
        setSecretNeeded(id, false);
        Net.deleteProfile(id);
    }

    // The prompts live in the popup and the settings page; closing them drops it.
    function clearPrompts() {
        if (Object.keys(secretNeeded).length > 0)
            secretNeeded = {};
    }

    function setSecretNeeded(id, on) {
        const s = Object.assign({}, secretNeeded);
        if (on)
            s[id] = true;
        else
            delete s[id];
        secretNeeded = s;
    }

    // NetworkManager names a WireGuard interface after the file, which must be
    // a valid interface name (≤ 15 chars), so the file is copied under one.
    readonly property string importScript: `
file=$1; type=$2
[ -r "$file" ] || { echo "Can't read $file" >&2; exit 1; }
dir=$(mktemp -d) || exit 1
trap 'rm -rf "$dir"' EXIT
if [ "$type" = wireguard ]; then
    name=$(basename "$file" .conf | tr -c 'A-Za-z0-9_=+.-' '-' | cut -c1-15 | sed 's/^-*//; s/-*$//')
    case "$name" in ''|.|..) name=wg0 ;; esac
    cp "$file" "$dir/$name.conf" && file="$dir/$name.conf"
fi
out=$(nmcli connection import type "$type" file "$file" 2>&1) || { echo "$out" >&2; exit 1; }
uuid=$(printf '%s' "$out" | sed -n 's/.*(\\([0-9a-f-]\\{36\\}\\)).*/\\1/p')
[ -n "$uuid" ] || { echo "$out" >&2; exit 1; }
nmcli connection modify uuid "$uuid" connection.autoconnect no >/dev/null 2>&1
nmcli connection down uuid "$uuid" >/dev/null 2>&1
nmcli -g connection.id connection show uuid "$uuid"
`

    function find(idOrName) {
        return connections.find(c => c.id === idOrName || c.name.toLowerCase() === idOrName.toLowerCase()) ?? null;
    }

    // `secret` is the password for profiles that asked for one.
    function setActive(id, on, secret) {
        setError(id, "");
        if (on)
            setSecretNeeded(id, false);
        if (id === "mullvad") {
            Quickshell.execDetached(["mullvad", on ? "connect" : "disconnect"]);
            return;
        }
        const operation = operations[id];
        if (operation) {
            if (!on && pending[id] === "connecting") {
                const p = Object.assign({}, pending);
                p[id] = "disconnecting";
                pending = p;
                operation.cancelled = true;
                operation.signal(15);
            }
            return;
        }
        const connection = connections.find(c => c.id === id);
        if (!connection || (on && connection.state === "on") || (!on && connection.state === "off"))
            return;
        const p = Object.assign({}, pending);
        p[id] = on ? "connecting" : "disconnecting";
        pending = p;
        const args = ["python3", Quickshell.shellPath("services/vpn-connect.py"), id];
        if (secret)
            args.push("--secret-stdin");
        const proc = toggler.createObject(root, {
            uuid: id,
            secret: secret ?? "",
            withSecret: !!secret,
            command: on ? args : ["nmcli", "connection", "down", "uuid", id]
        });
        const ops = Object.assign({}, operations);
        ops[id] = proc;
        operations = ops;
        proc.running = true;
    }

    function toggle(id) {
        const c = connections.find(c => c.id === id);
        if (!c)
            return;
        if (c.needsSecret)
            setSecretNeeded(id, false);
        else
            setActive(id, c.state === "off" || c.state === "error");
    }

    function setError(id, text) {
        const e = Object.assign({}, errors);
        if (text)
            e[id] = text;
        else
            delete e[id];
        errors = e;
    }

    function refresh() {
        if (hasNmcli && !nmList.running)
            nmList.running = true;
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v mullvad >/dev/null && echo mullvad"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hasMullvad = text.trim() === "mullvad";
                if (root.hasMullvad)
                    mullvadListen.running = true;
            }
        }
    }

    Connections {
        target: Net

        function onHasNmcliChanged(): void {
            root.refresh();
        }

        function onChanged(): void {
            root.refresh();
        }
    }

    Component.onCompleted: refresh()

    // Prints the current state, then every change.
    Process {
        id: mullvadListen

        command: ["mullvad", "status", "--json", "listen"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.mullvad = JSON.parse(line);
                } catch (e) {}
            }
        }
        onExited: {
            root.mullvad = null;
            mullvadRetry.start();
        }
    }

    // The daemon may be restarting; try again.
    Timer {
        id: mullvadRetry

        interval: 5000
        onTriggered: mullvadListen.running = true
    }

    // Connections plus device states: an active profile on a device that is
    // "connected (externally)" belongs to someone else (e.g. Mullvad's own
    // wg0-mullvad), so it isn't listed.
    Process {
        id: nmList

        // The service type (OpenVPN, OpenConnect, …) is only in each profile's settings.
        command: ["sh", "-c", `nmcli -t -f NAME,UUID,TYPE,ACTIVE,DEVICE,AUTOCONNECT connection show | while IFS= read -r line; do
    case "$line" in
    *:vpn:*)
        uuid=$(printf '%s' "$line" | sed 's/.*:\\([0-9a-f-]\\{36\\}\\):vpn:.*/\\1/')
        printf '%s\\t%s\\n' "$line" "$(nmcli -g vpn.service-type connection show uuid "$uuid")" ;;
    *) echo "$line" ;;
    esac
done
echo ---
nmcli -t -f DEVICE,STATE device`]
        stdout: StdioCollector {
            onStreamFinished: {
                const [conns, devs] = text.split("\n---\n");
                const external = new Set((devs ?? "").split("\n").map(l => Net.splitTerse(l)).filter(f => (f[1] ?? "").includes("externally")).map(f => f[0]));
                root.profiles = (conns ?? "").split("\n").filter(l => l).map(l => {
                    const [line, service] = l.split("\t");
                    return Net.splitTerse(line).concat([service ?? ""]);
                }).filter(f => (f[2] === "wireguard" || f[2] === "vpn") && !(f[3] === "yes" && external.has(f[4]))).map(f => ({
                            name: f[0],
                            uuid: f[1],
                            type: f[2],
                            active: f[3] === "yes",
                            autoconnect: f[5] === "yes",
                            service: f[6]
                        })).sort((a, b) => a.name.localeCompare(b.name));
            }
        }
    }

    Process {
        id: importProc

        stdout: StdioCollector {
            id: importOut
        }
        stderr: StdioCollector {
            id: importErr
        }
        onExited: code => {
            root.importing = "";
            if (code === 0) {
                root.imported(importOut.text.trim());
                root.refresh();
                return;
            }
            const lines = importErr.text.trim().split("\n");
            const line = lines.find(l => l.startsWith("Error:")) ?? lines.pop() ?? "";
            root.importError = line.replace(/^Error:\s*/, "") || "Import failed";
        }
    }

    component Toggler: Process {
        id: proc

        required property string uuid
        property string secret
        // A failed attempt with a password asks for it again.
        property bool withSecret: false
        property bool cancelled: false

        stdinEnabled: true
        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: err
        }
        onStarted: {
            if (withSecret) {
                write(secret + "\n");
                secret = "";
            }
        }
        onExited: code => {
            const p = Object.assign({}, root.pending);
            delete p[proc.uuid];
            root.pending = p;
            const ops = Object.assign({}, root.operations);
            delete ops[proc.uuid];
            root.operations = ops;
            // vpn-connect.py: the profile wants a password it doesn't store.
            if (code === 3) {
                root.setSecretNeeded(proc.uuid, true);
                // Started from IPC or a keybind: nothing shows the prompt yet.
                if (!Ui.settingsOpen && !Ui.activePopup) {
                    const name = root.connections.find(c => c.id === proc.uuid)?.name ?? "VPN";
                    Notifs.notify({
                        summary: `${name} needs your password`,
                        body: "Enter it in Settings → Network.",
                        actions: [
                            {
                                text: "Enter password",
                                run: () => Ui.openSettings("network")
                            }
                        ]
                    });
                }
            }
            else if (code !== 0 && !proc.cancelled) {
                // nmcli prints warnings first; the "Error:" line is the useful one.
                const lines = err.text.trim().split("\n");
                const line = lines.find(l => l.startsWith("Error:")) ?? lines.pop() ?? "";
                root.setError(proc.uuid, line.replace(/^Error:\s*/, "").replace(/^Connection activation failed:\s*/, "") || "Failed");
                if (proc.withSecret)
                    root.setSecretNeeded(proc.uuid, true);
            }
            root.refresh();
            proc.destroy();
        }
    }

    Component {
        id: toggler

        Toggler {}
    }
}
