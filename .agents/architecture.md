# Architecture

## Layout

```
shell.qml        root ShellRoot: Backdrop/Wallpaper per screen, ColorExtractor, Bar per
                 screen, NotificationToasts, Launcher, LockScreen, SettingsWindow,
                 ClipboardPanel, Osd, all IpcHandlers; touches lazy singletons
config/          Settings (persisted JSON), Theme (palette), Wallpapers, Icons   ← no deps on services
services/        singletons: Niri, Apps, Audio, Media, Net, Vpn, Notifs, Lock, Power, Ui,
                 Templates, Clipboard, Screenshots, Osd, Brightness, Idle
components/      reusable UI: Surface, SurfaceRegion, BarPopup, DropSheet, BarButton,
                 PanelHeader, SectionLabel, IconButton, Icon, StyledText,
                 StyledSlider, Toggle, Segmented, TextField, AppIcon, Avatar, NotificationCard, …
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

- `bar/Bar.qml` is a top-anchored `PanelWindow` per screen drawn as one
  `Shape` (SVG path from `outline()`): a full-width strip (`Theme.barHeight`),
  concave screen-corner fillets at both ends (`Theme.fillet`) and the clock tab
  hanging from the middle (`Theme.tabDepth`, smooth cubic shoulders). The window
  is taller than its exclusive zone (`barHeight`) so the fillets/tab fit; `mask`
  and blur cover only strip + tab. Left row: start, launcher, workspaces, active
  window. Right row: media, tray, a `Theme.well` with bluetooth/network/volume/
  battery, notifications, power. Title budgets per side come from fixed parts only.
- **Fused surfaces.** Everything that hangs from the bar is a `components/Surface`
  (square top + concave top fillets, rounded bottom) placed flush at
  `y = barHeight`, with the same fill (`Theme.popupBg` = `barBg`), so the join
  vanishes. Snapped to a screen edge, that side runs flat and ends in an edge
  fillet. The bar gives up what it covers:
  - `Ui.shownPopup` (visible popup incl. its closing animation): a snapped one
    hides that bar corner, instantly; at reveal 0 the panel's edge fillet sits
    exactly where the corner was (both radius `Theme.fillet`), so the handoff
    is invisible. Its x-range over the tab folds the tab away (animated).
  - `Ui.toastScreen` (toast drawer, snapped right) hides the right corner;
    `Ui.osdScreen` / `Ui.sheetScreen` (OSD, launcher/clipboard `DropSheet`)
    fold the tab.
  - Blur for a Surface: `SurfaceRegion` (child `Region`s use window coordinates;
    a parent region's x/y doesn't offset them, hence `bodyX/bodyY`).
- A full-size pass-through `MouseArea` (z 1000, `accepted = false`) calls
  `Ui.dismissPopup()`: the xdg-popup grab only dismisses on clicks into *other*
  clients, so presses on yuki's own surfaces must close popups themselves.
  `Wallpaper.qml` does the same for desktop clicks.
- Every dropdown extends `components/BarPopup.qml` (a `PopupWindow`):
  - `toggle(fromPointer)`: one popup at a time (`Ui.activePopup`), centered
    under the target and hanging from the bar's bottom edge; within
    `fillet + 4·gap` of a screen edge it snaps to it (`snapLeft/Right`).
  - Opens by growing out of the bar (`reveal` 0→1 scales the visible body
    height; content fades/slides in) and folds back on close.
  - `backdrop`: full-bleed items clipped to the panel's shape (media art wash).
  - Grabs focus only when opened by pointer (Wayland grants grabs only in
    response to input). IPC-opened popups don't grab and close on niri focus change.
  - Animated size: frame glides (`SmoothedAnimation`) to `targetWidth/Height`;
    the window keeps the larger size until a shrink finishes; `mask` = body.
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
- **Lock**: `lock()` → `locked = true` → `WlSessionLock`; each surface blurs
  in from its output's wallpaper. PAM via `pam/password.conf`. `preview` shows
  the same UI in overlay windows without locking. `lockThen(fn)` runs after
  `secure` (used for suspend). While locked, `$XDG_RUNTIME_DIR/yuki-locked`
  holds the session key (`NIRI_SOCKET`); a shell that starts and finds it
  matching locks again (crash failsafe).
- **Net**: `Quickshell.Networking` wrappers. `join(ssid, settings, secret)`
  covers what the API can't (802.1X, hidden SSIDs): `nmcli connection add`,
  then the secret through stdin into `nmcli connection edit` (never argv:
  Quickshell logs failed commands), then `up`; deletes the profile on failure.
  Used by `popups/WifiJoinForm.qml`.
- **Vpn**: Mullvad via `mullvad status --json listen` + `mullvad connect|disconnect`
  (its tunnel isn't an NM connection), NM `wireguard`/`vpn` profiles via nmcli
  (refreshed on `nmcli monitor`; active profiles on "connected (externally)"
  devices are skipped). `connections` is one list for both. OpenConnect profiles
  authenticate through `services/vpn-connect.py` in the desktop session; the
  cookie goes to nmcli on stdin and NetworkManager owns the resulting tunnel.
  Toggling off during login cancels the helper and any pending activation.
- **Templates**: debounced on palette change; writes niri/kitty/GTK/JSON into
  `~/.local/state/yuki/theme/`, then `niri msg action load-config-file` and
  `pkill -USR1` kitty.
- **Clipboard**: runs `wl-paste --watch cliphist store` (text + image) itself;
  lists/decodes via cliphist; thumbnails decoded into the cache dir.
- **Polkit** (`popups/PolkitDialog.qml`, not a service): `PolkitAgent`
  registers on startup; the dialog is a `LazyLoader` window while
  `agent.isActive`. After a wrong password the same `AuthFlow` asks again
  (`authenticationFailed`, then `isResponseRequired`).
- **Switcher** (+ `popups/WindowSwitcher.qml`): MRU snapshot from niri's
  `focus_timestamp` on the first `next`/`prev`. While open, a `ShortcutInhibitor`
  makes Alt+Tab arrive as keys and the Alt release commits. Looks are
  `popups/Switcher{Cards,List,Island}.qml` behind a `Loader`; each exposes
  `panel`, `panelRadius` and `dims` for the window's blur/dim.
- **Weather**: Open-Meteo via `XMLHttpRequest` (geocoding for a city setting,
  ipinfo.io when empty), cached with a `FileView` in the cache dir. Lazy: only
  fetches once the dashboard or lock screen touches it. **SysStats** polls
  `/proc` + `df` + hwmon only while `users > 0` (the open dashboard).
- **Idle**: two `IdleMonitor`s (lock, screen off via niri `PowerOffMonitors`),
  `keepAwake` disables both.

## Theme pipeline

```
Settings.d.themeSource ─┬─ "wallpaper": Wallpapers.colorSourcePath
                        │      → ColorExtractor (Canvas 64×64 → WorkerScript lib/colorworker.mjs)
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

`yuki-bar` (Top; `yuki-osd`, `yuki-notifications` and the sheets sit flush under
it with exclusive zone 0), `yuki-wallpaper` + `yuki-backdrop` + `yuki-color-extractor`
(Background), `yuki-notifications`, `yuki-osd`, `yuki-launcher`,
`yuki-clipboard`, `yuki-settings`, `yuki-polkit`, `yuki-switcher`, `yuki-lock-preview` (Overlay). The generated
niri.kdl places `yuki-backdrop` within niri's overview backdrop. Toasts and OSD
are one window *per screen*, shown only on the focused output.

## State on disk

| Path | What |
| --- | --- |
| `~/.local/state/quickshell/by-shell/yuki/settings.json` | all settings (watched) |
| `~/.local/state/yuki/theme/` | generated app colors |
| `~/.cache/quickshell/…/clipboard/` | decoded clipboard image thumbnails |
| cliphist db | clipboard history |
