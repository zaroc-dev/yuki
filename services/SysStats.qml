pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, root disk and CPU temperature, polled only while something
// shows them (`users` > 0, e.g. the open dashboard).
Singleton {
    id: root

    property int users: 0
    // Fractions 0..1.
    property real cpu: 0
    property real memory: 0
    property real disk: 0
    property real memUsed: 0
    property real memTotal: 0
    property real diskUsed: 0
    property real diskTotal: 0
    // °C, or -1 when no CPU sensor was found.
    property real temperature: -1
    property var lastCpu: null

    function formatBytes(b) {
        const gib = b / 1073741824;
        return gib >= 100 ? `${Math.round(gib)} GiB` : `${gib.toFixed(1)} GiB`;
    }

    function parse(text) {
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/);
            if (f[0] === "cpu") {
                const n = f.slice(1).map(Number);
                const idle = n[3] + (n[4] ?? 0);
                const total = n.reduce((a, b) => a + b, 0);
                if (lastCpu && total > lastCpu.total)
                    cpu = 1 - (idle - lastCpu.idle) / (total - lastCpu.total);
                lastCpu = { idle: idle, total: total };
            } else if (f[0] === "MemTotal:") {
                memTotal = Number(f[1]) * 1024;
            } else if (f[0] === "MemAvailable:") {
                memUsed = memTotal - Number(f[1]) * 1024;
                memory = memTotal > 0 ? memUsed / memTotal : 0;
            } else if (f[0] === "disk") {
                diskTotal = Number(f[1]);
                diskUsed = Number(f[2]);
                disk = diskTotal > 0 ? diskUsed / diskTotal : 0;
            } else if (f[0] === "temp") {
                temperature = f[1] ? Number(f[1]) / 1000 : -1;
            }
        }
    }

    Timer {
        running: root.users > 0
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    Process {
        id: poll

        // CPU sensor by driver preference (Intel, AMD, ARM SoCs, then ACPI).
        command: ["sh", "-c", `
            head -1 /proc/stat
            grep -E '^(MemTotal|MemAvailable):' /proc/meminfo
            df -P -B1 / | awk 'NR==2 { print "disk", $2, $3 }'
            for n in coretemp k10temp zenpower cpu_thermal acpitz; do
                for h in /sys/class/hwmon/hwmon*; do
                    [ "$(cat "$h/name" 2>/dev/null)" = "$n" ] && echo "temp $(cat "$h/temp1_input" 2>/dev/null)" && exit
                done
            done`]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }
}
