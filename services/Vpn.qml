pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// VPN connections. Quickshell.Networking has no VPN support, so this talks to
// the Mullvad daemon (its own tunnel, invisible to NetworkManager) through its
// CLI and to NetworkManager VPN/WireGuard profiles through nmcli.
Singleton {
    id: root

    property bool hasMullvad: false
    property bool hasNmcli: false
    // Last JSON from `mullvad status --json`.
    property var mullvad: null
    // [{ uuid, name, type, active }]
    property var profiles: []
    // id -> connecting|disconnecting while an operation runs
    property var pending: ({})
    // Keep the activation process so a second toggle can cancel browser login.
    property var operations: ({})
    // id -> error text from the last toggle
    property var errors: ({})

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
                detail: busy === "connecting" ? "Connecting… · click to cancel" : busy === "disconnecting" ? "Disconnecting…" : `${p.active ? "Connected" : "Off"} · ${p.type === "wireguard" ? "WireGuard" : "VPN"}`
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
            detail
        };
    }

    function find(idOrName) {
        return connections.find(c => c.id === idOrName || c.name.toLowerCase() === idOrName.toLowerCase()) ?? null;
    }

    function setActive(id, on) {
        setError(id, "");
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
        const proc = toggler.createObject(root, {
            uuid: id,
            command: on ? ["python3", Quickshell.shellPath("services/vpn-connect.py"), id] : ["nmcli", "connection", "down", "uuid", id]
        });
        const ops = Object.assign({}, operations);
        ops[id] = proc;
        operations = ops;
        proc.running = true;
    }

    function toggle(id) {
        const c = connections.find(c => c.id === id);
        if (c)
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

    Process {
        running: true
        command: ["sh", "-c", "command -v mullvad >/dev/null && echo mullvad; command -v nmcli >/dev/null && echo nmcli"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.split("\n");
                root.hasMullvad = found.includes("mullvad");
                root.hasNmcli = found.includes("nmcli");
                if (root.hasMullvad)
                    mullvadListen.running = true;
                if (root.hasNmcli) {
                    nmMonitor.running = true;
                    root.refresh();
                }
            }
        }
    }

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

        command: ["sh", "-c", "nmcli -t -f NAME,UUID,TYPE,ACTIVE,DEVICE connection show && echo --- && nmcli -t -f DEVICE,STATE device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [conns, devs] = text.split("\n---\n");
                const external = new Set((devs ?? "").split("\n").map(l => root.splitTerse(l)).filter(f => (f[1] ?? "").includes("externally")).map(f => f[0]));
                root.profiles = (conns ?? "").split("\n").filter(l => l).map(l => root.splitTerse(l)).filter(f => (f[2] === "wireguard" || f[2] === "vpn") && !(f[3] === "yes" && external.has(f[4]))).map(f => ({
                            name: f[0],
                            uuid: f[1],
                            type: f[2],
                            active: f[3] === "yes"
                        })).sort((a, b) => a.name.localeCompare(b.name));
            }
        }
    }

    // Any NetworkManager change re-reads the list (debounced).
    Process {
        id: nmMonitor

        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: refreshDebounce.restart()
        }
    }

    Timer {
        id: refreshDebounce

        interval: 400
        onTriggered: root.refresh()
    }

    component Toggler: Process {
        id: proc

        required property string uuid
        property bool cancelled: false

        stdout: StdioCollector {}
        stderr: StdioCollector {
            id: err
        }
        onExited: code => {
            const p = Object.assign({}, root.pending);
            delete p[proc.uuid];
            root.pending = p;
            const ops = Object.assign({}, root.operations);
            delete ops[proc.uuid];
            root.operations = ops;
            if (code !== 0 && !proc.cancelled) {
                // nmcli prints warnings first; the "Error:" line is the useful one.
                const lines = err.text.trim().split("\n");
                const line = lines.find(l => l.startsWith("Error:")) ?? lines.pop() ?? "";
                root.setError(proc.uuid, line.replace(/^Error:\s*/, "").replace(/^Connection activation failed:\s*/, "") || "Failed");
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
