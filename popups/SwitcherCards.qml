import QtQuick
import qs.config
import qs.components
import qs.services

// Switcher look "cards": a centered panel of big app tiles, the selected
// window's full title underneath.
Item {
    id: root

    readonly property Item panel: box
    readonly property real panelRadius: box.radius
    readonly property bool dims: true

    readonly property int tile: 128

    Rectangle {
        id: box

        anchors.centerIn: parent
        width: Math.min(row.contentWidth, root.width - Theme.gap * 8) + 24
        height: column.implicitHeight + 24
        radius: Theme.radius + 6
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

        // Swallow clicks so they don't cancel.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: column

            anchors.centerIn: parent
            spacing: 12

            ListView {
                id: row

                width: box.width - 24
                height: root.tile
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                interactive: false
                model: Switcher.windows
                currentIndex: Switcher.index
                highlightMoveDuration: Theme.anim
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: root.tile
                preferredHighlightEnd: width - root.tile

                highlight: Rectangle {
                    radius: Theme.radius + 2
                    color: Qt.alpha(Theme.accent, 0.18)
                    border.width: 1.5
                    border.color: Qt.alpha(Theme.accent, 0.8)
                }

                delegate: MouseArea {
                    id: card

                    required property var modelData
                    required property int index
                    readonly property bool selected: index === Switcher.index

                    width: root.tile
                    height: root.tile
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Switcher.select(index);
                        Switcher.commit();
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius + 2
                        color: card.containsMouse && !card.selected ? Theme.hover : "transparent"
                    }

                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 18
                        appId: card.modelData.app_id ?? ""
                        size: 56
                        scale: card.selected ? 1.06 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.anim
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: workspace.top
                        anchors.bottomMargin: 2
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        text: Apps.nameFor(card.modelData.app_id ?? "") || card.modelData.app_id || "Window"
                        font.weight: card.selected ? Font.DemiBold : Font.Normal
                        color: card.selected ? Theme.text : Theme.subtext1
                    }

                    StyledText {
                        id: workspace

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        text: Switcher.workspaceLabel(card.modelData)
                        color: Theme.overlay1
                        font.pixelSize: Theme.smallFontSize
                    }

                    // Urgent windows get a dot.
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        width: 8
                        height: 8
                        radius: 4
                        visible: card.modelData.is_urgent ?? false
                        color: Theme.red
                    }
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, row.width)
                horizontalAlignment: Text.AlignHCenter
                text: Switcher.current?.title || ""
                font.pixelSize: 15
            }
        }
    }
}
