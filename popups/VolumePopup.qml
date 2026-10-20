import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.components
import qs.services

BarPopup {
    id: root

    // One app's playback stream: icon (click to mute), name, what's playing, volume.
    component AppStream: RowLayout {
        id: stream

        required property var modelData
        readonly property bool muted: modelData.audio?.muted ?? false
        readonly property real volume: modelData.audio?.volume ?? 0

        Layout.fillWidth: true
        spacing: 12

        MouseArea {
            implicitWidth: 36
            implicitHeight: 36
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Audio.toggleMute(stream.modelData)

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: parent.containsMouse ? Theme.cardHover : Theme.card
            }

            AppIcon {
                anchors.centerIn: parent
                appId: Audio.appIdOf(stream.modelData)
                fallback: Icons.music
                size: 22
                opacity: stream.muted ? 0.35 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }
            }

            Icon {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                visible: stream.muted
                text: Icons.volumeOff
                size: 12
                color: Theme.red
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    text: Audio.appNameOf(stream.modelData)
                    font.pixelSize: Theme.smallFontSize + 1
                    font.weight: Font.DemiBold
                    color: stream.muted ? Theme.overlay1 : Theme.text
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Audio.mediaOf(stream.modelData)
                    color: Theme.overlay1
                    font.pixelSize: Theme.smallFontSize
                }

                StyledText {
                    text: `${Math.round(stream.volume * 100)}`
                    color: Theme.subtext1
                    font.family: Theme.displayFont
                    font.pixelSize: Theme.smallFontSize + 1
                    font.weight: Font.Bold
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                thickness: 10
                value: stream.volume
                fill: stream.muted ? Theme.overlay0 : Theme.accent
                onMoved: v => Audio.setVolume(stream.modelData, v)
            }
        }
    }

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
        spacing: 8

        SectionLabel {
            text: channel.title

            // Current device; opens the picker when there is a choice.
            MouseArea {
                id: picker

                implicitWidth: pickRow.implicitWidth + 16
                implicitHeight: 26
                enabled: channel.devices.length > 1
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: channel.expanded = !channel.expanded

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: channel.expanded ? Qt.alpha(Theme.accent, 0.18) : picker.containsMouse ? Theme.hover : "transparent"
                }

                Row {
                    id: pickRow

                    anchors.centerIn: parent
                    spacing: 4

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 200)
                        text: Audio.nameOf(channel.node)
                        color: Theme.subtext1
                        font.pixelSize: Theme.smallFontSize
                    }

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: picker.enabled
                        text: Icons.chevronRight
                        size: 13
                        color: Theme.subtext0
                        rotation: channel.expanded ? 90 : 0

                        Behavior on rotation {
                            NumberAnimation {
                                duration: Theme.anim
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            IconButton {
                size: 34
                icon: channel.muted ? channel.mutedIcon : channel.icon
                color: channel.muted ? Theme.red : Theme.text
                onClicked: Audio.toggleMute(channel.node)
            }

            StyledSlider {
                Layout.fillWidth: true
                thickness: 26
                value: channel.volume
                fill: channel.muted ? Theme.overlay0 : Theme.accent
                onMoved: v => Audio.setVolume(channel.node, v)
            }

            Row {
                Layout.preferredWidth: 46
                layoutDirection: Qt.RightToLeft

                StyledText {
                    anchors.baseline: pct.baseline
                    text: "%"
                    color: Theme.subtext0
                    font.pixelSize: Theme.smallFontSize
                    font.weight: Font.Bold
                }

                StyledText {
                    id: pct

                    text: channel.muted ? "—" : Math.round(channel.volume * 100)
                    color: channel.muted ? Theme.overlay1 : Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: 20
                    font.weight: Font.ExtraBold
                    font.features: {
                        "tnum": 1
                    }
                }
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
                        height: 36
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
                            radius: height / 2
                            color: dev.current ? Qt.alpha(Theme.accent, 0.16) : dev.containsMouse ? Theme.hover : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 12

                            StyledText {
                                Layout.fillWidth: true
                                text: Audio.nameOf(dev.modelData)
                                color: dev.current ? Theme.accent : Theme.text
                                font.weight: dev.current ? Font.DemiBold : Font.Normal
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

    PanelHeader {
        Layout.preferredWidth: 360
        icon: Audio.muted ? Icons.volumeOff : Icons.volumeHigh
        lit: !Audio.muted
        title: "Sound"
        subtitle: Audio.micInUse ? "Microphone in use" : Audio.playback.length > 0 ? `${Audio.playback.length} app${Audio.playback.length > 1 ? "s" : ""} playing` : "Nothing playing"
    }

    Channel {
        title: "Output"
        node: Audio.sink
        devices: Audio.sinks
        icon: Icons.volumeHigh
        mutedIcon: Icons.volumeOff
    }

    // Per-app mixer.
    ColumnLayout {
        Layout.fillWidth: true
        visible: Audio.playback.length > 0
        spacing: 10

        SectionLabel {
            text: "Apps"
        }

        Repeater {
            model: ScriptModel {
                values: Audio.playback
            }

            AppStream {}
        }
    }

    Channel {
        title: "Input"
        node: Audio.source
        devices: Audio.sources
        icon: Icons.mic
        mutedIcon: Icons.micOff
    }

    // Who is using the microphone right now.
    Rectangle {
        Layout.fillWidth: true
        visible: Audio.micInUse
        implicitHeight: 34
        radius: height / 2
        color: Qt.alpha(Theme.red, 0.12)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: Theme.red

                SequentialAnimation on opacity {
                    running: Audio.micInUse && root.visible
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.3
                        duration: 700
                    }
                    NumberAnimation {
                        to: 1
                        duration: 700
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: `Recording · ${[...new Set(Audio.recording.map(n => Audio.appNameOf(n)))].join(", ")}`
                color: Theme.red
                font.pixelSize: Theme.smallFontSize + 1
                font.weight: Font.DemiBold
            }
        }
    }
}
