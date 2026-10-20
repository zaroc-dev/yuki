import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services

// Panel that grows out of the bar under a widget. Uses an xdg popup grab, so
// clicking into another app (or pressing Escape) dismisses it; clicks on the
// shell's own surfaces are handled by Ui.dismissPopup().
//
// The panel hangs flush from the bar's bottom edge and is drawn as one Surface
// with it (concave fillets at the join). Panels that would end up close to a
// screen edge snap to it and run down the edge like a drawer.
//
// Size changes animate: the frame glides to the content's size while the
// window keeps the larger of old/new size until a shrink has finished.
PopupWindow {
    id: root

    required property Item target
    // Name used by `qs ipc call bar toggle <name>`.
    property string name
    default property alias content: body.data
    // Full-bleed items behind the content (clipped to the panel).
    property alias backdrop: backdropSlot.data
    property int padding: 16
    property alias spacing: body.spacing
    property real minWidth: 0
    property double closedAt: 0
    // Compositors only grant a popup grab in response to input on the bar, so
    // popups opened from IPC (keybinds) go without and close on focus change.
    property bool grab: true
    property bool closing: false
    property bool snapLeft: false
    property bool snapRight: false
    // 0 = folded into the bar, 1 = fully grown.
    property real reveal: 0
    // Horizontal extent of the body in bar coordinates (for the bar's tab).
    property real barX: 0
    readonly property real barRight: barX + frame.width
    readonly property var barWindow: target.QsWindow.window

    // Size the content wants; the frame animates towards it.
    readonly property real targetWidth: Math.max(minWidth, body.implicitWidth + padding * 2)
    readonly property real targetHeight: body.implicitHeight + padding * 2
    property real windowWidth: targetWidth
    property real windowHeight: targetHeight

    // Key presses while the popup has keyboard focus (pointer-opened popups).
    signal keyPressed(var event)

    // Centers the panel under its target, or snaps it to a screen edge when it
    // would come close to one.
    function place() {
        const win = target.QsWindow.window;
        if (!win)
            return;
        const f = Theme.fillet;
        const reach = f + Theme.gap * 4;
        const p = target.mapToItem(win.contentItem, 0, 0);
        let x = Math.round(p.x + target.width / 2 - targetWidth / 2);
        snapLeft = x < reach;
        snapRight = !snapLeft && x + targetWidth > win.width - reach;
        if (snapLeft)
            x = 0;
        else if (snapRight)
            x = win.width - targetWidth;
        barX = x;
        anchor.rect.x = snapLeft ? 0 : snapRight ? win.width - windowWidth - f : x - f;
        anchor.rect.y = 0;
        anchor.rect.height = Theme.barHeight;
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
        reveal = 0;
        visible = true;
    }

    // Closed by us (not the compositor): fold back into the bar first unless immediate.
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
        openAnim.stop();
        closeAnim.restart();
    }

    onVisibleChanged: {
        if (visible) {
            Ui.shownPopup = root;
            openAnim.restart();
        } else {
            closing = false;
            reveal = 0;
            if (Ui.shownPopup === root)
                Ui.shownPopup = null;
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
    onWindowWidthChanged: {
        if (visible && snapRight)
            place();
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
    implicitWidth: windowWidth + (snapLeft ? 0 : Theme.fillet) + (snapRight ? 0 : Theme.fillet)
    // Room below the body for the edge fillet of a snapped panel.
    implicitHeight: windowHeight + Theme.fillet
    // Transparent slack (fillets, shrinking) must not eat clicks.
    mask: Region {
        item: clip
    }
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    SurfaceRegion {
        id: blurRegion

        bodyX: clip.x
        bodyWidth: clip.width
        bodyHeight: clip.height
        snapLeft: root.snapLeft
        snapRight: root.snapRight
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

    // Logical frame: carries the animated size; Surface and clip follow it.
    Item {
        id: frame

        x: root.snapLeft ? 0 : root.snapRight ? Theme.fillet + root.windowWidth - width : Theme.fillet
        width: root.targetWidth
        height: root.targetHeight

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
    }

    Surface {
        x: frame.x - bodyX
        bodyWidth: frame.width
        bodyHeight: clip.height
        snapLeft: root.snapLeft
        snapRight: root.snapRight
    }

    Item {
        id: clip

        x: frame.x
        width: frame.width
        height: Math.round(frame.height * root.reveal)
        clip: true
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onPressed: event => root.keyPressed(event)

        // Rounded like the Surface (square top, square on a snapped side).
        ClippingRectangle {
            id: backdropSlot

            width: clip.width
            height: clip.height
            visible: contentItem.children.length > 0
            color: "transparent"
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: root.snapLeft ? 0 : Math.min(Theme.radiusLarge, height / 2)
            bottomRightRadius: root.snapRight ? 0 : Math.min(Theme.radiusLarge, height / 2)
        }

        // Laid out at its own size and revealed by the (clipping) frame.
        ColumnLayout {
            id: body

            x: root.padding
            y: root.padding
            width: root.targetWidth - root.padding * 2
            spacing: 12

            transform: Translate {
                id: shift
            }
        }
    }

    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: root
            property: "reveal"
            from: 0
            to: 1
            duration: Theme.animGrow
            easing.type: Easing.OutQuint
        }
        SequentialAnimation {
            PropertyAction {
                target: body
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: 70
            }
            NumberAnimation {
                target: body
                property: "opacity"
                to: 1
                duration: 220
            }
        }
        NumberAnimation {
            target: shift
            property: "y"
            from: -16
            to: 0
            duration: Theme.animGrow
            easing.type: Easing.OutQuint
        }
    }

    SequentialAnimation {
        id: closeAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "reveal"
                to: 0
                duration: 220
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: body
                property: "opacity"
                to: 0
                duration: 120
            }
            NumberAnimation {
                target: shift
                property: "y"
                to: -10
                duration: 220
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: root.visible = false
        }
    }
}
