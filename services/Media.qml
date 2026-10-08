pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    // Set when the user explicitly picks a player; otherwise follow whatever plays.
    property MprisPlayer pinned: null
    readonly property MprisPlayer active: (pinned && players.includes(pinned) ? pinned : null) ?? players.find(p => p.isPlaying) ?? players[0] ?? null

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00";
        seconds = Math.floor(seconds);
        const h = Math.floor(seconds / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        const s = String(seconds % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${s}` : `${m}:${s}`;
    }

    // Live streams report garbage lengths (e.g. INT64_MAX µs).
    function hasLength(player) {
        return (player?.lengthSupported ?? false) && player.length > 0 && player.length < 1e7;
    }

    function nameOf(player) {
        return player?.identity || player?.desktopEntry || "Player";
    }
}
