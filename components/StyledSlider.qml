import QtQuick
import qs.config

// Minimal slider: drag or click to set, scroll to nudge.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real step: 0.05
    property color fill: Theme.accent
    readonly property bool dragging: area.pressed

    signal moved(real value)

    implicitHeight: 18
    implicitWidth: 200

    function setFrom(x) {
        const v = from + Math.max(0, Math.min(1, x / width)) * (to - from);
        moved(v);
    }

    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surface1

        Rectangle {
            width: Math.max(height, parent.width * root.frac)
            height: parent.height
            radius: parent.radius
            color: root.fill

            Behavior on width {
                enabled: !root.dragging
                NumberAnimation {
                    duration: 100
                }
            }
        }
    }

    Rectangle {
        x: root.frac * (root.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: area.containsMouse || root.dragging ? 16 : 12
        height: width
        radius: width / 2
        color: Theme.text
        border.width: 3
        border.color: root.fill

        Behavior on width {
            NumberAnimation {
                duration: Theme.anim
            }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: e => root.setFrom(e.x - 4)
        onPositionChanged: e => {
            if (pressed)
                root.setFrom(e.x - 4);
        }
        onWheel: e => root.moved(Math.max(root.from, Math.min(root.to, root.value + (e.angleDelta.y > 0 ? root.step : -root.step))))
    }
}
