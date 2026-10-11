import QtQuick
import qs.config
import qs.components
import qs.services

Item {
    id: root

    required property string output
    readonly property var window: Niri.activeWindowOn(output)
    readonly property bool shown: window !== null && Settings.d.showActiveWindow
    // Room the bar gives the title (with its spacing); below a readable minimum
    // only the icon stays. fixedWidth/titleNatural never depend on the title's
    // laid-out width, so the bar's budget can't feed back into itself.
    property real titleMax: 320 + row.spacing
    readonly property real titleNatural: Math.min(title.implicitWidth, 320) + row.spacing
    readonly property real fixedWidth: icon.width + 12

    visible: shown
    implicitWidth: row.implicitWidth + 12
    implicitHeight: parent?.height ?? 24
    opacity: Niri.focusedOutput === output ? 1 : 0.6

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8

        AppIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            appId: root.window?.app_id ?? ""
            size: 18
        }

        StyledText {
            id: title

            readonly property string target: root.window?.title || Apps.nameFor(root.window?.app_id ?? "")

            anchors.verticalCenter: parent.verticalCenter
            visible: root.titleMax - row.spacing >= 48
            width: Math.min(implicitWidth, 320, root.titleMax - row.spacing)
            text: target
            // Fade the text out and back in when the window changes.
            onTargetChanged: fade.restart()

            SequentialAnimation {
                id: fade

                NumberAnimation {
                    target: title
                    property: "opacity"
                    to: 0.2
                    duration: 80
                }
                // Read at run time: a bound PropertyAction value can still be the
                // previous title when onTargetChanged restarts the animation.
                ScriptAction {
                    script: title.text = title.target
                }
                NumberAnimation {
                    target: title
                    property: "opacity"
                    to: 1
                    duration: 160
                }
            }
        }
    }
}
