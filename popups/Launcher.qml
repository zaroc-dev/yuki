import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Application launcher overlay, shown on the focused output.
LazyLoader {
    active: Ui.launcherOpen

    PanelWindow {
        id: win

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
        WlrLayershell.namespace: "yuki-launcher"
        BackgroundEffect.blurRegion: Region {
            item: Theme.blur ? box : null
            radius: box.radius
        }

        property var results: Apps.search(search.text)

        function close() {
            Ui.launcherOpen = false;
        }

        function launch(entry) {
            if (!entry)
                return;
            Apps.launch(entry);
            close();
        }

        Rectangle {
            id: dim

            anchors.fill: parent
            color: Qt.alpha(Theme.crust, 0.4)
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
            y: parent.height * 0.18
            width: 560
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

            // Swallow clicks so they don't close the launcher.
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: column

                anchors.fill: parent
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
                        anchors.rightMargin: 14
                        spacing: 10

                        Icon {
                            text: Icons.search
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
                            Keys.onReturnPressed: win.launch(win.results[list.currentIndex])
                            Keys.onEnterPressed: win.launch(win.results[list.currentIndex])
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onTabPressed: list.incrementCurrentIndex()
                            Keys.onBacktabPressed: list.decrementCurrentIndex()

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !search.text
                                text: "Search applications…"
                                color: Theme.overlay0
                                font.pixelSize: 15
                            }
                        }

                        StyledText {
                            text: `${win.results.length}`
                            color: Theme.overlay1
                            font.pixelSize: Theme.smallFontSize
                        }
                    }
                }

                ListView {
                    id: list

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 8 * 52)
                    visible: count > 0
                    clip: true
                    model: win.results
                    spacing: 2
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
                        height: 50
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = index
                        onClicked: e => {
                            if (e.button === Qt.RightButton)
                                Apps.togglePin(modelData);
                            else
                                win.launch(modelData);
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            AppIcon {
                                iconName: item.modelData.icon
                                size: 30
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: item.modelData.name
                                    color: item.ListView.isCurrentItem ? Theme.accent : Theme.text
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: item.modelData.comment || item.modelData.genericName || ""
                                    color: Theme.subtext0
                                    font.pixelSize: Theme.smallFontSize
                                }
                            }

                            Icon {
                                visible: Apps.isPinned(item.modelData)
                                text: Icons.pin
                                size: 14
                                color: Theme.accent
                            }
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: 12
                    visible: list.count === 0
                    text: "No matches"
                    color: Theme.overlay1
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Enter to launch · ↑↓ to move · right-click to pin"
                    color: Theme.overlay0
                    font.pixelSize: Theme.smallFontSize
                }
            }
        }
    }
}
