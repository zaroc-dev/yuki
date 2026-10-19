import QtQuick
import qs.config
import qs.components
import qs.services

// niri workspaces of this bar's output, inside a well. The active marker is a
// drop of liquid: its leading edge darts ahead and the trailing edge follows,
// so it stretches across the gap before settling.
Rectangle {
    id: root

    required property string output
    readonly property var workspaces: Niri.workspacesOn(output)
    readonly property bool outputFocused: Niri.focusedOutput === output
    readonly property int activeIndex: workspaces.findIndex(w => w.is_active)
    readonly property real slot: 24

    implicitWidth: row.implicitWidth + 6
    implicitHeight: parent?.height ?? 30
    radius: height / 2
    color: Theme.well

    MouseArea {
        anchors.fill: parent
        onWheel: e => Niri.action(e.angleDelta.y > 0 ? "FocusWorkspaceUp" : "FocusWorkspaceDown")
    }

    // Two followers of the active slot at different speeds; the drop spans both.
    Item {
        id: drop

        readonly property real target: root.activeIndex * root.slot
        property real lead: target
        property real tail: target

        x: 3 + Math.min(lead, tail)
        y: 3
        width: Math.abs(lead - tail) + root.slot
        height: root.height - 6
        visible: root.activeIndex >= 0

        Behavior on lead {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        Behavior on tail {
            NumberAnimation {
                duration: 520
                easing.type: Easing.OutQuint
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            opacity: root.outputFocused ? 1 : 0.45
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Theme.accent
                }
                GradientStop {
                    position: 1
                    color: Theme.accent2
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim
                }
            }
        }
    }

    Row {
        id: row

        x: 3
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.workspaces

            MouseArea {
                id: ws

                required property var modelData
                required property int index
                readonly property bool active: modelData.is_active
                readonly property bool occupied: Niri.windowCount(modelData.id) > 0

                width: root.slot
                height: root.height - 6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(modelData.id)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: ws.containsMouse && !ws.active ? Theme.hover : "transparent"
                }

                StyledText {
                    anchors.centerIn: parent
                    text: ws.modelData.name || ws.modelData.idx
                    font.family: Theme.displayFont
                    font.pixelSize: 12
                    font.weight: ws.active ? Font.Black : ws.occupied ? Font.Bold : Font.Medium
                    color: ws.active ? Theme.onAccent : ws.occupied ? Theme.text : Theme.overlay0
                    scale: ws.active ? 1.08 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.anim
                            easing.type: Easing.OutBack
                        }
                    }
                }

                // Urgent: a red spark under the number.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: 4
                    height: 4
                    radius: 2
                    visible: ws.modelData.is_urgent
                    color: Theme.red
                }
            }
        }
    }
}
