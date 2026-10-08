//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config
import qs.services
import qs.bar
import qs.popups
import qs.lock
import qs.wallpaper
import qs.settings

ShellRoot {
    // Created before the wallpapers so it stacks below them even when niri
    // hasn't been told to move it into the overview backdrop yet.
    Variants {
        model: Settings.d.overviewBackdrop ? Quickshell.screens : []

        Backdrop {}
    }

    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }

    ColorExtractor {}

    // Singletons are lazy; touch the ones that must run from the start.
    readonly property var services: [Templates, Clipboard, Idle, Screenshots, Brightness, Osd]

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    NotificationToasts {}
    Launcher {}
    LockScreen {}
    SettingsWindow {}
    ClipboardPanel {}
    Osd {}

    // `qs -p <dir> ipc call launcher toggle`, etc.
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Ui.launcherOpen = !Ui.launcherOpen;
        }
        function open(): void {
            Ui.launcherOpen = true;
        }
        function close(): void {
            Ui.launcherOpen = false;
        }
    }

    IpcHandler {
        target: "bar"

        // Opens on the focused output: media | calendar | notifications | network | volume | power
        function toggle(name: string): void {
            Ui.popupRequested(name, Niri.focusedOutput);
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            Lock.lock();
        }
        // Shows the lock screen without locking the session.
        function preview(): void {
            Lock.showPreview();
        }
        function isLocked(): bool {
            return Lock.locked;
        }
        function closePreview(): void {
            Lock.cancelPreview();
        }
    }

    IpcHandler {
        target: "power"

        // lock | suspend | logout | reboot | poweroff
        function run(action: string): void {
            Power.run(action);
        }
    }

    IpcHandler {
        target: "wallpaper"

        // screen: output name, or "all"
        function set(screen: string, path: string): void {
            Wallpapers.set(screen, path);
        }
        function random(screen: string): void {
            Wallpapers.random(screen);
        }
        function shuffle(): void {
            Wallpapers.shuffleAll();
        }
        function get(screen: string): string {
            return Wallpapers.pathFor(screen);
        }
    }

    IpcHandler {
        target: "settings"

        // appearance | wallpaper | bar | notifications | start | about
        function open(page: string): void {
            Ui.openSettings(page);
        }
        function toggle(): void {
            if (Ui.settingsOpen)
                Ui.settingsOpen = false;
            else
                Ui.openSettings();
        }
        function close(): void {
            Ui.settingsOpen = false;
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            Ui.clipboardOpen = !Ui.clipboardOpen;
        }
        function clear(): void {
            Clipboard.wipe();
        }
    }

    IpcHandler {
        target: "screenshot"

        function region(): void {
            Screenshots.region();
        }
        function screen(): void {
            Screenshots.screen();
        }
        function window(): void {
            Screenshots.window();
        }
    }

    IpcHandler {
        target: "audio"

        // percent steps; the OSD shows the result
        function up(step: int): void {
            Audio.setVolume(Audio.sink, Audio.volume + (step || 5) / 100);
        }
        function down(step: int): void {
            Audio.setVolume(Audio.sink, Audio.volume - (step || 5) / 100);
        }
        function mute(): void {
            Audio.toggleMute(Audio.sink);
        }
        function micMute(): void {
            Audio.toggleMute(Audio.source);
        }
    }

    IpcHandler {
        target: "media"

        function toggle(): void {
            Media.active?.togglePlaying();
        }
        function next(): void {
            Media.active?.next();
        }
        function previous(): void {
            Media.active?.previous();
        }
        // Players the shell sees and which one the bar shows.
        function status(): string {
            return Media.players.map(p => `${p === Media.active ? "*" : " "} ${Media.keyOf(p)} [${p.identity}] ${MprisPlaybackState.toString(p.playbackState)} "${p.trackTitle}"`).join("\n") || "no players";
        }
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            Brightness.adjust(0.05);
        }
        function down(): void {
            Brightness.adjust(-0.05);
        }
        function set(percent: int): void {
            Brightness.set(percent / 100);
        }
    }

    IpcHandler {
        target: "idle"

        function toggleKeepAwake(): bool {
            Idle.keepAwake = !Idle.keepAwake;
            return Idle.keepAwake;
        }
    }

    IpcHandler {
        target: "shell"

        // hard: recreate every window instead of reusing them
        function reload(hard: bool): void {
            Quickshell.reload(hard);
        }
    }

    IpcHandler {
        target: "theme"

        function flavor(name: string): string {
            return Theme.setFlavor(name) ? `flavor: ${name}` : `unknown flavor, try: ${Object.keys(Theme.flavors).join(", ")}, custom`;
        }
        function accent(name: string): string {
            return Theme.setAccent(name) ? `accent: ${name}` : `unknown accent, try: ${Theme.accents.join(", ")}`;
        }
        function cycle(): void {
            Theme.cycleFlavor();
        }
        function source(name: string): bool {
            return Theme.setSource(name);
        }
        function mode(mode: string): bool {
            return Theme.setMode(mode);
        }
        function scheme(name: string): string {
            return Theme.setScheme(name) ? `scheme: ${name}` : `unknown scheme, try: ${Theme.schemes.join(", ")}`;
        }
    }

    IpcHandler {
        target: "notifications"

        function toggleDnd(): bool {
            Notifs.toggleDnd();
            return Notifs.dnd;
        }
        function clear(): void {
            Notifs.clearAll();
        }
    }
}
