# Gotchas

Every one of these cost a debugging round. Check here before assuming a bug is
elsewhere.

## QML / Qt Quick

- **`visible` is *effective* visibility.** `visible: child.visible` on a parent
  deadlocks: once the parent hides, the child reports `false` forever. Bind
  both to the underlying condition (the media pill disappeared for good when the
  bar started without a player).
- **`Repeater.itemAt()` isn't reactive.** Bindings using it evaluate before the
  delegates exist and never update. Add a dependency:
  `{ row.width; repeater.count; return repeater.itemAt(i) }` (Segmented highlight,
  SDDM user/session lookup).
- **A hidden `Column` measures 0.** An accordion with
  `visible: implicitHeight > 0` and `implicitHeight: expanded ? column.implicitHeight : 0`
  never opens. Use `visible: opacity > 0` with an opacity animation.
- **`ColumnLayout { Layout.fillWidth: true }` doesn't grow** if none of its
  children can: a layout's max width comes from its children. Give the text
  children `Layout.fillWidth: true` too (Bluetooth header switch, settings ✕).
- **Rows with only `Layout.preferredWidth` don't stretch** to a wider parent
  layout; add `Layout.fillWidth: true`. `BarPopup`'s body has a fixed width.
- **`PropertyAction { value: x }` inside an animation restarted from
  `onXChanged`** can apply the *previous* value (handler runs before the
  `value` binding updates). Use `ScriptAction { script: target.prop = x }`
  (the active-window title showed the previous window).
- **JS arrays as models reset everything** on change; add/remove transitions
  never run. Wrap in `ScriptModel { values: array }` (Quickshell diffs it).
- **Calling a state-mutating function inside a binding** (e.g. requesting a
  thumbnail) risks binding loops; trigger it from `Component.onCompleted` and
  bind to the cached result.
- **`property alias x: someVarObject.y`** is invalid; aliases need `id.property`.
- **Inline `component`s**: declare them at the document root.
- **Nerd Font glyphs are off-center** in their advance box. `Icon` shifts by the
  ink (`TextMetrics.tightBoundingRect`); don't fight it with manual margins.

## QV4 (Qt's JS engine)

- No object spread (`{...a, ...b}`): use `Object.assign({}, a, b)`. Array
  spread is fine. Two spots in `lib/mcu` are patched for this (marked
  `patched: QV4 lacks object spread`); re-apply when updating the vendored lib.
- ES modules only via `.mjs` entry points (`import "../lib/material.mjs" as M`);
  imported `.js` files inside a module are fine. Use mcu **0.3.0**: 0.4.0 has
  broken extensionless imports.
- `WorkerScript` with an `.mjs` source works; send messages only after
  `worker.ready` (earlier ones are dropped silently).
- Canvas `drawImage(item)` of an `Image` with opacity 0 yields transparent
  pixels; use `loadImage(url)` + `drawImage(url, …)`.

## Quickshell / Wayland / niri

- **xdg-popup grabs** are only granted in response to input on the parent
  (opening from IPC fails with "Failed to create grabbing popup"), and they
  only dismiss on clicks into *other* clients. Hence `grab: fromPointer` and
  `Ui.dismissPopup()`.
- **Two grabbing popups at once** re-parents the second to the first and
  misplaces it. `Ui.activePopup` enforces one.
- **Moving a window between outputs** (changing `screen`) recreates its surface
  and drops `BackgroundEffect` blur. Use one window per screen and toggle
  `visible` (toasts, OSD).
- **ShellId**: without `//@ pragma ShellId yuki` the state dir is derived from
  the config *path*: store builds would get empty settings. Pragmas only apply
  at process start (restart, not reload). The first reload after changing it
  on a running instance failed to resolve `qs.*` modules: restart instead.
- Soft reloads reuse windows; stale layer surfaces can survive
  (`ipc call shell reload true` for a hard reload).
- `WlSessionLock`: if the client dies while locked, niri stays locked by design.
  Test with `ipc call lock preview`.
- Only one `org.freedesktop.Notifications` owner: another daemon (noctalia,
  mako) means yuki shows no toasts until it exits.
- Layer surfaces on the same layer stack by creation order: `Backdrop` is
  created before `Wallpaper` so it stays below until niri's
  `place-within-backdrop` rule is active.
- The bar's `Loader { active: Lock.capturing }` with an invisible full-size
  `ScreencopyView` is how lock snapshots are taken; it's intentional.
- niri sends its own "Screenshot captured" notification; `Notifs` expires it.
- kitty's `globinclude` rejects absolute patterns; use `include /abs/path`
  (missing file = warning only). niri: `include optional=true "/abs/path"`.

## Shell commands while developing

- `pkill -f <pattern>` / `pgrep -f` match **your own** `zsh -c "…"` command
  line when the pattern appears in it, so the tool call kills itself (exit 144). Use
  PIDs, or a bracket trick: `pgrep -f "[q]uickshell -p"`.
- `notify-send -A …` blocks until an action is chosen: background it.
- `sddm --version` hangs; use `sddm-greeter-qt6 --test-mode --theme <dir>`
  (with `timeout`).
- Foreground `sleep` is blocked in some agent harnesses; `python3 -c
  "import time; time.sleep(n)"` works.
