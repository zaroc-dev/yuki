pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Backlight via sysfs (read) and brightnessctl (write). Inert without a backlight.
Singleton {
    id: root

    property string device: ""
    property real value: 0
    readonly property bool available: device !== ""

    function set(v) {
        if (!available)
            return;
        v = Math.max(0.01, Math.min(1, v));
        Quickshell.execDetached(["brightnessctl", "-q", "set", `${Math.round(v * 100)}%`]);
        value = v;
        Osd.show(Icons.brightness, "Brightness", value, false);
    }

    function adjust(delta) {
        set(value + delta);
    }

    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -e \"$d/brightness\" ] && echo \"$d\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        id: cur

        path: root.available ? root.device + "/brightness" : ""
        onLoaded: root.value = parseInt(text()) / Math.max(1, parseInt(max.text()))
    }

    FileView {
        id: max

        path: root.available ? root.device + "/max_brightness" : ""
        blockLoading: true
    }

    // sysfs doesn't notify; re-read now and then to catch outside changes.
    Timer {
        running: root.available
        interval: 3000
        repeat: true
        onTriggered: cur.reload()
    }
}
