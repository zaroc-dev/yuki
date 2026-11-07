import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config
import qs.services

// A wired device: connection name, link state and speed. `details` adds its
// addresses (settings page).
Rectangle {
    id: root

    required property var modelData
    property bool details: false

    Layout.fillWidth: true
    implicitHeight: body.implicitHeight + 20
    radius: Theme.radius + 2
    color: Theme.card

    ColumnLayout {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: 12
                color: root.modelData.connected ? Qt.alpha(Theme.accent, 0.18) : Theme.well

                Icon {
                    anchors.centerIn: parent
                    text: Icons.ethernet
                    color: root.modelData.connected ? Theme.accent : Theme.overlay1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    // nmcli knows the profile name ("Wired connection 1") the device list doesn't.
                    text: Net.details[root.modelData.name]?.connection || root.modelData.network?.name || root.modelData.name
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Theme.smallFontSize
                    color: Theme.subtext0
                    text: {
                        const d = root.modelData;
                        const iface = root.details ? ` · ${d.name}` : "";
                        if (!d.connected)
                            return (d.hasLink ? ConnectionState.toString(d.state) : "Cable unplugged") + iface;
                        const speed = d.linkSpeed > 0 ? ` · ${d.linkSpeed >= 1000 ? d.linkSpeed / 1000 + " Gb/s" : d.linkSpeed + " Mb/s"}` : "";
                        return `Connected${speed}${iface}`;
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.leftMargin: 48
            active: root.details && root.modelData.connected
            visible: active

            sourceComponent: NetworkDetails {
                iface: root.modelData.name
                mac: root.modelData.address
            }
        }
    }
}
