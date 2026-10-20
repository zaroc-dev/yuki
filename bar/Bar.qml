import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// The frostline: one frosted strip fused to the top of the screen. Its ends
// curve down into the screen edges (rounded screen corners) and panels grow
// out of its bottom edge. Along that edge runs the horizon, a thin aurora
// line that opens wherever something hangs from the bar and carries on around
// it. Light gathers on it: under the cursor, where a panel joins, in a sun
// that crosses the screen once a day, and in a comet that shoots across to
// the corner the toasts drop from when a notification arrives.
PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property string output: modelData.name

    // What currently hangs from this bar.
    readonly property var popup: Ui.shownPopup && Ui.shownPopup.barWindow === root ? Ui.shownPopup : null
    readonly property bool toastsHere: Ui.toastScreen === output
    readonly property bool osdHere: Ui.osdScreen === output
    readonly property bool sheetHere: Ui.sheetScreen === output

    // Corners hand over to a snapped panel/drawer without animating: at that
    // moment the panel's own edge fillet sits exactly where the corner was.
    readonly property real cornerLeft: popup?.snapLeft ? 0 : Theme.fillet
    readonly property real cornerRight: popup?.snapRight || toastsHere ? 0 : Theme.fillet

    // Stretches of the bottom edge taken by something hanging from the bar
    // (body plus its fillets); the horizon breaks there and the hanging
    // surface's own rim carries it on.
    readonly property var joins: {
        const f = Theme.fillet, w = width, mid = w / 2, out = [];
        if (popup)
            out.push([popup.snapLeft ? 0 : popup.barX - f, popup.snapRight ? w : popup.barRight + f]);
        if (osdHere)
            out.push([mid - Ui.osdWidth / 2 - f, mid + Ui.osdWidth / 2 + f]);
        if (sheetHere)
            out.push([mid - Ui.sheetWidth / 2 - f, mid + Ui.sheetWidth / 2 + f]);
        if (toastsHere)
            out.push([w - 400 - f, w]);
        return out.sort((a, b) => a[0] - b[0]);
    }

    // Follows the cursor with a little lag, like light through frost.
    property real lightX: hover.point.position.x
    property real cursorLight: hover.hovered ? 1 : 0
    readonly property real sunX: width * (day.date.getHours() * 60 + day.date.getMinutes()) / 1440

    // ---- comet ----
    readonly property var newestToast: Notifs.popups[0] ?? null
    // Notification ids only grow; older ones resurfacing (when the newest
    // goes away) don't fire it again.
    property int seenToast: -1
    property real cometX: -300
    property real cometPower: 0

    // ---- elastic titles ----
    // Room for each side, from parts whose width never depends on a title
    // (measuring the rows would feed back into the budget, see gotchas).
    readonly property real sideRoom: Math.round(width / 2) - Math.round(clock.implicitWidth / 2) - edgePad - Theme.gap * 3
    readonly property real edgePad: 10
    readonly property real leftFixed: start.implicitWidth + (launcher.visible ? launcher.implicitWidth + leftRow.spacing : 0) + workspaces.implicitWidth + activeWindow.fixedWidth + leftRow.spacing * 2
    readonly property real rightFixed: (media.visible ? media.fixedWidth + rightRow.spacing : 0) + (tray.visible ? tray.implicitWidth + rightRow.spacing : 0) + status.implicitWidth + notif.implicitWidth + power.implicitWidth + rightRow.spacing * 2

    // Outline as an SVG path. The corner arcs run counterclockwise (sweep 0).
    function outline(w, h, cl, cr) {
        const arc = (r, x, y) => r < 0.5 ? ` L ${x} ${y}` : ` A ${r} ${r} 0 0 0 ${x} ${y}`;
        return `M 0 0 L ${w} 0 L ${w} ${h + cr}` + arc(cr, w - cr, h) + ` L ${cl} ${h}` + arc(cl, 0, h + cl) + " Z";
    }

    // The horizon as a fill: a band lw thick along the inside of the bottom
    // edge and corners (concentric arcs), minus the joins. Lights are
    // gradients over the same band, so nothing renders offscreen.
    function horizon(w, h, cl, cr, joins, lw) {
        let free = [[cl, w - cr]];
        for (const [a, b] of joins)
            free = free.reduce((out, [x0, x1]) => out.concat([[x0, Math.min(x1, a)], [Math.max(x0, b), x1]]), []);
        free = free.filter(([x0, x1]) => x1 - x0 > 0.5);
        let d = "";
        for (const [x0, x1] of free) {
            const leftCorner = x0 === cl && cl > 0;
            const rightCorner = x1 === w - cr && cr > 0;
            d += leftCorner ? `M ${-lw} ${h + cl} A ${cl + lw} ${cl + lw} 0 0 1 ${cl} ${h - lw}` : `M ${x0} ${h - lw}`;
            d += ` L ${x1} ${h - lw}`;
            d += rightCorner ? ` A ${cr + lw} ${cr + lw} 0 0 1 ${w + lw} ${h + cr} L ${w} ${h + cr} A ${cr} ${cr} 0 0 0 ${x1} ${h}` : ` L ${x1} ${h}`;
            d += ` L ${x0} ${h}`;
            d += leftCorner ? ` A ${cl} ${cl} 0 0 0 0 ${h + cl} Z ` : " Z ";
        }
        // Where a panel's fillet rim leaves the bar it starts out flat along
        // the bar's edge, above the panel's window, so the panel can't draw
        // that bit: the bar draws the part of the arc inside its strip.
        const f = Theme.fillet, r = f + lw, dx = Math.sqrt(r * r - f * f);
        for (const [a, b] of joins) {
            if (a > 0.5)
                d += `M ${a} ${h - lw} A ${r} ${r} 0 0 1 ${a + dx} ${h} L ${a} ${h} Z `;
            if (b < w - 0.5)
                d += `M ${b} ${h - lw} A ${r} ${r} 0 0 0 ${b - dx} ${h} L ${b} ${h} Z `;
        }
        return d;
    }
    readonly property string band: horizon(width, Theme.barHeight, cornerLeft, cornerRight, joins, Theme.horizonWidth)

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

    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null
    Component.onCompleted: seenToast = newestToast?.id ?? -1
    onNewestToastChanged: {
        if (!newestToast || newestToast.id <= seenToast)
            return;
        seenToast = newestToast.id;
        if (Niri.focusedOutput === output)
            comet.restart();
    }

    Behavior on cursorLight {
        NumberAnimation {
            duration: Theme.animSlow
        }
    }
    Behavior on lightX {
        SmoothedAnimation {
            velocity: 2400
        }
    }

    Region {
        id: blurRegion

        width: root.width
        height: Theme.barHeight
    }

    // The strip takes input; the fillets let clicks through.
    mask: Region {
        width: root.width
        height: Theme.barHeight
    }

    SystemClock {
        id: day

        precision: SystemClock.Minutes
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Under every widget and non-blocking, so it only watches the cursor.
        // On the topmost item it kept the buttons from getting hover-leave
        // (their hover capsules stayed lit).
        HoverHandler {
            id: hover

            blocking: false
        }

        ShapePath {
            fillColor: Theme.barBg
            strokeWidth: -1

            PathSvg {
                path: root.outline(root.width, Theme.barHeight, root.cornerLeft, root.cornerRight)
            }
        }

        // Resting aurora across the whole width.
        ShapePath {
            strokeWidth: -1
            fillGradient: LinearGradient {
                x1: 0
                x2: root.width

                GradientStop {
                    position: 0
                    color: Qt.alpha(Theme.accent, Theme.horizonRest)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(Theme.accent2, Theme.horizonRest)
                }
            }

            PathSvg {
                path: root.band
            }
        }

        // The sun: crosses the horizon once a day, left at midnight.
        Light {
            path: root.band
            from: root.sunX
            to: root.sunX
            reach: 180
            tint: Theme.accent2
            strength: 0.7
        }

        // Where panels join the bar (both ends of each join).
        Light {
            path: root.band
            from: root.joins[0]?.[0] ?? 0
            to: root.joins[0]?.[1] ?? 0
            strength: root.joins.length > 0 ? 0.9 : 0
        }
        Light {
            path: root.band
            from: root.joins[1]?.[0] ?? 0
            to: root.joins[1]?.[1] ?? 0
            strength: root.joins.length > 1 ? 0.9 : 0
        }
        Light {
            path: root.band
            from: root.joins[2]?.[0] ?? 0
            to: root.joins[2]?.[1] ?? 0
            strength: root.joins.length > 2 ? 0.9 : 0
        }

        // Comet: a long tail and a hot head.
        Light {
            path: root.band
            from: root.cometX - 160
            to: root.cometX - 160
            reach: 260
            tint: Theme.accent2
            strength: 0.9 * root.cometPower
        }
        Light {
            path: root.band
            from: root.cometX
            to: root.cometX
            reach: 60
            tint: Theme.text
            strength: root.cometPower
        }

        Light {
            path: root.band
            from: root.lightX
            to: root.lightX
            reach: 260
            strength: root.cursorLight
        }
    }

    // The frost lit from behind where the cursor is.
    Item {
        width: root.width
        height: Theme.barHeight
        clip: true
        opacity: root.cursorLight
        visible: opacity > 0

        Glow {
            center: root.lightX
            y: Theme.barHeight - height / 2
            width: 520
            height: 120
            peak: Theme.dark ? 0.16 : 0.2
        }
    }

    ParallelAnimation {
        id: comet

        NumberAnimation {
            target: root
            property: "cometX"
            from: -200
            to: root.width + 200
            duration: 1100
            easing.type: Easing.InOutCubic
        }
        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "cometPower"
                from: 0
                to: 1
                duration: 200
            }
            PauseAnimation {
                duration: 600
            }
            NumberAnimation {
                target: root
                property: "cometPower"
                to: 0
                duration: 300
            }
        }
    }

    // A pool of light on the horizon band: full strength over [from, to],
    // fading out over `reach` on either side.
    component Light: ShapePath {
        id: light

        property string path
        property real from: 0
        property real to: 0
        property real reach: 140
        property color tint: Theme.accent
        property real strength: 1
        readonly property real edge: reach / Math.max(1, to - from + reach * 2)
        readonly property color lit: Qt.alpha(tint, Theme.horizonLit * Math.min(1, strength))

        strokeWidth: -1
        fillGradient: LinearGradient {
            x1: light.from - light.reach
            x2: light.to + light.reach

            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: light.edge
                color: light.lit
            }
            GradientStop {
                position: 1 - light.edge
                color: light.lit
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }

        PathSvg {
            path: light.strength > 0.01 ? light.path : ""
        }
    }

    // A soft round glow (a radial gradient on a circle, squashed to
    // width × height, so it fades out evenly in every direction).
    component Glow: Item {
        id: glow

        property real center: 0
        property color tint: Theme.accent
        property real strength: 1
        property real peak: 0.35

        x: center - width / 2
        visible: strength > 0.01

        Shape {
            width: glow.width
            height: width
            preferredRendererType: Shape.CurveRenderer
            transform: Scale {
                yScale: glow.height / Math.max(1, glow.width)
            }

            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: glow.width / 2
                    centerY: glow.width / 2
                    centerRadius: glow.width / 2
                    focalX: glow.width / 2
                    focalY: glow.width / 2

                    GradientStop {
                        position: 0
                        color: Qt.alpha(glow.tint, glow.peak * Math.min(1, glow.strength))
                    }
                    GradientStop {
                        position: 1
                        color: "transparent"
                    }
                }

                PathSvg {
                    path: `M 0 ${glow.width / 2} A ${glow.width / 2} ${glow.width / 2} 0 0 0 ${glow.width} ${glow.width / 2} A ${glow.width / 2} ${glow.width / 2} 0 0 0 0 ${glow.width / 2} Z`
                }
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
            screenHeight: root.modelData.height
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
        y: Math.round((Theme.barHeight - height) / 2)
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
