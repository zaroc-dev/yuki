import QtQuick
import qs.config

Text {
    property real size: Theme.iconSize

    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorAnimation {
            duration: Theme.animSlow
        }
    }
}
