import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Everything drawn on one output while locked (or previewing).
Item {
    id: root

    required property string screenName
    property bool preview: false
    // 0 = the crisp wallpaper, 1 = fully locked look. Drives enter and exit.
    property real phase: 0
    readonly property string wallpaper: Wallpapers.pathFor(screenName)
    readonly property bool busy: Lock.state === "busy"
    readonly property bool bad: Lock.state === "failed" || Lock.state === "error"
    property string armed: ""

    function act(id) {
        if (armed !== id) {
            armed = id;
            return;
        }
        armed = "";
        if (id === "reboot")
            Quickshell.execDetached(["systemctl", "reboot"]);
        else if (id === "poweroff")
            Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    Component.onCompleted: {
        phase = 1;
        input.forceActiveFocus();
    }

    Behavior on phase {
        NumberAnimation {
            duration: 550
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: Lock

        function onUnlockingChanged(): void {
            if (Lock.unlocking)
                root.phase = 0;
        }

        function onRejected(): void {
            shakeAnim.restart();
        }
    }

    Timer {
        running: root.armed !== ""
        interval: 4000
        onTriggered: root.armed = ""
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    // ---------- background ----------

    // Used when there is no wallpaper: theme gradient with two soft color blobs.
    Rectangle {
        anchors.fill: parent
        visible: wall.status !== Image.Ready
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.base
            }
            GradientStop {
                position: 1
                color: Theme.crust
            }
        }

        Item {
            id: blobs

            anchors.fill: parent
            visible: false

            Rectangle {
                x: parent.width * 0.12
                y: parent.height * 0.1
                width: parent.width * 0.45
                height: width
                radius: width / 2
                color: Qt.alpha(Theme.accent, 0.35)
            }

            Rectangle {
                x: parent.width * 0.5
                y: parent.height * 0.45
                width: parent.width * 0.4
                height: width
                radius: width / 2
                color: Qt.alpha(Theme.blue, 0.25)
            }
        }

        MultiEffect {
            anchors.fill: parent
            source: blobs
            blurEnabled: true
            blurMax: 64
            blur: 1
            autoPaddingEnabled: false
        }
    }

    // Half resolution is plenty, it gets blurred anyway.
    Image {
        id: wall

        anchors.fill: parent
        source: root.wallpaper ? "file://" + root.wallpaper : ""
        sourceSize: Qt.size(root.width / 2, root.height / 2)
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        visible: wall.status === Image.Ready
        source: wall
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: root.phase
        blurMultiplier: 0.6
        brightness: -0.12 * root.phase
        saturation: -0.15 * root.phase
        scale: 1 + 0.05 * root.phase
    }

    // Theme tint + vignette so text reads on any wallpaper.
    Rectangle {
        anchors.fill: parent
        opacity: root.phase
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.alpha(Theme.crust, 0.35)
            }
            GradientStop {
                position: 0.45
                color: Qt.alpha(Theme.base, 0.25)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(Theme.crust, 0.75)
            }
        }
    }

    // Clicking anywhere returns focus to the (invisible) password input.
    MouseArea {
        anchors.fill: parent
        onClicked: input.forceActiveFocus()
    }

    // ---------- foreground ----------

    Item {
        anchors.fill: parent
        opacity: root.phase

        // Clock
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.13 - (1 - root.phase) * 40
            spacing: 0

            Row {
                anchors.horizontalCenter: parent.horizontalCenter

                StyledText {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.family: Theme.displayFont
                    font.pixelSize: 136
                    font.weight: Font.Bold
                    font.letterSpacing: -3
                    font.features: {
                        "tnum": 1
                    }
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd · d MMMM").toUpperCase()
                font.pixelSize: 15
                font.weight: Font.Bold
                font.letterSpacing: 3
                color: Theme.accent
            }

            // Weather (cached, so it's there even before the network is).
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 14
                spacing: 10
                visible: Weather.available
                Component.onCompleted: Weather.refresh()

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.icon
                    size: 26
                    color: Theme.accent
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.temp
                    font.family: Theme.displayFont
                    font.pixelSize: 22
                    font.weight: Font.ExtraBold
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.place ? `${Weather.condition} · ${Weather.place}` : Weather.condition
                    font.pixelSize: 17
                    color: Theme.subtext1
                }
            }
        }

        // Avatar, name, password.
        ColumnLayout {
            id: auth

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.52 + (1 - root.phase) * 50
            spacing: 14

            transform: Translate {
                id: shake
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 112
                implicitHeight: 112

                // Aurora ring: the gradient disc seen through a ring-shaped mask.
                Rectangle {
                    id: auroraDisc

                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                    layer.enabled: true
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.bad ? Theme.red : Theme.accent
                        }
                        GradientStop {
                            position: 1
                            color: root.bad ? Theme.red : Theme.accent2
                        }
                    }
                }

                Rectangle {
                    id: ringShape

                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 3
                    border.color: "white"
                    visible: false
                    layer.enabled: true
                }

                MultiEffect {
                    id: ring

                    anchors.fill: parent
                    source: auroraDisc
                    maskEnabled: true
                    maskSource: ringShape
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                    opacity: 0.85

                    SequentialAnimation on opacity {
                        running: root.busy
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) ring.opacity = 0.85

                        NumberAnimation {
                            to: 0.2
                            duration: 500
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 0.85
                            duration: 500
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                Avatar {
                    anchors.centerIn: parent
                    size: 98
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Power.user
                font.family: Theme.displayFont
                font.pixelSize: 22
                font.weight: Font.ExtraBold
            }

            Rectangle {
                id: field

                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                implicitWidth: 340
                implicitHeight: 52
                radius: height / 2
                color: Qt.alpha(Theme.base, 0.55)
                border.width: 1.5
                border.color: root.bad ? Theme.red : Lock.password !== "" ? Qt.alpha(Theme.accent, 0.55) : Theme.rim

                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.anim
                    }
                }

                TextInput {
                    id: input

                    anchors.fill: parent
                    opacity: 0
                    focus: true
                    echoMode: TextInput.Password
                    readOnly: root.busy || Lock.unlocking
                    cursorVisible: false
                    onTextChanged: {
                        if (Lock.password !== text)
                            Lock.password = text;
                        if (text !== "" && root.bad)
                            Lock.state = "idle";
                    }
                    Keys.onReturnPressed: Lock.submit()
                    Keys.onEnterPressed: Lock.submit()
                    Keys.onEscapePressed: {
                        if (text === "" && root.preview)
                            Lock.cancelPreview();
                        else
                            text = "";
                    }

                    Connections {
                        target: Lock

                        function onPasswordChanged(): void {
                            if (input.text !== Lock.password)
                                input.text = Lock.password;
                        }
                    }
                }

                Icon {
                    id: lockIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.busy ? Icons.loading : Lock.unlocking ? Icons.lockOpen : Icons.lockOutline
                    color: root.bad ? Theme.red : Theme.subtext0

                    RotationAnimation on rotation {
                        running: root.busy
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                        onRunningChanged: if (!running) lockIcon.rotation = 0
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: Lock.password === "" && !root.busy
                    text: "Enter password"
                    color: Theme.overlay1
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    Repeater {
                        model: Math.min(Lock.password.length, 20)

                        Rectangle {
                            required property int index

                            width: 10
                            height: 10
                            radius: 5
                            // Aurora across the dots.
                            color: root.busy ? Theme.overlay1 : Qt.tint(Theme.accent, Qt.alpha(Theme.accent2, index / 16))
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

                MouseArea {
                    id: submit

                    anchors.right: parent.right
                    anchors.rightMargin: 7
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    height: 38
                    enabled: Lock.password !== "" && !root.busy
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Lock.submit()

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.well
                        scale: submit.pressed ? 0.92 : 1
                        gradient: submit.enabled ? aurora : null

                        Gradient {
                            id: aurora

                            GradientStop {
                                position: 0
                                color: submit.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                            }
                            GradientStop {
                                position: 1
                                color: submit.containsMouse ? Qt.lighter(Theme.accent2, 1.1) : Theme.accent2
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Icon {
                        anchors.centerIn: parent
                        text: Icons.arrowRight
                        size: 20
                        color: submit.enabled ? Theme.onAccent : Theme.overlay1
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 20
                text: {
                    if (Lock.unlocking)
                        return "Welcome back";
                    if (root.busy)
                        return "Checking…";
                    if (Lock.message)
                        return Lock.message;
                    return root.preview ? "Preview · Esc to leave" : "";
                }
                color: root.bad ? Theme.red : Theme.subtext0
                font.pixelSize: Theme.fontSize
            }
        }

        // Now playing.
        Rectangle {
            visible: Media.active !== null
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 32
            width: mediaRow.implicitWidth + 24
            height: 68
            radius: Theme.radiusLarge
            color: Qt.alpha(Theme.base, 0.45)
            border.width: 1
            border.color: Theme.rim

            RowLayout {
                id: mediaRow

                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                ClippingRectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 12
                    color: Theme.surface0

                    Image {
                        anchors.fill: parent
                        source: Media.active?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(96, 96)
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        Layout.maximumWidth: 240
                        text: Media.active?.trackTitle || Media.nameOf(Media.active)
                        font.weight: Font.Bold
                    }

                    StyledText {
                        Layout.maximumWidth: 240
                        text: Media.active?.trackArtist ?? ""
                        color: Theme.subtext0
                        font.pixelSize: Theme.smallFontSize + 1
                    }
                }

                IconButton {
                    icon: Icons.previous
                    enabled: Media.active?.canGoPrevious ?? false
                    onClicked: Media.active.previous()
                }

                IconButton {
                    filled: true
                    icon: Media.active?.isPlaying ? Icons.pause : Icons.play
                    onClicked: Media.active.togglePlaying()
                }

                IconButton {
                    icon: Icons.next
                    enabled: Media.active?.canGoNext ?? false
                    onClicked: Media.active.next()
                }
            }
        }

        // Layout, battery and power.
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 32
            spacing: 10

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.armed !== ""
                rightPadding: 6
                text: root.armed === "reboot" ? "Click again to restart" : "Click again to shut down"
                color: Theme.red
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: Niri.keyboardLayout !== ""
                width: kbRow.implicitWidth + 28
                height: 44
                radius: 22
                color: Qt.alpha(Theme.base, 0.45)
                border.width: 1
                border.color: Theme.rim

                Row {
                    id: kbRow

                    anchors.centerIn: parent
                    spacing: 8

                    Icon {
                        text: Icons.keyboard
                        color: Theme.subtext0
                    }

                    StyledText {
                        text: Niri.keyboardLayout
                        color: Theme.subtext1
                    }
                }
            }

            Repeater {
                model: [
                    { id: "suspend", icon: Icons.sleep },
                    { id: "reboot", icon: Icons.restart },
                    { id: "poweroff", icon: Icons.power }
                ]

                MouseArea {
                    id: pb

                    required property var modelData
                    readonly property bool isArmed: root.armed === modelData.id

                    width: 44
                    height: 44
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.id === "suspend")
                            Quickshell.execDetached(["systemctl", "suspend"]);
                        else
                            root.act(modelData.id);
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: pb.isArmed ? Theme.red : pb.containsMouse ? Qt.alpha(Theme.text, 0.16) : Qt.alpha(Theme.base, 0.45)
                        border.width: pb.isArmed ? 0 : 1
                        border.color: Theme.rim

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.anim
                            }
                        }
                    }

                    Icon {
                        anchors.centerIn: parent
                        text: pb.modelData.icon
                        size: 18
                        color: pb.isArmed ? Theme.onAccent : Theme.text
                    }
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
