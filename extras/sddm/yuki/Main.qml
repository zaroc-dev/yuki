// SDDM login theme matching the shell's lock screen: blurred wallpaper, a giant
// stacked clock with aurora minutes, avatar and password on a glass card,
// sessions on the bottom left, keyboard layout and power on the bottom right.
// Only needs QtQuick + QtQuick.Effects (Qt 6).
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    readonly property color accent: config.accent || "#b3c5ff"
    readonly property color accent2: config.accent2 || "#e1bbdc"
    readonly property color onAccent: config.onAccent || "#192e60"
    readonly property color base: config.base || "#121318"
    readonly property color crust: config.crust || "#0d0e13"
    readonly property color surface: config.surface || "#292a2f"
    readonly property color textColor: config.text || "#e3e2e9"
    readonly property color subtext: config.subtext || "#c5c6d0"
    readonly property color muted: config.muted || "#8f909a"
    readonly property color error: config.error || "#ffb4ab"
    readonly property string font: config.font || "Inter"
    readonly property string displayFont: Qt.fontFamilies().includes(config.displayFont || "Inter Display") ? config.displayFont || "Inter Display" : font
    // Side by side on landscape screens, stacked on portrait ones.
    readonly property bool wide: width > height * 1.15
    readonly property real clockSize: Math.round(Math.min(width * (wide ? 0.13 : 0.22), height * 0.21))

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

        // Giant stacked clock: hours over minutes, the minutes filled with the
        // aurora. Placed by font metrics: digits span ~0.24..0.97 em.
        Item {
            id: clockBlock

            readonly property real em: root.clockSize

            x: root.wide ? Math.round(parent.width * 0.08) : Math.round((parent.width - width) / 2)
            y: (root.wide ? Math.round((parent.height - height) / 2) - 20 : Math.round(parent.height * 0.08)) - (1 - root.phase) * 40
            width: Math.max(hours.implicitWidth, minutes.implicitWidth, date.implicitWidth)
            height: date.y + date.height

            Text {
                id: hours

                text: Qt.formatTime(clockTick.now, "HH")
                color: root.textColor
                font.family: root.displayFont
                font.pixelSize: root.clockSize
                font.weight: Font.Black
                font.letterSpacing: -root.clockSize * 0.04
                font.features: {
                    "tnum": 1
                }
            }

            Item {
                id: minutesBox

                y: Math.round(clockBlock.em * 0.82)
                width: minutes.implicitWidth
                height: minutes.implicitHeight

                Text {
                    id: minutes

                    text: Qt.formatTime(clockTick.now, "mm")
                    font: hours.font
                    visible: false
                    layer.enabled: true
                }

                Rectangle {
                    id: aurora

                    width: minutes.implicitWidth
                    height: minutes.implicitHeight
                    visible: false
                    layer.enabled: true
                    gradient: Gradient {
                        GradientStop {
                            position: 0.25
                            color: root.accent
                        }
                        GradientStop {
                            position: 0.95
                            color: root.accent2
                        }
                    }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: aurora
                    maskEnabled: true
                    maskSource: minutes
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
            }

            // Seconds sweep under the digits.
            Rectangle {
                id: sweep

                x: clockBlock.em * 0.04
                y: Math.round(minutesBox.y + clockBlock.em * 1.06)
                width: clockBlock.width - x * 2
                height: 4
                radius: 2
                color: Qt.alpha(root.textColor, 0.14)

                Rectangle {
                    width: Math.max(parent.height, parent.width * clockTick.now.getSeconds() / 59)
                    height: parent.height
                    radius: parent.radius
                    color: root.textColor
                }
            }

            Text {
                id: date

                x: sweep.x
                y: sweep.y + 22
                text: Qt.formatDate(clockTick.now, "dddd · d MMMM").toUpperCase()
                color: root.textColor
                font.family: root.font
                font.pixelSize: Math.max(14, Math.round(root.clockSize * 0.075))
                font.weight: Font.Bold
                font.letterSpacing: 4
            }
        }

        // Avatar, name and password on a glass card.
        Rectangle {
            id: card

            x: root.wide ? Math.round(parent.width * 0.92 - width) : Math.round((parent.width - width) / 2)
            y: (root.wide ? Math.round((parent.height - height) / 2) : Math.round(parent.height * 0.56)) + (1 - root.phase) * 50
            width: auth.implicitWidth + 64
            height: auth.implicitHeight + 64
            radius: 36
            color: Qt.alpha(root.base, 0.42)
            border.width: 1
            border.color: Qt.alpha(root.textColor, 0.1)

            transform: Translate {
                id: shakeOffset
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(root.failed ? root.error : root.accent, 0.16)
                    }
                    GradientStop {
                        position: 0.5
                        color: "transparent"
                    }
                }
            }

            Column {
                id: auth

                anchors.centerIn: parent
                spacing: 14

                // Avatar in an aurora ring; arrows switch user when there are several.
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
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: root.failed ? root.error : root.accent
                                }
                                GradientStop {
                                    position: 1
                                    color: root.failed ? root.error : root.accent2
                                }
                            }

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
                            anchors.centerIn: parent
                            width: 104
                            height: 104
                            radius: 52
                            color: root.base
                        }

                        Rectangle {
                            id: avatarBg

                            anchors.centerIn: parent
                            width: 96
                            height: 96
                            radius: 48
                            color: Qt.alpha(root.accent, 0.25)

                            Text {
                                anchors.centerIn: parent
                                visible: avatar.status !== Image.Ready
                                text: (root.user?.realName || root.userName).charAt(0).toUpperCase()
                                color: root.accent
                                font.family: root.displayFont
                                font.pixelSize: 40
                                font.weight: Font.Black
                            }

                            Image {
                                id: avatar

                                anchors.fill: parent
                                source: root.user?.icon ?? ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(192, 192)
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
                    font.family: root.displayFont
                    font.pixelSize: 26
                    font.weight: Font.Black
                }

                Rectangle {
                    id: field

                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 340
                    height: 56
                    radius: 28
                    color: Qt.alpha(root.crust, 0.5)
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

                    // One aurora dot per character, popping in.
                    Row {
                        anchors.centerIn: parent
                        spacing: 7

                        Repeater {
                            model: Math.min(password.text.length, 16)

                            Rectangle {
                                required property int index

                                width: 10
                                height: 10
                                radius: 5
                                color: root.busy ? root.muted : Qt.tint(root.accent, Qt.alpha(root.accent2, index / 16))
                                scale: 0
                                Component.onCompleted: scale = 1

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutBack
                                        easing.overshoot: 2.5
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 40
                        radius: 20
                        color: Qt.alpha(root.surface, 0.8)

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            visible: password.text !== "" && !root.busy
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: root.accent
                                }
                                GradientStop {
                                    position: 1
                                    color: root.accent2
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "→"
                            color: password.text ? root.onAccent : root.muted
                            font.pixelSize: 18
                            font.weight: Font.Bold
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
        }

        // Session picker (click to cycle).
        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 32
            width: sessionLabel.implicitWidth + 36
            height: 48
            radius: 24
            color: sessionArea.containsMouse ? Qt.alpha(root.textColor, 0.16) : Qt.alpha(root.base, 0.42)
            border.width: 1
            border.color: Qt.alpha(root.textColor, 0.1)

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
                height: 48
                radius: 24
                color: Qt.alpha(root.base, 0.42)
                border.width: 1
                border.color: Qt.alpha(root.textColor, 0.1)

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
                    width: 48
                    height: 48
                    radius: 24
                    color: root.armed === modelData.id ? root.error : pbArea.containsMouse ? Qt.alpha(root.textColor, 0.16) : Qt.alpha(root.base, 0.42)
                    border.width: 1
                    border.color: Qt.alpha(root.textColor, 0.1)

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
