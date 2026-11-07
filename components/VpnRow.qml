import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// One VPN connection (an entry of Vpn.connections) with an on/off switch, and a
// password card underneath when the profile asks for one. `manage` adds forget.
ColumnLayout {
    id: root

    required property var modelData
    property bool manage: false
    readonly property bool on: modelData.state === "on"
    readonly property bool busy: modelData.state === "connecting" || modelData.state === "disconnecting"
    readonly property string error: Vpn.errors[modelData.id] ?? ""
    // Forget takes a second click.
    property bool armed: false

    Layout.fillWidth: true
    spacing: 4

    Timer {
        running: root.armed
        interval: 4000
        onTriggered: root.armed = false
    }

    MouseArea {
        id: row

        Layout.fillWidth: true
        implicitHeight: 52
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Vpn.toggle(root.modelData.id)

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius + 2
            color: root.on ? Qt.alpha(Theme.accent, 0.16) : row.containsMouse ? Theme.cardHover : Theme.card

            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 12

            Icon {
                text: Icons.vpn
                color: root.on ? Theme.accent : root.modelData.state === "error" ? Theme.red : Theme.text
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.modelData.name
                    color: root.on ? Theme.accent : Theme.text
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.armed ? "Click the bin again to remove this profile" : root.error || root.modelData.detail
                    font.pixelSize: Theme.smallFontSize
                    color: root.armed || root.error || root.modelData.state === "error" ? Theme.red : Theme.subtext0
                }
            }

            Spinner {
                visible: root.busy
            }

            IconButton {
                visible: root.manage && root.modelData.id !== "mullvad" && !root.busy
                size: 28
                iconSize: 15
                icon: Icons.trash
                color: root.armed ? Theme.red : Theme.overlay1
                onClicked: {
                    if (!root.armed) {
                        root.armed = true;
                        return;
                    }
                    root.armed = false;
                    Vpn.remove(root.modelData.id);
                }
            }

            Toggle {
                checked: root.on || root.modelData.state === "connecting" || root.modelData.needsSecret
                onToggled: v => {
                    if (!v && root.modelData.needsSecret)
                        Vpn.setSecretNeeded(root.modelData.id, false);
                    else
                        Vpn.setActive(root.modelData.id, v);
                }
            }
        }
    }

    // NetworkManager doesn't store this profile's password (`nmcli --ask`).
    Loader {
        Layout.fillWidth: true
        active: root.modelData.needsSecret
        visible: active

        sourceComponent: Rectangle {
            id: card

            implicitHeight: prompt.implicitHeight + 24
            radius: Theme.innerRadius + 2
            color: Qt.alpha(Theme.surface0, 0.5)
            border.width: 1
            border.color: Theme.surface0

            Component.onCompleted: secret.focusInput()

            function submit() {
                if (!secret.text)
                    return;
                Vpn.setActive(root.modelData.id, true, secret.text);
            }

            ColumnLayout {
                id: prompt

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                TextField {
                    id: secret

                    Layout.fillWidth: true
                    icon: Icons.lock
                    placeholder: "VPN password"
                    password: true
                    onAccepted: card.submit()
                    onCancelled: Vpn.setSecretNeeded(root.modelData.id, false)
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Not stored. If your VPN uses a one-time code, type it right after the password."
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.smallFontSize
                    color: Theme.subtext0
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item {
                        Layout.fillWidth: true
                    }

                    PillButton {
                        text: "Cancel"
                        onClicked: Vpn.setSecretNeeded(root.modelData.id, false)
                    }

                    PillButton {
                        text: "Connect"
                        primary: true
                        onClicked: card.submit()
                    }
                }
            }
        }
    }
}
