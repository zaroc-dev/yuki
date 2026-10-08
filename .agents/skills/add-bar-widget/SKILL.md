---
name: add-bar-widget
description: Add a new widget to yuki's bar (icon/label button, optional dropdown popup, IPC name, settings toggle, Nerd Font glyph lookup). Use when adding or restructuring anything in the top bar.
---

# Add a bar widget

1. **Service first.** If it needs data, add or extend a singleton in
   `services/` (`pragma Singleton`, root `Singleton`, `readonly` properties,
   action functions). Lazy singletons only start when referenced; if it must run
   from launch, add it to `services: [...]` in `shell.qml`.
2. **Glyph.** Find the Material Design codepoint in the Nerd Fonts list:
   `curl -sL https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json`
   → key `md-<name>` → `code`. Add it to `config/Icons.qml` as
   `readonly property string foo: "\u{f0xxx}"`. Never guess codepoints.
3. **Widget** `bar/FooWidget.qml`:
   ```qml
   BarButton {
       id: root

       hPadding: 7
       active: popup.visible
       onClicked: e => e.button === Qt.MiddleButton ? quickAction() : popup.toggle()

       Icon {
           anchors.verticalCenter: parent.verticalCenter
           text: Icons.foo
       }

       FooPopup {
           id: popup

           name: "foo"          // ipc call bar toggle foo
           target: root
       }
   }
   ```
   Hide when unavailable with `visible: <condition>` (bind to the data, never
   to a child's `visible`).
4. **Popup** `popups/FooPopup.qml`: `BarPopup { … }`, first row
   `RowLayout { Layout.preferredWidth: 340; Layout.fillWidth: true }`, text
   columns with `Layout.fillWidth: true` on their texts. Lists with
   `ScriptModel`, expanding parts with height+opacity animation (gotchas.md).
5. **Place it** in `bar/Bar.qml` inside the right pill group; add `Separator {}`
   between groups, not between every item.
6. **Optional toggle**: `Settings.d.showFoo` + a `SettingRow`/`Toggle` in
   `settings/BarPage.qml` (see the add-setting skill).
7. **Docs**: README bar table / IPC list if you added an IPC name.
8. **Verify** with the verify-in-session skill: zoomed bar screenshot, popup via
   `ipc call bar toggle foo`, light mode (`ipc call theme mode light`) and back.
