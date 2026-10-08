# shell

A Quickshell desktop shell for niri: three floating, frosted pills along the top edge.

| Pill   | Contents                                                                    |
| ------ | --------------------------------------------------------------------------- |
| left   | start menu + app launcher; media player as its own pill (art, title, controls, progress) |
| center | clock/date → calendar, niri workspaces of *this* output, its active window  |
| right  | tray · notifications · bluetooth, network (name on hover), volume, battery · power |

Every widget has a popup: media controls + seek + player switcher, a calendar,
a notification center (with do-not-disturb), the network (wired/Wi-Fi list with a password prompt),
and audio (output/input sliders and device pickers). The shell is also the notification
daemon, with toasts in the top right of the focused output, and has an app launcher.

## Desktop services

- **Bluetooth:** adapter toggle, scan, pair (auto trust + connect), connect/disconnect,
  device battery, forget (right-click).
- **Clipboard:** history via cliphist (the shell runs the `wl-paste --watch` recorders),
  a searchable panel with image thumbnails, Enter copies, Del removes.
- **Screenshots:** niri's own tools (region/screen/window from the start menu or IPC);
  the shell shows a toast with a thumbnail and Open / Show folder.
- **OSD:** a volume/brightness pill on the focused screen for any change (keys, apps).
- **Idle:** lock and screen-off timers, respecting apps that inhibit idle; "Awake" toggle.
- **Power:** power-profiles-daemon picker (power menu, battery popup, settings).
- **App colors:** niri, kitty and GTK snippets in `~/.local/state/shell/theme/`
  (see `~/dotfiles/HANDOFF.md`), plus a blurred wallpaper for niri's overview backdrop.

## Start menu & settings

The distro icon opens the **start menu**:
- **Header:** avatar, user@host and uptime, with buttons for settings, lock and power.
- **Pinned apps:** right-click a tile to unpin.
- **Frequent apps:** the ones you launch most.
- **Wallpaper card:** previous, next and shuffle for that screen.
- **Quick toggles:** Dark/Light, Dynamic colors, Silent (do not disturb).

The grid icon next to it opens the **launcher**. Right-click an app there to pin it;
with an empty search, apps are sorted by how often you launch them.

**Settings** (gear in the start menu, or `ipc call settings open [page]`):
- **Appearance:** color source, dark/light mode, which screen's wallpaper the colors
  come from, Material scheme (with live previews), Catppuccin flavor and accent,
  blur and opacity.
- **Wallpaper:** folder, per-screen or all-screen picker, shuffle.
- **Bar:** clock format, date, media and active-window widgets.
- **Notifications:** do not disturb, toast duration, clear all.
- **Start menu:** reorder and unpin pinned apps.
- **About:** paths and reload.

## Wallpapers & dynamic colors

The shell draws the wallpaper itself, one per output, with a fade-and-settle
transition. Outputs without their own wallpaper use the default (or the first
image in the folder, `~/wallpapers` by default).

With the color source set to `wallpaper`, the seed color of one output's wallpaper
(the output at 0,0 unless set otherwise) is extracted with Google's
material-color-utilities (vendored in `lib/mcu`, run in a WorkerScript) and turned
into a Material You scheme. `tonal-spot` is the same scheme noctalia's
`m3-tonal-spot` uses, so you get matching colors. Seeds are cached per image in
the settings file.

## Power menu & lock screen

The power button opens tiles for **L**ock, **S**uspend, Log out (**E**), **R**estart
and Shut down (**P**). Log out, restart and shut down need a second press within 4 s.
Suspend locks first and suspends once every output is covered.

The lock screen is a real `ext-session-lock`. Before locking, each bar snapshots
its output in memory, so the lock blurs in from what was on screen and blurs back
out on unlock. It shows a clock, your avatar (`~/.face.icon`), and a password
field authenticated through PAM (`pam/password.conf`, plain `pam_unix`). Also:
now-playing controls, the niri keyboard layout, and suspend/restart/shut down.

`qs … ipc call lock preview` shows the same UI *without* locking (Esc leaves).
Use it to tweak the design safely.

If the shell ever dies while locked, niri keeps the session locked (by design).
Recover from a TTY (Ctrl+Alt+F2):

```sh
WAYLAND_DISPLAY=wayland-1 qs -p ~/source/shell &   # start a new instance
WAYLAND_DISPLAY=wayland-1 qs -p ~/source/shell ipc call lock lock
```

and unlock normally on the new lock screen.

For idle locking, have swayidle/hypridle call `qs -p ~/source/shell ipc call lock lock`.

## Nix flake

```nix
inputs.shell.url = "github:zaroc-dev/shell";
```

| Output | What |
| --- | --- |
| `packages.<system>.shell` (default) | `shell` = `qs -p <config>` with cliphist, wl-clipboard, brightnessctl, xdg-utils on PATH. `shell ipc call …` talks to it. `.override { configDir = "/path"; }` runs a checkout instead of the store copy |
| `packages.<system>.sddm-theme` | `.override { background = ./wall.jpg; settings = { accent = "#…"; }; }` |
| `packages.<system>.plymouth-theme` | `.override { accent = …; base = …; surface = …; text = …; }` |
| `homeManagerModules.default` | `programs.shell = { enable; configDir; systemd.enable; gtk.enable; }` |
| `nixosModules.default` | `programs.shell = { sddm = { enable; background; }; plymouth.enable; palette = { … }; }` |

For hot reload, point `configDir` at a checkout (e.g. an out-of-store
symlink): the shell then runs the live QML, and settings are shared with the
packaged build because the shell id is pinned (`//@ pragma ShellId shell`).

