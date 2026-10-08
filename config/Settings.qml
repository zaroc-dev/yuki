pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Every persisted setting, in one watched JSON file:
// ~/.local/state/quickshell/by-shell/<id>/settings.json
// Maps/lists must be reassigned (not mutated) to be saved.
Singleton {
    id: root

    readonly property alias d: adapter
    readonly property string path: file.path

    function set(key, value) {
        adapter[key] = value;
    }

    // Map helpers: copy, modify, reassign.
    function setIn(key, subKey, value) {
        const m = Object.assign({}, adapter[key]);
        if (value === undefined)
            delete m[subKey];
        else
            m[subKey] = value;
        adapter[key] = m;
    }

    function expand(path) {
        return path.startsWith("~") ? Quickshell.env("HOME") + path.slice(1) : path;
    }

    FileView {
        id: file

        path: Quickshell.statePath("settings.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            // ---- theme ----
            // "wallpaper" (Material You from a wallpaper), "catppuccin", or "custom"
            property string themeSource: "wallpaper"
            property string themeMode: "dark"
            // Material scheme: tonal-spot, content, expressive, fidelity, fruit-salad,
            // monochrome, neutral, rainbow, vibrant
            property string scheme: "tonal-spot"
            // Output whose wallpaper drives the colors ("" = first screen).
            property string colorScreen: ""
            // wallpaper path -> extracted seed color (cache)
            property var seeds: ({})
            property string flavor: "mocha"
            property string accent: "mauve"
            property var custom: ({})
            property bool blur: true
            // App color templates: niri, kitty, gtk (false disables one)
            property var templates: ({})
            // Blurred wallpaper behind workspaces in niri's overview
            property bool overviewBackdrop: true
            property real opacity: 0.78

            // ---- wallpaper ----
            property string wallpaperDir: "~/wallpapers"
            property string wallpaperDefault: ""
            // output name -> path
            property var wallpapers: ({})

            // ---- clipboard ----
            // Run `wl-paste --watch cliphist store` from the shell.
            property bool clipboardWatch: true

            // ---- power / idle ----
            property int lockAfterMinutes: 10
            property int screenOffAfterMinutes: 15

            // ---- bar ----
            property bool clock24h: true
            property bool showDate: true
            property bool showMedia: true
            property bool showLauncherButton: true
            // Media player shown in the bar whenever it's running (matched
            // against MPRIS identity / desktop entry, case-insensitive). "" = auto.
            property string preferredPlayer: ""
            property bool showActiveWindow: true

            // ---- notifications ----
            property bool dnd: false
            property real toastSeconds: 6

            // ---- start menu / launcher ----
            // desktop entry ids
            property var pinnedApps: []
            // desktop entry id -> launch count
            property var appUsage: ({})
        }
    }
}
