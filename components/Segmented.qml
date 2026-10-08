import QtQuick
import qs.config

// Row of mutually exclusive options with a sliding highlight.
// options: [{ value, label, icon? }]
Rectangle {
    id: root

    required property var options
    property var value

    signal selected(var value)

    readonly property int index: options.findIndex(o => o.value === value)
    // itemAt() isn't reactive; depending on the row's size re-evaluates it once laid out.
    readonly property Item currentItem: {
        row.width;
        repeater.count;
        return index >= 0 ? repeater.itemAt(index) : null;
    }

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 34
    radius: height / 2
    color: Qt.alpha(Theme.surface0, 0.8)

    Rectangle {
        visible: root.currentItem !== null
        x: 4 + (root.currentItem?.x ?? 0)
        y: 4
        width: root.currentItem?.width ?? 0
        height: parent.height - 8
        radius: height / 2
        color: Theme.accent

        Behavior on x {
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
    }

    Row {
        id: row

        x: 4
        y: 4
        height: parent.height - 8

        Repeater {
            id: repeater

            model: root.options

            MouseArea {
                id: opt

                required property var modelData
                required property int index
                readonly property bool current: index === root.index

                width: content.implicitWidth + 24
                height: parent.height
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(modelData.value)

                Row {
                    id: content

                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        visible: !!opt.modelData.icon
                        text: opt.modelData.icon ?? ""
                        size: 14
                        color: opt.current ? Theme.onAccent : Theme.subtext0
                    }

                    StyledText {
                        text: opt.modelData.label
                        font.pixelSize: Theme.smallFontSize + 1
                        font.weight: opt.current ? Font.DemiBold : Font.Normal
                        color: opt.current ? Theme.onAccent : Theme.subtext1
                    }
                }
            }
        }
    }
}
