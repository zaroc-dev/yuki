import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Opens from the distro badge as a drawer down the left edge: a big hello,
// your apps, tools and quick toggles.
BarPopup {
    id: root

    readonly property string screenName: target.QsWindow.window?.screen?.name ?? ""
    readonly property string wallpaper: Wallpapers.pathFor(screenName)
    property date now: new Date()

    function launch(entry) {
        close();
        Apps.launch(entry);
    }

    function greeting(h) {
        if (h >= 5 && h < 12)
            return "Good morning";
        if (h >= 12 && h < 18)
            return "Good afternoon";
        if (h >= 18 && h < 23)
            return "Good evening";
        return "Good night";
    }

    onVisibleChanged: {
        if (visible) {
            now = new Date();
            Power.refresh();
        }
    }

    // A big toggle tile: icon well, label, state underneath.
    component Quick: MouseArea {
        id: q

        property string icon
        property string label
        property string detail
        property bool on: false

        Layout.fillWidth: true
        implicitHeight: 58
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: q.containsMouse ? Theme.cardHover : Theme.card
            scale: q.pressed ? 0.96 : 1

            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 100
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: q.on ? 1 : 0
                gradient: Gradient {
                    orientation: Gradient.Horizontal

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

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                implicitWidth: 38
                implicitHeight: 38
                radius: 14
                color: q.on ? Qt.alpha(Theme.onAccent, 0.14) : Theme.well

                Icon {
                    anchors.centerIn: parent
                    text: q.icon
                    size: 18
                    color: q.on ? Theme.onAccent : Theme.text
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: q.label
                    font.weight: Font.Bold
                    color: q.on ? Theme.onAccent : Theme.text
                }

                StyledText {
                    Layout.fillWidth: true
                    text: q.detail
                    font.pixelSize: Theme.smallFontSize
                    color: q.on ? Qt.alpha(Theme.onAccent, 0.75) : Theme.subtext0
                }
            }
        }
    }

    // ---------- hero ----------
    RowLayout {
        Layout.preferredWidth: 440
        Layout.fillWidth: true
        spacing: 16

        // Avatar in an aurora ring.
        Rectangle {
            implicitWidth: 66
            implicitHeight: 66
            radius: width / 2
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

            Rectangle {
                anchors.centerIn: parent
                width: 60
                height: 60
                radius: 30
                color: Theme.base

                Avatar {
                    anchors.centerIn: parent
                    size: 54
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -2

            StyledText {
                Layout.fillWidth: true
                text: `${root.greeting(root.now.getHours())},`
                color: Theme.subtext0
                font.pixelSize: Theme.fontSize + 1
            }

            StyledText {
                Layout.fillWidth: true
                text: Power.user
                font.family: Theme.displayFont
                font.pixelSize: 30
                font.weight: Font.Black
                font.letterSpacing: -0.5
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 3
                text: `${Power.hostname} · up ${Power.formatUptime(Power.uptime)}`
                font.pixelSize: Theme.smallFontSize
                color: Theme.overlay1
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 2

            IconButton {
                icon: Icons.settings
                color: Theme.subtext1
                onClicked: Ui.openSettings()
            }

            IconButton {
                icon: Icons.lockOutline
                color: Theme.subtext1
                onClicked: {
                    root.close();
                    Lock.lock();
                }
            }

            IconButton {
                icon: Icons.power
                color: containsMouse ? Theme.red : Theme.subtext1
                onClicked: {
                    root.close();
                    Ui.popupRequested("power", root.screenName);
                }
            }
        }
    }

    // A fake search field: the real one lives in the launcher.
    MouseArea {
        id: search

        Layout.fillWidth: true
        implicitHeight: 44
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onClicked: {
            root.close();
            Ui.launcherOpen = true;
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.well
            border.width: 1
            border.color: search.containsMouse ? Qt.alpha(Theme.accent, 0.6) : Theme.rim

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 8
            spacing: 10

            Icon {
                text: Icons.search
                color: search.containsMouse ? Theme.accent : Theme.overlay1
            }

            StyledText {
                Layout.fillWidth: true
                text: "Search apps…"
                color: Theme.overlay1
            }

            Rectangle {
                implicitWidth: allLabel.implicitWidth + 18
                implicitHeight: 28
                radius: 14
                color: Theme.card

                StyledText {
                    id: allLabel

                    anchors.centerIn: parent
                    text: `${Apps.entries.length} apps`
                    font.pixelSize: Theme.smallFontSize
                    font.weight: Font.DemiBold
                    color: Theme.subtext1
                }
            }
        }
    }

    // ---------- pinned ----------
    SectionLabel {
        text: "Pinned"
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 5
        columnSpacing: 4
        rowSpacing: 4

        Repeater {
            model: Apps.pinned

            MouseArea {
                id: tile

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 84
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: e => {
                    if (e.button === Qt.RightButton)
                        Apps.togglePin(modelData);
                    else
                        root.launch(modelData);
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: tile.pressed ? Theme.pressed : tile.containsMouse ? Theme.card : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.anim
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        iconName: tile.modelData.icon
                        size: 38
                        scale: tile.containsMouse ? 1.12 : 1
                        y: tile.containsMouse ? -2 : 0

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.anim
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(implicitWidth, tile.width - 8)
                        horizontalAlignment: Text.AlignHCenter
                        text: tile.modelData.name
                        font.pixelSize: Theme.smallFontSize
                        font.weight: tile.containsMouse ? Font.DemiBold : Font.Normal
                        color: tile.containsMouse ? Theme.text : Theme.subtext1
                    }
                }
            }
        }
    }

    // ---------- frequent ----------
    SectionLabel {
        visible: Apps.frequent.length > 0
        text: "Frequent"
    }

    Flow {
        Layout.fillWidth: true
        visible: Apps.frequent.length > 0
        spacing: 6

        Repeater {
            model: Apps.frequent.slice(0, 4)

            MouseArea {
                id: chip

                required property var modelData

                width: chipRow.implicitWidth + 24
                height: 36
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launch(modelData)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: chip.containsMouse ? Theme.cardHover : Theme.card
                }

                Row {
                    id: chipRow

                    anchors.centerIn: parent
                    spacing: 8

                    AppIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: chip.modelData.icon
                        size: 20
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: chip.modelData.name
                        font.pixelSize: Theme.smallFontSize + 1
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }

    // ---------- tools ----------
    SectionLabel {
        text: "Capture"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: [
                { icon: Icons.region, label: "Region", run: () => Screenshots.region() },
                { icon: Icons.screenshot, label: "Screen", run: () => Screenshots.screen() },
                { icon: Icons.window, label: "Window", run: () => Screenshots.window() },
                { icon: Icons.clipboard, label: "Clipboard", run: () => Ui.clipboardOpen = true }
            ]

            MouseArea {
                id: tool

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 64
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.close(true);
                    // Let the popup disappear before niri captures the screen.
                    Qt.callLater(() => delay.start());
                }

                Timer {
                    id: delay

                    interval: 180
                    onTriggered: tool.modelData.run()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: tool.containsMouse ? Theme.cardHover : Theme.card
                    border.width: tool.containsMouse ? 1 : 0
                    border.color: Qt.alpha(Theme.accent, 0.4)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tool.modelData.icon
                        size: 20
                        color: tool.containsMouse ? Theme.accent : Theme.text
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tool.modelData.label
                        font.pixelSize: Theme.smallFontSize
                        font.weight: Font.Medium
                        color: Theme.subtext1
                    }
                }
            }
        }
    }

    // ---------- wallpaper card ----------
    ClippingRectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        visible: Settings.d.wallpaperEnabled && root.wallpaper !== ""
        implicitHeight: 92
        radius: 20
        color: Theme.card

        // The wallpaper itself is the card's background, darkened for the text.
        Image {
            anchors.fill: parent
            source: root.wallpaper ? "file://" + root.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(480, 184)
            asynchronous: true
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.alpha(Theme.crust, 0.85)
                }
                GradientStop {
                    position: 0.7
                    color: Qt.alpha(Theme.crust, 0.35)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(Theme.crust, 0.6)
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Ui.openSettings("wallpaper")
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 10
            spacing: 4

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: "WALLPAPER"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.6
                    color: Theme.accent
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.wallpaper.split("/").pop().replace(/\.[^.]+$/, "").replace(/[_-]+/g, " ")
                    font.family: Theme.displayFont
                    font.pixelSize: 17
                    font.weight: Font.ExtraBold
                    color: "white"
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.screenName
                    font.pixelSize: Theme.smallFontSize
                    color: Qt.alpha("white", 0.7)
                }
            }

            IconButton {
                icon: Icons.chevronLeft
                color: "white"
                onClicked: Wallpapers.step(root.screenName, -1)
            }

            IconButton {
                icon: Icons.chevronRight
                color: "white"
                onClicked: Wallpapers.step(root.screenName, 1)
            }

            IconButton {
                icon: Icons.shuffle
                color: "white"
                onClicked: Wallpapers.shuffleAll()
            }
        }
    }

    // ---------- quick toggles ----------
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 6
        rowSpacing: 6

        Quick {
            icon: Theme.lightMode ? Icons.sun : Icons.moon
            label: Theme.lightMode ? "Light" : "Dark"
            detail: "Appearance"
            on: !Theme.lightMode
            onClicked: Theme.toggleMode()
        }

        Quick {
            icon: Icons.image
            label: "Dynamic"
            detail: Theme.source === "wallpaper" ? "From wallpaper" : Theme.source === "custom" ? "Custom palette" : "Catppuccin"
            on: Theme.source === "wallpaper"
            onClicked: Theme.setSource(Theme.source === "wallpaper" ? "catppuccin" : "wallpaper")
        }

        Quick {
            icon: Notifs.dnd ? Icons.bellOff : Icons.bellOutline
            label: "Silent"
            detail: Notifs.dnd ? "Toasts muted" : "Toasts on"
            on: Notifs.dnd
            onClicked: Notifs.toggleDnd()
        }

        Quick {
            icon: Icons.awake
            label: "Awake"
            detail: Idle.keepAwake ? "Never sleeps" : "Idles normally"
            on: Idle.keepAwake
            onClicked: Idle.keepAwake = !Idle.keepAwake
        }
    }
}
