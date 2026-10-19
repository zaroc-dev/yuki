import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Application launcher on the focused output: a command palette that grows
// out of the middle of the bar.
LazyLoader {
    active: Ui.launcherOpen

    DropSheet {
        id: win

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

        WlrLayershell.namespace: "yuki-launcher"
        onDismissed: close()

        // Search: big type, the query is the hero.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            radius: 20
            color: Theme.well
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.35)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 12
                spacing: 12

                Icon {
                    text: Icons.search
                    size: 22
                    color: Theme.accent
                }

                TextInput {
                    id: search

                    Layout.fillWidth: true
                    color: Theme.text
                    selectionColor: Qt.alpha(Theme.accent, 0.4)
                    font.family: Theme.displayFont
                    font.pixelSize: 21
                    font.weight: Font.Bold
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
                        text: "Launch something…"
                        color: Theme.overlay0
                        font.family: Theme.displayFont
                        font.pixelSize: 21
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    implicitWidth: resultCount.implicitWidth + 16
                    implicitHeight: 26
                    radius: 13
                    color: Theme.card

                    StyledText {
                        id: resultCount

                        anchors.centerIn: parent
                        text: `${win.results.length}`
                        color: Theme.subtext1
                        font.family: Theme.displayFont
                        font.pixelSize: Theme.smallFontSize
                        font.weight: Font.Bold
                    }
                }
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            // From the count: contentHeight of a not yet laid out list is 0.
            Layout.preferredHeight: Math.min(count, 7) * 58 - spacing
            visible: count > 0
            clip: true
            model: win.results
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 160
            highlightResizeDuration: 0
            highlight: Rectangle {
                radius: 18
                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0
                        color: Qt.alpha(Theme.accent, 0.24)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Theme.accent2, 0.06)
                    }
                }

                // Accent tick on the left of the selection.
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 0
                    width: 3
                    height: parent.height * 0.5
                    radius: 1.5
                    color: Theme.accent
                }
            }

            delegate: MouseArea {
                id: item

                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem

                width: ListView.view.width
                height: 56
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
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 14

                    AppIcon {
                        iconName: item.modelData.icon
                        size: 34
                        scale: item.current ? 1.08 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.anim
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.name
                            color: item.current ? Theme.text : Theme.subtext1
                            font.pixelSize: Theme.fontSize + 1
                            font.weight: item.current ? Font.Bold : Font.Medium
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

                    // Keycap on the selected row.
                    Rectangle {
                        visible: item.current
                        implicitWidth: enter.implicitWidth + 14
                        implicitHeight: 22
                        radius: 7
                        color: Theme.card
                        border.width: 1
                        border.color: Theme.rim

                        StyledText {
                            id: enter

                            anchors.centerIn: parent
                            text: "↵"
                            font.weight: Font.Bold
                            color: Theme.subtext1
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: 18
            visible: list.count === 0
            spacing: 2

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Nothing by that name"
                font.family: Theme.displayFont
                font.pixelSize: 16
                font.weight: Font.ExtraBold
                color: Theme.subtext1
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Try part of the name or what it does."
                color: Theme.overlay1
                font.pixelSize: Theme.smallFontSize + 1
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 2
            spacing: 14

            Repeater {
                model: [
                    { key: "↵", label: "launch" },
                    { key: "↑↓", label: "move" },
                    { key: "Esc", label: "close" },
                    { key: "RMB", label: "pin" }
                ]

                Row {
                    id: hint

                    required property var modelData

                    spacing: 5

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: keyLabel.implicitWidth + 10
                        height: 18
                        radius: 5
                        color: Theme.card
                        border.width: 1
                        border.color: Theme.rim

                        StyledText {
                            id: keyLabel

                            anchors.centerIn: parent
                            text: hint.modelData.key
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: Theme.subtext1
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: hint.modelData.label
                        color: Theme.overlay1
                        font.pixelSize: Theme.smallFontSize
                    }
                }
            }
        }
    }
}
