import QtQuick
import qs.config

Text {
    id: root

    property real size: Theme.iconSize
    // Nerd Font glyphs often sit off-center in their advance box; shift so
    // the visible ink is centered instead.
    property bool centerInk: true

    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    transform: Translate {
        x: root.centerInk && root.text.length > 0 ? (metrics.advanceWidth - metrics.tightBoundingRect.width) / 2 - metrics.tightBoundingRect.x : 0
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.animSlow
        }
    }

    TextMetrics {
        id: metrics

        font: root.font
        text: root.text
    }
}
