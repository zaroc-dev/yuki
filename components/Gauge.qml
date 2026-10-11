import QtQuick
import QtQuick.Shapes
import qs.config

// Ring gauge (0..1) with an icon in the middle.
Item {
    id: root

    property real value: 0
    property string icon
    property color color: Theme.accent
    property real size: 56
    property real thickness: 5

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(Theme.text, 0.1)
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, root.value))

                Behavior on sweepAngle {
                    NumberAnimation {
                        duration: Theme.animSlow
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    Icon {
        anchors.centerIn: parent
        text: root.icon
        size: root.size * 0.34
        color: root.color
    }
}
