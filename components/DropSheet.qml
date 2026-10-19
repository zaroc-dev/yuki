import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Keyboard-focused overlay (launcher, clipboard) on the focused output: a
// sheet that grows out of the middle of the bar. Everything below the bar
// dims except the sheet, whose outline is cut out of the dim so it stays one
// surface with the bar. Clicking outside emits dismissed().
PanelWindow {
    id: root

    default property alias content: column.data
    property alias spacing: column.spacing
    property real bodyWidth: 620
    property real padding: 14
    readonly property real bodyX: Math.round((width - bodyWidth) / 2)
    property real bodyHeight: column.implicitHeight + padding * 2
    property real reveal: 0

    signal dismissed

    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null
    Component.onCompleted: {
        Ui.sheetWidth = bodyWidth;
        Ui.sheetScreen = screen?.name ?? "";
        reveal = 1;
    }
    Component.onDestruction: {
        if (Ui.sheetScreen === screen?.name)
            Ui.sheetScreen = "";
    }

    Behavior on reveal {
        NumberAnimation {
            duration: Theme.animGrow
            easing.type: Easing.OutQuint
        }
    }
    Behavior on bodyHeight {
        enabled: root.reveal === 1
        SmoothedAnimation {
            duration: 200
            velocity: -1
        }
    }

    SurfaceRegion {
        id: blurRegion

        bodyX: root.bodyX
        bodyY: Theme.barHeight
        bodyWidth: root.bodyWidth
        bodyHeight: clip.height
    }

    // Dim below the bar around the sheet, pieced together like the Surface
    // (a cut-out path would re-tessellate full screen every frame).
    Item {
        id: dim

        readonly property color tint: Qt.alpha(Theme.crust, 0.45)
        readonly property real y0: Theme.barHeight
        readonly property real x0: root.bodyX
        readonly property real x1: root.bodyX + root.bodyWidth

        anchors.fill: parent
        opacity: root.reveal

        Rectangle {
            y: dim.y0
            width: dim.x0 - surface.ft
            height: root.height - dim.y0
            color: dim.tint
        }
        Rectangle {
            x: dim.x1 + surface.ft
            y: dim.y0
            width: root.width - x
            height: root.height - dim.y0
            color: dim.tint
        }
        // Under the fillets: what the fillet doesn't cover, and the strip below.
        Corner {
            x: dim.x0 - size
            y: dim.y0
            size: surface.ft
            band: size
            color: dim.tint
        }
        Corner {
            x: dim.x1
            y: dim.y0
            size: surface.ft
            band: size
            flipX: true
            color: dim.tint
        }
        Rectangle {
            x: dim.x0 - surface.ft
            y: dim.y0 + surface.ft
            width: surface.ft
            height: root.height - y
            color: dim.tint
        }
        Rectangle {
            x: dim.x1
            y: dim.y0 + surface.ft
            width: surface.ft
            height: root.height - y
            color: dim.tint
        }
        // Below the sheet, and outside its rounded bottom corners.
        Rectangle {
            x: dim.x0
            y: dim.y0 + clip.height
            width: root.bodyWidth
            height: root.height - y
            color: dim.tint
        }
        Corner {
            x: dim.x0
            y: dim.y0 + clip.height - size
            size: surface.rr
            flipX: true
            flipY: true
            color: dim.tint
        }
        Corner {
            x: dim.x1 - size
            y: dim.y0 + clip.height - size
            size: surface.rr
            flipY: true
            color: dim.tint
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Surface {
        id: surface

        x: root.bodyX - Theme.fillet
        y: Theme.barHeight
        bodyWidth: root.bodyWidth
        bodyHeight: clip.height
    }

    Item {
        id: clip

        x: root.bodyX
        y: Theme.barHeight
        width: root.bodyWidth
        height: Math.round(root.bodyHeight * root.reveal)
        clip: true

        // Swallow clicks so they don't dismiss the sheet.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: column

            x: root.padding
            y: root.padding - (1 - root.reveal) * 16
            width: parent.width - root.padding * 2
            opacity: root.reveal
            spacing: 10
        }
    }
}
