import QtQuick
import QtQuick.Shapes
import qs.config

// One quarter of a round corner as a Shape whose path only depends on its
// size, so animated surfaces built from these (plus Rectangles) just move
// pieces around instead of re-tessellating a whole outline every frame, which
// stutters at high refresh rates. The arc is centred on the bottom-left
// corner of the `size` square and bulges to the top right; mirror with
// flipX/flipY.
//  - band < 0: the square minus the quarter disc (a concave fillet, or what
//    lies outside a rounded corner).
//  - band > 0: a quarter ring from radius `size - band` to `size` (a rim;
//    band = size gives the whole quarter disc).
Shape {
    id: root

    property real size: Theme.fillet
    property real band: -1
    property color color: Theme.popupBg
    property bool flipX: false
    property bool flipY: false

    width: size
    height: size
    visible: size > 0.5
    preferredRendererType: Shape.CurveRenderer
    transform: Scale {
        origin.x: root.size / 2
        origin.y: root.size / 2
        xScale: root.flipX ? -1 : 1
        yScale: root.flipY ? -1 : 1
    }

    ShapePath {
        fillColor: root.color
        strokeWidth: -1

        PathSvg {
            path: {
                const s = root.size;
                if (root.band < 0)
                    return `M 0 0 L ${s} 0 L ${s} ${s} A ${s} ${s} 0 0 0 0 0 Z`;
                const r0 = Math.max(0, s - root.band);
                return `M ${s} ${s} A ${s} ${s} 0 0 0 0 0 L 0 ${s - r0}` + (r0 > 0.5 ? ` A ${r0} ${r0} 0 0 1 ${r0} ${s}` : ` L 0 ${s}`) + " Z";
            }
        }
    }
}
