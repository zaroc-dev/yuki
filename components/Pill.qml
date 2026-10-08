import QtQuick
import qs.config

// One of the floating islands of the bar.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing

    implicitWidth: row.implicitWidth + Theme.padding * 2
    implicitHeight: Theme.barHeight
    radius: Theme.radius
    color: Theme.barBg
    border.width: 1
    border.color: Theme.barBorder

    Behavior on color {
        ColorAnimation {
            duration: Theme.animSlow
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.anim
            easing.type: Easing.OutCubic
        }
    }

    // Faint light from the top edge: reads as glass on any wallpaper.
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: parent.radius - 1
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.alpha(Theme.text, Theme.dark ? 0.07 : 0.25)
            }
            GradientStop {
                position: 0.5
                color: "transparent"
            }
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        height: parent.height - Theme.padding * 2
        spacing: Theme.spacing
    }
}
