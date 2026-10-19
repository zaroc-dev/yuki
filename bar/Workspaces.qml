import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.services

// niri workspaces of this bar's output, inside a well. The active one opens
// into a live minimap of its scrolling layout (columns to scale, stacked
// windows split, the focused one solid) on a drop of liquid aurora: the
// edge in the direction of travel darts ahead and the other follows, so the
// drop stretches across before settling.
Rectangle {
    id: root

    required property string output
    property real screenHeight: 1440
    readonly property var workspaces: Niri.workspacesOn(output)
    readonly property bool outputFocused: Niri.focusedOutput === output
    readonly property int activeIndex: workspaces.findIndex(w => w.is_active)
    readonly property real slot: 24
    // Minimap tiles: as tall as the drop allows, widths to the same scale as
    // the screen, squeezed if the strip gets long.
    readonly property real mapHeight: height - 16
    readonly property real mapScale: mapHeight / Math.max(1, screenHeight)
    readonly property real mapMax: 140
    readonly property real mapGap: 2
    // Where the drop goes, from the data rather than the (animating) slots:
    // everything left of the active workspace is a plain slot.
    readonly property real activeWidth: activeIndex >= 0 ? widthOf(Niri.columnsOf(workspaces[activeIndex].id), true) : slot
    // Ink on the drop; the drop is dimmed on unfocused outputs.
    readonly property color ink: outputFocused ? Theme.onAccent : Theme.text

    function columnWidth(col, k) {
        return Math.max(4, Math.round(Math.max(...col.map(w => w.layout.tile_size[0])) * mapScale * k));
    }

    function mapNatural(columns) {
        return columns.reduce((sum, col) => sum + columnWidth(col, 1), 0) + Math.max(0, columns.length - 1) * mapGap;
    }

    function squeeze(columns) {
        return Math.min(1, mapMax / Math.max(1, mapNatural(columns)));
    }

    function widthOf(columns, active) {
        return active && columns.length > 0 ? Math.round(mapNatural(columns) * squeeze(columns)) + 18 : slot;
    }

    implicitWidth: row.implicitWidth + 6
    implicitHeight: parent?.height ?? 30
    radius: height / 2
    color: Theme.well

    MouseArea {
        anchors.fill: parent
        onWheel: e => Niri.action(e.angleDelta.y > 0 ? "FocusWorkspaceUp" : "FocusWorkspaceDown")
    }

    Item {
        id: drop

        property real fromX: Math.max(0, root.activeIndex) * root.slot
        property real toX: fromX + root.activeWidth

        x: 3 + fromX
        y: 3
        width: toX - fromX
        height: root.height - 6
        visible: root.activeIndex >= 0

        Behavior on fromX {
            id: leftEdge

            SmoothedAnimation {
                velocity: leftEdge.targetValue < drop.fromX ? 420 : 150
            }
        }
        Behavior on toX {
            id: rightEdge

            SmoothedAnimation {
                velocity: rightEdge.targetValue > drop.toX ? 420 : 150
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
            id: repeater

            // Keyed by id: niri patches workspaces as new objects, and plain
            // arrays would rebuild every slot (no width animation).
            model: ScriptModel {
                values: root.workspaces
                objectProp: "id"
            }

            MouseArea {
                id: ws

                required property var modelData
                required property int index
                readonly property bool active: modelData.is_active
                readonly property var columns: Niri.columnsOf(modelData.id)
                readonly property bool occupied: columns.length > 0 || Niri.windowCount(modelData.id) > 0
                readonly property bool mapped: active && columns.length > 0

                width: root.widthOf(columns, active)
                height: root.height - 6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(modelData.id)

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animSlow
                        easing.type: Easing.OutQuint
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: ws.containsMouse && !ws.active ? Theme.hover : "transparent"
                }

                StyledText {
                    anchors.centerIn: parent
                    opacity: ws.mapped ? 0 : 1
                    scale: ws.mapped ? 0.6 : ws.active ? 1.08 : 1
                    text: ws.modelData.name || ws.modelData.idx
                    font.family: Theme.displayFont
                    font.pixelSize: 12
                    font.weight: ws.active ? Font.Black : ws.occupied ? Font.Bold : Font.Medium
                    color: ws.active ? root.ink : ws.occupied ? Theme.text : Theme.overlay0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.anim
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.anim
                            easing.type: Easing.OutBack
                        }
                    }
                }

                // The minimap: one column of tiles per niri column.
                Row {
                    anchors.centerIn: parent
                    spacing: root.mapGap
                    opacity: ws.mapped ? 1 : 0
                    scale: ws.mapped ? 1 : 0.6
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.anim
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animSlow
                            easing.type: Easing.OutBack
                        }
                    }

                    Repeater {
                        model: ws.columns

                        Column {
                            id: col

                            required property var modelData
                            readonly property real total: modelData.reduce((sum, w) => sum + w.layout.tile_size[1], 0)

                            width: root.columnWidth(modelData, root.squeeze(ws.columns))
                            spacing: root.mapGap

                            Behavior on width {
                                NumberAnimation {
                                    duration: Theme.animSlow
                                    easing.type: Easing.OutQuint
                                }
                            }

                            Repeater {
                                model: col.modelData

                                MouseArea {
                                    id: tile

                                    required property var modelData
                                    readonly property bool focused: modelData.id === ws.modelData.active_window_id

                                    width: col.width
                                    height: Math.max(2, (root.mapHeight - root.mapGap * (col.modelData.length - 1)) * modelData.layout.tile_size[1] / Math.max(1, col.total))
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Niri.focusWindow(modelData.id)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Math.min(3, width / 2)
                                        color: tile.focused ? root.ink : Qt.alpha(root.ink, tile.containsMouse ? 0.6 : 0.32)
                                        border.width: tile.modelData.is_urgent ? 1 : 0
                                        border.color: Theme.red

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Theme.anim
                                            }
                                        }
                                    }
                                }
                            }
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
                    visible: ws.modelData.is_urgent && !ws.mapped
                    color: Theme.red
                }
            }
        }
    }
}
