import QtQuick
import qs.config

// A panel that grows out of the bar: square top joined to the bar by concave
// fillets, rounded bottom. Snapped to a screen edge, that side runs flat down
// the edge and ends in a concave fillet instead, like the bar's own corners,
// so the panel reads as the bar flowing down the side of the screen.
//
// The body (bodyWidth × bodyHeight) starts at bodyX; the item is wider by the
// fillets and taller by one fillet (for the edge fillets). Its free edge
// carries the horizon on from where the bar's ends, lit at the join and
// fading towards the bottom.
//
// Built from a Rectangle and static Corner pieces, so growing it every frame
// only moves things (see Corner).
Item {
    id: root

    property real bodyWidth: 0
    property real bodyHeight: 0
    property bool snapLeft: false
    property bool snapRight: false
    property real fillet: Theme.fillet
    property real radius: Theme.radiusLarge
    property color color: Theme.popupBg
    property bool lit: true

    readonly property real bodyX: snapLeft ? 0 : fillet
    readonly property real bodyRight: bodyX + bodyWidth
    // Bottom radius and top fillets shrink while the body is shorter than
    // they are, so a panel starting at height 0 swells out of the bar.
    readonly property real rr: Math.max(0, Math.min(radius, bodyHeight / 2, bodyWidth / 2))
    readonly property real ft: Math.max(0, Math.min(fillet, bodyHeight - rr))
    readonly property real lw: Theme.horizonWidth
    readonly property bool shown: bodyHeight > 0.5
    readonly property color rimTop: Qt.alpha(Theme.accent, Theme.horizonLit * 0.8)
    readonly property color rimRest: Qt.alpha(Theme.accent2, Theme.horizonRest)

    implicitWidth: bodyWidth + (snapLeft ? 0 : fillet) + (snapRight ? 0 : fillet)
    implicitHeight: bodyHeight + fillet
    // Rim pieces poke out above (into the bar) and past snapped edges.
    clip: true

    // ---- fill ----
    Rectangle {
        x: root.bodyX
        width: root.bodyWidth
        height: root.bodyHeight
        visible: root.shown
        color: root.color
        bottomLeftRadius: root.snapLeft ? 0 : root.rr
        bottomRightRadius: root.snapRight ? 0 : root.rr
    }

    Corner {
        x: root.bodyX - size
        size: root.snapLeft || !root.shown ? 0 : root.ft
        color: root.color
    }
    Corner {
        x: root.bodyRight
        size: root.snapRight || !root.shown ? 0 : root.ft
        flipX: true
        color: root.color
    }
    // Edge fillets of snapped sides, under the body like the bar's corners.
    Corner {
        y: root.bodyHeight
        size: root.snapLeft && root.shown ? root.fillet : 0
        flipX: true
        color: root.color
    }
    Corner {
        x: root.bodyRight - size
        y: root.bodyHeight
        size: root.snapRight && root.shown ? root.fillet : 0
        color: root.color
    }

    // ---- rim ----
    Item {
        anchors.fill: parent
        visible: root.lit && root.shown

        // Top fillets, continuing the bar's horizon downwards.
        Corner {
            x: root.bodyX - root.ft
            y: -root.lw
            size: root.snapLeft ? 0 : root.ft + root.lw
            band: root.lw
            color: root.rimTop
        }
        Corner {
            x: root.bodyRight - root.lw
            y: -root.lw
            size: root.snapRight ? 0 : root.ft + root.lw
            band: root.lw
            flipX: true
            color: root.rimTop
        }

        // Sides, fading from the join down.
        Repeater {
            model: [!root.snapLeft, !root.snapRight]

            Rectangle {
                required property bool modelData
                required property int index

                x: index === 0 ? root.bodyX : root.bodyRight - root.lw
                y: root.ft
                width: root.lw
                height: Math.max(0, root.bodyHeight - root.ft - root.rr)
                visible: modelData
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.rimTop
                    }
                    GradientStop {
                        position: Math.min(0.9, 90 / Math.max(1, root.bodyHeight))
                        color: Qt.alpha(Theme.accent2, Theme.horizonRest * 1.6)
                    }
                    GradientStop {
                        position: 1
                        color: root.rimRest
                    }
                }
            }
        }

        // Bottom corners and edge.
        Corner {
            x: root.bodyX
            y: root.bodyHeight - root.rr
            size: root.snapLeft ? 0 : root.rr
            band: root.lw
            flipX: true
            flipY: true
            color: root.rimRest
        }
        Corner {
            x: root.bodyRight - root.rr
            y: root.bodyHeight - root.rr
            size: root.snapRight ? 0 : root.rr
            band: root.lw
            flipY: true
            color: root.rimRest
        }
        Rectangle {
            x: root.snapLeft ? root.fillet : root.bodyX + root.rr
            y: root.bodyHeight - root.lw
            width: (root.snapRight ? root.bodyRight - root.fillet : root.bodyRight - root.rr) - x
            height: root.lw
            color: root.rimRest
        }

        // Edge fillets of snapped sides, like the bar's corners.
        Corner {
            x: -root.lw
            y: root.bodyHeight - root.lw
            size: root.snapLeft ? root.fillet + root.lw : 0
            band: root.lw
            flipX: true
            color: root.rimRest
        }
        Corner {
            x: root.bodyRight - root.fillet
            y: root.bodyHeight - root.lw
            size: root.snapRight ? root.fillet + root.lw : 0
            band: root.lw
            color: root.rimRest
        }
    }
}
