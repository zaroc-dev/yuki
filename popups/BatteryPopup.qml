import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.config
import qs.components

BarPopup {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
    readonly property bool full: dev.state === UPowerDeviceState.FullyCharged

    function duration(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.round(seconds % 3600 / 60);
        return h > 0 ? `${h} h ${m} min` : `${m} min`;
    }

    RowLayout {
        Layout.preferredWidth: 320
        Layout.fillWidth: true
        spacing: 14

        Icon {
            text: Icons.batteryLevel(root.dev.percentage, root.charging)
            size: 36
            color: root.charging ? Theme.green : root.dev.percentage < 0.15 ? Theme.red : Theme.accent
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: `${Math.round(root.dev.percentage * 100)}%`
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                color: Theme.subtext0
                text: {
                    if (root.full)
                        return "Fully charged";
                    if (root.charging)
                        return root.dev.timeToFull > 0 ? `Full in ${root.duration(root.dev.timeToFull)}` : "Charging";
                    return root.dev.timeToEmpty > 0 ? `${root.duration(root.dev.timeToEmpty)} remaining` : "On battery";
                }
            }
        }

        StyledText {
            visible: root.dev.healthSupported
            text: `Health ${Math.round(root.dev.healthPercentage)}%`
            font.pixelSize: Theme.smallFontSize
            color: Theme.subtext0
        }
    }

    StyledText {
        text: "POWER PROFILE"
        font.pixelSize: Theme.smallFontSize
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        color: Theme.overlay2
    }

    ProfilePicker {
        Layout.alignment: Qt.AlignHCenter
    }
}
