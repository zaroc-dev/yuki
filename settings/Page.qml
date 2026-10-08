import QtQuick
import QtQuick.Layouts
import qs.config

// Scrollable page body.
Flickable {
    id: root

    default property alias content: column.data

    contentWidth: width
    contentHeight: column.implicitHeight + 8
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column

        width: root.width - 6
        spacing: 22
    }

    // Slim scroll indicator.
    Rectangle {
        visible: root.contentHeight > root.height
        x: root.width - 4
        y: root.visibleArea.yPosition * root.height
        width: 3
        height: root.visibleArea.heightRatio * root.height
        radius: 2
        color: Theme.surface2
        opacity: root.moving ? 0.9 : 0.4
    }
}