```nix
# home-manager
imports = [ inputs.shell.homeManagerModules.default ];
programs.shell = {
  enable = true;
  configDir = "${config.home.homeDirectory}/source/shell";
};

# nixos
imports = [ inputs.shell.nixosModules.default ];
programs.shell = {
  sddm = { enable = true; background = ./wallpapers/raiden.shogun.jpg; };
  plymouth.enable = true;
};
```

## Running

Needs Quickshell ≥ 0.3 (`pkgs.quickshell`), niri, NetworkManager, PipeWire, UPower,
`JetBrainsMono Nerd Font` (icons) and `Inter` (text).

```sh
nix run nixpkgs#quickshell -- -p ~/source/shell    # try it
```

Files are hot-reloaded on save.

To make it your shell, add `pkgs.quickshell` to your packages, then in niri's `config.kdl`:

```kdl
// spawn-at-startup "noctalia"
spawn-at-startup "qs" "-p" "/home/zaroc/source/shell"
```

and in `keybinds.kdl`:

```kdl
Mod+Space hotkey-overlay-title="App Launcher" { spawn "qs" "-p" "/home/zaroc/source/shell" "ipc" "call" "launcher" "toggle"; }
Mod+N     hotkey-overlay-title="Notifications" { spawn "qs" "-p" "/home/zaroc/source/shell" "ipc" "call" "bar" "toggle" "notifications"; }
Super+Alt+L hotkey-overlay-title="Lock" { spawn "qs" "-p" "/home/zaroc/source/shell" "ipc" "call" "lock" "lock"; }
```

(Or symlink this directory to `~/.config/quickshell` and drop the `-p …` everywhere.)

While noctalia is running it owns `org.freedesktop.Notifications`. This shell then
shows no toasts, and takes the name over automatically once noctalia exits.

## Interaction

| Where           | Action                                                      |
| --------------- | ----------------------------------------------------------- |
| start button    | click: start menu · right-click: cycle themes               |
| launcher button | click: launcher                                             |
| media           | click: popup · middle: play/pause                           |
| workspaces      | click: focus · scroll: up/down                              |
| notifications   | click: center · right-click: toggle do-not-disturb          |
| volume          | click: popup · scroll: ±5% · middle: mute                   |
| tray item       | click: activate · right-click: menu · middle: secondary     |
| power           | click: power menu (keys L S E R P inside)                   |
| launcher        | type to filter · ↑/↓/Tab · Enter launches · Esc closes      |

## IPC

```sh
qs -p ~/source/shell ipc show
qs … ipc call launcher toggle|open|close
qs … ipc call bar toggle media|calendar|notifications|network|volume|power
qs … ipc call lock lock|preview|closePreview|isLocked
qs … ipc call settings open [appearance|wallpaper|bar|notifications|start|about]
qs … ipc call wallpaper set <output|all> <path>
qs … ipc call wallpaper random <output> · shuffle · get <output>
qs … ipc call theme source wallpaper|catppuccin|custom
qs … ipc call theme mode dark|light
qs … ipc call theme scheme tonal-spot|content|expressive|fidelity|fruit-salad|monochrome|neutral|rainbow|vibrant
qs … ipc call clipboard toggle|clear
qs … ipc call screenshot region|screen|window
qs … ipc call audio up <step>|down <step>|mute|micMute
qs … ipc call media toggle|next|previous
qs … ipc call brightness up|down|set <percent>
qs … ipc call idle toggleKeepAwake
qs … ipc call bar toggle start|media|calendar|notifications|bluetooth|network|volume|battery|power
qs … ipc call shell reload [true = hard]
qs … ipc call power run lock|suspend|logout|reboot|poweroff
qs … ipc call theme flavor mocha|macchiato|frappe|latte|custom
qs … ipc call theme accent mauve|blue|pink|…
qs … ipc call theme cycle
qs … ipc call notifications toggleDnd|clear
```

## Theming

All colors come from `config/Theme.qml`. Whatever the source, it exposes the same
Catppuccin-shaped palette, so every widget works with every theme. Settings
persist in `~/.local/state/quickshell/by-shell/<id>/settings.json`. The file is
watched, so editing it by hand restyles the shell live.

- `themeSource: "wallpaper"`: Material You from the wallpaper (`scheme`, `themeMode`, `colorScreen`)
- `themeSource: "catppuccin"`: `flavor` + `accent`, with light mode = Latte
- `themeSource: "custom"`: Mocha overridden by any keys in `custom`

`blur` uses niri's `ext-background-effect`. With it off, surfaces fall back to
near-opaque.

## Layout

```
shell.qml            root: wallpapers, bars, toasts, launcher, lock screen, settings, IPC
lib/                 material.mjs (Material You), vendored material-color-utilities, color worker
wallpaper/           per-output Wallpaper windows, ColorExtractor
settings/            SettingsWindow and its pages
extras/sddm/shell/   SDDM login theme in the lock screen's design
extras/plymouth/     Plymouth boot theme + image generator
config/              Settings (persisted), Theme (palette from wallpaper/Catppuccin), Wallpapers, Icons
services/            singletons: Niri (IPC event stream), Audio, Media, Net, Notifs, Apps, Lock, Power, Ui
components/          Pill, BarButton, BarPopup, StyledText, Icon, IconButton, StyledSlider, AppIcon, NotificationCard
bar/                 Bar + one file per widget
popups/              per-widget popups (incl. PowerMenu, TrayMenu), Launcher, NotificationToasts
lock/                LockScreen (session lock + preview windows), LockSurface (the UI)
pam/                 PAM config used by the lock screen
```

## Known limitations

- Popups opened from IPC can't take a pointer grab (Wayland only grants that in
  response to a click). They close when window focus changes instead of on any
  outside click.

## License

Apache-2.0, see [LICENSE](LICENSE). `lib/mcu` is Google's
material-color-utilities, also Apache-2.0 (its own LICENSE is kept there).
