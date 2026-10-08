import QtQuick
import qs.config
import qs.components
import qs.services
import qs.popups

BarButton {
    id: root

    hPadding: 7
    spacing: 5
    active: popup.visible
    onClicked: e => {
        if (e.button === Qt.MiddleButton)
            Audio.toggleMute(Audio.sink);
        else
            popup.toggle();
    }
    onWheel: e => Audio.setVolume(Audio.sink, Audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05))

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.volume(Audio.volume, Audio.muted)
        color: Audio.muted ? Theme.overlay1 : Theme.text
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: `${Math.round(Audio.volume * 100)}%`
        color: Audio.muted ? Theme.overlay1 : Theme.subtext1
        font.pixelSize: Theme.smallFontSize + 1
    }

    VolumePopup {
        id: popup

        name: "volume"
        target: root
    }
}
