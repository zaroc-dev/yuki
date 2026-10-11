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
    // Apps playing audio (one node per stream; an app can have several).
    readonly property var playback: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream && n.audio)
    // Apps recording from a microphone. Captures of an output (visualizers,
    // screen recorders' desktop audio) aren't the mic.
    readonly property var recording: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream && n.properties["stream.capture.sink"] !== "true")
    readonly property bool micInUse: recording.length > 0

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

    // Desktop-entry-ish id of a stream's app ("brave-browser", "spotify").
    function appIdOf(node) {
        const p = node?.properties ?? {};
        const binary = (p["application.process.binary"] ?? "").replace(/^\./, "").replace(/-wrapped$/, "");
        return p["application.icon-name"] || p["application.id"] || binary || (p["application.name"] ?? "").toLowerCase();
    }

    // The app's own name when it looks like one ("Brave"), else its desktop
    // entry by exact id ("spotify" → "Spotify"). No fuzzy lookup: it turned
    // pw-record into "NixOS Manual".
    function appNameOf(node) {
        const name = node?.properties?.["application.name"] ?? "";
        if (/[A-Z ]/.test(name))
            return name;
        const entry = DesktopEntries.byId(appIdOf(node));
        if (entry)
            return entry.name;
        return name ? name[0].toUpperCase() + name.slice(1) : node?.name || "Unknown";
    }

    // What the stream is (track, tab, call), when the app says.
    function mediaOf(node) {
        const p = node?.properties ?? {};
        const m = p["media.name"] ?? "";
        const generic = ["playback", "audio stream", "audiostream", "audio", (p["application.name"] ?? "").toLowerCase()];
        return generic.includes(m.toLowerCase()) ? "" : m;
    }

    // Binding nodes to a tracker is what makes their audio properties live.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources, ...root.playback]
    }
}
