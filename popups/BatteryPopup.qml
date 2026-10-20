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

    PanelHeader {
        Layout.preferredWidth: 340
        icon: Icons.batteryLevel(root.dev.percentage, root.charging)
        lit: root.charging || root.dev.percentage >= 0.15
        title: "Battery"
        subtitle: {
            if (root.full)
                return "Fully charged";
            if (root.charging)
                return root.dev.timeToFull > 0 ? `Full in ${root.duration(root.dev.timeToFull)}` : "Charging";
            return root.dev.timeToEmpty > 0 ? `${root.duration(root.dev.timeToEmpty)} remaining` : "On battery";
        }

        Row {
            StyledText {
                id: pct

                text: Math.round(root.dev.percentage * 100)
                font.family: Theme.displayFont
                font.pixelSize: 30
                font.weight: Font.Black
                color: root.charging ? Theme.green : root.dev.percentage < 0.15 ? Theme.red : Theme.text
            }

            StyledText {
                anchors.baseline: pct.baseline
                text: "%"
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Theme.subtext0
            }
        }
    }

    // Charge as a fat capsule.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 14
        radius: 7
        color: Theme.well

        Rectangle {
            width: Math.max(height, parent.width * root.dev.percentage)
            height: parent.height
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: root.charging ? Theme.green : root.dev.percentage < 0.15 ? Theme.red : Theme.accent
                }
                GradientStop {
                    position: 1
                    color: root.charging ? Theme.teal : root.dev.percentage < 0.15 ? Theme.peach : Theme.accent2
                }
            }
        }
    }

    SectionLabel {
        text: "Power profile"

        StyledText {
            visible: root.dev.healthSupported
            text: `Health ${Math.round(root.dev.healthPercentage)}%`
            font.pixelSize: Theme.smallFontSize
            color: Theme.subtext0
        }
    }

    ProfilePicker {
        Layout.alignment: Qt.AlignHCenter
    }
}
