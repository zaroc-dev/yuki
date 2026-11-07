import QtQuick
import qs.config

// Spinning loading glyph; only animates while visible.
Icon {
    id: root

    text: Icons.loading
    color: Theme.accent

    RotationAnimation on rotation {
        running: root.visible
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 900
    }
}
