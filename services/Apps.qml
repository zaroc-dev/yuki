pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values.filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

    // Used until the user pins something themselves.
    readonly property var defaultPinned: ["brave-browser", "kitty", "org.gnome.Nautilus", "spotify", "vesktop", "steam", "dev.zed.Zed", "code", "firefox", "org.kde.dolphin"]
    readonly property var pinnedIds: Settings.d.pinnedApps.length > 0 ? Settings.d.pinnedApps : defaultPinned
    readonly property var pinned: pinnedIds.map(id => DesktopEntries.byId(id)).filter(e => e)
    // Most launched apps that aren't pinned.
    readonly property var frequent: Object.entries(Settings.d.appUsage).sort((a, b) => b[1] - a[1]).map(([id]) => DesktopEntries.byId(id)).filter(e => e && !pinnedIds.includes(e.id))

    function usage(entry) {
        return Settings.d.appUsage[entry?.id] ?? 0;
    }

    function isPinned(entry) {
        return pinnedIds.includes(entry?.id);
    }

    function togglePin(entry) {
        const ids = pinnedIds.slice();
        const i = ids.indexOf(entry.id);
        if (i >= 0)
            ids.splice(i, 1);
        else
            ids.push(entry.id);
        Settings.d.pinnedApps = ids;
    }

    function movePin(entry, delta) {
        const ids = pinnedIds.slice();
        const i = ids.indexOf(entry.id);
        const j = i + delta;
        if (i < 0 || j < 0 || j >= ids.length)
            return;
        [ids[i], ids[j]] = [ids[j], ids[i]];
        Settings.d.pinnedApps = ids;
    }

    // Resolves an icon name, absolute path or URL to something an Image can load.
    function resolveIcon(name) {
        if (!name)
            return "";
        if (name.includes("://"))
            return name;
        if (name.startsWith("/"))
            return "file://" + name;
        return Quickshell.iconPath(name, true);
    }

    // Resolves a window app_id (or icon name) to a themed icon path, or "" if none.
    function iconFor(appId) {
        if (!appId)
            return "";
        const entry = DesktopEntries.heuristicLookup(appId);
        const candidates = [entry?.icon, appId, appId.toLowerCase(), appId.split(".").pop().toLowerCase()];
        for (const name of candidates) {
            const path = resolveIcon(name);
            if (path)
                return path;
        }
        return "";
    }

    function nameFor(appId) {
        return DesktopEntries.heuristicLookup(appId)?.name ?? appId;
    }

    // Subsequence fuzzy score; higher is better, -1 means no match.
    function score(query, text) {
        text = text.toLowerCase();
        if (text.startsWith(query))
            return 1000 - text.length;
        const idx = text.indexOf(query);
        if (idx >= 0)
            return 500 - idx;
        let ti = 0, s = 0, streak = 0;
        for (const c of query) {
            const found = text.indexOf(c, ti);
            if (found < 0)
                return -1;
            streak = found === ti ? streak + 1 : 0;
            s += 1 + streak * 2;
            ti = found + 1;
        }
        return s;
    }

    function search(query) {
        query = query.trim().toLowerCase();
        if (!query)
            return entries.slice().sort((a, b) => usage(b) - usage(a) || a.name.localeCompare(b.name));
        const results = [];
        for (const e of entries) {
            const best = Math.max(score(query, e.name), score(query, e.genericName ?? "") - 50, String(e.keywords ?? "").toLowerCase().includes(query) ? 100 : -1);
            if (best >= 0)
                results.push({
                    entry: e,
                    score: best
                });
        }
        return results.sort((a, b) => b.score - a.score).map(r => r.entry);
    }

    function launch(entry) {
        Settings.setIn("appUsage", entry.id, usage(entry) + 1);
        if (entry.runInTerminal)
            Quickshell.execDetached(["kitty", "-e", ...entry.command]);
        else
            entry.execute();
    }
}
