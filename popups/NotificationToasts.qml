import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.services

// Toasts drop out of the bar's top-right corner as a drawer down the screen
// edge; it grows and shrinks with the stack and folds back into the corner
// when the last one goes. One window per output (shown only on the focused
// one): moving a single window between outputs recreates its surface and
// drops the blur.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property ShellScreen modelData
        readonly property bool active: modelData.name === (Niri.focusedOutput || Quickshell.screens[0]?.name)
        // The notification center lists the same things.
        readonly property var popups: active && Ui.activePopup?.name !== "notifications" ? Notifs.popups.filter(n => n) : []
        readonly property real padding: 10
        property real drawerHeight: popups.length > 0 ? column.implicitHeight + padding * 2 : 0

        visible: popups.length > 0 || drawerHeight > 0.5
        onVisibleChanged: {
            if (visible)
                Ui.toastScreen = modelData.name;
            else if (Ui.toastScreen === modelData.name)
                Ui.toastScreen = "";
        }
        Component.onDestruction: {
            if (Ui.toastScreen === modelData.name)
                Ui.toastScreen = "";
        }

        screen: modelData
        anchors {
            top: true
            right: true
        }
        // Zone 0: placed under the bar, flush with its bottom edge.
        exclusiveZone: 0
        implicitWidth: 400 + Theme.fillet
        // Keeps the old height while the drawer folds up.
        implicitHeight: Math.max(drawerHeight, popups.length > 0 ? column.implicitHeight + padding * 2 : 0) + Theme.fillet
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "yuki-notifications"
        mask: Region {
            item: body
        }
        BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

        Behavior on drawerHeight {
            NumberAnimation {
                duration: Theme.animGrow
                easing.type: Easing.OutQuint
            }
        }

        SurfaceRegion {
            id: blurRegion

            bodyX: body.x
            bodyWidth: body.width
            bodyHeight: body.height
            snapRight: true
        }

        Surface {
            bodyWidth: 400
            bodyHeight: root.drawerHeight
            snapRight: true
        }

        Item {
            id: body

            x: Theme.fillet
            width: 400
            height: root.drawerHeight
            clip: true

            Column {
                id: column

                x: root.padding
                y: root.padding
                width: parent.width - root.padding * 2
                spacing: 8

                move: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: Theme.animGrow
                        easing.type: Easing.OutQuint
                    }
                }

                Repeater {
                    model: ScriptModel {
                        values: root.popups
                    }

                    NotificationCard {
                        id: card

                        required property var modelData
                        readonly property real lifetime: {
                            // expireTimeout is in seconds; -1/0 means "server decides".
                            const requested = modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000 : Settings.d.toastSeconds * 1000;
                            return Math.min(Math.max(requested, 2000), 20000);
                        }
                        readonly property bool timed: modelData.urgency !== NotificationUrgency.Critical

                        width: column.width
                        notif: modelData
                        toast: true
                        opacity: 0
                        transform: Translate {
                            id: slide

                            x: 40

                            Behavior on x {
                                NumberAnimation {
                                    duration: Theme.animGrow
                                    easing.type: Easing.OutQuint
                                }
                            }
                        }
                        Component.onCompleted: {
                            opacity = 1;
                            slide.x = 0;
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.anim
                            }
                        }

                        // Drains while the toast is on screen; hovering pauses it.
                        Rectangle {
                            id: life

                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                            x: 20
                            height: 2
                            radius: 1
                            visible: card.timed
                            width: card.width - 40
                            opacity: 0.7
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

                            NumberAnimation on width {
                                running: card.timed
                                paused: running && card.hovered
                                from: card.width - 40
                                to: 0
                                duration: card.lifetime
                                onFinished: Notifs.hidePopup(card.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
