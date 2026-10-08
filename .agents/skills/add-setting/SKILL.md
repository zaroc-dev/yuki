---
name: add-setting
description: Add a persisted user setting to yuki (Settings.qml JsonAdapter property, settings-page control, live binding). Use when something should be configurable.
---

# Add a setting

1. **Property** in `config/Settings.qml` → `JsonAdapter { id: adapter … }`,
   grouped under the matching `// ---- section ----` comment:
   `property bool showFoo: true` (scalars) or `property var fooMap: ({})` /
   `property var fooList: []`. Defaults must be good without any settings file.
2. **Read** it anywhere as `Settings.d.showFoo` (import `qs.config`). Bindings
   update live, including when the user edits the JSON by hand.
3. **Write** scalars directly (`Settings.d.showFoo = v`). Maps:
   `Settings.setIn("fooMap", key, value)` (`undefined` deletes). Lists: assign a
   new array. Mutating in place is **not** saved.
4. **UI** in the right `settings/*Page.qml`:
   ```qml
   Section {
       title: "Group"

       SettingRow {
           icon: Icons.foo
           label: "Show foo"
           description: "What it does, in one line"

           Toggle {
               checked: Settings.d.showFoo
               onToggled: v => Settings.d.showFoo = v
           }
       }
   }
   ```
   Choices: `Segmented { options: [{ value, label, icon }]; value; onSelected }`.
   Ranges: `StyledSlider { from; to; step; value; onMoved }`. New page: add it
   to `pages` and the `Loader` map in `settings/SettingsWindow.qml`.
5. **IPC** (optional) if a keybind should flip it: `IpcHandler` in `shell.qml`.
6. **Verify**: `ipc call settings open <page>`, screenshot, flip the value via
   the JSON file (watched) and confirm the UI follows.
