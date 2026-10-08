import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Floating settings panel on the focused output. The backdrop stays clear so
// theme and wallpaper changes are visible live; clicking outside closes it.
LazyLoader {
    active: Ui.settingsOpen

    PanelWindow {
        id: win

        readonly property var pages: [
            { id: "appearance", label: "Appearance", icon: Icons.paint, title: "Appearance", subtitle: "Colors, mode and surfaces" },
            { id: "wallpaper", label: "Wallpaper", icon: Icons.image, title: "Wallpaper", subtitle: "Per-screen wallpapers from your folder" },
            { id: "bar", label: "Bar", icon: Icons.bar, title: "Bar", subtitle: "What the top bar shows" },
            { id: "notifications", label: "Notifications", icon: Icons.bellOutline, title: "Notifications", subtitle: "Toasts and do not disturb" },
            { id: "start", label: "Start menu", icon: Icons.nixos, title: "Start menu", subtitle: "Pinned apps" },
            { id: "system", label: "System", icon: Icons.timer, title: "System", subtitle: "Idle, power and clipboard" },
            { id: "about", label: "About", icon: Icons.info, title: "About", subtitle: "This shell" }
        ]
        readonly property var page: pages.find(p => p.id === Ui.settingsPage) ?? pages[0]

        screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "yuki-settings"
        BackgroundEffect.blurRegion: Region {
            item: Theme.blur ? panel : null
            radius: panel.radius
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Ui.settingsOpen = false
        }

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: Math.min(940, parent.width - 80)
            height: Math.min(640, parent.height - 120)
            radius: Theme.radius + 6
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.barBorder
            focus: true
            Keys.onEscapePressed: Ui.settingsOpen = false
            opacity: 0
            scale: 0.97
            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Theme.anim
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: panel.forceActiveFocus()
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ---------- sidebar ----------
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 220
                    topLeftRadius: panel.radius
                    bottomLeftRadius: panel.radius
                    color: Qt.alpha(Theme.mantle, 0.5)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4

                        RowLayout {
                            Layout.bottomMargin: 14
                            Layout.leftMargin: 6
                            Layout.topMargin: 6
                            spacing: 10

                            Icon {
                                text: Icons.settings
                                size: 20
                                color: Theme.accent
                            }

                            StyledText {
                                text: "Settings"
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                            }
                        }

                        Repeater {
                            model: win.pages

                            MouseArea {
                                id: nav

                                required property var modelData
                                readonly property bool current: win.page.id === modelData.id

                                Layout.fillWidth: true
                                implicitHeight: 40
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Ui.settingsPage = modelData.id

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.innerRadius + 2
                                    color: nav.current ? Qt.alpha(Theme.accent, 0.16) : nav.containsMouse ? Theme.hover : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.anim
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: nav.current
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 3
                                    height: 18
                                    radius: 2
                                    color: Theme.accent
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    spacing: 12

                                    Icon {
                                        text: nav.modelData.icon
                                        color: nav.current ? Theme.accent : Theme.subtext0
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: nav.modelData.label
                                        color: nav.current ? Theme.text : Theme.subtext1
                                        font.weight: nav.current ? Font.DemiBold : Font.Normal
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        StyledText {
                            Layout.leftMargin: 6
                            text: "Esc to close"
                            font.pixelSize: Theme.smallFontSize
                            color: Theme.overlay0
                        }
                    }
                }

                // ---------- page ----------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 24
                    Layout.rightMargin: 18
                    spacing: 18

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: win.page.title
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: win.page.subtitle
                                color: Theme.subtext0
                            }
                        }

                        IconButton {
                            icon: Icons.close
                            color: Theme.subtext0
                            onClicked: Ui.settingsOpen = false
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        source: ({
                                appearance: "AppearancePage.qml",
                                wallpaper: "WallpaperPage.qml",
                                bar: "BarPage.qml",
                                notifications: "NotificationsPage.qml",
                                start: "StartPage.qml",
                                system: "SystemPage.qml",
                                about: "AboutPage.qml"
                            })[win.page.id]
                    }
                }
            }
        }
    }
}
