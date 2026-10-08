import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components

Page {
    id: root

    readonly property bool wallpaperMode: Theme.source === "wallpaper"

    component Swatches: Row {
        property var colors: []
        property int size: 18

        spacing: -5

        Repeater {
            model: parent.colors

            Rectangle {
                required property var modelData

                width: parent.size
                height: parent.size
                radius: width / 2
                color: modelData
                border.width: 2
                border.color: Theme.base
            }
        }
    }

    // Selectable card showing a palette preview.
    component PaletteCard: MouseArea {
        id: card

        property string title
        property var colors: []
        property bool selected: false

        Layout.fillWidth: true
        implicitHeight: 64
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: card.containsMouse ? Theme.hover : Qt.alpha(Theme.surface0, 0.55)
            border.width: 2
            border.color: card.selected ? Theme.accent : "transparent"

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: card.title
                    font.weight: card.selected ? Font.DemiBold : Font.Normal
                }

                Icon {
                    visible: card.selected
                    text: Icons.check
                    size: 14
                    color: Theme.accent
                }
            }

            Swatches {
                colors: card.colors
            }
        }
    }

    Section {
        title: "Colors"

        SettingRow {
            label: "Source"
            description: root.wallpaperMode ? "Material You palette generated from your wallpaper" : "Catppuccin palette"

            Segmented {
                options: [
                    { value: "wallpaper", label: "Wallpaper", icon: Icons.image },
                    { value: "catppuccin", label: "Catppuccin", icon: Icons.palette }
                ]
                value: Theme.source === "custom" ? "" : Theme.source
                onSelected: v => Theme.setSource(v)
            }
        }

        SettingRow {
            label: "Mode"

            Segmented {
                options: [
                    { value: "dark", label: "Dark", icon: Icons.moon },
                    { value: "light", label: "Light", icon: Icons.sun }
                ]
                value: Theme.lightMode ? "light" : "dark"
                onSelected: v => Theme.setMode(v)
            }
        }

        SettingRow {
            visible: root.wallpaperMode && Quickshell.screens.length > 1
            label: "Colors from"
            description: "Whose wallpaper the palette is generated from"

            Segmented {
                options: Quickshell.screens.map(s => ({ value: s.name, label: s.name, icon: Icons.monitor }))
                value: Wallpapers.colorScreen
                onSelected: v => Settings.d.colorScreen = v
            }
        }

        SettingRow {
            visible: root.wallpaperMode
            label: "Seed color"
            description: Theme.seed ? `Extracted from ${Wallpapers.colorSourcePath.split("/").pop()}` : "Extracting…"

            Row {
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: Theme.seed || Theme.surface1
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.seed.toUpperCase()
                    font.family: "JetBrainsMono Nerd Font"
                    color: Theme.subtext1
                }
            }
        }
    }

    Section {
        visible: root.wallpaperMode
        title: "Scheme"
        subtitle: "How the wallpaper's color is turned into a palette. Tonal Spot is the Material default."

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            columns: 3
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: Theme.schemes

                PaletteCard {
                    required property string modelData
                    readonly property var pal: Theme.previewPalette(modelData, !Theme.lightMode)

                    title: modelData.split("-").map(w => w[0].toUpperCase() + w.slice(1)).join(" ")
                    colors: [pal.primary, pal.secondary, pal.tertiary, pal.surface1, pal.base]
                    selected: Settings.d.scheme === modelData
                    onClicked: Theme.setScheme(modelData)
                }
            }
        }
    }

    Section {
        visible: !root.wallpaperMode
        title: "Flavor"

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            columns: 4
            columnSpacing: 8

            Repeater {
                model: ["mocha", "macchiato", "frappe", "latte"]

                PaletteCard {
                    required property string modelData
                    readonly property var pal: Theme.flavors[modelData]

                    title: modelData[0].toUpperCase() + modelData.slice(1)
                    colors: [pal.mauve, pal.blue, pal.green, pal.peach, pal.base]
                    selected: modelData === "latte" ? Theme.lightMode : !Theme.lightMode && Theme.flavor === modelData
                    onClicked: Theme.setFlavor(modelData)
                }
            }
        }
    }

    Section {
        visible: !root.wallpaperMode
        title: "Accent"

        Flow {
            Layout.fillWidth: true
            Layout.margins: 14
            spacing: 10

            Repeater {
                model: Theme.accents

                MouseArea {
                    id: dot

                    required property string modelData
                    readonly property bool selected: Settings.d.accent === modelData

                    width: 30
                    height: 30
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Theme.setAccent(modelData)

                    Rectangle {
                        anchors.centerIn: parent
                        width: dot.selected || dot.containsMouse ? 30 : 24
                        height: width
                        radius: width / 2
                        color: Theme.p[dot.modelData]
                        border.width: dot.selected ? 3 : 0
                        border.color: Theme.text

                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.anim
                            }
                        }
                    }
                }
            }
        }
    }

    Section {
        title: "Colors in other apps"
        subtitle: "Written to ~/.local/state/shell/theme/ whenever the palette changes. Your niri and kitty configs need to include them (see HANDOFF.md)."

        Repeater {
            model: [
                { key: "niri", label: "niri", description: "Focus ring, borders, overview backdrop" },
                { key: "kitty", label: "kitty", description: "Terminal colors, reloaded live" },
                { key: "gtk", label: "GTK 3 / 4", description: "libadwaita colors for newly opened apps" }
            ]

            SettingRow {
                id: appRow

                required property var modelData

                label: modelData.label
                description: modelData.description

                Toggle {
                    checked: Settings.d.templates[appRow.modelData.key] !== false
                    onToggled: v => Settings.setIn("templates", appRow.modelData.key, v)
                }
            }
        }

        SettingRow {
            label: "Overview backdrop"
            description: "Blurred wallpaper behind workspaces in niri's overview"

            Toggle {
                checked: Settings.d.overviewBackdrop
                onToggled: v => Settings.d.overviewBackdrop = v
            }
        }
    }

    Section {
        title: "Surfaces"

        SettingRow {
            label: "Background blur"
            description: "Frosted glass behind the bar and popups (niri background effect)"

            Toggle {
                checked: Settings.d.blur
                onToggled: v => Settings.d.blur = v
            }
        }

        SettingRow {
            label: "Opacity"
            description: `${Math.round(Theme.opacity * 100)}%`

            StyledSlider {
                implicitWidth: 200
                from: 0.4
                to: 1
                value: Settings.d.opacity
                onMoved: v => Settings.d.opacity = Math.round(v * 100) / 100
            }
        }
    }
}
