import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// One OSD window per output; only the focused one shows.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData
        readonly property bool active: modelData.name === (Niri.focusedOutput || Quickshell.screens[0]?.name)

        screen: modelData
        visible: active && (Osd.shown || pill.opacity > 0)
        anchors.bottom: true
        margins.bottom: 96
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 320
        implicitHeight: 56
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "yuki-osd"
        BackgroundEffect.blurRegion: Region {
            item: Theme.blur ? pill : null
            radius: pill.radius
        }

        Rectangle {
            id: pill

            anchors.fill: parent
            radius: height / 2
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.barBorder
            opacity: Osd.shown ? 1 : 0
            scale: Osd.shown ? 1 : 0.92

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 14

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Osd.icon
                    size: 20
                    color: Osd.muted ? Theme.overlay1 : Theme.accent
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 190
                    height: 8
                    radius: 4
                    color: Theme.surface1

                    Rectangle {
                        width: parent.width * Math.min(1, Osd.value)
                        height: parent.height
                        radius: parent.radius
                        color: Osd.muted ? Theme.overlay0 : Theme.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    horizontalAlignment: Text.AlignRight
                    text: Osd.muted ? "Mute" : `${Math.round(Osd.value * 100)}%`
                    color: Theme.subtext1
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
