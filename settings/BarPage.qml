import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    Section {
        title: "Clock"

        SettingRow {
            label: "24-hour clock"

            Toggle {
                checked: Settings.d.clock24h
                onToggled: v => Settings.d.clock24h = v
            }
        }

        SettingRow {
            label: "Show date"

            Toggle {
                checked: Settings.d.showDate
                onToggled: v => Settings.d.showDate = v
            }
        }
    }

    Section {
        title: "Left"

        SettingRow {
            icon: Icons.apps
            label: "Launcher button"
            description: "Next to the start button (the launcher also opens from the start menu or a keybind)"

            Toggle {
                checked: Settings.d.showLauncherButton
                onToggled: v => Settings.d.showLauncherButton = v
            }
        }
    }

    Section {
        title: "Widgets"

        SettingRow {
            icon: Icons.music
            label: "Media player"
            description: "Now playing next to the start button"

            Toggle {
                checked: Settings.d.showMedia
                onToggled: v => Settings.d.showMedia = v
            }
        }

        SettingRow {
            label: "Preferred player"
            description: "Always shown while it's running, even if something else starts playing. Right-click a player in the media popup to set it."

            Segmented {
                readonly property var keys: {
                    const k = Media.players.map(p => Media.keyOf(p)).filter(k => k);
                    if (Settings.d.preferredPlayer && !k.includes(Settings.d.preferredPlayer))
                        k.push(Settings.d.preferredPlayer);
                    return [...new Set(k)];
                }

                options: [{ value: "", label: "Auto" }].concat(keys.map(k => ({ value: k, label: k[0].toUpperCase() + k.slice(1) })))
                value: Settings.d.preferredPlayer
                onSelected: v => Settings.d.preferredPlayer = v
            }
        }

        SettingRow {
            icon: Icons.dashboard
            label: "Active window"
            description: "Focused window's icon and title in the center"

            Toggle {
                checked: Settings.d.showActiveWindow
                onToggled: v => Settings.d.showActiveWindow = v
            }
        }
    }
}
