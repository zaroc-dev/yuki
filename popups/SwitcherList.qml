import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Switcher look "list": a launcher-style panel, one row per window with its
// title, app and workspace.
Item {
    id: root

    readonly property Item panel: box
    readonly property real panelRadius: box.radius
    readonly property bool dims: true

    readonly property int rowHeight: 52

    Rectangle {
        id: box

        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.18
        width: Math.min(560, root.width - Theme.gap * 4)
        height: column.implicitHeight + 24
        radius: 28
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.rim
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

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6

                StyledText {
                    Layout.fillWidth: true
                    text: "WINDOWS"
                    color: Theme.overlay2
                    font.pixelSize: Theme.smallFontSize
                    font.letterSpacing: 1
                    font.weight: Font.DemiBold
                }

                StyledText {
                    text: `${Switcher.index + 1} / ${Switcher.windows.length}`
                    color: Theme.overlay1
                    font.pixelSize: Theme.smallFontSize
                }
            }

            ListView {
                id: list

                Layout.fillWidth: true
                implicitHeight: Math.min(count, 8) * (root.rowHeight + spacing) - spacing
                spacing: 2
                clip: true
                interactive: false
                model: Switcher.windows
                currentIndex: Switcher.index
                highlightMoveDuration: Theme.anim
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: root.rowHeight
                preferredHighlightEnd: height - root.rowHeight

                highlight: Rectangle {
                    radius: Theme.radius
                    color: Qt.alpha(Theme.accent, 0.16)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: parent.height - 20
                        radius: 1.5
                        color: Theme.accent
                    }
                }

                delegate: MouseArea {
                    id: entry

                    required property var modelData
                    required property int index
                    readonly property bool selected: index === Switcher.index

                    width: ListView.view.width
                    height: root.rowHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Switcher.select(index);
                        Switcher.commit();
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius
                        color: entry.containsMouse && !entry.selected ? Theme.hover : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 12

                        AppIcon {
                            appId: entry.modelData.app_id ?? ""
                            size: 30
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                Layout.fillWidth: true
                                text: entry.modelData.title || Apps.nameFor(entry.modelData.app_id ?? "")
                                font.weight: entry.selected ? Font.DemiBold : Font.Normal
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Apps.nameFor(entry.modelData.app_id ?? "") || entry.modelData.app_id || ""
                                color: Theme.subtext0
                                font.pixelSize: Theme.smallFontSize
                            }
                        }

                        Rectangle {
                            visible: entry.modelData.is_urgent ?? false
                            implicitWidth: 8
                            implicitHeight: 8
                            radius: 4
                            color: Theme.red
                        }

                        // Workspace chip.
                        Rectangle {
                            implicitWidth: chip.implicitWidth + 16
                            implicitHeight: 22
                            radius: height / 2
                            visible: chip.text !== ""
                            color: entry.selected ? Qt.alpha(Theme.accent, 0.22) : Qt.alpha(Theme.surface0, 0.7)

                            StyledText {
                                id: chip

                                anchors.centerIn: parent
                                text: Switcher.workspaceLabel(entry.modelData)
                                color: entry.selected ? Theme.text : Theme.subtext0
                                font.pixelSize: Theme.smallFontSize
                            }
                        }
                    }
                }
            }
        }
    }
}
