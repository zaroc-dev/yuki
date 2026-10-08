pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// Auto-lock and screen-off after inactivity (apps that inhibit idle, like
// video players, are respected). "Keep awake" disables both.
Singleton {
    id: root

    property bool keepAwake: false

    IdleMonitor {
        enabled: !root.keepAwake && Settings.d.lockAfterMinutes > 0
        timeout: Settings.d.lockAfterMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Lock.lock();
        }
    }

    IdleMonitor {
        enabled: !root.keepAwake && Settings.d.screenOffAfterMinutes > 0
        timeout: Settings.d.screenOffAfterMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                Niri.action("PowerOffMonitors");
        }
    }
}
