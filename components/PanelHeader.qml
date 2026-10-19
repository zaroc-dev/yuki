import QtQuick
import QtQuick.Layouts
import qs.config

// Top of a panel: aurora glyph badge, display-weight title, a quiet subtitle,
// and whatever controls go on the right (children).
RowLayout {
    id: root

    property string icon
    property string title
    property string subtitle
    // Lights the badge (e.g. the radio is on).
    property bool lit: true
    default property alias trailing: trail.data

    Layout.fillWidth: true
    spacing: 12

    Rectangle {
        visible: root.icon !== ""
        implicitWidth: 40
        implicitHeight: 40
        radius: 14
        color: Theme.well
        gradient: root.lit ? aurora : null

        Gradient {
            id: aurora

            GradientStop {
                position: 0
                color: Theme.accent
            }
            GradientStop {
                position: 1
                color: Theme.accent2
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: root.lit
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.alpha("white", 0.25)
                }
                GradientStop {
                    position: 0.5
                    color: "transparent"
                }
            }
        }

        Icon {
            anchors.centerIn: parent
            text: root.icon
            size: 19
            color: root.lit ? Theme.onAccent : Theme.overlay1
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: root.title
            font.family: Theme.displayFont
            font.pixelSize: 20
            font.weight: Font.ExtraBold
            font.letterSpacing: -0.2
        }

        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.subtitle
            font.pixelSize: Theme.smallFontSize + 1
            color: Theme.subtext0
        }
    }

    RowLayout {
        id: trail

        spacing: 4
    }
}
