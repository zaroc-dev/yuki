pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell

// Per-output wallpapers. An output without its own entry shows the default
// (or the first image in the directory).
Singleton {
    id: root

    readonly property string dir: Settings.expand(Settings.d.wallpaperDir)
    property var files: []
    // YUKI_WALLPAPER is the packager's default (Nix `wallpaper` option); a
    // wallpaper picked in the shell is saved as wallpaperDefault and wins.
    readonly property string fallback: Settings.expand(Settings.d.wallpaperDefault) || Settings.expand(Quickshell.env("YUKI_WALLPAPER") ?? "") || (files[0] ?? "")

    // Output whose wallpaper the colors are extracted from.
    // Defaults to the output at the layout origin (usually the primary one).
    readonly property string colorScreen: Settings.d.colorScreen || ((Quickshell.screens.find(s => s.x === 0 && s.y === 0) ?? Quickshell.screens[0])?.name ?? "")
    readonly property string colorSourcePath: pathFor(colorScreen)
    readonly property bool colorFromRinka: managedByRinka(colorScreen)
    // Runtime stills are replaced after edits and disappear with the host.
    // The last Rinka seed (or the saved wallpaper's) stays until the new still
    // is extracted, so edits don't flash the fallback palette.
    property var rinkaSeed: ({ screen: "", path: "", seed: "" })
    readonly property string colorSeed: colorFromRinka && rinkaSeed.screen === colorScreen && rinkaSeed.seed ? rinkaSeed.seed : (Settings.d.seeds[savedPathFor(colorScreen)] ?? "")
    readonly property bool colorSeedStale: colorSourcePath !== "" && (colorFromRinka ? rinkaSeed.path !== colorSourcePath : !(colorSourcePath in Settings.d.seeds))

    onColorFromRinkaChanged: if (!colorFromRinka) rinkaSeed = { screen: "", path: "", seed: "" }

    function managedByRinka(screenName) {
        return Rinka.imageFor(screenName) !== "";
    }

    // What the output shows: Rinka's still while it owns the output.
    function pathFor(screenName) {
        return Rinka.imageFor(screenName) || savedPathFor(screenName);
    }

    // Yuki's own choice, kept while Rinka owns the output.
    function savedPathFor(screenName) {
        return Settings.expand(Settings.d.wallpapers[screenName] ?? "") || fallback;
    }

    function hasOwn(screenName) {
        return !!Settings.d.wallpapers[screenName];
    }

    // screenName "" or "all" sets the default and clears per-output overrides.
    function set(screenName, path) {
        if (!screenName || screenName === "all") {
            Settings.d.wallpaperDefault = path;
            Settings.d.wallpapers = {};
        } else {
            Settings.setIn("wallpapers", screenName, path);
        }
    }

    function random(screenName) {
        const current = savedPathFor(screenName || colorScreen);
        const pool = files.filter(f => f !== current);
        if (pool.length > 0)
            set(screenName, pool[Math.floor(Math.random() * pool.length)]);
    }

    // Different random wallpaper on every output.
    function shuffleAll() {
        const pool = files.slice().sort(() => Math.random() - 0.5);
        const map = {};
        Quickshell.screens.forEach((s, i) => map[s.name] = pool[i % pool.length]);
        Settings.d.wallpapers = map;
    }

    function step(screenName, delta) {
        const i = files.indexOf(savedPathFor(screenName));
        set(screenName, files[(i + delta + files.length) % files.length]);
    }

    function refresh() {
        const list = [];
        for (let i = 0; i < folder.count; i++)
            list.push(folder.get(i, "filePath"));
        files = list;
    }

    FolderListModel {
        id: folder

        folder: "file://" + root.dir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
        caseSensitive: false
        showDirs: false
        sortCaseSensitive: false
        onCountChanged: root.refresh()
        onStatusChanged: if (status === FolderListModel.Ready) root.refresh()
    }
}
