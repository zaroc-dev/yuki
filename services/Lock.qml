pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Lock screen state. The lock surface blurs in from each output's wallpaper.
Singleton {
    id: root

    // Real ext-session-lock. Read by lock/LockScreen.qml.
    property bool locked: false
    // Same UI in an overlay without locking the session, for trying designs.
    property bool preview: false
    readonly property bool shown: locked || preview
    // True while the exit animation plays; the lock is released afterwards.
    property bool unlocking: false
    // Set by LockScreen from WlSessionLock.secure (all outputs covered).
    property bool secure: false

    property string password: ""
    // idle | busy | failed | error
    property string state: "idle"
    property string message: ""
    property int attempts: 0

    property var afterLock: []
    // Identifies this compositor session (niri's socket path contains its pid).
    readonly property string sessionKey: Quickshell.env("NIRI_SOCKET") || Quickshell.env("WAYLAND_DISPLAY") || ""

    signal rejected

    function lock() {
        if (shown)
            return;
        reset();
        locked = true;
    }

    function showPreview() {
        if (shown)
            return;
        reset();
        preview = true;
    }

    // Lock, then run fn once every output is covered (e.g. suspend).
    function lockThen(fn) {
        if (locked && secure) {
            fn();
            return;
        }
        afterLock = [...afterLock, fn];
        lock();
    }

    function reset() {
        password = "";
        state = "idle";
        message = "";
        unlocking = false;
    }

    function submit() {
        if (state === "busy" || unlocking)
            return;
        if (password === "") {
            rejected();
            return;
        }
        state = "busy";
        message = "";
        if (!pam.start()) {
            state = "error";
            message = "Couldn't start authentication";
        }
    }

    function unlock() {
        unlocking = true;
        unlockTimer.restart();
    }

    function cancelPreview() {
        if (preview && !locked)
            unlock();
    }

    // Failsafe: if the shell dies while locked, the marker is still there and
    // the restarted shell locks again. It lives in the runtime dir and holds
    // the session key, so a new login or boot never starts locked.
    onLockedChanged: {
        if (marker.path)
            marker.setText(locked ? sessionKey : "");
    }

    Component.onCompleted: {
        if (sessionKey && marker.path && marker.text().trim() === sessionKey) {
            console.warn("Lock: the shell stopped while locked, locking again");
            lock();
        }
    }

    onSecureChanged: {
        if (!secure)
            return;
        const fns = afterLock;
        afterLock = [];
        for (const fn of fns)
            fn();
    }

    // Matches the exit animation in LockSurface.
    Timer {
        id: unlockTimer

        interval: 550
        onTriggered: {
            root.locked = false;
            root.preview = false;
            root.unlocking = false;
            root.password = "";
        }
    }

    FileView {
        id: marker

        path: Quickshell.env("XDG_RUNTIME_DIR") ? Quickshell.env("XDG_RUNTIME_DIR") + "/yuki-locked" : ""
        blockLoading: true
        // On disk before the lock goes up, in case the shell dies right after.
        blockWrites: true
        printErrors: false
        atomicWrites: true
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellPath("pam")
        config: "password.conf"

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.state = "idle";
                root.unlock();
                return;
            }
            root.attempts++;
            root.state = "failed";
            root.message = result === PamResult.MaxTries ? "Too many attempts, wait a moment" : "Incorrect password";
            root.password = "";
            root.rejected();
        }

        onError: error => {
            root.state = "error";
            root.message = `Authentication error: ${PamError.toString(error)}`;
            root.password = "";
            root.rejected();
        }
    }
}
