import QtQuick
import qs.config

// Control-center slider: a thick capsule that fills with the aurora gradient,
// an optional glyph riding inside it. Thin ones (seek bars) get a round knob.
// Drag or click to set, scroll to nudge.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real step: 0.05
    property color fill: Theme.accent
    property color fill2: Qt.colorEqual(fill, Theme.accent) ? Theme.accent2 : fill
    property real thickness: 22
    // Glyph inside the start of the track.
    property string icon: ""
    readonly property bool dragging: area.pressed
    readonly property bool thin: thickness < 12
    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))

    signal moved(real value)

    implicitHeight: Math.max(thickness, thin ? 16 : 0)
    implicitWidth: 200

    function setFrom(x) {
        const v = from + Math.max(0, Math.min(1, x / width)) * (to - from);
        moved(v);
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness + (area.containsMouse || root.dragging ? (root.thin ? 2 : 2) : 0)
        radius: height / 2
        color: Theme.well

        Behavior on height {
            NumberAnimation {
                duration: Theme.anim
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: bar

            // Never narrower than a circle, so the rounded end always shows.
            width: track.height + (track.width - track.height) * root.frac
            height: parent.height
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: root.fill
                }
                GradientStop {
                    position: 1
                    color: root.fill2
                }
            }

            Behavior on width {
                enabled: !root.dragging
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            // Grip line at the end of a thick fill.
            Rectangle {
                visible: !root.thin
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width - width - root.thickness / 2 + 1
                width: 3
                height: parent.height * (area.containsMouse || root.dragging ? 0.6 : 0.45)
                radius: 1.5
                color: Theme.onAccent
                opacity: 0.85

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }
            }
        }

        Icon {
            visible: root.icon !== "" && !root.thin
            anchors.verticalCenter: parent.verticalCenter
            x: root.thickness / 2 - 1
            text: root.icon
            size: Math.round(root.thickness * 0.6)
            color: bar.width > x + width + 6 ? Theme.onAccent : Theme.subtext1
        }
    }

    // Round knob for thin sliders.
    Rectangle {
        visible: root.thin
        x: root.frac * (root.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: area.containsMouse || root.dragging ? 16 : 12
        height: width
        radius: width / 2
        color: Theme.text
        border.width: 3
        border.color: root.fill2

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
