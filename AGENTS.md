# yuki

A Quickshell (QML) desktop shell for the niri compositor on NixOS: floating
"pill" bar, start menu, launcher, notifications, lock screen, per-output
wallpapers with Material You colors, clipboard history, screenshots, OSD,
Bluetooth/network/audio popups, settings panel. Ships SDDM + Plymouth themes in
the same design and a Nix flake (package, home-manager and NixOS modules).

Read this file first. Deeper context lives in `.agents/`:

| File | When |
| --- | --- |
| `.agents/architecture.md` | before touching services, theming, popups, lock |
| `.agents/conventions.md` | before writing any QML |
| `.agents/gotchas.md` | when something "should work" but doesn't (read it anyway) |
| `.agents/testing.md` | to verify a change in the running session |
| `.agents/design.md` | for anything visual |
| `.agents/skills/` | step-by-step recipes (also exposed to Claude Code via `.claude/skills`) |

## Quick facts

- Stack: Quickshell 0.3.x (Qt 6), niri, NixOS. QML modules are imported as
  `qs.<dir>` (`qs.config`, `qs.services`, `qs.components`, …).
- Entry: `shell.qml` (wallpapers, bars, toasts, launcher, lock, settings,
  clipboard, OSD, all `IpcHandler`s). `//@ pragma ShellId yuki` is load-bearing
  (it fixes the settings path); never remove it.
- Settings: `config/Settings.qml` → `~/.local/state/quickshell/by-shell/yuki/settings.json`
  (watched; edits apply live).
- Generated app colors: `~/.local/state/yuki/theme/` (niri, kitty, GTK, colors.json).
- The user's checkout is `~/source/shell` and usually runs live (hot reload);
  their dotfiles (`~/dotfiles`, NixOS flake, dendritic modules) consume this repo
  as `github:zaroc-dev/yuki`. See `~/dotfiles/HANDOFF.md`.

## Run / develop

```sh
qs -p .                                  # run from the checkout (hot reloads on save)
qs -p . ipc show                         # every IPC target/function
qs -p . ipc call shell reload true       # hard reload (recreates windows)
qs -p . ipc call bar toggle volume       # open a popup without clicking
nix flake check --no-build               # validate the flake
nix develop                              # quickshell, qmlls, qmlformat, nixfmt
```

A dev instance may already be running. Check before starting another
(`ps -eo pid,args | grep "[q]uickshell"`), and never `pkill -f` with a pattern
that also matches your own shell command (it kills the tool call).

## Rules

- **Theme tokens only.** No literal colors or sizes in widgets; use `Theme.*`
  (colors, `gap`, `radius`, `anim`) and `Icons.*` (Nerd Font glyphs, verify
  codepoints, see the add-bar-widget skill).
- **Match the surrounding code**: 4-space indent, `id: root` on the file root,
  `required property` for inputs, sparse comments that explain *why*.
- **Settings maps/lists are reassigned, never mutated** (`Settings.setIn(...)` or
  `Settings.d.x = [...]`), or they won't be saved.
- **Verify visually.** Run the change in the live session and screenshot it
  (`.agents/testing.md`). Say what you couldn't verify (hover/click, laptop-only).
- **Don't lock the real session** to test the lock screen; use
  `ipc call lock preview`. A crashed locker leaves niri locked.
- **Nix**: don't `nix build` unless asked; use `nix flake check --no-build` /
  `nix eval`. Format with `nixfmt`.
- **Commits**: Conventional Commits (`feat(scope):`, `fix(scope):`, `refactor!:`
  + `BREAKING CHANGE:` footer…), scopes = directory or feature (`bar`, `lock`,
  `theme`, `settings`, `media`, …). Commit/push only when asked.
- **Privacy**: the repo is public. Don't commit screenshots, personal paths
  beyond the README examples, or test data (names from real notifications etc.).
- License: Apache-2.0. `lib/mcu` is vendored Google material-color-utilities
  (Apache-2.0); only patched for QV4 compatibility (see gotchas). Don't reformat it.

## Open work

Tracked as GitHub issues on `zaroc-dev/yuki` (`gh issue list -R zaroc-dev/yuki`).
