pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.config

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    // Set when the user explicitly picks a player; otherwise follow whatever plays.
    property MprisPlayer pinned: null
    readonly property string preferred: Settings.d.preferredPlayer.toLowerCase()
    readonly property MprisPlayer preferredPlayer: preferred ? players.find(p => matches(p, preferred)) ?? null : null
    // Chosen in the media popup > preferred player (whenever it runs) >
    // whatever is playing > anything.
    readonly property MprisPlayer active: (pinned && players.includes(pinned) ? pinned : null) ?? preferredPlayer ?? players.find(p => p.isPlaying) ?? players[0] ?? null

    function matches(player, name) {
        return [player.identity, player.desktopEntry, player.dbusName].some(s => (s ?? "").toLowerCase().includes(name));
    }

    // Stable key for a player, used by the "preferred player" setting.
    function keyOf(player) {
        return (player?.desktopEntry || player?.identity || "").toLowerCase();
    }

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
