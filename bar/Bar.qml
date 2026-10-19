import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// The frostline: one frosted strip fused to the top of the screen. Its ends
// curve down into the screen edges (rounded screen corners), the clock hangs
// from the middle in a tab, and panels grow out of its bottom edge. Whatever
// hangs from the bar takes over the piece of outline it covers: a panel
// snapped to an edge replaces that corner, anything under the clock folds
// the tab away.
PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property string output: modelData.name

    // What currently hangs from this bar.
    readonly property var popup: Ui.shownPopup && Ui.shownPopup.barWindow === root ? Ui.shownPopup : null
    readonly property bool toastsHere: Ui.toastScreen === output
    // The OSD and the launcher/clipboard sheets hang from the middle of the bar.
    readonly property bool centerClaimed: Ui.osdScreen === output || Ui.sheetScreen === output

    // ---- tab ----
    readonly property real shoulder: 28
    readonly property real tabHalf: Math.round(clock.implicitWidth / 2) + 10
    readonly property real tabLeft: Math.round(width / 2) - tabHalf
    readonly property real tabRight: Math.round(width / 2) + tabHalf
    readonly property bool tabCovered: centerClaimed || (popup !== null && !popup.closing && popup.barX < tabRight + shoulder && popup.barRight > tabLeft - shoulder)
    property real tabDepth: tabCovered ? 0 : Theme.tabDepth

    // Corners hand over to a snapped panel/drawer without animating: at that
    // moment the panel's own edge fillet sits exactly where the corner was.
    readonly property real cornerLeft: popup?.snapLeft ? 0 : Theme.fillet
    readonly property real cornerRight: popup?.snapRight || toastsHere ? 0 : Theme.fillet

    // ---- elastic titles ----
    // Room for each side, from parts whose width never depends on a title
    // (measuring the rows would feed back into the budget, see gotchas).
    readonly property real sideRoom: tabLeft - shoulder - edgePad - Theme.gap * 2
    readonly property real edgePad: 10
    readonly property real leftFixed: start.implicitWidth + (launcher.visible ? launcher.implicitWidth + leftRow.spacing : 0) + workspaces.implicitWidth + activeWindow.fixedWidth + leftRow.spacing * 2
    readonly property real rightFixed: (media.visible ? media.fixedWidth + rightRow.spacing : 0) + (tray.visible ? tray.implicitWidth + rightRow.spacing : 0) + status.implicitWidth + notif.implicitWidth + power.implicitWidth + rightRow.spacing * 2

    // Outline as an SVG path. The corner arcs run counterclockwise (sweep 0).
    function outline(w, h, cl, cr, tl, tr, depth, s) {
        const arc = (r, x, y) => r < 0.5 ? ` L ${x} ${y}` : ` A ${r} ${r} 0 0 0 ${x} ${y}`;
        let d = `M 0 0 L ${w} 0 L ${w} ${h + cr}` + arc(cr, w - cr, h);
        if (depth > 0.25) {
            // Smooth drip: horizontal tangents at both ends of each shoulder.
            d += ` L ${tr + s} ${h} C ${tr + s / 2} ${h} ${tr + s / 2} ${h + depth} ${tr} ${h + depth}`;
            d += ` L ${tl} ${h + depth} C ${tl - s / 2} ${h + depth} ${tl - s / 2} ${h} ${tl - s} ${h}`;
        }
        d += ` L ${cl} ${h}` + arc(cl, 0, h + cl) + " Z";
        return d;
    }

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + Theme.fillet
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "yuki-bar"

    Behavior on tabDepth {
        NumberAnimation {
            duration: Theme.animGrow
            easing.type: Easing.OutQuint
        }
    }

    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    Region {
        id: blurRegion

        Region {
            width: root.width
            height: Theme.barHeight
        }
        Region {
            x: root.tabLeft - root.shoulder / 3
            y: Theme.barHeight - root.tabDepth
            width: root.tabRight - root.tabLeft + root.shoulder * 2 / 3
            height: root.tabDepth * 2
            radius: root.tabDepth
        }
    }

    // The strip and the tab take input; the fillets let clicks through.
    mask: Region {
        Region {
            width: root.width
            height: Theme.barHeight
        }
        Region {
            x: root.tabLeft
            y: Theme.barHeight
            width: root.tabRight - root.tabLeft
            height: root.tabDepth
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Theme.barBg
            strokeWidth: -1

            PathSvg {
                path: root.outline(root.width, Theme.barHeight, root.cornerLeft, root.cornerRight, root.tabLeft, root.tabRight, root.tabDepth, root.shoulder)
            }
        }
    }

    // Sees every press first (without taking it) to dismiss open popups.
    MouseArea {
        anchors.fill: parent
        z: 1000
        acceptedButtons: Qt.AllButtons
        onPressed: mouse => {
            Ui.dismissPopup(this, mouse.x, mouse.y);
            mouse.accepted = false;
        }
    }

    Row {
        id: leftRow

        x: root.edgePad
        y: (Theme.barHeight - height) / 2
        height: Theme.barHeight - 10
        spacing: 6

        StartButton {
            id: start
        }

        LauncherButton {
            id: launcher
        }

        Workspaces {
            id: workspaces

            output: root.output
        }

        ActiveWindow {
            id: activeWindow

            output: root.output
            titleMax: root.sideRoom - root.leftFixed
        }
    }

    Clock {
        id: clock

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round((Theme.barHeight + root.tabDepth - height) / 2)
        height: Theme.barHeight - 6
    }

    Row {
        id: rightRow

        anchors.right: parent.right
        anchors.rightMargin: root.edgePad
        y: (Theme.barHeight - height) / 2
        height: Theme.barHeight - 10
        spacing: 6

        MediaWidget {
            id: media

            titleMax: root.sideRoom - root.rightFixed
        }

        Tray {
            id: tray
        }

        // Status icons share one inset well.
        Rectangle {
            id: status

            implicitWidth: statusRow.implicitWidth + 4
            height: parent.height
            radius: height / 2
            color: Theme.well

            Row {
                id: statusRow

                anchors.centerIn: parent
                height: parent.height - 4
                spacing: 0

                BluetoothWidget {}
                NetworkWidget {}
                VolumeWidget {}
                BatteryWidget {}
            }
        }

        NotificationButton {
            id: notif
        }

        PowerButton {
            id: power
        }
    }
}
