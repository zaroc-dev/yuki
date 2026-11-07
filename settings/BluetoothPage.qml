import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Adapter settings and every device, grouped like the popup, with rename and
// trust on top. Scanning stops when the page closes.
Page {
    id: root

    readonly property var adapter: Bt.adapter

    Component.onDestruction: Bt.setDiscovering(false)

    component Group: ColumnLayout {
        id: group

        property string title
        default property alias content: rows.data

        Layout.fillWidth: true
        spacing: 8

        SectionLabel {
            text: group.title
        }

        ColumnLayout {
            id: rows

            Layout.fillWidth: true
            spacing: 6
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.adapter === null
        text: "No Bluetooth adapter found."
        color: Theme.overlay1
    }

    Section {
        visible: root.adapter !== null
        title: "Adapter"

        SettingRow {
            icon: Bt.on ? Icons.bluetooth : Icons.bluetoothOff
            label: "Bluetooth"
            description: !Bt.on ? "Off" : Bt.connected.length > 0 ? `${Bt.connected.length} connected` : "On, nothing connected"

            Toggle {
                checked: Bt.on
                onToggled: v => root.adapter.enabled = v
            }
        }

        SettingRow {
            visible: Bt.on
            icon: Icons.pencil
            label: "Name"
            description: "What other devices see when they search"

            TextField {
                id: nameField

                implicitWidth: 220
                text: root.adapter?.name ?? ""
                onAccepted: {
                    if (text.trim() && root.adapter)
                        root.adapter.name = text.trim();
                }
                onCancelled: text = root.adapter?.name ?? ""
                // Unsaved edits are dropped when focus leaves without Enter.
                onHasFocusChanged: if (!hasFocus) text = Qt.binding(() => root.adapter?.name ?? "")
            }
        }

        SettingRow {
            visible: Bt.on
            icon: Icons.scan
            label: "Visible to other devices"
            description: {
                const timeout = root.adapter?.discoverableTimeout ?? 0;
                if (!root.adapter?.discoverable)
                    return "Lets phones and other computers find this one";
                return timeout > 0 ? `Visible for ${Math.round(timeout / 60)} min` : "Visible until turned off";
            }

            Toggle {
                checked: root.adapter?.discoverable ?? false
                onToggled: v => root.adapter.discoverable = v
            }
        }

        SettingRow {
            visible: Bt.on
            icon: Icons.key
            label: "Accept pairing"
            description: "Turned on automatically when you pair from here"

            Toggle {
                checked: root.adapter?.pairable ?? false
                onToggled: v => root.adapter.pairable = v
            }
        }
    }

    Group {
        visible: Bt.on
        title: Bt.discovering ? "Searching…" : "Find devices"

        MouseArea {
            id: scanRow

            Layout.fillWidth: true
            implicitHeight: 44
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Bt.setDiscovering(!Bt.discovering)

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Bt.discovering ? Qt.alpha(Theme.accent, 0.14) : scanRow.containsMouse ? Theme.hover : "transparent"
                border.width: 1
                border.color: Bt.discovering ? Qt.alpha(Theme.accent, 0.35) : Theme.rim
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Icon {
                    id: scanIcon

                    text: Icons.scan
                    color: Bt.discovering ? Theme.accent : Theme.subtext0

                    SequentialAnimation on opacity {
                        running: Bt.discovering
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) scanIcon.opacity = 1
                        NumberAnimation {
                            to: 0.4
                            duration: 600
                        }
                        NumberAnimation {
                            to: 1
                            duration: 600
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Bt.discovering ? (Bt.nearby.length > 0 ? `${Bt.nearby.length} found · click to stop` : "Looking for devices in pairing mode…") : "Search for new devices"
                    color: Bt.discovering ? Theme.accent : Theme.subtext0
                }
            }
        }

        Repeater {
            model: Bt.discovering ? Bt.nearby : []

            BluetoothDeviceRow {
                manage: true
            }
        }
    }

    Group {
        visible: Bt.on && Bt.connected.length > 0
        title: "Connected"

        Repeater {
            model: Bt.on ? Bt.connected : []

            BluetoothDeviceRow {
                manage: true
            }
        }
    }

    Group {
        visible: Bt.on && Bt.paired.length > 0
        title: "Paired"

        Repeater {
            model: Bt.on ? Bt.paired : []

            BluetoothDeviceRow {
                manage: true
            }
        }
    }
}
