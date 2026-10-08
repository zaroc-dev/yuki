pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors niri's state from its IPC event stream ($NIRI_SOCKET).
Singleton {
    id: root

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") ?? ""
    readonly property bool available: socketPath !== ""

    // Sorted by output, then index.
    property var workspaces: []
    // window id -> window object as sent by niri.
    property var windows: ({})
    property var focusedWindowId: null
    property bool overviewOpen: false

    // path is empty when the screenshot was only copied to the clipboard
    signal screenshotCaptured(string path)
    property var keyboardLayouts: []
    property int keyboardLayoutIdx: 0
    readonly property string keyboardLayout: keyboardLayouts[keyboardLayoutIdx] ?? ""

    readonly property var focusedWindow: focusedWindowId !== null ? windows[focusedWindowId] ?? null : null
    readonly property var focusedWorkspace: workspaces.find(w => w.is_focused) ?? null
    readonly property string focusedOutput: focusedWorkspace?.output ?? ""

    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output);
    }

    function activeWorkspaceOn(output) {
        return workspaces.find(w => w.output === output && w.is_active) ?? null;
    }

    // The window that has focus within the visible workspace of an output.
    function activeWindowOn(output) {
        const ws = activeWorkspaceOn(output);
        return ws && ws.active_window_id !== null ? windows[ws.active_window_id] ?? null : null;
    }

    function windowCount(workspaceId) {
        let n = 0;
        for (const id in windows)
            if (windows[id].workspace_id === workspaceId)
                n++;
        return n;
    }

    function action(name, args) {
        send({
            Action: {
                [name]: args ?? {}
            }
        });
    }

    function focusWorkspace(id) {
        action("FocusWorkspace", {
            reference: {
                Id: id
            }
        });
    }

    function focusWindow(id) {
        action("FocusWindow", {
            id: id
        });
    }

    function send(request) {
        if (!requests.connected)
            return;
        requests.write(JSON.stringify(request) + "\n");
        requests.flush();
    }

    function sortWorkspaces(list) {
        return list.sort((a, b) => a.output === b.output ? a.idx - b.idx : a.output.localeCompare(b.output));
    }

    function patchWorkspaces(fn) {
        workspaces = workspaces.map(w => fn(Object.assign({}, w)));
    }

    function handleEvent(event) {
        const [kind, data] = Object.entries(event)[0];
        switch (kind) {
        case "WorkspacesChanged":
            workspaces = sortWorkspaces(data.workspaces);
            break;
        case "WorkspaceActivated":
            {
                const target = workspaces.find(w => w.id === data.id);
                if (!target)
                    break;
                patchWorkspaces(w => {
                    if (w.output === target.output)
                        w.is_active = w.id === data.id;
                    if (data.focused)
                        w.is_focused = w.id === data.id;
                    return w;
                });
                break;
            }
        case "WorkspaceActiveWindowChanged":
            patchWorkspaces(w => {
                if (w.id === data.workspace_id)
                    w.active_window_id = data.active_window_id;
                return w;
            });
            break;
        case "WorkspaceUrgencyChanged":
            patchWorkspaces(w => {
                if (w.id === data.id)
                    w.is_urgent = data.urgent;
                return w;
            });
            break;
        case "WindowsChanged":
            {
                const map = {};
                for (const win of data.windows) {
                    map[win.id] = win;
                    if (win.is_focused)
                        focusedWindowId = win.id;
                }
                windows = map;
                break;
            }
        case "WindowOpenedOrChanged":
            {
                const map = Object.assign({}, windows);
                map[data.window.id] = data.window;
                windows = map;
                if (data.window.is_focused)
                    focusedWindowId = data.window.id;
                break;
            }
        case "WindowClosed":
            {
                const map = Object.assign({}, windows);
                delete map[data.id];
                windows = map;
                if (focusedWindowId === data.id)
                    focusedWindowId = null;
                break;
            }
        case "WindowFocusChanged":
            focusedWindowId = data.id;
            break;
        case "WindowUrgencyChanged":
            {
                const win = windows[data.id];
                if (!win)
                    break;
                const map = Object.assign({}, windows);
                map[data.id] = Object.assign({}, win, {
                    is_urgent: data.urgent
                });
                windows = map;
                break;
            }
        case "KeyboardLayoutsChanged":
            keyboardLayouts = data.keyboard_layouts.names;
            keyboardLayoutIdx = data.keyboard_layouts.current_idx;
            break;
        case "KeyboardLayoutSwitched":
            keyboardLayoutIdx = data.idx;
            break;
        case "ScreenshotCaptured":
            screenshotCaptured(data.path ?? "");
            break;
        case "OverviewOpenedOrClosed":
            overviewOpen = data.is_open;
            break;
        }
    }

    Socket {
        id: events

        path: root.socketPath
        connected: root.available
        onConnectedChanged: {
            if (connected) {
                write('"EventStream"\n');
                flush();
            }
        }

        parser: SplitParser {
            onRead: line => {
                try {
                    const msg = JSON.parse(line);
                    // The first line is the reply to the EventStream request.
                    if (!("Ok" in msg) && !("Err" in msg))
                        root.handleEvent(msg);
                } catch (e) {
                    console.warn("niri: bad event", e, line);
                }
            }
        }
    }

    Socket {
        id: requests

        path: root.socketPath
        connected: root.available

        // Replies are ignored; drain them so the buffer doesn't grow.
        parser: SplitParser {}
    }

    // Reconnect if niri restarts.
    Timer {
        interval: 2000
        repeat: true
        running: root.available && (!events.connected || !requests.connected)
        onTriggered: {
            events.connected = true;
            requests.connected = true;
        }
    }
}
