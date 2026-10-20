import QtQuick
import QtQuick.Layouts
import qs.config

// Spaced-out caps label trailed by a rule that fades out.
RowLayout {
    id: root

    property string text
    default property alias trailing: trail.data

    Layout.fillWidth: true
    Layout.topMargin: 4
    spacing: 10

    StyledText {
        text: root.text.toUpperCase()
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 1.8
        color: Theme.overlay2
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Theme.rim
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }

    RowLayout {
        id: trail

        spacing: 4
    }
}
