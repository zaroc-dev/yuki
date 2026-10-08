import QtQuick
import Quickshell.Services.UPower
import qs.config
import qs.components
import qs.popups

BarButton {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool charging: dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged || dev.state === UPowerDeviceState.PendingCharge
    readonly property real percent: dev.percentage
    readonly property color tint: charging ? Theme.green : percent < 0.15 ? Theme.red : percent < 0.3 ? Theme.peach : Theme.text

    visible: dev.ready && dev.isLaptopBattery
    hPadding: 7
    spacing: 4
    active: popup.visible
    onClicked: popup.toggle()

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.batteryLevel(root.percent, root.charging)
        color: root.tint
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: `${Math.round(root.percent * 100)}%`
        color: root.tint
        font.pixelSize: Theme.smallFontSize + 1
    }

    BatteryPopup {
        id: popup

        name: "battery"
        target: root
    }
}
