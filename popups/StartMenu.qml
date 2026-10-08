import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Opens from the distro icon: who you are, your apps, and quick controls.
BarPopup {
    id: root

    readonly property string screenName: target.QsWindow.window?.screen?.name ?? ""
    readonly property string wallpaper: Wallpapers.pathFor(screenName)

    function launch(entry) {
        close();
        Apps.launch(entry);
    }

    onVisibleChanged: {
        if (visible)
            Power.refresh();
    }

    component SectionLabel: StyledText {
        font.pixelSize: Theme.smallFontSize
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        color: Theme.overlay2
    }

    component Quick: MouseArea {
        id: q

        property string icon
        property string label
        property bool on: false

        Layout.fillWidth: true
        implicitHeight: 44
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: q.on ? Theme.accent : q.containsMouse ? Theme.surface1 : Qt.alpha(Theme.surface0, 0.7)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.anim
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: q.icon
                color: q.on ? Theme.onAccent : Theme.text
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: q.label
                font.pixelSize: Theme.smallFontSize + 1
                font.weight: Font.DemiBold
                color: q.on ? Theme.onAccent : Theme.text
            }
        }
    }

    // ---------- header ----------
    RowLayout {
        Layout.preferredWidth: 400
        Layout.fillWidth: true
        spacing: 14

        Item {
            implicitWidth: 58
            implicitHeight: 58

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
            }

            Avatar {
                anchors.centerIn: parent
                size: 50
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            StyledText {
                Layout.fillWidth: true
                text: Power.user
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                text: `${Power.hostname} · up ${Power.formatUptime(Power.uptime)}`
                font.pixelSize: Theme.smallFontSize + 1
                color: Theme.subtext0
            }
        }

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
            id: powerBtn

            icon: Icons.power
            color: containsMouse ? Theme.red : Theme.subtext1
            onClicked: {
                root.close();
                Ui.popupRequested("power", root.screenName);
            }
        }
    }

    // ---------- pinned ----------
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4

        SectionLabel {
            Layout.fillWidth: true
            text: "PINNED"
        }

        MouseArea {
            id: allApps

            implicitWidth: allRow.implicitWidth
            implicitHeight: allRow.implicitHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.close();
                Ui.launcherOpen = true;
            }

            Row {
                id: allRow

                spacing: 2

                StyledText {
                    text: "All apps"
                    font.pixelSize: Theme.smallFontSize + 1
                    color: allApps.containsMouse ? Theme.accent : Theme.subtext0
                }

                Icon {
                    text: Icons.chevronRight
                    size: 14
                    color: allApps.containsMouse ? Theme.accent : Theme.subtext0
                }
            }
        }
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
                implicitHeight: 78
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
                    radius: Theme.radius
                    color: tile.pressed ? Theme.pressed : tile.containsMouse ? Theme.hover : "transparent"
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 7

                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        iconName: tile.modelData.icon
                        size: 34
                        scale: tile.containsMouse ? 1.08 : 1

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
                        color: tile.containsMouse ? Theme.text : Theme.subtext1
                    }
                }
            }
        }
    }

    // ---------- frequent ----------
    SectionLabel {
        visible: Apps.frequent.length > 0
        text: "FREQUENT"
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

                width: chipRow.implicitWidth + 20
                height: 32
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.launch(modelData)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: chip.containsMouse ? Theme.surface1 : Qt.alpha(Theme.surface0, 0.8)
                }

                Row {
                    id: chipRow

                    anchors.centerIn: parent
                    spacing: 7

                    AppIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: chip.modelData.icon
                        size: 18
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: chip.modelData.name
                        font.pixelSize: Theme.smallFontSize + 1
                    }
                }
            }
        }
    }

    // ---------- tools ----------
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
                implicitHeight: 56
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
                    radius: Theme.radius
                    color: tool.containsMouse ? Theme.surface1 : Qt.alpha(Theme.surface0, 0.7)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tool.modelData.icon
                        size: 18
                        color: tool.containsMouse ? Theme.accent : Theme.text
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tool.modelData.label
                        font.pixelSize: Theme.smallFontSize
                        color: Theme.subtext1
                    }
                }
            }
        }
    }

    // ---------- wallpaper card ----------
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: 76
        radius: Theme.radius
        color: Qt.alpha(Theme.surface0, 0.7)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            MouseArea {
                Layout.preferredWidth: 107
                Layout.fillHeight: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Ui.openSettings("wallpaper")

                ClippingRectangle {
                    anchors.fill: parent
                    radius: Theme.innerRadius
                    color: Theme.surface1

                    Image {
                        anchors.fill: parent
                        source: root.wallpaper ? "file://" + root.wallpaper : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(220, 124)
                        asynchronous: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: root.wallpaper.split("/").pop().replace(/\.[^.]+$/, "").replace(/[_-]+/g, " ")
                    font.weight: Font.DemiBold
                }

                StyledText {
                    Layout.fillWidth: true
                    text: `Wallpaper · ${root.screenName}`
                    font.pixelSize: Theme.smallFontSize
                    color: Theme.subtext0
                }
            }

            IconButton {
                icon: Icons.chevronLeft
                onClicked: Wallpapers.step(root.screenName, -1)
            }

            IconButton {
                icon: Icons.chevronRight
                onClicked: Wallpapers.step(root.screenName, 1)
            }

            IconButton {
                icon: Icons.shuffle
                onClicked: Wallpapers.shuffleAll()
            }
        }
    }

    // ---------- quick toggles ----------
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Quick {
            icon: Theme.lightMode ? Icons.sun : Icons.moon
            label: Theme.lightMode ? "Light" : "Dark"
            on: !Theme.lightMode
            onClicked: Theme.toggleMode()
        }

        Quick {
            icon: Icons.image
            label: "Dynamic"
            on: Theme.source === "wallpaper"
            onClicked: Theme.setSource(Theme.source === "wallpaper" ? "catppuccin" : "wallpaper")
        }

        Quick {
            icon: Notifs.dnd ? Icons.bellOff : Icons.bellOutline
            label: "Silent"
            on: Notifs.dnd
            onClicked: Notifs.toggleDnd()
        }

        Quick {
            icon: Icons.awake
            label: "Awake"
            on: Idle.keepAwake
            onClicked: Idle.keepAwake = !Idle.keepAwake
        }
    }
}
