import QtQuick
import qs.config
import qs.components
import qs.services

// Switcher look "island": a compact strip of app icons hanging under the
// bar, the selected window's title beneath. No dimming; reads as part of the bar.
Item {
    id: root

    readonly property Item panel: box
    readonly property real panelRadius: box.radius
    readonly property bool dims: false

    readonly property int slot: 48

    Rectangle {
        id: box

        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.barHeight + Theme.gap * 2 - (1 - opacity) * 10
        width: Math.min(Math.max(strip.contentWidth, title.implicitWidth + 12, 220), root.width - Theme.gap * 4) + 20
        height: strip.height + title.height + 30
        radius: Theme.radius + 4
        color: Theme.popupBg
        border.width: 1
        border.color: Theme.barBorder
        opacity: 0
        Component.onCompleted: opacity = 1

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Theme.anim
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        ListView {
            id: strip

            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            width: Math.min(contentWidth, box.width - 20)
            height: root.slot
            orientation: ListView.Horizontal
            spacing: 4
            clip: true
            interactive: false
            model: Switcher.windows
            currentIndex: Switcher.index
            highlightMoveDuration: Theme.anim
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: root.slot
            preferredHighlightEnd: width - root.slot

            highlight: Rectangle {
                radius: Theme.radius
                color: Theme.accent
            }

            delegate: MouseArea {
                id: icon

                required property var modelData
                required property int index
                readonly property bool selected: index === Switcher.index

                width: root.slot
                height: root.slot
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Switcher.select(index);
                    Switcher.commit();
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: icon.containsMouse && !icon.selected ? Theme.hover : "transparent"
                }

                AppIcon {
                    anchors.centerIn: parent
                    appId: icon.modelData.app_id ?? ""
                    size: icon.selected ? 30 : 26
                    opacity: icon.selected ? 1 : 0.75

                    Behavior on size {
                        NumberAnimation {
                            duration: Theme.anim
                            easing.type: Easing.OutBack
                        }
                    }
                }

                // Urgent windows get a dot.
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 5
                    width: 7
                    height: 7
                    radius: 3.5
                    visible: icon.modelData.is_urgent ?? false
                    color: Theme.red
                }
            }
        }

        Row {
            id: title

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: strip.bottom
            anchors.topMargin: 8
            height: 20
            spacing: 8

            StyledText {
                id: titleText

                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, root.width - Theme.gap * 4 - 120)
                text: Switcher.current?.title || Apps.nameFor(Switcher.current?.app_id ?? "")
                font.weight: Font.DemiBold
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Switcher.workspaceLabel(Switcher.current)
                color: Theme.overlay1
                font.pixelSize: Theme.smallFontSize
            }
        }
    }
}
