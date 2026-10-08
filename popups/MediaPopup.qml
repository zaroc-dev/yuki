import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.services

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

    RowLayout {
        Layout.preferredWidth: 340
        Layout.fillWidth: true
        spacing: 14

        ClippingRectangle {
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            radius: Theme.innerRadius + 2
            color: Theme.surface0

            Image {
                id: art

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(192, 192)
                asynchronous: true
            }

            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: Icons.music
                size: 36
                color: Theme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Nothing playing"
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackArtist ?? ""
                color: Theme.subtext1
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

            RowLayout {
                spacing: 4

                IconButton {
                    icon: Icons.shuffle
                    visible: root.player?.shuffleSupported ?? false
                    color: root.player?.shuffle ? Theme.accent : Theme.overlay1
                    onClicked: root.player.shuffle = !root.player.shuffle
                }

                IconButton {
                    icon: Icons.previous
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }

                IconButton {
                    size: 38
                    iconSize: 20
                    filled: true
                    icon: root.player?.isPlaying ? Icons.pause : Icons.play
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }

                IconButton {
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
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: Media.hasLength(root.player)
        spacing: 2

        StyledSlider {
            Layout.fillWidth: true
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
                color: Theme.subtext0
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: Media.formatTime(root.player?.length ?? 0)
                font.pixelSize: Theme.smallFontSize
                color: Theme.subtext0
            }
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

                width: chipRow.implicitWidth + 20
                height: 26
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
                    color: chip.current ? Theme.accent : chip.containsMouse ? Theme.surface1 : Theme.surface0
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
                        color: chip.current ? Theme.onAccent : Theme.text
                    }
                }
            }
        }
    }
}
