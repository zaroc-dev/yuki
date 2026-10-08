# Design language

The user's original sketch: three rounded islands along the top edge (left,
center, right) floating over a frosted wallpaper. Everything since follows
that: calm, frosted, rounded, accent-driven.

## Surfaces

- **Pills/islands**: `Pill`: `Theme.barBg` (base at `Theme.opacity`), 1px
  `barBorder`, `Theme.radius` (12), faint top highlight gradient (glass).
  Height `barHeight` (36), `gap` (8) from screen edges and between pills.
- **Popups/panels**: `Theme.popupBg` (slightly more opaque), same border,
  radius 12 (panels/launcher: radius + 4..6), 14px padding, 10px spacing.
- **Blur**: niri `ext-background-effect` via `BackgroundEffect.blurRegion` on
  every floating surface (pills, popups, toasts, OSD, launcher, settings).
  With blur off, surfaces become near-opaque.
- **Cards inside panels**: `Qt.alpha(Theme.surface0, 0.55–0.7)`, radius 12.
- Overlays dim with `Qt.alpha(Theme.crust, 0.35–0.4)` except Settings (clear
  backdrop so theme/wallpaper changes are visible live).

## Color

- Only `Theme.*`. Accent = `Theme.accent` (Material primary when dynamic),
  text on accent = `Theme.onAccent`. Selected/active = accent fill or
  `Qt.alpha(accent, 0.15–0.18)`; hover = `Theme.hover`; pressed = `Theme.pressed`.
- Destructive = `Theme.red`; power tiles use the named hues (blue suspend,
  yellow logout, peach restart, red shutdown).
- Secondary text `subtext0/1`, hints `overlay0/1`, section labels `overlay2`
  uppercase small with letter spacing.

## Type & icons

- Inter (`Theme.font`), 13px body, 11px small, 15px popup titles, 17–22px panel
  titles, Light 136px clock on lock/login.
- JetBrainsMono Nerd Font Material Design glyphs (`Icons.*`), 16px default.

## Motion

- `Theme.anim` 180ms for hover/color/small moves, `animSlow` 320ms for theme
  color changes. OutCubic for movement, OutBack for little pops (dots, icons).
- Popups: fade + 8px slide in, 130ms fade out; size changes glide (240ms).
- Accordions animate height + opacity; lists use ScriptModel add/remove/displaced
  transitions. Nothing should jump.
- Lock/login: desktop snapshot blurs/dims/zooms in over ~550ms, reverse on unlock.

## Interaction patterns

- Left click = primary, right click = secondary (cycle theme, pin/unpin,
  toggle DND, preferred player, forget device), middle click = quick toggle
  (play/pause, mute, Bluetooth power), scroll = adjust (volume, workspaces).
- Destructive actions are two-step: first press arms (fills red, "Confirm",
  draining 4s countdown), second runs.
- One popup at a time; clicking anywhere else (including the bar) closes it.
- Keyboard: Esc closes, Enter confirms, arrows/Tab move in lists, letter
  shortcuts in the power menu.
- Hidden detail on hover (network interface name slides out).
