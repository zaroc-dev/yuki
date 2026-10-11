pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// logind integration: lock before any suspend (not only yuki's own power
// menu) and follow `loginctl lock-session` / `unlock-session`.
//
// Sleep: a delay inhibitor is held while awake; PrepareForSleep(true) locks,
// and the inhibitor is released once every output is covered, so the system
// resumes to the lock screen. logind also gives up waiting after
// InhibitDelayMaxSec (5s by default), so a stuck lock can't block suspend.
Singleton {
    id: root

    readonly property string sessionId: Quickshell.env("XDG_SESSION_ID") ?? ""
    readonly property string sessionPath: sessionId ? `/org/freedesktop/login1/session/${escapeLabel(sessionId)}` : ""
    // Between PrepareForSleep(true) and (false).
    property bool sleeping: false
    // Next "boolean" line of dbus-monitor belongs to this signal.
    property string pendingArg: ""

    // sd-bus object path label escaping: "2" -> "_32", "c1" -> "c1".
    function escapeLabel(s) {
        let out = "";
        for (let i = 0; i < s.length; i++) {
            const c = s[i];
            if (/[A-Za-z0-9]/.test(c) && !(i === 0 && /[0-9]/.test(c)))
                out += c;
            else
                out += "_" + c.charCodeAt(0).toString(16).padStart(2, "0");
        }
        return out;
    }

    function prepareForSleep(start) {
        sleeping = start;
        if (!start) {
            syncInhibitor();
            return;
        }
        if (!Settings.d.lockBeforeSleep)
            return;
        releaseTimer.restart();
        // Ignored if it fires after resume (lock took longer than the delay).
        Lock.lockThen(() => {
            if (root.sleeping)
                root.release();
        });
    }

    function release() {
        releaseTimer.stop();
        inhibitor.running = false;
    }

    function syncInhibitor() {
        inhibitor.running = Settings.d.lockBeforeSleep && !sleeping;
    }

    function handleLine(line) {
        if (line.startsWith("signal ")) {
            pendingArg = "";
            const path = /path=([^;]+);/.exec(line)?.[1] ?? "";
            const member = /member=(\w+)/.exec(line)?.[1] ?? "";
            if (member === "PrepareForSleep")
                pendingArg = member;
            else if (path === sessionPath && member === "Lock")
                Lock.lock();
            else if (path === sessionPath && member === "Unlock" && Lock.locked)
                Lock.unlock();
        } else if (pendingArg === "PrepareForSleep" && line.trim().startsWith("boolean ")) {
            pendingArg = "";
            prepareForSleep(line.trim() === "boolean true");
        }
    }

    Component.onCompleted: {
        if (!sessionId)
            console.warn("Logind: XDG_SESSION_ID is unset; loginctl lock-session won't lock");
        syncInhibitor();
    }

    Connections {
        target: Settings.d

        function onLockBeforeSleepChanged() {
            root.syncInhibitor();
        }
    }

    // BecomeMonitor is root-only on the system bus; dbus-monitor falls back to
    // plain match rules, which still receive logind's broadcast signals.
    Process {
        id: monitor

        running: true
        command: ["dbus-monitor", "--system", "type='signal',sender='org.freedesktop.login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'", "type='signal',sender='org.freedesktop.login1',interface='org.freedesktop.login1.Session'"]
        stdout: SplitParser {
            onRead: line => root.handleLine(line)
        }
        onExited: code => {
            console.warn(`Logind: dbus-monitor exited (${code}), restarting`);
            restartTimer.restart();
        }
    }

    // Holds the delay lock until killed (systemd-inhibit takes `sleep` down with it).
    Process {
        id: inhibitor

        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=yuki", "--why=Lock the screen before sleep", "sleep", "infinity"]
        onExited: {
            if (Settings.d.lockBeforeSleep && !root.sleeping)
                restartTimer.restart();
        }
    }

    Timer {
        id: restartTimer

        interval: 2000
        onTriggered: {
            monitor.running = true;
            root.syncInhibitor();
        }
    }

    // Don't hold the delay for nothing if the lock never becomes secure.
    Timer {
        id: releaseTimer

        interval: 3000
        onTriggered: root.release()
    }
}
