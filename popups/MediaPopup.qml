import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.services

// Now playing, lit by its own cover: the art, blurred and faded, washes the
// whole panel behind the controls.
BarPopup {
    id: root

    readonly property MprisPlayer player: Media.active

    // MPRIS doesn't push position updates; poll while visible.
    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // Ambient wash behind the content.
    backdrop: Item {
        anchors.fill: parent
        visible: art.status === Image.Ready

        Image {
            id: wash

            anchors.fill: parent
            source: art.source
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(96, 96)
            asynchronous: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: wash
            blurEnabled: true
            blur: 1
            blurMax: 64
            saturation: 0.25
            opacity: Theme.dark ? 0.32 : 0.4
        }

        // Fade the wash out towards the bottom so the controls stay calm.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.2
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(Theme.base, 0.7)
                }
            }
        }
    }

    RowLayout {
        Layout.preferredWidth: 380
        Layout.fillWidth: true
        spacing: 16

        Item {
            implicitWidth: 120
            implicitHeight: 120

            // Soft shadow under the cover.
            RectangularShadow {
                anchors.fill: cover
                offset.y: 6
                blur: 22
                radius: cover.radius
                color: Qt.alpha("black", 0.45)
            }

            ClippingRectangle {
                id: cover

                anchors.fill: parent
                radius: 18
                color: Theme.surface0

                Image {
                    id: art

                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(240, 240)
                    asynchronous: true
                }

                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: Icons.music
                    size: 42
                    color: Theme.accent
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: Media.nameOf(root.player).toUpperCase()
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.6
                color: Theme.overlay2
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: root.player?.trackTitle || "Nothing playing"
                font.family: Theme.displayFont
                font.pixelSize: 20
                font.weight: Font.ExtraBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                color: Theme.accent
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackAlbum ?? ""
                color: Theme.subtext0
                font.pixelSize: Theme.smallFontSize
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: Media.hasLength(root.player)
        spacing: 4

        StyledSlider {
            Layout.fillWidth: true
            thickness: 6
            value: root.player?.position ?? 0
            to: Math.max(1, root.player?.length ?? 1)
            step: 5
            enabled: root.player?.canSeek ?? false
            onMoved: v => root.player.position = v
        }

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: Media.formatTime(root.player?.position ?? 0)
                font.pixelSize: Theme.smallFontSize
                font.features: {
                    "tnum": 1
                }
                color: Theme.subtext0
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: `-${Media.formatTime(Math.max(0, (root.player?.length ?? 0) - (root.player?.position ?? 0)))}`
                font.pixelSize: Theme.smallFontSize
                font.features: {
                    "tnum": 1
                }
                color: Theme.subtext0
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 14

        IconButton {
            icon: Icons.shuffle
            visible: root.player?.shuffleSupported ?? false
            color: root.player?.shuffle ? Theme.accent : Theme.overlay1
            onClicked: root.player.shuffle = !root.player.shuffle
        }

        IconButton {
            size: 42
            iconSize: 22
            icon: Icons.previous
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }

        IconButton {
            size: 58
            iconSize: 28
            filled: true
            icon: root.player?.isPlaying ? Icons.pause : Icons.play
            enabled: root.player?.canTogglePlaying ?? false
            onClicked: root.player.togglePlaying()
        }

        IconButton {
            size: 42
            iconSize: 22
            icon: Icons.next
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }

        IconButton {
            icon: Icons.repeat
            visible: root.player?.loopSupported ?? false
            color: root.player?.loopState !== MprisLoopState.None ? Theme.accent : Theme.overlay1
            onClicked: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
        }
    }

    // Player switcher when more than one MPRIS player is around.
    Flow {
        Layout.fillWidth: true
        visible: Media.players.length > 1
        spacing: 6

        Repeater {
            model: Media.players

            MouseArea {
                id: chip

                required property var modelData
                readonly property bool current: modelData === root.player

                readonly property bool preferred: Media.preferred !== "" && Media.keyOf(modelData) === Media.preferred

                width: chipRow.implicitWidth + 22
                height: 28
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                // Left: show this one now. Right: make it the preferred player.
                onClicked: e => {
                    if (e.button === Qt.RightButton)
                        Settings.d.preferredPlayer = preferred ? "" : Media.keyOf(modelData);
                    else
                        Media.pinned = modelData;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: chip.current ? Theme.accent : chip.containsMouse ? Theme.cardHover : Theme.card
                }

                Row {
                    id: chipRow

                    anchors.centerIn: parent
                    spacing: 4

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: chip.preferred
                        text: Icons.pin
                        size: 11
                        color: chip.current ? Theme.onAccent : Theme.accent
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Media.nameOf(chip.modelData)
                        font.pixelSize: Theme.smallFontSize
                        font.weight: Font.DemiBold
                        color: chip.current ? Theme.onAccent : Theme.text
                    }
                }
            }
        }
    }
}
