# Design language: Frostline

One frosted strip fused to the top edge of every screen. Everything else grows
out of it: the bar and whatever hangs from it read as a single liquid surface.
Bold display type and an aurora gradient carry the accent.

## Surfaces

- **The bar**: full-width `Theme.barBg` strip, `Theme.barHeight` (40). Its ends
  curve down into the screen edges (concave fillets, `Theme.fillet` 16) so the
  screen gets rounded top corners. Straight bottom edge, no bulges: every
  curve in the shell is a circular fillet or radius.
- **The horizon**: a `Theme.horizonWidth` (2) aurora line along the bar's lower
  edge and corners, drawn as a gradient-filled band. It breaks where something hangs from the bar
  and the hanging surface's rim carries it on, so bar + panel share one
  outline. Resting strength `Theme.horizonRest`; light pools on it
  (`Theme.horizonLit`) under the cursor (which also lights the frost from
  behind), at panel joins, in the sun (x = time of day) and in the comet on a
  new notification. Lights stay on the line; only the cursor also lights the
  frost (clipped to the strip), nothing glows outside the bar.
- **Panels** (popups, OSD, toast drawer, launcher/clipboard sheets): a `Surface`
  flush with the bar's bottom edge, same fill, concave fillets where they meet
  it, `Theme.radiusLarge` (22) at the bottom. A panel within reach of a screen
  edge snaps to it and runs down that edge, ending in an edge fillet. The bar
  hands over the corner and opens its horizon for whatever covers it. Panel
  rims are lit at the join and fade towards the bottom.
- **Floating dialogs** (settings, polkit, switcher): radius 28–30, `Theme.rim`
  border, aurora light falling in from the top edge. Settings keeps a clear
  backdrop so theme changes are visible live.
- **Inside panels**: cards `Theme.card` (radius 18–22), hover `Theme.cardHover`;
  inset wells `Theme.well` (status icons in the bar, workspaces, slider tracks,
  text fields, chips). Capsules (radius = height/2) for rows, chips and buttons.
- **Blur**: niri `ext-background-effect` on every surface (`SurfaceRegion` for
  fused ones). Fillets stay unblurred (small; the tint covers them).
- Overlays dim with `Qt.alpha(Theme.crust, 0.45)` below the bar, with the
  sheet's outline cut out of the dim.

## Color

- Only `Theme.*`. **Aurora** = vertical or horizontal gradient `Theme.accent` →
  `Theme.accent2` (Material tertiary / Catppuccin pink). Primary fills use it:
  start badge, workspace drop, slider fills, toggles, filled buttons, the
  current settings page, the selected launcher row (as a tint), the lock /
  login avatar ring, password dots and submit button.
  Text on it is `Theme.onAccent`.
- Active/selected otherwise: `Qt.alpha(accent, 0.16–0.26)`; hover `Theme.hover`;
  pressed `Theme.pressed` plus a slight scale-down.
- Destructive = `Theme.red`; power tiles use the named hues (blue suspend,
  yellow logout, peach restart, red shutdown) as hover glows.
- Secondary text `subtext0/1`, hints `overlay0/1`; labels above values
  (app name in a toast, player name, "WALLPAPER") are 10px bold caps in accent
  or `overlay2` with 1.2–1.8 letter spacing.

## Type & icons

- Inter (`Theme.font`) for text, 13px body, 11px small.
- **Inter Display** (`Theme.displayFont`) for numerals and titles, heavy:
  panel titles 20 ExtraBold, bar clock 17 ExtraBold with tabular figures
  (digits roll in from below, OutBack),
  percentages 20–30 Black, dashboard clock 84 Black, lock/login clock 136 Bold
  over the date in 15px accent caps.
- Section labels: `SectionLabel` (10px bold caps, 1.8 spacing, fading rule).
- JetBrainsMono Nerd Font Material Design glyphs (`Icons.*`), 16px default;
  panel headers put theirs in an aurora badge (40px, radius 14).

## Motion

- `Theme.anim` 180ms for hover/color, `animSlow` 320ms for theme colors,
  `animGrow` 420ms OutQuint for anything growing out of the bar.
- Panels grow from height 0 (the top fillets swell with them), content fades in
  after 70ms and slides 16px; closing folds back in 220ms InCubic.
- Corners hand over instantly (the panel's fillet starts in the same place).
- Workspace drop: the edge in the direction of travel moves ~3× faster than
  the other, so it stretches. The active workspace opens into a minimap of
  its niri columns (to screen scale, stacked windows split, focused solid).
- Horizon: cursor light follows with a short lag; the comet crosses the
  screen in 1.1s (InOutCubic) with a white head and an accent2 tail.
- Media: equalizer bars step out of phase at 8 fps while playing. Nothing in
  the bar animates continuously (see the render-loop gotcha).
- Toggles overshoot (OutBack), badges pop in (OutBack), toasts slide in from the
  edge and drain a timer line (paused on hover).

## Interaction patterns

- Left click = primary, right click = secondary (cycle theme, pin/unpin,
  toggle DND, preferred player, forget device), middle click = quick toggle
  (play/pause, mute, Bluetooth power), scroll = adjust (volume, workspaces).
- Destructive actions are two-step: first press arms (fills red, "Confirm",
  draining 4s countdown), second runs.
- One popup at a time; clicking anywhere else (including the bar) closes it.
- Keyboard: Esc closes, Enter confirms, arrows/Tab move in lists, letter
  shortcuts in the power menu; sheets show their keys as keycaps.
- Hidden detail on hover (network interface name slides out).
