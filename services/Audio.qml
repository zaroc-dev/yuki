pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink?.ready ?? false

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)

    function setVolume(node, value) {
        if (!node?.ready || !node.audio)
            return;
        node.audio.muted = false;
        node.audio.volume = Math.max(0, Math.min(1.5, value));
    }

    function toggleMute(node) {
        if (node?.ready && node.audio)
            node.audio.muted = !node.audio.muted;
    }

    function nameOf(node) {
        return node?.description || node?.nickname || node?.name || "Unknown";
    }

    // Binding nodes to a tracker is what makes their audio properties live.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources]
    }
}
