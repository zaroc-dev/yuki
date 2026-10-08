# Testing & verifying

There are no unit tests: verification means running the change in the user's
live niri session and looking at it. Report what you verified and what you
couldn't (hover, real clicks, laptop-only hardware).

## Tools

`grim` and `notify-send` may not be installed. Get them without touching the
user's profile:

```sh
S=<scratch dir>
nix build nixpkgs#grim nixpkgs#libnotify --out-link $S/tools   # grim in tools/, notify-send in tools-1/
```

(Ask first if the user's rules forbid `nix build`; `nix shell nixpkgs#grim -c grim …` also works.)

## Loop

1. Edit → Quickshell hot-reloads. Check the log (the dev instance's stdout, or
   `/run/user/$UID/quickshell/by-id/*/log.qslog`) for `WARN`/`ERROR` lines.
   Harmless noise: `dropped operation`, `QObject::connect(QJSEngine…nullptr`,
   portal app-id warnings.
2. Open things via IPC instead of clicking:
   `qs -p . ipc call bar toggle <start|media|calendar|notifications|bluetooth|network|volume|battery|power>`,
   `ipc call settings open <page>`, `ipc call launcher toggle`,
   `ipc call clipboard toggle`, `ipc call lock preview` (+ `closePreview`).
3. Screenshot a region, often zoomed:
   `grim -g "0,0 1920x52" -s 2 out.png`, or a whole output `grim -o DP-1 -s 0.5 out.png`.
   Read the PNG to look at it. Capture mid-animation with short sleeps to check
   motion. Sample exact pixels with `grim -g "x,y 1x1" -t ppm - | tail -c 3 | od -An -tu1`.
4. Close what you opened.

Overlay windows (launcher, clipboard, settings, lock preview) take exclusive
keyboard focus: open, screenshot, close quickly; the user is working.

## Notifications without fighting the real daemon

Run a second instance on a private D-Bus session so it owns
`org.freedesktop.Notifications`:

```sh
dbus-run-session -- sh -c '
  qs -p ~/source/shell & Q=$!; sleep 3
  notify-send -a Test "Summary" "Body <b>markup</b>"
  notify-send -a Test -A ok=OK "With action" "…" &   # -A blocks: background it
  notify-send -u critical -a Test "Critical" "…"
  sleep 1.5; grim -g "1400,0 520x560" toasts.png
  qs ipc --pid $Q call bar toggle notifications; sleep 1; grim … center.png
  kill $Q'
```

Use made-up names/content: screenshots of real notifications contain private data.

## Things that need care

- **Lock screen**: never lock the real session to test. `ipc call lock preview`
  exercises the same UI. A temporary IPC function that submits a dummy wrong
  password tests the PAM failure path (log shows `Failed to authenticate`);
  remove it afterwards.
- **Volume/screenshots/clipboard** touch real state: restore volume, delete test
  screenshots, remove test clipboard entries (`cliphist list | head -1` → `cliphist delete`).
- **Clicks/hover** can't be simulated. For hover visuals, temporarily force the
  state (e.g. an `objectName === "dbg"` check in `BarButton`), screenshot,
  revert. Don't commit debug hooks (grep for `TEMP`/`DBG` before committing).
- **SDDM theme**: `timeout 9 sddm-greeter-qt6 --test-mode --theme <copy-with-background-set>`
  opens real windows for a few seconds; screenshot them. Power buttons/keyboard
  layout are hidden in test mode.
- **Plymouth**: can't run outside boot; compose a static preview with
  `magick` from the generated PNGs.
- **niri/kitty snippets**: `niri validate -c <copy-of-config-with-include>`,
  `kitty +runpy "from kitty.config import load_config; load_config('<file>')"`.
- **Flake**: `nix flake check --no-build`, `nix eval .#packages.x86_64-linux.yuki.drvPath`;
  modules: evaluate a minimal `nixosSystem` / `homeManagerConfiguration` in a
  scratch flake that imports `github:zaroc-dev/yuki` (or `path:`).
