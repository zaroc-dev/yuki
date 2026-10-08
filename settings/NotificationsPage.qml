import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    Section {
        title: "Behaviour"

        SettingRow {
            icon: Icons.bellOff
            label: "Do not disturb"
            description: "Only critical notifications pop up"

            Toggle {
                checked: Notifs.dnd
                onToggled: Notifs.toggleDnd()
            }
        }

        SettingRow {
            label: "Toast duration"
            description: `${Settings.d.toastSeconds} seconds, unless the app asks for something else`

            StyledSlider {
                implicitWidth: 200
                from: 2
                to: 20
                step: 1
                value: Settings.d.toastSeconds
                onMoved: v => Settings.d.toastSeconds = Math.round(v)
            }
        }
    }

    Section {
        title: "History"

        SettingRow {
            label: `${Notifs.count} notification${Notifs.count === 1 ? "" : "s"}`
            description: "Kept until dismissed"

            IconButton {
                icon: Icons.clearAll
                enabled: Notifs.count > 0
                onClicked: Notifs.clearAll()
            }
        }
    }
}
