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
    // Side by side on landscape outputs, stacked on portrait ones.
    readonly property bool wide: width > height * 1.15
    readonly property real clockSize: Math.round(Math.min(width * (wide ? 0.13 : 0.22), height * 0.21))

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

        // Giant stacked clock: hours over minutes, the minutes filled with the
        // aurora. Left of the password on wide outputs, above it on tall ones.
        // Placed by font metrics: digits span ~0.24..0.97 em of the line box.
        Item {
            id: clockBlock

            readonly property real em: root.clockSize

            x: root.wide ? Math.round(parent.width * 0.08) : Math.round((parent.width - width) / 2)
            y: (root.wide ? Math.round((parent.height - height) / 2) - 20 : Math.round(parent.height * 0.08)) - (1 - root.phase) * 40
            width: Math.max(hours.implicitWidth, minutes.implicitWidth, date.implicitWidth)
            height: weather.y + weather.height

            StyledText {
                id: hours

                text: Qt.formatDateTime(clock.date, Settings.d.clock24h ? "HH" : "hh")
                font.family: Theme.displayFont
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

                StyledText {
                    id: minutes

                    text: Qt.formatDateTime(clock.date, "mm")
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
                            color: Theme.accent
                        }
                        GradientStop {
                            position: 0.95
                            color: Theme.accent2
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
                color: Qt.alpha(Theme.text, 0.14)

                Rectangle {
                    width: Math.max(parent.height, parent.width * clock.date.getSeconds() / 59)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.text

                    Behavior on width {
                        enabled: clock.date.getSeconds() !== 0
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            StyledText {
                id: date

                x: sweep.x
                y: sweep.y + 22
                text: Qt.formatDateTime(clock.date, "dddd · d MMMM").toUpperCase()
                font.pixelSize: Math.max(14, Math.round(root.clockSize * 0.075))
                font.weight: Font.Bold
                font.letterSpacing: 4
                color: Theme.text
            }

            // Weather (cached, so it's there even before the network is).
            Row {
                id: weather

                x: sweep.x
                y: date.y + date.height + 10
                spacing: 10
                visible: Weather.available
                Component.onCompleted: Weather.refresh()

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.icon
                    size: 24
                    color: Theme.accent
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.temp
                    font.family: Theme.displayFont
                    font.pixelSize: 20
                    font.weight: Font.ExtraBold
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.place ? `${Weather.condition} · ${Weather.place}` : Weather.condition
                    font.pixelSize: 16
                    color: Theme.subtext1
                }
            }
        }

        // Avatar, name, password on a glass card.
        Rectangle {
            id: card

            x: root.wide ? Math.round(parent.width * 0.92 - width) : Math.round((parent.width - width) / 2)
            y: (root.wide ? Math.round((parent.height - height) / 2) : Math.round(parent.height * 0.56)) + (1 - root.phase) * 50
            width: auth.implicitWidth + 64
            height: auth.implicitHeight + 64
            radius: 36
            color: Qt.alpha(Theme.base, 0.42)
            border.width: 1
            border.color: Qt.alpha(Theme.text, 0.1)

            transform: Translate {
                id: shake
            }

            // Aurora light at the top edge of the card.
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(root.bad ? Theme.red : Theme.accent, 0.16)
                    }
                    GradientStop {
                        position: 0.5
                        color: "transparent"
                    }
                }
            }

            ColumnLayout {
                id: auth

                anchors.centerIn: parent
                spacing: 14

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 112
                    implicitHeight: 112

                    // Aurora ring; red after a wrong password, breathing while checking.
                    Rectangle {
                        id: ring

                        anchors.fill: parent
                        radius: width / 2
                        opacity: 0.95
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: root.bad ? Theme.red : Theme.accent
                            }
                            GradientStop {
                                position: 1
                                color: root.bad ? Theme.peach : Theme.accent2
                            }
                        }

                        SequentialAnimation on opacity {
                            running: root.busy
                            loops: Animation.Infinite
                            onRunningChanged: if (!running) ring.opacity = 0.95

                            NumberAnimation {
                                to: 0.25
                                duration: 500
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                to: 0.95
                                duration: 500
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 104
                        height: 104
                        radius: 52
                        color: Theme.base
                    }

                    Avatar {
                        anchors.centerIn: parent
                        size: 96
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Power.user
                        font.family: Theme.displayFont
                        font.pixelSize: 26
                        font.weight: Font.Black
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        visible: Power.hostname !== ""
                        text: `on ${Power.hostname}`
                        color: Theme.subtext0
                    }
                }

                Rectangle {
                    id: field

                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    implicitWidth: 340
                    implicitHeight: 56
                    radius: height / 2
                    color: Qt.alpha(Theme.crust, 0.5)
                    border.width: 1.5
                    border.color: root.bad ? Theme.red : Lock.password !== "" ? Qt.alpha(Theme.accent, 0.9) : Qt.alpha(Theme.text, 0.14)

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
                        anchors.leftMargin: 20
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

                    // One aurora dot per character, popping in.
                    Row {
                        anchors.centerIn: parent
                        spacing: 7

                        Repeater {
                            model: Math.min(Lock.password.length, 16)

                            Rectangle {
                                required property int index

                                width: 10
                                height: 10
                                radius: 5
                                color: root.busy ? Theme.overlay1 : Qt.tint(Theme.accent, Qt.alpha(Theme.accent2, index / 16))
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

                    MouseArea {
                        id: submit

                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 40
                        enabled: Lock.password !== "" && !root.busy
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Lock.submit()

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.alpha(Theme.surface1, 0.6)
                            scale: submit.containsMouse ? 1.06 : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Theme.anim
                                    easing.type: Easing.OutBack
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                opacity: submit.enabled ? 1 : 0
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: Theme.accent
                                    }
                                    GradientStop {
                                        position: 1
                                        color: Theme.accent2
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Theme.anim
                                    }
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
        }

        // Now playing.
        Rectangle {
            visible: Media.active !== null
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 32
            width: mediaRow.implicitWidth + 24
            height: 72
            radius: 36
            color: Qt.alpha(Theme.base, 0.42)
            border.width: 1
            border.color: Qt.alpha(Theme.text, 0.1)

            RowLayout {
                id: mediaRow

                anchors.fill: parent
                anchors.margins: 12
                anchors.rightMargin: 14
                spacing: 12

                ClippingRectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 24
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
                        color: Theme.accent
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
                height: 48
                radius: 24
                color: Qt.alpha(Theme.base, 0.42)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.1)

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

                    width: 48
                    height: 48
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
                        color: pb.isArmed ? Theme.red : pb.containsMouse ? Qt.alpha(Theme.text, 0.16) : Qt.alpha(Theme.base, 0.42)
                        border.width: 1
                        border.color: Qt.alpha(Theme.text, 0.1)

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
