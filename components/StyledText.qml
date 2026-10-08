import QtQuick
import qs.config

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    textFormat: Text.PlainText

    Behavior on color {
        ColorAnimation {
            duration: Theme.animSlow
        }
    }
}
