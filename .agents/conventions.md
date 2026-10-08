# Conventions

## QML

- 4-space indent, qmlformat-ish style: one property per line, blank line between
  property groups and child objects, `id` first, then `required property`,
  `property`, `readonly property`, signals, functions, then visual properties,
  handlers, `Behavior`s, children.
- Root object `id: root`; reference ids explicitly (`root.player`), not `parent.parent`.
- Imports: `QtQuick`, `QtQuick.Layouts`, `Quickshell…`, then `qs.config`,
  `qs.components`, `qs.services`, `qs.popups`.
- Comments: short, explain *why* (constraint, workaround), not *what*.
- Inputs as `required property`; computed values as `readonly property`.
- Bindings over imperative updates; use functions on singletons for actions
  (`Audio.setVolume(node, v)`, `Wallpapers.set(screen, path)`).
- Inline components (`component Foo: Item {}`) at the document root.

## Building blocks (use them, don't re-roll)

| Need | Use |
| --- | --- |
| text | `StyledText` (theme font/color, color animation, elide) |
| glyph | `Icon { text: Icons.x }` (ink-centered) |
| app icon | `AppIcon { appId / iconName }` (falls back to a glyph) |
| bar chunk | `BarButton` (hover/pressed/active background, left/right/middle clicks) |
| round button | `IconButton` (`filled` for primary) |
| dropdown | `BarPopup { name; target }` + `Layout.fillWidth` header rows |
| switch / choice | `Toggle`, `Segmented { options: [{value,label,icon}] }` |
| slider | `StyledSlider` (`onMoved: v => …`) |
| settings row | `SettingRow { label; description; icon/appIcon; <control> }` inside `Section` inside `Page` |
| notification | `Notifs.notify({ summary, body, image, actions: [{ text, run }] })` |

## Settings

- Add a property to `config/Settings.qml`'s `JsonAdapter` with a sensible
  default; read as `Settings.d.foo`.
- Write scalars directly (`Settings.d.foo = v`); maps via
  `Settings.setIn("map", key, value)`; lists by reassigning a copy.
- Expose it in the matching `settings/*Page.qml`.

## IPC

- Targets live in `shell.qml` (`IpcHandler { target: "x" }`), typed params and
  return types (`function f(name: string): bool`). Keep names short and verb-y
  (`toggle`, `open`, `set`, `status`). Document new ones in the README IPC block.

## Nix

- `nix/*.nix` are `callPackage`-style; modules take `self` first. Keep option
  namespaces `programs.yuki` (HM and NixOS). Format with `nixfmt`.

## Git

- Conventional Commits, scope = feature/dir. Breaking changes `!` + footer.
- Don't commit generated files, screenshots or personal data.
