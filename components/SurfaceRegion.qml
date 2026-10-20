import QtQuick
import Quickshell
import qs.config

// Blur region matching a Surface body: square top (it meets the bar), rounded
// bottom, square bottom corner on a snapped side. The fillets stay unblurred;
// they are small and the tint covers them.
Region {
    id: root

    property real bodyX: 0
    property real bodyY: 0
    property real bodyWidth: 0
    property real bodyHeight: 0
    property bool snapLeft: false
    property bool snapRight: false
    readonly property real r: Math.min(Theme.radiusLarge, bodyHeight / 2)

    Region {
        x: root.bodyX
        y: root.bodyY
        width: root.bodyWidth
        height: Math.max(0, root.bodyHeight - root.r)
    }
    Region {
        x: root.bodyX
        y: root.bodyY + root.bodyHeight - root.r * 2
        width: root.bodyWidth
        height: root.r * 2
        radius: root.r
    }
    Region {
        x: root.snapLeft ? root.bodyX : root.bodyX + root.bodyWidth - root.r
        y: root.bodyY + root.bodyHeight - root.r
        width: root.snapLeft || root.snapRight ? root.r : 0
        height: root.r
    }
}
