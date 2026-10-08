// SDDM login theme matching the shell's lock screen: blurred wallpaper, big
// thin clock, avatar with an accent ring, a pill password field, sessions on
// the bottom left, keyboard layout and power on the bottom right.
// Only needs QtQuick + QtQuick.Effects (Qt 6).
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    readonly property color accent: config.accent || "#b3c5ff"
    readonly property color onAccent: config.onAccent || "#192e60"
    readonly property color base: config.base || "#121318"
    readonly property color crust: config.crust || "#0d0e13"
    readonly property color surface: config.surface || "#292a2f"
    readonly property color textColor: config.text || "#e3e2e9"
    readonly property color subtext: config.subtext || "#c5c6d0"
    readonly property color muted: config.muted || "#8f909a"
    readonly property color error: config.error || "#ffb4ab"
    readonly property string font: config.font || "Inter"

    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property bool busy: false
    property bool failed: false
    property string armed: ""
    property real phase: 0

    // userModel/sessionModel are list models; read roles through a Repeater.
    // itemAt() isn't reactive; depend on count so these update once filled.
    readonly property var user: users.count > 0 ? users.itemAt(userIndex) : null
    readonly property string userName: user?.name ?? ""
    readonly property var session: sessions.count > 0 ? sessions.itemAt(sessionIndex) : null

    function login() {
        if (busy || password.text === "")
            return;
        busy = true;
        failed = false;
        sddm.login(userName, password.text, sessionIndex);
    }

    function power(action) {
        if (armed !== action) {
            armed = action;
            disarm.restart();
            return;
        }
        if (action === "reboot")
            sddm.reboot();
        else if (action === "poweroff")
            sddm.powerOff();
    }

    color: base
    Component.onCompleted: {
        phase = 1;
        password.forceActiveFocus();
    }

    Behavior on phase {
        NumberAnimation {
            duration: 700
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.busy = false;
            root.failed = true;
            password.text = "";
            shake.restart();
        }

        function onLoginSucceeded() {
            root.phase = 0;
        }
    }

    Timer {
        id: disarm

        interval: 4000
        onTriggered: root.armed = ""
    }

    Timer {
        id: clockTick

        property date now: new Date()

        interval: 1000
        repeat: true
        running: true
        onTriggered: now = new Date()
    }

    Repeater {
        id: users

        model: userModel

        Item {
            required property string name
            required property string realName
            required property string icon
        }
    }

    Repeater {
        id: sessions

        model: sessionModel

        Item {
            required property string name
        }
    }

    // ---------- background ----------
    Image {
        id: wallpaper

        anchors.fill: parent
        source: config.background ? "file://" + config.background : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: parseInt(config.blur) || 64
        blur: root.phase
        blurMultiplier: 0.6
        brightness: -0.12 * root.phase
        saturation: -0.15 * root.phase
        scale: 1 + 0.05 * root.phase
    }

    Rectangle {
        anchors.fill: parent
        opacity: root.phase
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.alpha(root.crust, 0.35)
            }
            GradientStop {
                position: 0.45
                color: Qt.alpha(root.base, 0.25)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(root.crust, 0.75)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: password.forceActiveFocus()
    }

    // ---------- foreground ----------
    Item {
        anchors.fill: parent
        opacity: root.phase

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.13 - (1 - root.phase) * 40

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clockTick.now, "HH:mm")
                color: root.textColor
                font.family: root.font
                font.pixelSize: 136
                font.weight: Font.Light
                font.letterSpacing: -4
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clockTick.now, "dddd, d MMMM")
                color: root.subtext
                font.family: root.font
                font.pixelSize: 21
            }
        }

        Column {
            id: auth

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.52 + (1 - root.phase) * 50
            spacing: 14

            transform: Translate {
                id: shakeOffset
            }

            // Avatar with accent ring; arrows switch user when there are several.
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: userModel.count > 1
                    text: "‹"
                    color: root.muted
                    font.pixelSize: 34

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.userIndex = (root.userIndex - 1 + userModel.count) % userModel.count
                    }
                }

                Item {
                    width: 112
                    height: 112

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: 2
                        border.color: root.failed ? root.error : root.accent

                        SequentialAnimation on opacity {
                            running: root.busy
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: 0.25
                                duration: 500
                            }
                            NumberAnimation {
                                to: 1
                                duration: 500
                            }
                        }
                    }

                    Rectangle {
                        id: avatarBg

                        anchors.centerIn: parent
                        width: 98
                        height: 98
                        radius: 49
                        color: Qt.alpha(root.accent, 0.25)

                        Text {
                            anchors.centerIn: parent
                            visible: avatar.status !== Image.Ready
                            text: (root.user?.realName || root.userName).charAt(0).toUpperCase()
                            color: root.accent
                            font.family: root.font
                            font.pixelSize: 40
                            font.weight: Font.DemiBold
                        }

                        Image {
                            id: avatar

                            anchors.fill: parent
                            source: root.user?.icon ?? ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(196, 196)
                            visible: false
                        }

                        Rectangle {
                            id: avatarMask

                            anchors.fill: parent
                            radius: width / 2
                            visible: false
                            layer.enabled: true
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: avatar
                            visible: avatar.status === Image.Ready
                            maskEnabled: true
                            maskSource: avatarMask
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: userModel.count > 1
                    text: "›"
                    color: root.muted
                    font.pixelSize: 34

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.userIndex = (root.userIndex + 1) % userModel.count
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.user?.realName || root.userName
                color: root.textColor
                font.family: root.font
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }

            Rectangle {
                id: field

                anchors.horizontalCenter: parent.horizontalCenter
                width: 340
                height: 52
                radius: 26
                color: Qt.alpha(root.base, 0.55)
                border.width: 1.5
                border.color: root.failed ? root.error : password.text ? Qt.alpha(root.accent, 0.9) : Qt.alpha(root.textColor, 0.14)

                TextInput {
                    id: password

                    anchors.fill: parent
                    opacity: 0
                    echoMode: TextInput.Password
                    focus: true
                    readOnly: root.busy
                    onTextChanged: if (text) root.failed = false
                    Keys.onReturnPressed: root.login()
                    Keys.onEnterPressed: root.login()
                    Keys.onEscapePressed: text = ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: password.text === "" && !root.busy
                    text: "Enter password"
                    color: root.muted
                    font.family: root.font
                    font.pixelSize: 14
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    Repeater {
                        model: Math.min(password.text.length, 20)

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: root.busy ? root.muted : root.textColor
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

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 7
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    height: 38
                    radius: 19
                    color: password.text && !root.busy ? root.accent : Qt.alpha(root.surface, 0.8)

                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        color: password.text ? root.onAccent : root.muted
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.login()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 20
                color: root.failed ? root.error : root.muted
                font.family: root.font
                font.pixelSize: 13
                text: root.busy ? "Signing in…" : root.failed ? "Incorrect password" : keyboard.capsLock ? "Caps Lock is on" : ""
            }
        }

        // Session picker (click to cycle).
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 32
            width: sessionLabel.implicitWidth + 36
            height: 44
            radius: 22
            color: sessionArea.containsMouse ? Qt.alpha(root.textColor, 0.16) : Qt.alpha(root.base, 0.45)

            Text {
                id: sessionLabel

                anchors.centerIn: parent
                text: (root.session?.name ?? "Session") + (sessions.count > 1 ? "  ⌄" : "")
                color: root.subtext
                font.family: root.font
                font.pixelSize: 14
            }

            MouseArea {
                id: sessionArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessions.count)
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 32
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.armed !== ""
                rightPadding: 6
                text: root.armed === "reboot" ? "Click again to restart" : "Click again to shut down"
                color: root.error
                font.family: root.font
                font.pixelSize: 14
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: keyboard.layouts.length > 0
                width: kb.implicitWidth + 28
                height: 44
                radius: 22
                color: Qt.alpha(root.base, 0.45)

                Text {
                    id: kb

                    anchors.centerIn: parent
                    text: keyboard.layouts[keyboard.currentLayout]?.longName ?? ""
                    color: root.subtext
                    font.family: root.font
                    font.pixelSize: 14
                }
            }

            Repeater {
                model: [
                    { id: "suspend", glyph: "☾", show: sddm.canSuspend },
                    { id: "reboot", glyph: "↻", show: sddm.canReboot },
                    { id: "poweroff", glyph: "⏻", show: sddm.canPowerOff }
                ]

                Rectangle {
                    id: pb

                    required property var modelData

                    visible: modelData.show
                    width: 44
                    height: 44
                    radius: 22
                    color: root.armed === modelData.id ? root.error : pbArea.containsMouse ? Qt.alpha(root.textColor, 0.16) : Qt.alpha(root.base, 0.45)

                    Text {
                        anchors.centerIn: parent
                        text: pb.modelData.glyph
                        color: root.armed === pb.modelData.id ? root.crust : root.textColor
                        font.pixelSize: 18
                    }

                    MouseArea {
                        id: pbArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pb.modelData.id === "suspend" ? sddm.suspend() : root.power(pb.modelData.id)
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: shake

        NumberAnimation { target: shakeOffset; property: "x"; to: -14; duration: 45 }
        NumberAnimation { target: shakeOffset; property: "x"; to: 12; duration: 70 }
        NumberAnimation { target: shakeOffset; property: "x"; to: -8; duration: 60 }
        NumberAnimation { target: shakeOffset; property: "x"; to: 5; duration: 50 }
        NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 45 }
    }
}
