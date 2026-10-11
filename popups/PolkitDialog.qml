import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs.config
import qs.components
import qs.services

// Polkit authentication agent (pkexec, GNOME Disks, "open as admin", …):
// a centered dialog on the focused output while a request is active.
Scope {
    id: root

    readonly property AuthFlow flow: agent.flow

    PolkitAgent {
        id: agent

        onIsRegisteredChanged: {
            if (isRegistered)
                console.info("Polkit: authentication agent registered");
        }
    }

    // Registration fails while another agent serves this session; there is no
    // error signal, so check once after startup.
    Timer {
        running: true
        interval: 3000
        onTriggered: {
            if (!agent.isRegistered)
                console.warn("Polkit: couldn't register the authentication agent (is another one running?)");
        }
    }

    component DialogButton: MouseArea {
        id: button

        property string text
        property bool filled: false

        implicitWidth: label.implicitWidth + 36
        implicitHeight: 38
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: enabled ? 1 : 0.5

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: button.filled ? (button.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent) : button.pressed ? Theme.pressed : button.containsMouse ? Theme.hover : Qt.alpha(Theme.surface0, 0.7)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        StyledText {
            id: label

            anchors.centerIn: parent
            text: button.text
            font.weight: Font.DemiBold
            color: button.filled ? Theme.onAccent : Theme.text
        }
    }

    LazyLoader {
        active: agent.isActive && root.flow !== null

        PanelWindow {
            id: win

            readonly property AuthFlow flow: root.flow
            // Submitted and waiting for polkit to answer.
            readonly property bool busy: flow !== null && !flow.isResponseRequired && !flow.isCompleted
            property bool reveal: false
            property string error: ""

            function submit() {
                if (!flow?.isResponseRequired || input.text === "")
                    return;
                error = "";
                flow.submit(input.text);
            }

            function cancel() {
                flow?.cancelAuthenticationRequest();
            }

            screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) ?? Quickshell.screens[0]
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "yuki-polkit"
            BackgroundEffect.blurRegion: Region {
                item: Theme.blur ? box : null
                radius: box.radius
            }

            Connections {
                target: win.flow

                function onAuthenticationFailed() {
                    win.error = "Incorrect password";
                    input.text = "";
                    shakeAnim.restart();
                }

                // polkit asks again after a failed attempt; keep typing focus.
                function onIsResponseRequiredChanged() {
                    if (win.flow.isResponseRequired)
                        input.forceActiveFocus();
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.crust, 0.4)
                opacity: 0
                Component.onCompleted: opacity = 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }
            }

            // Modal: clicks outside do nothing (Esc or Cancel to dismiss).
            MouseArea {
                anchors.fill: parent
                onClicked: input.forceActiveFocus()
            }

            Rectangle {
                id: box

                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.3
                width: 420
                height: column.implicitHeight + 40
                radius: Theme.radius + 6
                color: Theme.popupBg
                border.width: 1
                border.color: Theme.barBorder
                opacity: 0
                scale: 0.96
                Component.onCompleted: {
                    opacity = 1;
                    scale = 1;
                }

                transform: Translate {
                    id: shake
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.anim
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.anim
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Theme.anim
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: input.forceActiveFocus()
                }

                ColumnLayout {
                    id: column

                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 44
                            implicitHeight: 44
                            radius: width / 2
                            color: Qt.alpha(Theme.accent, 0.15)

                            AppIcon {
                                anchors.centerIn: parent
                                iconName: win.flow?.iconName ?? ""
                                fallback: Icons.shieldLock
                                size: 24
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            StyledText {
                                Layout.fillWidth: true
                                text: "Authentication required"
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: win.flow?.message ?? ""
                                color: Theme.subtext0
                                wrapMode: Text.Wrap
                                elide: Text.ElideNone
                            }
                        }
                    }

                    // Who authenticates; click to switch when polkit offers several admins.
                    MouseArea {
                        id: identityRow

                        readonly property var identities: win.flow?.identities ?? []
                        readonly property var identity: win.flow?.selectedIdentity ?? null
                        readonly property string name: identity?.displayName ?? ""

                        Layout.fillWidth: true
                        implicitHeight: 40
                        visible: name !== ""
                        enabled: identities.length > 1 && !win.busy
                        hoverEnabled: enabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            const i = identities.indexOf(identity);
                            win.flow.selectedIdentity = identities[(i + 1) % identities.length];
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius
                            color: identityRow.containsMouse ? Theme.hover : Qt.alpha(Theme.surface0, 0.55)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.anim
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 12
                            spacing: 10

                            Avatar {
                                visible: identityRow.name === Power.user
                                size: 26
                            }

                            Icon {
                                visible: identityRow.name !== Power.user
                                Layout.preferredWidth: 26
                                text: identityRow.identity?.isGroup ? Icons.accountGroup : Icons.account
                                color: Theme.subtext0
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: identityRow.name
                            }

                            StyledText {
                                visible: identityRow.enabled
                                text: `${identityRow.identities.indexOf(identityRow.identity) + 1}/${identityRow.identities.length}`
                                color: Theme.overlay1
                                font.pixelSize: Theme.smallFontSize
                            }
                        }
                    }

                    Rectangle {
                        id: field

                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: height / 2
                        color: Qt.alpha(Theme.base, 0.55)
                        border.width: 1.5
                        border.color: win.error !== "" ? Theme.red : input.activeFocus && input.text !== "" ? Qt.alpha(Theme.accent, 0.9) : Qt.alpha(Theme.text, 0.14)

                        Behavior on border.color {
                            ColorAnimation {
                                duration: Theme.anim
                            }
                        }

                        Icon {
                            id: fieldIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: win.busy ? Icons.loading : Icons.lockOutline
                            color: win.error !== "" ? Theme.red : Theme.subtext0

                            RotationAnimation on rotation {
                                running: win.busy
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 900
                                onRunningChanged: if (!running) fieldIcon.rotation = 0
                            }
                        }

                        TextInput {
                            id: input

                            // Plain text when polkit says so (e.g. a username), or on reveal.
                            readonly property bool plain: (win.flow?.responseVisible ?? false) || win.reveal

                            anchors.left: fieldIcon.right
                            anchors.right: eyeButton.left
                            anchors.leftMargin: 12
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            // Dots are drawn below instead of the bullet glyphs.
                            opacity: plain ? 1 : 0
                            echoMode: plain ? TextInput.Normal : TextInput.Password
                            color: Theme.text
                            selectionColor: Qt.alpha(Theme.accent, 0.4)
                            font.family: Theme.font
                            font.pixelSize: 15
                            clip: true
                            focus: true
                            readOnly: win.busy
                            onTextChanged: {
                                if (text !== "")
                                    win.error = "";
                            }
                            Keys.onReturnPressed: win.submit()
                            Keys.onEnterPressed: win.submit()
                            Keys.onEscapePressed: win.cancel()
                        }

                        StyledText {
                            anchors.left: input.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === "" && !win.busy
                            // polkit/PAM prompts look like "Password: ".
                            text: (win.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                            color: Theme.overlay1
                        }

                        Row {
                            anchors.left: input.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !input.plain
                            spacing: 6

                            Repeater {
                                model: Math.min(input.text.length, 24)

                                Rectangle {
                                    width: 9
                                    height: 9
                                    radius: 4.5
                                    color: win.busy ? Theme.overlay1 : Theme.text
                                    scale: 0
                                    Component.onCompleted: scale = 1

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                            }
                        }

                        IconButton {
                            id: eyeButton

                            anchors.right: parent.right
                            anchors.rightMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !(win.flow?.responseVisible ?? false)
                            icon: win.reveal ? Icons.eyeOff : Icons.eye
                            color: Theme.subtext0
                            onClicked: {
                                win.reveal = !win.reveal;
                                input.forceActiveFocus();
                            }
                        }
                    }

                    StyledText {
                        readonly property string info: win.flow?.supplementaryMessage ?? ""

                        Layout.fillWidth: true
                        Layout.topMargin: -4
                        visible: text !== ""
                        text: win.error || info
                        color: win.error !== "" || (win.flow?.supplementaryIsError ?? false) ? Theme.red : Theme.subtext0
                        font.pixelSize: Theme.smallFontSize
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 8

                        Item {
                            Layout.fillWidth: true
                        }

                        DialogButton {
                            text: "Cancel"
                            onClicked: win.cancel()
                        }

                        DialogButton {
                            text: "Authenticate"
                            filled: true
                            enabled: input.text !== "" && !win.busy
                            onClicked: win.submit()
                        }
                    }
                }
            }

            SequentialAnimation {
                id: shakeAnim

                NumberAnimation { target: shake; property: "x"; to: -14; duration: 45 }
                NumberAnimation { target: shake; property: "x"; to: 12; duration: 70 }
                NumberAnimation { target: shake; property: "x"; to: -8; duration: 60 }
                NumberAnimation { target: shake; property: "x"; to: 5; duration: 50 }
                NumberAnimation { target: shake; property: "x"; to: 0; duration: 45 }
            }
        }
    }
}
