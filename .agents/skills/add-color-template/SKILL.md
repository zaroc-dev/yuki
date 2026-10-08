---
name: add-color-template
description: Make another program follow yuki's theme by generating a color file from the palette (like the niri, kitty and GTK templates). Use for requests like "theme Vencord/Zen/qt6ct/starship with the wallpaper colors".
---

# Add an app color template

All templates live in `services/Templates.qml`; output goes to
`~/.local/state/yuki/theme/` (outside the read-only Nix store, so the user's
configs include/import it).

1. **Find the format** the app reads and how it reloads (signal, file watch,
   CLI). Prefer an include/import mechanism in the app's config that tolerates
   a missing file.
2. **Render function** in `Templates.qml`: `function foo() { return \`…\` }`
   using `m.<materialRole>` (all Material roles: `primary`, `onPrimary`,
   `surface`, `surfaceContainer*`, `onSurface`, `outlineVariant`, `error`, …) and
   `p.<name>` for named hues (`p.red`, `p.green`, …). `hex(c)` strips alpha,
   `alpha(c, 0.5)` appends one. `Theme.lightMode` for mode-dependent bits.
3. **Write it** in `write()`, gated by `enabled("foo")`, via a new `FileView`
   (`atomicWrites: true`, `printErrors: false`). Add a reload `Process` if the
   app needs a nudge.
4. **Toggle** in `settings/AppearancePage.qml` → "Colors in other apps" repeater
   (`{ key: "foo", label, description }`).
5. **Validate** the generated file with the app's own parser if it has one
   (`niri validate`, `kitty +runpy load_config(...)`), and check it changes when
   `ipc call theme scheme vibrant` / `theme mode light` run (then restore).
6. **Docs**: README "App colors" + tell the user which include line their
   dotfiles need (`~/dotfiles/HANDOFF.md` style).
