import QtQuick
import QtQuick.Shapes
import qs.config

// A panel that grows out of the bar: square top joined to the bar by concave
// fillets, rounded bottom. Snapped to a screen edge, that side runs flat down
// the edge and ends in a concave fillet instead, like the bar's own corners,
// so the panel reads as the bar flowing down the side of the screen.
//
// The body (bodyWidth × bodyHeight) starts at bodyX; the item is wider by the
// fillets and taller by one fillet (for the edge fillets).
Item {
    id: root

    property real bodyWidth: 0
    property real bodyHeight: 0
    property bool snapLeft: false
    property bool snapRight: false
    property real fillet: Theme.fillet
    property real radius: Theme.radiusLarge
    property color color: Theme.popupBg

    readonly property real bodyX: snapLeft ? 0 : fillet

    // SVG path of the outline, optionally shifted by (ox, oy) (to cut it out
    // of another shape). Arcs: sweep 1 = clockwise on screen (y down).
    function outline(w, h, f, r, snapL, snapR, ox = 0, oy = 0) {
        const rr = Math.max(0, Math.min(r, h / 2, w / 2));
        // Top fillets shrink while the body is shorter than they are, so a
        // panel starting at height 0 swells out of the bar.
        const ft = Math.max(0, Math.min(f, h - rr));
        const bx = snapL ? 0 : f;
        const xr = bx + w;
        const P = (x, y) => `${x + ox} ${y + oy}`;
        const arc = (rad, sweep, x, y) => rad < 0.5 ? ` L ${P(x, y)}` : ` A ${rad} ${rad} 0 0 ${sweep} ${P(x, y)}`;
        let d;
        if (snapL)
            d = `M ${P(0, 0)} L ${P(0, h + f)}` + arc(f, 1, f, h);
        else
            d = `M ${P(bx - ft, 0)}` + arc(ft, 1, bx, ft) + ` L ${P(bx, h - rr)}` + arc(rr, 0, bx + rr, h);
        if (snapR)
            d += ` L ${P(xr - f, h)}` + arc(f, 1, xr, h + f) + ` L ${P(xr, 0)} Z`;
        else
            d += ` L ${P(xr - rr, h)}` + arc(rr, 0, xr, h - rr) + ` L ${P(xr, ft)}` + arc(ft, 1, xr + ft, 0) + " Z";
        return d;
    }

    implicitWidth: bodyWidth + (snapLeft ? 0 : fillet) + (snapRight ? 0 : fillet)
    implicitHeight: bodyHeight + fillet

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeWidth: -1

            PathSvg {
                path: root.outline(root.bodyWidth, root.bodyHeight, root.fillet, root.radius, root.snapLeft, root.snapRight)
            }
        }
    }
}
