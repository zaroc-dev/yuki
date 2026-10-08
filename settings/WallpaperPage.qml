import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

Page {
    id: root

    // Output being edited, or "all" for every output.
    property string target: Niri.focusedOutput || "all"
    readonly property string current: target === "all" ? Wallpapers.fallback : Wallpapers.pathFor(target)

    Section {
        title: "Folder"

        SettingRow {
            icon: Icons.folder
            label: "Wallpaper directory"
            description: `${Wallpapers.files.length} images`

            Rectangle {
                implicitWidth: 300
                implicitHeight: 36
                radius: Theme.innerRadius
                color: Qt.alpha(Theme.surface1, 0.6)
                border.width: 1
                border.color: dirInput.activeFocus ? Theme.accent : "transparent"

                TextInput {
                    id: dirInput

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    text: Settings.d.wallpaperDir
                    color: Theme.text
                    selectionColor: Qt.alpha(Theme.accent, 0.4)
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    onEditingFinished: Settings.d.wallpaperDir = text
                }
            }
        }
    }

    Section {
        title: "Screen"

        SettingRow {
            label: "Apply to"
            description: root.target === "all" ? "Sets the default and clears per-screen choices" : "Only this screen"

            Segmented {
                options: [{ value: "all", label: "All screens" }].concat(Quickshell.screens.map(s => ({ value: s.name, label: s.name, icon: Icons.monitor })))
                value: root.target
                onSelected: v => root.target = v
            }
        }

        SettingRow {
            label: "Shuffle"
            description: "Random wallpaper on every screen"

            Row {
                spacing: 6

                IconButton {
                    icon: Icons.shuffle
                    onClicked: Wallpapers.shuffleAll()
                }
            }
        }
    }

    Section {
        title: "Library"

        GridLayout {
            id: grid

            Layout.fillWidth: true
            Layout.margins: 10
            columns: 3
            columnSpacing: 10
            rowSpacing: 10

            Repeater {
                model: Wallpapers.files

                MouseArea {
                    id: thumb

                    required property string modelData
                    readonly property bool selected: modelData === root.current
                    readonly property var usedOn: Quickshell.screens.filter(s => Wallpapers.pathFor(s.name) === modelData).map(s => s.name)

                    Layout.fillWidth: true
                    Layout.preferredHeight: width * 9 / 16 + 26
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpapers.set(root.target, modelData)

                    ClippingRectangle {
                        id: frame

                        width: parent.width
                        height: width * 9 / 16
                        radius: Theme.radius
                        color: Theme.surface1
                        border.width: thumb.selected ? 3 : 0
                        border.color: Theme.accent

                        Image {
                            anchors.fill: parent
                            source: "file://" + thumb.modelData
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(320, 180)
                            asynchronous: true
                            scale: thumb.containsMouse ? 1.05 : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Theme.animSlow
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // Which screens show this one.
                        Row {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            spacing: 4

                            Repeater {
                                model: thumb.usedOn

                                Rectangle {
                                    required property string modelData

                                    width: tag.implicitWidth + 12
                                    height: 18
                                    radius: 9
                                    color: Qt.alpha(Theme.crust, 0.75)

                                    StyledText {
                                        id: tag

                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: thumb.selected
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            width: 22
                            height: 22
                            radius: 11
                            color: Theme.accent

                            Icon {
                                anchors.centerIn: parent
                                text: Icons.check
                                size: 13
                                color: Theme.onAccent
                            }
                        }
                    }

                    StyledText {
                        anchors.top: frame.bottom
                        anchors.topMargin: 5
                        width: parent.width
                        text: thumb.modelData.split("/").pop()
                        font.pixelSize: Theme.smallFontSize
                        color: thumb.selected ? Theme.accent : Theme.subtext0
                    }
                }
            }
        }
    }
}
