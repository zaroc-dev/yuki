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

    SectionLabel {
        visible: root.title !== ""
        Layout.topMargin: 0
        text: root.title
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
        radius: 20
        color: Theme.card

        ColumnLayout {
            id: card

            anchors.fill: parent
            anchors.margins: 4
            spacing: 0
        }
    }
}
