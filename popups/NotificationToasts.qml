import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.services

// Transient notification popups in the top-right of the focused output.
// One window per output (shown only on the focused one): moving a single
// window between outputs recreates its surface and drops the blur.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property ShellScreen modelData
        readonly property bool active: modelData.name === (Niri.focusedOutput || Quickshell.screens[0]?.name)
        readonly property var popups: active ? Notifs.popups.filter(n => n) : []

        visible: popups.length > 0
        screen: modelData
        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.gap
            right: Theme.gap
        }
        exclusiveZone: 0
        implicitWidth: 380
        implicitHeight: Math.max(1, column.implicitHeight)
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "yuki-notifications"
        // Each toast card adds its own rounded rect to this region.
        BackgroundEffect.blurRegion: Theme.blur ? blur : null

        Region {
            id: blur
        }

        Column {
            id: column

            width: parent.width
            spacing: Theme.gap

            move: Transition {
                NumberAnimation {
                    property: "y"
                    duration: Theme.anim
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: ScriptModel {
                    values: root.popups
                }

                NotificationCard {
                    id: card

                    required property var modelData

                    width: column.width
                    notif: modelData
                    toast: true
                    blurRegion: blur
                    opacity: 0
                    Component.onCompleted: opacity = 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.anim
                        }
                    }

                    Timer {
                        // expireTimeout is in seconds; -1/0 means "server decides".
                        readonly property real requested: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout * 1000 : Settings.d.toastSeconds * 1000

                        interval: Math.min(Math.max(requested, 2000), 20000)
                        running: card.modelData.urgency !== NotificationUrgency.Critical && !card.hovered
                        onTriggered: Notifs.hidePopup(card.modelData)
                    }
                }
            }
        }
    }
}
