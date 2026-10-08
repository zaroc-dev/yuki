import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config
import qs.components
import qs.services

BarPopup {
    id: root

    component Channel: ColumnLayout {
        id: channel

        required property string title
        required property var node
        required property var devices
        required property string icon
        required property string mutedIcon
        property bool expanded: false
        readonly property bool muted: node?.audio?.muted ?? false
        readonly property real volume: node?.audio?.volume ?? 0

        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: channel.title
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: Audio.nameOf(channel.node)
                color: Theme.subtext0
                font.pixelSize: Theme.smallFontSize
                horizontalAlignment: Text.AlignRight
            }

            IconButton {
                size: 24
                visible: channel.devices.length > 1
                icon: Icons.chevronRight
                rotation: channel.expanded ? 90 : 0
                color: Theme.subtext0
                onClicked: channel.expanded = !channel.expanded

                Behavior on rotation {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            IconButton {
                icon: channel.muted ? channel.mutedIcon : channel.icon
                color: channel.muted ? Theme.overlay1 : Theme.accent
                onClicked: Audio.toggleMute(channel.node)
            }

            StyledSlider {
                Layout.fillWidth: true
                value: channel.volume
                fill: channel.muted ? Theme.overlay0 : Theme.accent
                onMoved: v => Audio.setVolume(channel.node, v)
            }

            StyledText {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(channel.volume * 100)}%`
                color: Theme.subtext1
            }
        }

        // Device picker: height and opacity animate, so expanding feels
        // like an accordion instead of a jump.
        Item {
            Layout.fillWidth: true
            implicitHeight: channel.expanded ? deviceList.implicitHeight : 0
            opacity: channel.expanded ? 1 : 0
            clip: true
            // Not implicitHeight: a hidden Column measures 0 and never grows.
            visible: opacity > 0

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            Column {
                id: deviceList

                width: parent.width
                spacing: 2

                Repeater {
                    model: channel.devices

                    MouseArea {
                        id: dev

                        required property var modelData
                        readonly property bool current: modelData === channel.node

                        width: deviceList.width
                        height: 32
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.isSink)
                                Pipewire.preferredDefaultAudioSink = modelData;
                            else
                                Pipewire.preferredDefaultAudioSource = modelData;
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.innerRadius
                            color: dev.current ? Qt.alpha(Theme.accent, 0.15) : dev.containsMouse ? Theme.hover : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            StyledText {
                                Layout.fillWidth: true
                                text: Audio.nameOf(dev.modelData)
                                color: dev.current ? Theme.accent : Theme.text
                            }

                            Icon {
                                visible: dev.current
                                text: Icons.check
                                color: Theme.accent
                            }
                        }
                    }
                }
            }
        }
    }

    Channel {
        Layout.preferredWidth: 340
        Layout.fillWidth: true
        title: "Output"
        node: Audio.sink
        devices: Audio.sinks
        icon: Icons.volumeHigh
        mutedIcon: Icons.volumeOff
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.surface0
    }

    Channel {
        title: "Input"
        node: Audio.source
        devices: Audio.sources
        icon: Icons.mic
        mutedIcon: Icons.micOff
    }
}
