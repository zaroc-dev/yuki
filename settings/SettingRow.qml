import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// Label + description on the left, control on the right.
Item {
    id: root

    property string label
    property string description
    property string icon
    // Desktop icon name shown instead of a glyph.
    property string appIcon
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: Math.max(52, row.implicitHeight + 20)

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 14

        AppIcon {
            visible: root.appIcon !== ""
            iconName: root.appIcon
            size: 26
        }

        Icon {
            visible: root.icon !== ""
            text: root.icon
            size: 18
            color: Theme.subtext0
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.label
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.description !== ""
                text: root.description
                wrapMode: Text.Wrap
                font.pixelSize: Theme.smallFontSize
                color: Theme.subtext0
            }
        }

        Item {
            id: slot

            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
