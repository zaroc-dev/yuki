import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Volume/brightness readout that drops out of the middle of the bar and
// melts back in. One window per output;
// only the focused one shows.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property bool active: modelData.name === (Niri.focusedOutput || Quickshell.screens[0]?.name)
        readonly property real bodyWidth: 340
        readonly property real bodyHeight: 64
        property real reveal: active && Osd.shown ? 1 : 0

        screen: modelData
        visible: reveal > 0.001
        onVisibleChanged: {
            if (visible) {
                Ui.osdWidth = bodyWidth;
                Ui.osdScreen = modelData.name;
            }
            else if (Ui.osdScreen === modelData.name)
                Ui.osdScreen = "";
        }
        Component.onDestruction: {
            if (Ui.osdScreen === modelData.name)
                Ui.osdScreen = "";
        }
        anchors.top: true
        // Zone 0: placed under the bar, flush with its bottom edge.
        exclusiveZone: 0
        implicitWidth: bodyWidth + Theme.fillet * 2
        implicitHeight: bodyHeight + Theme.fillet
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "yuki-osd"
        BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

        // Grows out with a long ease-out, folds back quicker.
        Behavior on reveal {
            id: revealBehavior

            NumberAnimation {
                duration: revealBehavior.targetValue > 0.5 ? Theme.animGrow : 260
                easing.type: revealBehavior.targetValue > 0.5 ? Easing.OutQuint : Easing.InCubic
            }
        }

        SurfaceRegion {
            id: blurRegion

            bodyX: Theme.fillet
            bodyWidth: win.bodyWidth
            bodyHeight: body.height
        }

        Surface {
            bodyWidth: win.bodyWidth
            bodyHeight: body.height
        }

        Item {
            id: body

            x: Theme.fillet
            width: win.bodyWidth
            height: Math.round(win.bodyHeight * win.reveal)
            clip: true

            Row {
                x: 14
                y: (win.bodyHeight - height) / 2 - (1 - win.reveal) * 12
                opacity: win.reveal
                spacing: 12

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    height: 38
                    radius: 14
                    color: Theme.well
                    gradient: Osd.muted ? null : aurora

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

                    Icon {
                        anchors.centerIn: parent
                        text: Osd.icon
                        size: 19
                        color: Osd.muted ? Theme.overlay1 : Theme.onAccent
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: win.bodyWidth - 14 * 2 - 38 - 12 * 2 - value.width
                    spacing: 7

                    StyledText {
                        width: parent.width
                        text: (Osd.label || "").toUpperCase()
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: Theme.overlay2
                    }

                    Rectangle {
                        width: parent.width
                        height: 10
                        radius: 5
                        color: Theme.well

                        Rectangle {
                            width: Math.max(height, parent.width * Math.min(1, Osd.value))
                            height: parent.height
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal

                                GradientStop {
                                    position: 0
                                    color: Osd.muted ? Theme.overlay0 : Theme.accent
                                }
                                GradientStop {
                                    position: 1
                                    color: Osd.muted ? Theme.overlay0 : Theme.accent2
                                }
                            }

                            Behavior on width {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                StyledText {
                    id: value

                    anchors.verticalCenter: parent.verticalCenter
                    width: 52
                    horizontalAlignment: Text.AlignRight
                    text: Osd.muted ? "Mute" : Math.round(Osd.value * 100)
                    color: Osd.muted ? Theme.overlay1 : Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: Osd.muted ? 15 : 26
                    font.weight: Font.Black
                    font.features: {
                        "tnum": 1
                    }
                }
            }
        }
    }
}
