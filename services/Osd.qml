pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Transient value display (volume, brightness) on the focused output.
Singleton {
    id: root

    property bool shown: false
    property string icon
    property string label
    property real value: 0
    property bool muted: false
    // Ignore the burst of changes while services start up.
    property bool armed: false

    function show(icon, label, value, muted) {
        if (!armed)
            return;
        root.icon = icon;
        root.label = label;
        root.value = value;
        root.muted = muted ?? false;
        shown = true;
        hide.restart();
    }

    Timer {
        id: hide

        interval: 1600
        onTriggered: root.shown = false
    }

    Timer {
        running: true
        interval: 2500
        onTriggered: root.armed = true
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.volume();
        }
        function onMutedChanged(): void {
            root.volume();
        }
    }

    function volume() {
        // The volume popup already shows this.
        if (Ui.activePopup?.name === "volume")
            return;
        show(Icons.volume(Audio.volume, Audio.muted), Audio.nameOf(Audio.sink), Audio.volume, Audio.muted);
    }
}
