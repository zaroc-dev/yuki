import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Clipboard history overlay on the focused output.
LazyLoader {
    active: Ui.clipboardOpen

    PanelWindow {
        id: win

        readonly property var results: Clipboard.search(search.text)

        function close() {
            Ui.clipboardOpen = false;
        }

        function pick(entry) {
            if (!entry)
                return;
            Clipboard.copy(entry);
            close();
        }

        Component.onCompleted: Clipboard.refresh()

        screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-clipboard"
        BackgroundEffect.blurRegion: Region {
            item: Theme.blur ? box : null
            radius: box.radius
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.crust, 0.35)
            opacity: 0
            Component.onCompleted: opacity = 1

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }

        Rectangle {
            id: box

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.16
            width: 600
            height: column.implicitHeight + 24
            radius: Theme.radius + 4
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.barBorder
            opacity: 0
            scale: 0.96
            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Theme.anim
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                SmoothedAnimation {
                    duration: 200
                    velocity: -1
                }
            }

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: column

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Theme.radius
                    color: Theme.surface0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 6
                        spacing: 10

                        Icon {
                            text: Icons.clipboard
                            size: 18
                            color: Theme.accent
                        }

                        TextInput {
                            id: search

                            Layout.fillWidth: true
                            color: Theme.text
                            selectionColor: Qt.alpha(Theme.accent, 0.4)
                            font.family: Theme.font
                            font.pixelSize: 15
                            focus: true
                            onTextChanged: list.currentIndex = 0

                            Keys.onEscapePressed: win.close()
                            Keys.onReturnPressed: win.pick(win.results[list.currentIndex])
                            Keys.onEnterPressed: win.pick(win.results[list.currentIndex])
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onTabPressed: list.incrementCurrentIndex()
                            Keys.onBacktabPressed: list.decrementCurrentIndex()
                            Keys.onDeletePressed: {
                                const e = win.results[list.currentIndex];
                                if (e)
                                    Clipboard.remove(e);
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !search.text
                                text: "Search clipboard history…"
                                color: Theme.overlay0
                                font.pixelSize: 15
                            }
                        }

                        IconButton {
                            icon: Icons.trash
                            color: Theme.subtext0
                            enabled: Clipboard.entries.length > 0
                            onClicked: Clipboard.wipe()
                        }
                    }
                }

                ListView {
                    id: list

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 440)
                    visible: count > 0
                    clip: true
                    spacing: 2
                    model: ScriptModel {
                        values: win.results
                    }
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 120
                    highlight: Rectangle {
                        radius: Theme.radius
                        color: Qt.alpha(Theme.accent, 0.16)
                    }

                    delegate: MouseArea {
                        id: item

                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: modelData.isImage ? 72 : 46
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = index
                        onClicked: win.pick(modelData)
                        Component.onCompleted: {
                            if (modelData.isImage)
                                Clipboard.thumb(modelData);
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 6
                            spacing: 12

                            ClippingRectangle {
                                visible: item.modelData.isImage
                                Layout.preferredWidth: 96
                                Layout.preferredHeight: 56
                                radius: Theme.innerRadius
                                color: Theme.surface1

                                Image {
                                    anchors.fill: parent
                                    source: Clipboard.thumbs[item.modelData.id] ?? ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize: Qt.size(192, 112)
                                    asynchronous: true
                                }
                            }

                            Icon {
                                visible: !item.modelData.isImage
                                text: Icons.text
                                color: Theme.overlay1
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: item.modelData.preview
                                maximumLineCount: 2
                                wrapMode: Text.WrapAnywhere
                                color: item.ListView.isCurrentItem ? Theme.text : Theme.subtext1
                            }

                            IconButton {
                                size: 28
                                iconSize: 14
                                icon: Icons.close
                                color: Theme.overlay1
                                visible: item.containsMouse
                                onClicked: Clipboard.remove(item.modelData)
                            }
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: 12
                    visible: list.count === 0
                    text: Clipboard.entries.length === 0 ? "Clipboard history is empty" : "No matches"
                    color: Theme.overlay1
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Enter to copy · Del to remove"
                    color: Theme.overlay0
                    font.pixelSize: Theme.smallFontSize
                }
            }
        }
    }
}
