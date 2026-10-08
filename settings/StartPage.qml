import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

Page {
    Section {
        title: "Pinned apps"
        subtitle: "Right-click any app in the launcher to pin or unpin it."

        Repeater {
            model: Apps.pinned

            SettingRow {
                id: row

                required property var modelData
                required property int index

                appIcon: modelData.icon
                label: modelData.name
                description: modelData.id

                Row {
                    spacing: 2

                    IconButton {
                        icon: Icons.arrowUp
                        enabled: row.index > 0
                        onClicked: Apps.movePin(row.modelData, -1)
                    }

                    IconButton {
                        icon: Icons.arrowDown
                        enabled: row.index < Apps.pinned.length - 1
                        onClicked: Apps.movePin(row.modelData, 1)
                    }

                    IconButton {
                        icon: Icons.pinOff
                        color: Theme.red
                        onClicked: Apps.togglePin(row.modelData)
                    }
                }
            }
        }

        SettingRow {
            label: "Reset"
            description: "Go back to the default pinned apps"

            IconButton {
                icon: Icons.reload
                onClicked: Settings.d.pinnedApps = []
            }
        }
    }
}
