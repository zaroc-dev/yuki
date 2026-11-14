pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The user's picture as AccountsService (org.freedesktop.Accounts) reports
// it, the same source SDDM and GNOME/KDE settings use. Updated when the
// daemon signals a change; `revision` lets images reload a file that was
// replaced under the same path.
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") ?? ""
    // Absolute path, or "" when the daemon isn't running or has none set.
    property string iconFile: ""
    property int revision: 0
    // Set once the first answer is in, so avatars don't show a fallback
    // picture and then switch.
    property bool ready: false

    function refresh() {
        query.running = false;
        query.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: query

        // FindUserByName also makes the daemon load the user if it hasn't yet.
        command: ["sh", "-c", `p=$(busctl --system call org.freedesktop.Accounts /org/freedesktop/Accounts org.freedesktop.Accounts FindUserByName s "$1" 2>/dev/null | cut -d'"' -f2) && [ -n "$p" ] && busctl --system get-property org.freedesktop.Accounts "$p" org.freedesktop.Accounts.User IconFile 2>/dev/null | cut -d'"' -f2`, "sh", root.user]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                root.iconFile = path.startsWith("/") ? path : "";
                root.revision++;
                root.ready = true;
            }
        }
    }

    // User.Changed is broadcast on every property change (icon, name, ...);
    // re-reading one property is cheap. Plain match rules work unprivileged.
    Process {
        id: monitor

        running: true
        command: ["dbus-monitor", "--system", "type='signal',sender='org.freedesktop.Accounts',interface='org.freedesktop.Accounts.User',member='Changed'"]
        stdout: SplitParser {
            onRead: line => {
                // dbus-monitor also prints its own NameAcquired/NameLost.
                if (line.startsWith("signal ") && line.includes("member=Changed"))
                    debounce.restart();
            }
        }
        onExited: restart.restart()
    }

    Timer {
        id: debounce

        interval: 300
        onTriggered: root.refresh()
    }

    Timer {
        id: restart

        interval: 5000
        onTriggered: {
            monitor.running = true;
            root.refresh();
        }
    }
}
