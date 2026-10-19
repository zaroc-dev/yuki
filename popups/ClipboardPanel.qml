import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Clipboard history on the focused output, as a sheet out of the bar.
LazyLoader {
    active: Ui.clipboardOpen

    DropSheet {
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

        bodyWidth: 620
        WlrLayershell.namespace: "yuki-clipboard"
        onDismissed: close()

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
                anchors.rightMargin: 10
                spacing: 12

                Icon {
                    text: Icons.clipboard
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
                        text: "Search the clipboard…"
                        color: Theme.overlay0
                        font.family: Theme.displayFont
                        font.pixelSize: 21
                        font.weight: Font.Bold
                    }
                }

                IconButton {
                    icon: Icons.trash
                    color: containsMouse ? Theme.red : Theme.subtext0
                    enabled: Clipboard.entries.length > 0
                    onClicked: Clipboard.wipe()
                }
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 460)
            visible: count > 0
            clip: true
            spacing: 2
            model: ScriptModel {
                values: win.results
            }
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 160
            highlightResizeDuration: 120
            // The ScriptModel fills in after creation; start on the newest entry.
            onCountChanged: {
                if (currentIndex < 0 && count > 0)
                    currentIndex = 0;
            }
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

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
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
                height: modelData.isImage ? 80 : 50
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
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 14

                    ClippingRectangle {
                        visible: item.modelData.isImage
                        Layout.preferredWidth: 104
                        Layout.preferredHeight: 62
                        radius: 12
                        color: Theme.card

                        Image {
                            anchors.fill: parent
                            source: Clipboard.thumbs[item.modelData.id] ?? ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(208, 124)
                            asynchronous: true
                        }
                    }

                    Rectangle {
                        visible: !item.modelData.isImage
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 11
                        color: item.current ? Qt.alpha(Theme.accent, 0.2) : Theme.card

                        Icon {
                            anchors.centerIn: parent
                            text: Icons.text
                            size: 15
                            color: item.current ? Theme.accent : Theme.overlay1
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: item.modelData.preview
                        maximumLineCount: 2
                        wrapMode: Text.WrapAnywhere
                        color: item.current ? Theme.text : Theme.subtext1
                        font.weight: item.current ? Font.Medium : Font.Normal
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

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: 18
            visible: list.count === 0
            spacing: 2

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Clipboard.entries.length === 0 ? "Nothing copied yet" : "No matches"
                font.family: Theme.displayFont
                font.pixelSize: 16
                font.weight: Font.ExtraBold
                color: Theme.subtext1
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Clipboard.entries.length === 0 ? "Copied text and images show up here." : "Try another word."
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
                    { key: "↵", label: "copy" },
                    { key: "↑↓", label: "move" },
                    { key: "Del", label: "remove" },
                    { key: "Esc", label: "close" }
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
