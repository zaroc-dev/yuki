import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Dropdown attached below a bar widget. Uses an xdg popup grab, so clicking
// into another app (or pressing Escape) dismisses it; clicks on the shell's own
// surfaces are handled by Ui.dismissPopup().
//
// Size changes animate: the frame glides to the content's size while the
// window keeps the larger of old/new size until a shrink has finished.
PopupWindow {
    id: root

    required property Item target
    // Name used by `qs ipc call bar toggle <name>`.
    property string name
    default property alias content: body.data
    property int padding: 14
    property alias spacing: body.spacing
    property real minWidth: 0
    property double closedAt: 0
    // Compositors only grant a popup grab in response to input on the bar, so
    // popups opened from IPC (keybinds) go without and close on focus change.
    property bool grab: true
    property bool closing: false

    // Size the content wants; the frame animates towards it.
    readonly property real targetWidth: Math.max(minWidth, body.implicitWidth + padding * 2)
    readonly property real targetHeight: body.implicitHeight + padding * 2
    property real windowWidth: targetWidth
    property real windowHeight: targetHeight

    // Key presses while the popup has keyboard focus (pointer-opened popups).
    signal keyPressed(var event)

    // Centers the popup under its target, kept inside the bar's side gutters,
    // hanging from the bottom of the pills rather than the button itself.
    function place() {
        const win = target.QsWindow.window;
        if (!win)
            return;
        const p = target.mapToItem(win.contentItem, 0, 0);
        const x = p.x + target.width / 2 - targetWidth / 2;
        anchor.rect.x = Math.round(Math.max(Theme.gap, Math.min(win.width - Theme.gap - targetWidth, x)));
        anchor.rect.height = win.height;
    }

    function toggle(fromPointer = true) {
        if (visible) {
            close();
            return;
        }
        // The click that dismissed the grab may also land on the bar button;
        // don't let it immediately reopen the popup.
        if (Date.now() - closedAt < 300)
            return;
        if (Ui.activePopup && Ui.activePopup !== root)
            Ui.activePopup.close(true);
        closeAnim.stop();
        closing = false;
        windowWidth = targetWidth;
        windowHeight = targetHeight;
        place();
        grab = fromPointer;
        Ui.activePopup = root;
        visible = true;
    }

    // Closed by us (not the compositor): fade out first unless immediate.
    function close(immediate = false) {
        if (!visible || closing)
            return;
        if (Ui.activePopup === root)
            Ui.activePopup = null;
        if (immediate) {
            visible = false;
            return;
        }
        closing = true;
        closeAnim.restart();
    }

    onVisibleChanged: {
        if (visible) {
            openAnim.restart();
        } else {
            closing = false;
            // Still registered = dismissed by the compositor; guard against
            // the same click reopening it.
            if (Ui.activePopup === root) {
                closedAt = Date.now();
                Ui.activePopup = null;
            }
        }
    }

    onTargetWidthChanged: {
        windowWidth = Math.max(windowWidth, targetWidth);
        shrink.restart();
        if (visible)
            place();
    }
    onTargetHeightChanged: {
        windowHeight = Math.max(windowHeight, targetHeight);
        shrink.restart();
    }

    // Let a shrink animation finish before the window gets smaller.
    Timer {
        id: shrink

        interval: 260
        onTriggered: {
            root.windowWidth = root.targetWidth;
            root.windowHeight = root.targetHeight;
        }
    }

    anchor.window: target.QsWindow.window
    anchor.rect.width: 1
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide
    grabFocus: grab
    color: "transparent"
    implicitWidth: windowWidth
    implicitHeight: windowHeight + Theme.gap
    // Transparent slack (while shrinking) must not eat clicks.
    mask: Region {
        item: frame
    }
    BackgroundEffect.blurRegion: Region {
        item: Theme.blur ? frame : null
        radius: Theme.radius
    }

    Connections {
        target: Ui

        function onPopupRequested(name: string, output: string): void {
            if (name === root.name && output === root.target.QsWindow.window?.screen?.name && root.target.visible)
                root.toggle(false);
        }
    }

    Connections {
        target: Niri
        enabled: root.visible && !root.grab

        function onFocusedWindowIdChanged(): void {
            root.close();
        }
    }

    Rectangle {
        id: frame

        y: Theme.gap
        width: root.targetWidth
        height: root.targetHeight
        radius: Theme.radius
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.barBorder
        clip: true
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onPressed: event => root.keyPressed(event)

        Behavior on width {
            enabled: root.visible && !openAnim.running
            SmoothedAnimation {
                duration: 240
                velocity: -1
            }
        }
        Behavior on height {
            enabled: root.visible && !openAnim.running
            SmoothedAnimation {
                duration: 240
                velocity: -1
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Theme.animSlow
            }
        }

        // Laid out at its own size and revealed by the (clipping) frame.
        ColumnLayout {
            id: body

            x: root.padding
            y: root.padding
            width: root.targetWidth - root.padding * 2
            spacing: 10
        }

        transform: Translate {
            id: shift
        }
    }

    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: frame
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.anim
        }
        NumberAnimation {
            target: shift
            property: "y"
            from: -8
            to: 0
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: closeAnim

        ParallelAnimation {
            NumberAnimation {
                target: frame
                property: "opacity"
                to: 0
                duration: 130
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: shift
                property: "y"
                to: -6
                duration: 130
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: root.visible = false
        }
    }
}
