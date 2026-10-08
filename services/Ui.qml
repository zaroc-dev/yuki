pragma Singleton

import QtQuick
import Quickshell

// Shell-wide UI state.
Singleton {
    property bool launcherOpen: false
    property bool settingsOpen: false
    property bool clipboardOpen: false
    // appearance | wallpaper | bar | notifications | start | about
    property string settingsPage: "appearance"

    // A press landed on one of the shell's own surfaces (which the popup grab
    // doesn't treat as "outside"). Close the open popup unless the press was
    // on its own bar button, which toggles it itself.
    function dismissPopup(item, x, y) {
        const p = activePopup;
        if (!p)
            return;
        const t = p.target;
        if (item && t && t.QsWindow.window === item.QsWindow.window && t.contains(t.mapFromItem(item, x, y)))
            return;
        p.close();
    }

    function openSettings(page) {
        if (page)
            settingsPage = page;
        if (activePopup)
            activePopup.close();
        settingsOpen = true;
    }
    // The one bar popup that is open; opening another closes it first, since
    // nested xdg popup grabs would re-parent (and misplace) the new one.
    property var activePopup: null

    // Asks the bar on `output` to toggle the popup called `name`
    // (media, calendar, notifications, network, volume).
    signal popupRequested(string name, string output)
}
