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
        title: "Weather"
        subtitle: "In the clock's dashboard and on the lock screen. Forecasts from Open-Meteo."

        SettingRow {
            icon: Icons.weatherPartly
            label: "Show weather"

            Toggle {
                checked: Settings.d.weather
                onToggled: v => Settings.d.weather = v
            }
        }

        SettingRow {
            icon: Icons.location
            label: "Location"
            description: Settings.d.weatherLocation ? (Weather.error || (Weather.place ? `Showing ${Weather.place}` : "")) : "Empty: located by your IP (ipinfo.io)"

            Rectangle {
                implicitWidth: 220
                implicitHeight: 36
                radius: Theme.innerRadius
                color: Qt.alpha(Theme.surface1, 0.6)
                border.width: 1
                border.color: locationInput.activeFocus ? Theme.accent : "transparent"

                TextInput {
                    id: locationInput

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    text: Settings.d.weatherLocation
                    color: Theme.text
                    selectionColor: Qt.alpha(Theme.accent, 0.4)
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    onEditingFinished: Settings.d.weatherLocation = text.trim()

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: locationInput.text === "" && !locationInput.activeFocus
                        text: "City or lat,lon"
                        color: Theme.overlay1
                    }
                }
            }
        }

        SettingRow {
            icon: Icons.thermometer
            label: "Units"

            Segmented {
                options: [
                    { value: false, label: "°C" },
                    { value: true, label: "°F" }
                ]
                value: Settings.d.fahrenheit
                onSelected: v => Settings.d.fahrenheit = v
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
