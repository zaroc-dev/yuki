---
name: verify-in-session
description: Run yuki in the user's live niri session and check a change visually (reload, logs, IPC, grim screenshots, isolated notification tests, lock preview). Use after any QML change, before saying something works.
---

# Verify a change in the live session

Full background: `.agents/testing.md`. Short version:

1. **Is a dev instance running?**
   `ps -eo pid,lstart,args | grep "[q]uickshell -p"`. If none, start one detached:
   `(qs -p ~/source/shell > "$S/qs.log" 2>&1 &)`. Never `pkill -f` a pattern that
   appears in your own command line; kill by PID.
2. **Reload & read the log.** Saving reloads automatically. Read new log lines
   only (`N=$(wc -l < log)` before, `tail -n +$N` after) and look for
   `WARN scene` / `ERROR`. Ignore `dropped operation`, `QObject::connect(QJSEngine…`,
   portal warnings. `qs -p . ipc call shell reload true` = hard reload.
3. **Open the thing via IPC** (`qs -p . ipc show` for the list):
   `bar toggle <name>`, `settings open <page>`, `launcher toggle`,
   `clipboard toggle`, `lock preview`/`closePreview`, `media status`.
4. **Screenshot**: `grim -g "x,y wxh" -s 2 "$S/x.png"` (get grim via
   `nix build nixpkgs#grim --out-link "$S/tools"` if missing) and Read the PNG.
   For motion, grab at ~100ms and ~600ms after triggering.
5. **Close what you opened**, restore anything you changed (volume, files,
   clipboard entries), remove temporary debug hooks (`grep -rn "TEMP\|DBG"`).
6. **Report** what you saw, and what you couldn't verify (hover, real clicks,
   laptop-only features like Wi-Fi/brightness/battery).

Notifications: test in a private bus (`dbus-run-session`), see testing.md, with
invented content. Lock screen: only `lock preview`, never a real lock.
