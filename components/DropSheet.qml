import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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

    // Dim below the bar with the sheet's outline cut out.
    Shape {
        anchors.fill: parent
        opacity: root.reveal

        ShapePath {
            fillColor: Qt.alpha(Theme.crust, 0.45)
            fillRule: ShapePath.OddEvenFill
            strokeWidth: -1

            PathSvg {
                path: `M 0 ${Theme.barHeight} L ${root.width} ${Theme.barHeight} L ${root.width} ${root.height} L 0 ${root.height} Z ` + surface.outline(root.bodyWidth, clip.height, Theme.fillet, Theme.radiusLarge, false, false, root.bodyX - Theme.fillet, Theme.barHeight)
            }
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
