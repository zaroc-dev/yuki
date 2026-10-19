import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services
import qs.popups

// Now playing: the cover spins like a record inside a ring that fills with
// the track's progress, a little equalizer dances while it plays.
BarButton {
    id: root

    readonly property var player: Media.active
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real progress: Media.hasLength(player) ? Math.min(1, (player?.position ?? 0) / Math.max(1, player?.length ?? 1)) : 0
    // Room the bar gives the title (with its spacing); below a readable minimum
    // only art and controls stay. Same no-feedback rule as ActiveWindow.
    property real titleMax: 240 + spacing
    readonly property real titleNatural: Math.min(title.implicitWidth, 240) + spacing
    readonly property real fixedWidth: disc.width + eq.width + controls.implicitWidth + spacing * 2 + hPadding * 2

    visible: player !== null && Settings.d.showMedia
    hPadding: 3
    spacing: 8
    active: popup.visible
    onClicked: e => {
        if (e.button === Qt.MiddleButton)
            player?.togglePlaying();
        else
            popup.toggle();
    }

    Item {
        id: disc

        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.alpha(Theme.text, 0.12)
                strokeWidth: 2

                PathAngleArc {
                    centerX: 14
                    centerY: 14
                    radiusX: 13
                    radiusY: 13
                    sweepAngle: 360
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.accent
                strokeWidth: 2
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: 14
                    centerY: 14
                    radiusX: 13
                    radiusY: 13
                    startAngle: -90
                    sweepAngle: 360 * root.progress

                    Behavior on sweepAngle {
                        NumberAnimation {
                            duration: 900
                        }
                    }
                }
            }
        }

        ClippingRectangle {
            id: cover

            anchors.centerIn: parent
            width: 20
            height: 20
            radius: 10
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
                size: 11
                color: Theme.accent
            }

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 9000
                loops: Animation.Infinite
                running: root.playing && art.status === Image.Ready
            }
        }

        // Spindle hole.
        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: 4
            radius: 2
            visible: art.status === Image.Ready
            color: Theme.base
        }
    }

    StyledText {
        id: title

        anchors.verticalCenter: parent.verticalCenter
        visible: root.titleMax - root.spacing >= 48
        width: Math.min(implicitWidth, 240, root.titleMax - root.spacing)
        textFormat: Text.StyledText
        font.weight: Font.Medium
        text: {
            const t = root.player?.trackTitle || Media.nameOf(root.player);
            const a = root.player?.trackArtist ?? "";
            const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");
            return a ? `${esc(t)} <font color="${Theme.subtext0}">· ${esc(a)}</font>` : esc(t);
        }
    }

    // Faux equalizer: four bars bouncing out of phase while playing.
    Row {
        id: eq

        anchors.verticalCenter: parent.verticalCenter
        height: 14
        spacing: 2

        Repeater {
            model: [0.9, 0.55, 1, 0.7]

            Rectangle {
                id: bar

                required property real modelData
                required property int index
                property real level: 0.3

                anchors.bottom: parent.bottom
                width: 2.5
                height: Math.max(3, eq.height * level)
                radius: 1.25
                color: Theme.accent

                SequentialAnimation on level {
                    running: root.playing
                    loops: Animation.Infinite
                    alwaysRunToEnd: true

                    PauseAnimation {
                        duration: bar.index * 90
                    }
                    NumberAnimation {
                        to: bar.modelData
                        duration: 260 + bar.index * 40
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        to: 0.2
                        duration: 300 + bar.index * 30
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    Row {
        id: controls

        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        IconButton {
            size: 24
            iconSize: 13
            icon: Icons.previous
            color: Theme.subtext0
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }

        IconButton {
            size: 24
            iconSize: 15
            icon: root.playing ? Icons.pause : Icons.play
            color: Theme.accent
            onClicked: root.player?.togglePlaying()
        }

        IconButton {
            size: 24
            iconSize: 13
            icon: Icons.next
            color: Theme.subtext0
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
    }

    // MPRIS doesn't push position updates.
    Timer {
        running: root.visible && root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    MediaPopup {
        id: popup

        name: "media"
        target: root
    }
}
