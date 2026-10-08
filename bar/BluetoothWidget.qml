import QtQuick
import Quickshell.Bluetooth
import qs.config
import qs.components
import qs.popups

BarButton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)

    visible: adapter !== null
    hPadding: 7
    spacing: 4
    active: popup.visible
    onClicked: e => {
        if (e.button === Qt.MiddleButton)
            adapter.enabled = !adapter.enabled;
        else
            popup.toggle();
    }

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: !root.adapter?.enabled ? Icons.bluetoothOff : root.connected.length > 0 ? Icons.bluetoothConnected : Icons.bluetooth
        color: root.adapter?.enabled ? (root.connected.length > 0 ? Theme.accent : Theme.text) : Theme.overlay1
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.connected.length > 1
        text: root.connected.length
        font.pixelSize: Theme.smallFontSize
        color: Theme.subtext1
    }

    BluetoothPopup {
        id: popup

        name: "bluetooth"
        target: root
    }
}
