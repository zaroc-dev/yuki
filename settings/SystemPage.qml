import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.config
import qs.components
import qs.services

Page {
    Component.onCompleted: Clipboard.refresh()

    component Minutes: Row {
        id: m

        property int value
        signal changed(int value)

        spacing: 10

        StyledSlider {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 160
            from: 0
            to: 60
            step: 1
            value: m.value
            onMoved: v => m.changed(Math.round(v))
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: 52
            text: m.value === 0 ? "Never" : `${m.value} min`
            color: Theme.subtext1
        }
    }

    Section {
        title: "When idle"
        subtitle: "Apps that keep the screen awake (video players, games) are respected."

        SettingRow {
            icon: Icons.lockOutline
            label: "Lock after"

            Minutes {
                value: Settings.d.lockAfterMinutes
                onChanged: v => Settings.d.lockAfterMinutes = v
            }
        }

        SettingRow {
            icon: Icons.monitor
            label: "Turn screens off after"

            Minutes {
                value: Settings.d.screenOffAfterMinutes
                onChanged: v => Settings.d.screenOffAfterMinutes = v
            }
        }

        SettingRow {
            icon: Icons.awake
            label: "Keep awake"
            description: "Pause both until turned off again"

            Toggle {
                checked: Idle.keepAwake
                onToggled: v => Idle.keepAwake = v
            }
        }
    }

    Section {
        title: "Power"

        SettingRow {
            icon: Icons.balanced
            label: "Power profile"

            ProfilePicker {}
        }
    }

    Section {
        title: "Clipboard"

        SettingRow {
            icon: Icons.clipboard
            label: "Record clipboard history"
            description: "Stores copied text and images with cliphist"

            Toggle {
                checked: Settings.d.clipboardWatch
                onToggled: v => Settings.d.clipboardWatch = v
            }
        }

        SettingRow {
            label: `${Clipboard.entries.length} entries`
            description: "Open with Mod+V (see HANDOFF.md) or the start menu"

            IconButton {
                icon: Icons.trash
                color: Theme.red
                onClicked: Clipboard.wipe()
            }
        }
    }
}
