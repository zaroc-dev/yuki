pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Alt+Tab window switcher state. niri's bind calls `ipc call switcher next`
// once; while open, the overlay inhibits niri's shortcuts and handles Tab and
// the Alt release itself (popups/Switcher.qml).
Singleton {
    id: root

    property bool open: false
    // Snapshot in most-recently-used order, taken when the switcher opens.
    property var windows: []
    property int index: 0
    readonly property var current: windows[index] ?? null

    function stamp(w) {
        return (w.focus_timestamp?.secs ?? 0) * 1e9 + (w.focus_timestamp?.nanos ?? 0);
    }

    function mru() {
        // The focused window first even if niri hasn't stamped it yet (it debounces).
        const focused = Niri.focusedWindowId;
        return Object.values(Niri.windows).sort((a, b) => (b.id === focused) - (a.id === focused) || stamp(b) - stamp(a));
    }

    function step(delta) {
        if (!open) {
            windows = mru();
            if (windows.length === 0)
                return;
            // First press goes to the previous window (or the last, backwards).
            index = delta > 0 ? Math.min(1, windows.length - 1) : windows.length - 1;
            open = true;
            return;
        }
        index = (index + delta + windows.length) % windows.length;
    }

    function next() {
        step(1);
    }

    function prev() {
        step(-1);
    }

    function select(i) {
        index = Math.max(0, Math.min(i, windows.length - 1));
    }

    function commit() {
        const w = current;
        open = false;
        if (w)
            Niri.focusWindow(w.id);
    }

    function cancel() {
        open = false;
    }

    // e.g. "2 · DP-3"
    function workspaceLabel(w) {
        const ws = Niri.workspaces.find(x => x.id === w?.workspace_id);
        if (!ws)
            return "";
        return Quickshell.screens.length > 1 ? `${ws.name || ws.idx} · ${ws.output}` : `${ws.name || ws.idx}`;
    }

    // Drop windows that close while the switcher is open; keep titles fresh.
    Connections {
        target: Niri
        enabled: root.open

        function onWindowsChanged() {
            const cur = root.current?.id;
            const list = root.windows.filter(w => w.id in Niri.windows).map(w => Niri.windows[w.id]);
            if (list.length === 0) {
                root.cancel();
                return;
            }
            root.windows = list;
            const i = list.findIndex(w => w.id === cur);
            root.index = i >= 0 ? i : Math.min(root.index, list.length - 1);
        }
    }
}
