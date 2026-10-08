import QtQuick
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services
import qs.popups

BarButton {
    id: root

    readonly property var player: Media.active

    visible: player !== null && Settings.d.showMedia
    hPadding: 4
    spacing: 8
    active: popup.visible
    onClicked: e => {
        if (e.button === Qt.MiddleButton)
            player?.togglePlaying();
        else
            popup.toggle();
    }

    ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 6
        color: Theme.surface0

        Image {
            id: art

            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(64, 64)
            asynchronous: true
        }

        Icon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: Icons.music
            size: 14
            color: Theme.accent
        }
    }

    StyledText {
        id: title

        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 260)
        textFormat: Text.StyledText
        text: {
            const t = root.player?.trackTitle || Media.nameOf(root.player);
            const a = root.player?.trackArtist ?? "";
            const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");
            return a ? `${esc(t)} <font color="${Theme.subtext0}">· ${esc(a)}</font>` : esc(t);
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        IconButton {
            size: 24
            iconSize: 14
            icon: Icons.previous
            color: Theme.subtext0
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }

        IconButton {
            size: 24
            iconSize: 15
            icon: root.player?.isPlaying ? Icons.pause : Icons.play
            color: Theme.accent
            onClicked: root.player?.togglePlaying()
        }

        IconButton {
            size: 24
            iconSize: 14
            icon: Icons.next
            color: Theme.subtext0
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
    }

    // Thin progress line under the title.
    Item {
        parent: root
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 36
        anchors.rightMargin: 82
        height: 2
        visible: Media.hasLength(root.player)

        Rectangle {
            anchors.fill: parent
            radius: 1
            color: Qt.alpha(Theme.text, 0.1)
        }

        Rectangle {
            width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
            height: parent.height
            radius: 1
            color: Theme.accent

            Behavior on width {
                NumberAnimation {
                    duration: 900
                }
            }
        }

        Timer {
            running: parent.visible && (root.player?.isPlaying ?? false)
            interval: 1000
            repeat: true
            onTriggered: root.player.positionChanged()
        }
    }

    MediaPopup {
        id: popup

        name: "media"
        target: root
    }
}
