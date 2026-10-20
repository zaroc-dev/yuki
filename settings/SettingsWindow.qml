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
            width: Math.min(980, parent.width - 80)
            height: Math.min(680, parent.height - 120)
            radius: 30
            color: Theme.popupBg
            border.width: 1
            border.color: Theme.rim
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

            // Aurora light falling in from the top edge.
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(Theme.accent, Theme.dark ? 0.1 : 0.16)
                    }
                    GradientStop {
                        position: 0.35
                        color: "transparent"
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ---------- sidebar ----------
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 236
                    topLeftRadius: panel.radius
                    bottomLeftRadius: panel.radius
                    color: Theme.well

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 4

                        RowLayout {
                            Layout.bottomMargin: 18
                            Layout.leftMargin: 4
                            Layout.topMargin: 4
                            spacing: 12

                            Rectangle {
                                implicitWidth: 38
                                implicitHeight: 38
                                radius: 13
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: Theme.accent
                                    }
                                    GradientStop {
                                        position: 1
                                        color: Theme.accent2
                                    }
                                }

                                Icon {
                                    anchors.centerIn: parent
                                    text: Icons.settings
                                    size: 19
                                    color: Theme.onAccent
                                }
                            }

                            StyledText {
                                text: "Settings"
                                font.family: Theme.displayFont
                                font.pixelSize: 21
                                font.weight: Font.Black
                            }
                        }

                        Repeater {
                            model: win.pages

                            MouseArea {
                                id: nav

                                required property var modelData
                                readonly property bool current: win.page.id === modelData.id

                                Layout.fillWidth: true
                                implicitHeight: 42
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Ui.settingsPage = modelData.id

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: nav.containsMouse ? Theme.hover : "transparent"
                                }

                                // The current page is an aurora pill.
                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    opacity: nav.current ? 1 : 0
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

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    spacing: 12

                                    Icon {
                                        text: nav.modelData.icon
                                        color: nav.current ? Theme.onAccent : Theme.subtext0
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: nav.modelData.label
                                        color: nav.current ? Theme.onAccent : Theme.subtext1
                                        font.weight: nav.current ? Font.Bold : Font.Medium
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
                    Layout.margins: 28
                    Layout.rightMargin: 20
                    spacing: 20

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: win.page.title
                                font.family: Theme.displayFont
                                font.pixelSize: 30
                                font.weight: Font.Black
                                font.letterSpacing: -0.5
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
