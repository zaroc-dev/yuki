pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

Singleton {
    id: root

    // Shell-generated notifications (screenshots, ...) have the same shape.
    property var internal: []
    property int nextInternalId: 1000000
    readonly property var list: [...internal, ...server.trackedNotifications.values.slice().reverse()]
    readonly property int count: server.trackedNotifications.values.length + internal.length

    // opts: { appName, summary, body, image, appIcon, actions: [{ text, run }] }
    function notify(opts) {
        const id = nextInternalId++;
        const n = {
            id: id,
            internal: true,
            appName: opts.appName ?? "yuki",
            appIcon: opts.appIcon ?? "",
            desktopEntry: "",
            summary: opts.summary ?? "",
            body: opts.body ?? "",
            image: opts.image ?? "",
            urgency: NotificationUrgency.Normal,
            expireTimeout: opts.timeout ?? -1,
            actions: [],
            dismiss: () => {
                root.internal = root.internal.filter(x => x.id !== id);
                root.hidePopup(n);
            }
        };
        n.actions = (opts.actions ?? []).map((a, i) => ({
                    identifier: a.identifier ?? `action-${i}`,
                    text: a.text,
                    invoke: () => {
                        a.run();
                        n.dismiss();
                    }
                }));
        const t = Object.assign({}, times);
        t[id] = new Date();
        times = t;
        internal = [n, ...internal].slice(0, 20);
        if (!dnd)
            popups = [n, ...popups].slice(0, 5);
        return n;
    }
    // Notifications currently shown as toasts (newest first).
    property var popups: []
    readonly property bool dnd: Settings.d.dnd

    function toggleDnd() {
        Settings.d.dnd = !Settings.d.dnd;
    }
    // id -> Date of arrival, since the spec doesn't carry a timestamp.
    property var times: ({})

    function hidePopup(n) {
        popups = popups.filter(p => p && p !== n);
    }

    function clearAll() {
        internal = [];
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
        popups = [];
    }

    function timeOf(n) {
        const t = times[n?.id];
        if (!t)
            return "";
        const mins = Math.floor((Date.now() - t) / 60000);
        if (mins < 1)
            return "now";
        if (mins < 60)
            return `${mins}m`;
        return Qt.formatTime(t, "HH:mm");
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true

        onNotification: n => {
            // The shell shows its own, richer screenshot toast (Screenshots.qml).
            if (n.appName === "niri" && n.summary.startsWith("Screenshot")) {
                n.expire();
                return;
            }
            n.tracked = true;
            const t = Object.assign({}, root.times);
            t[n.id] = new Date();
            root.times = t;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n, ...root.popups.filter(p => p && p.id !== n.id)].slice(0, 5);
            const id = n.id;
            n.closed.connect(() => {
                root.hidePopup(n);
                const t = Object.assign({}, root.times);
                delete t[id];
                root.times = t;
            });
        }
    }
}
