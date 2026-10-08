# Architecture

## Layout

```
shell.qml        root ShellRoot: Backdrop/Wallpaper per screen, ColorExtractor, Bar per
                 screen, NotificationToasts, Launcher, LockScreen, SettingsWindow,
                 ClipboardPanel, Osd, all IpcHandlers; touches lazy singletons
config/          Settings (persisted JSON), Theme (palette), Wallpapers, Icons   ← no deps on services
services/        singletons: Niri, Apps, Audio, Media, Net, Notifs, Lock, Power, Ui,
                 Templates, Clipboard, Screenshots, Osd, Brightness, Idle
components/      reusable UI: Pill, BarButton, BarPopup, IconButton, Icon, StyledText,
                 StyledSlider, Toggle, Segmented, AppIcon, Avatar, NotificationCard, …
bar/             Bar.qml (one PanelWindow per screen) + one file per widget
popups/          BarPopup-based dropdowns + overlay windows (Launcher, ClipboardPanel,
                 NotificationToasts, Osd)
settings/        SettingsWindow (overlay) + one Page per sidebar entry
lock/            LockScreen (WlSessionLock + preview windows), LockSurface (the UI)
wallpaper/       Wallpaper, Backdrop (overview), ColorExtractor (seed color)
lib/             material.mjs (palette from seed), colorworker.mjs, mcu/ (vendored)
pam/             password.conf (pam_unix) for the lock screen
extras/          sddm/yuki (SDDM theme), plymouth (script theme + image generator)
nix/             package, sddm-theme, plymouth-theme, home-module, nixos-module
```

Import direction: `config` ← `services` ← `components` ← `bar`/`popups`/`settings`/…
`config` must not import `services` (cycles). That's why `Wallpapers` lives in
`config/`: `Theme` needs the color-source wallpaper path.

## Bar & popups

- `bar/Bar.qml` is a top-anchored `PanelWindow` per screen with four pills:
  left (start, launcher), media (own pill, visible when a player exists),
  center (clock, workspaces, active window), right (tray | notifications |
  bluetooth, network, volume, battery | power). `mask` and `BackgroundEffect`
  regions cover only the pills.
- A full-size pass-through `MouseArea` (z 1000, `accepted = false`) calls
  `Ui.dismissPopup()`: the xdg-popup grab only dismisses on clicks into *other*
  clients, so presses on yuki's own surfaces must close popups themselves.
  `Wallpaper.qml` does the same for desktop clicks.
- Every dropdown extends `components/BarPopup.qml` (a `PopupWindow`):
  - `toggle(fromPointer)`: one popup at a time (`Ui.activePopup`), positioned
    under the target, clamped to the screen gutters, hanging from the pill bottom.
  - Grabs focus only when opened by pointer (Wayland grants grabs only in
    response to input). IPC-opened popups don't grab and close on niri focus change.
  - Animated size: frame glides (`SmoothedAnimation`) to `targetWidth/Height`;
    the window keeps the larger size until a shrink finishes; `mask` = frame.
  - Body is a `ColumnLayout` with a fixed width: header rows need
    `Layout.fillWidth: true` (see gotchas).
  - `name` makes it reachable via `ipc call bar toggle <name>`.

## Services

- **Niri**: one `Socket` streams `"EventStream"`, another sends actions
  (`Niri.action("FocusWorkspace", {...})`). Keeps `workspaces`, `windows`,
  `focusedWindowId`, keyboard layouts, overview state; emits `screenshotCaptured`.
- **Media**: MPRIS. `active` = popup-pinned player → preferred player
  (`Settings.d.preferredPlayer`) → playing → first.
- **Notifs**: `NotificationServer` (yuki is the daemon). `popups` = toasts,
  `list` = center. `notify(opts)` creates *internal* notifications with the
  same shape (used for screenshots). niri's own screenshot notification is
  expired in favor of ours.
- **Lock**: `lock()` → bars snapshot their output (`ScreencopyView` →
  `grabToImage`, in memory) → `locked = true` → `WlSessionLock`. PAM via
  `pam/password.conf`. `preview` shows the same UI in overlay windows without
  locking. `lockThen(fn)` runs after `secure` (used for suspend).
- **Templates**: debounced on palette change; writes niri/kitty/GTK/JSON into
  `~/.local/state/yuki/theme/`, then `niri msg action load-config-file` and
  `pkill -USR1` kitty.
- **Clipboard**: runs `wl-paste --watch cliphist store` (text + image) itself;
  lists/decodes via cliphist; thumbnails decoded into the cache dir.
- **Idle**: two `IdleMonitor`s (lock, screen off via niri `PowerOffMonitors`),
  `keepAwake` disables both.

## Theme pipeline

```
Settings.d.themeSource ─┬─ "wallpaper": Wallpapers.colorSourcePath
                        │      → ColorExtractor (Canvas 128×128 → WorkerScript lib/colorworker.mjs)
                        │      → Settings.d.seeds[path] = "#hex" (cached per image)
                        │      → Theme.p = Material.palette(seed, scheme, dark)
                        ├─ "catppuccin": Theme.flavors[flavor] / latte for light
                        └─ "custom": mocha + Settings.d.custom
Theme.p has Catppuccin-shaped keys (base, mantle, crust, surface0-2, overlay0-2,
text, subtext0-1, named hues) so every widget works with every source;
Theme.m3 has all Material roles (for templates); Theme.accent/onAccent.
```

`material.mjs` maps neutral tonal ramps onto those keys at Catppuccin-like
lightness steps and harmonizes the named hues toward the seed. tonal-spot
output matches noctalia/matugen closely (verified: `#b3c5ff` vs `#b4c5ff`).

## Windows & layers (niri namespaces)

`yuki-bar` (Top), `yuki-wallpaper` + `yuki-backdrop` + `yuki-color-extractor`
(Background), `yuki-notifications`, `yuki-osd`, `yuki-launcher`,
`yuki-clipboard`, `yuki-settings`, `yuki-lock-preview` (Overlay). The generated
niri.kdl places `yuki-backdrop` within niri's overview backdrop. Toasts and OSD
are one window *per screen*, shown only on the focused output.

## State on disk

| Path | What |
| --- | --- |
| `~/.local/state/quickshell/by-shell/yuki/settings.json` | all settings (watched) |
| `~/.local/state/yuki/theme/` | generated app colors |
| `~/.cache/quickshell/…/clipboard/` | decoded clipboard image thumbnails |
| cliphist db | clipboard history |
