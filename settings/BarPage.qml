import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

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
