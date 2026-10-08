import QtQuick
import qs.config
import qs.services

// niri workspaces of this bar's output.
Item {
    id: root

    required property string output
    readonly property var workspaces: Niri.workspacesOn(output)
    readonly property bool outputFocused: Niri.focusedOutput === output

    implicitWidth: row.implicitWidth + 12
    implicitHeight: parent?.height ?? 24

    MouseArea {
        anchors.fill: parent
        onWheel: e => Niri.action(e.angleDelta.y > 0 ? "FocusWorkspaceUp" : "FocusWorkspaceDown")
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: root.workspaces

            MouseArea {
                id: ws

                required property var modelData
                readonly property bool active: modelData.is_active
                readonly property bool occupied: Niri.windowCount(modelData.id) > 0

                width: active ? 28 : 12
                height: 22
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(modelData.id)

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.anim
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: ws.active ? 10 : ws.containsMouse ? 10 : 8
                    radius: height / 2
                    color: {
                        if (ws.modelData.is_urgent)
                            return Theme.red;
                        if (ws.active)
                            return root.outputFocused ? Theme.accent : Theme.overlay2;
                        return ws.occupied ? Theme.overlay0 : Theme.surface1;
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.anim
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.anim
                        }
                    }
                }
            }
        }
    }
}
