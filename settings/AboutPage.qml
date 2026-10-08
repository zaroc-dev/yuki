import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

Page {
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 6

        Icon {
            Layout.alignment: Qt.AlignHCenter
            text: Icons.nixos
            size: 64
            color: Theme.accent
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "shell"
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: `Quickshell on niri · ${Power.user}@${Power.hostname}`
            color: Theme.subtext0
        }
    }

    Section {
        title: "Files"

        SettingRow {
            icon: Icons.folder
            label: "Shell"
            description: Quickshell.shellDir

            IconButton {
                icon: Icons.chevronRight
                onClicked: Quickshell.execDetached(["xdg-open", Quickshell.shellDir])
            }
        }

        SettingRow {
            icon: Icons.settings
            label: "Settings file"
            description: Settings.path

            IconButton {
                icon: Icons.chevronRight
                onClicked: Quickshell.execDetached(["xdg-open", Settings.path])
            }
        }
    }

    Section {
        title: "Shell"

        SettingRow {
            icon: Icons.reload
            label: "Reload"
            description: "Re-read every QML file"

            IconButton {
                icon: Icons.reload
                onClicked: Quickshell.reload(false)
            }
        }
    }
}
