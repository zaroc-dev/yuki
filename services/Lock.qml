pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Lock screen state. Locking first snapshots every screen (the bars do the
// capture), so the lock surface can blur in from what was on screen.
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

    // screen name -> ItemGrabResult (kept alive so its url stays valid)
    property var snapshots: ({})
    property bool capturing: false
    property string pendingMode: ""
    property var afterLock: []

    signal captureRequested
    signal rejected

    function lock() {
        begin("lock");
    }

    function showPreview() {
        begin("preview");
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

    function begin(mode) {
        if (shown || capturing)
            return;
        reset();
        snapshots = {};
        pendingMode = mode;
        capturing = true;
        captureTimeout.restart();
        captureRequested();
    }

    function snapshotReady(screenName, result) {
        if (!capturing)
            return;
        const s = Object.assign({}, snapshots);
        s[screenName] = result;
        snapshots = s;
        if (Quickshell.screens.every(sc => sc.name in snapshots))
            finishCapture();
    }

    function finishCapture() {
        captureTimeout.stop();
        capturing = false;
        if (pendingMode === "lock")
            locked = true;
        else
            preview = true;
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

    onSecureChanged: {
        if (!secure)
            return;
        const fns = afterLock;
        afterLock = [];
        for (const fn of fns)
            fn();
    }

    // Don't hang forever if a screen never delivers a frame.
    Timer {
        id: captureTimeout

        interval: 800
        onTriggered: root.finishCapture()
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
            root.snapshots = {};
        }
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
