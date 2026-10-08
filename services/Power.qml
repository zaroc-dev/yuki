pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") ?? ""
    property string hostname: ""
    property real uptime: 0

    // id, label, glyph, palette color key, shortcut key, needs confirmation
    readonly property var actions: [
        { id: "lock", label: "Lock", icon: Icons.lockOutline, color: "accent", key: "L", confirm: false },
        { id: "suspend", label: "Suspend", icon: Icons.sleep, color: "blue", key: "S", confirm: false },
        { id: "logout", label: "Log out", icon: Icons.logout, color: "yellow", key: "E", confirm: true },
        { id: "reboot", label: "Restart", icon: Icons.restart, color: "peach", key: "R", confirm: true },
        { id: "poweroff", label: "Shut down", icon: Icons.power, color: "red", key: "P", confirm: true }
    ]

    function run(id) {
        switch (id) {
        case "lock":
            Lock.lock();
            break;
        case "suspend":
            Lock.lockThen(() => Quickshell.execDetached(["systemctl", "suspend"]));
            break;
        case "logout":
            Niri.action("Quit", {
                skip_confirmation: true
            });
            break;
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "poweroff":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        }
    }

    function formatUptime(seconds) {
        const d = Math.floor(seconds / 86400);
        const h = Math.floor(seconds % 86400 / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        if (d > 0)
            return `${d}d ${h}h`;
        if (h > 0)
            return `${h}h ${m}m`;
        return `${m}m`;
    }

    function refresh() {
        info.running = true;
    }

    Process {
        id: info

        command: ["cat", "/proc/sys/kernel/hostname", "/proc/uptime"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.hostname = lines[0] ?? "";
                root.uptime = parseFloat(lines[1]) || 0;
            }
        }
    }
}
