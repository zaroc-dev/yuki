import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// Titled card holding setting rows.
ColumnLayout {
    id: root

    property string title
    property string subtitle
    default property alias content: card.data

    Layout.fillWidth: true
    spacing: 8

    StyledText {
        visible: root.title !== ""
        text: root.title.toUpperCase()
        font.pixelSize: Theme.smallFontSize
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        color: Theme.overlay2
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.subtitle !== ""
        text: root.subtitle
        wrapMode: Text.Wrap
        font.pixelSize: Theme.smallFontSize + 1
        color: Theme.subtext0
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight + 8
        radius: Theme.radius
        color: Qt.alpha(Theme.surface0, 0.55)

        ColumnLayout {
            id: card

            anchors.fill: parent
            anchors.margins: 4
            spacing: 0
        }
    }
}
