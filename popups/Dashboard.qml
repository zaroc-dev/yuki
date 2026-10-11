import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// The clock's dropdown: greeting + time, weather with hourly and daily
// forecast, calendar, now playing and system gauges, as a grid of cards.
BarPopup {
    id: root

    property date now: new Date()
    // Counted once in SysStats.users while shown (polling runs only then).
    property bool polling: false

    function setPolling(on) {
        if (on === polling)
            return;
        polling = on;
        SysStats.users += on ? 1 : -1;
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

    function hourLabel(d, i) {
        return i === 0 ? "Now" : Qt.formatTime(d, Settings.d.clock24h ? "HH" : "h AP");
    }

    minWidth: 760
    spacing: 10
    onVisibleChanged: {
        setPolling(visible);
        if (visible) {
            calendar.reset();
            Power.refresh();
            Weather.refresh();
        }
    }
    Component.onDestruction: setPolling(false)

    component Card: Rectangle {
        default property alias content: inner.data
        property alias spacing: inner.spacing

        implicitWidth: inner.implicitWidth + 28
        implicitHeight: inner.implicitHeight + 28
        radius: Theme.radius
        color: Qt.alpha(Theme.surface0, 0.6)

        ColumnLayout {
            id: inner

            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
        }
    }

    component Chip: Rectangle {
        property alias icon: chipIcon.text
        property alias text: chipText.text

        implicitWidth: chipRow.implicitWidth + 16
        implicitHeight: 24
        radius: height / 2
        color: Qt.alpha(Theme.surface1, 0.6)

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: 5

            Icon {
                id: chipIcon

                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                size: 13
                color: Theme.subtext0
            }

            StyledText {
                id: chipText

                anchors.verticalCenter: parent.verticalCenter
                color: Theme.subtext1
                font.pixelSize: Theme.smallFontSize
            }
        }
    }

    // A cell that shares its row's width equally (a ColumnLayout wouldn't
    // grow past its children's width).
    component Stat: Item {
        property alias value: gauge.value
        property alias icon: gauge.icon
        property alias color: gauge.color
        property alias label: statLabel.text
        property alias detail: statDetail.text

        Layout.fillWidth: true
        implicitHeight: statColumn.implicitHeight

        Column {
            id: statColumn

            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Gauge {
                id: gauge

                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                id: statLabel

                anchors.horizontalCenter: parent.horizontalCenter
                font.weight: Font.DemiBold
            }

            StyledText {
                id: statDetail

                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.subtext0
                font.pixelSize: Theme.smallFontSize
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Greeting, big clock, date and a few facts.
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                spacing: 12

                Avatar {
                    size: 44
                }

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        text: root.greeting(root.now.getHours())
                        color: Theme.subtext0
                    }

                    StyledText {
                        text: Power.user
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Row {
                spacing: 8

                StyledText {
                    id: bigTime

                    text: Qt.formatTime(root.now, Settings.d.clock24h ? "HH:mm" : "h:mm")
                    font.pixelSize: 56
                    font.weight: Font.Light
                }

                StyledText {
                    anchors.baseline: bigTime.baseline
                    visible: !Settings.d.clock24h
                    text: Qt.formatTime(root.now, "AP")
                    color: Theme.subtext0
                    font.pixelSize: 17
                }
            }

            StyledText {
                Layout.topMargin: -6
                text: Qt.formatDate(root.now, "dddd, d MMMM")
                color: Theme.accent
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 6

                Chip {
                    icon: Icons.restart
                    text: `up ${Power.formatUptime(Power.uptime)}`
                }

                Chip {
                    icon: Icons.monitor
                    text: Power.hostname
                    visible: Power.hostname !== ""
                }

                Chip {
                    icon: Icons.sunrise
                    text: Weather.sunrise
                    visible: Weather.available && Weather.sunrise !== ""
                }

                Chip {
                    icon: Icons.sunset
                    text: Weather.sunset
                    visible: Weather.available && Weather.sunset !== ""
                }
            }
        }

        // Current weather and the next hours.
        Card {
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            visible: Settings.d.weather

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Icon {
                    text: Weather.icon
                    size: 46
                    color: Theme.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: Weather.temp
                        font.pixelSize: 34
                        font.weight: Font.DemiBold
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Weather.available ? Weather.condition : Weather.loading ? "Loading weather…" : Weather.error || "No weather yet"
                        color: Theme.subtext0
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 2

                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 4

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.location
                            size: 13
                            color: Theme.overlay1
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, 120)
                            text: Weather.place || "—"
                            color: Theme.subtext1
                            font.pixelSize: Theme.smallFontSize
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        visible: Weather.available
                        text: `Feels ${Weather.feelsLike}`
                        color: Theme.subtext0
                        font.pixelSize: Theme.smallFontSize
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        visible: Weather.available
                        text: `${Weather.humidity}% · ${Weather.wind}`
                        color: Theme.subtext0
                        font.pixelSize: Theme.smallFontSize
                    }

                    IconButton {
                        Layout.alignment: Qt.AlignRight
                        visible: !Weather.available && !Weather.loading
                        size: 26
                        iconSize: 14
                        icon: Icons.refresh
                        onClicked: Weather.refresh(true)
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                visible: Weather.hours.length > 0
                spacing: 0

                Repeater {
                    model: Weather.hours.slice(0, 6)

                    Item {
                        id: hour

                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: hourColumn.implicitHeight

                        Column {
                            id: hourColumn

                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.hourLabel(hour.modelData.time, hour.index)
                                color: hour.index === 0 ? Theme.text : Theme.subtext0
                                font.pixelSize: Theme.smallFontSize
                                font.weight: hour.index === 0 ? Font.DemiBold : Font.Normal
                            }

                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Weather.glyph(hour.modelData.code, hour.modelData.day)
                                size: 18
                                color: hour.index === 0 ? Theme.accent : Theme.subtext1
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: `${Math.round(hour.modelData.temp)}°`
                                font.pixelSize: Theme.smallFontSize
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Card {
            Layout.preferredWidth: 280
            Layout.fillHeight: true

            CalendarGrid {
                id: calendar

                Layout.fillWidth: true
                today: root.now
            }

            Item {
                Layout.fillHeight: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // The next days.
            Card {
                Layout.fillWidth: true
                visible: Settings.d.weather && Weather.days.length > 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: Weather.days.slice(0, 5)

                        Item {
                            id: day

                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: dayColumn.implicitHeight

                            Column {
                                id: dayColumn

                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 3

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: day.index === 0 ? "Today" : Qt.formatDate(day.modelData.date, "ddd")
                                    color: day.index === 0 ? Theme.text : Theme.subtext0
                                    font.pixelSize: Theme.smallFontSize
                                    font.weight: day.index === 0 ? Font.DemiBold : Font.Normal
                                }

                                Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Weather.glyph(day.modelData.code)
                                    size: 22
                                    color: day.index === 0 ? Theme.accent : Theme.subtext1
                                }

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 4

                                    StyledText {
                                        text: `${Math.round(day.modelData.max)}°`
                                        font.pixelSize: Theme.smallFontSize
                                        font.weight: Font.DemiBold
                                    }

                                    StyledText {
                                        text: `${Math.round(day.modelData.min)}°`
                                        color: Theme.overlay1
                                        font.pixelSize: Theme.smallFontSize
                                    }
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    // Only worth showing when rain is likely.
                                    opacity: day.modelData.rain >= 30 ? 1 : 0
                                    text: `${day.modelData.rain}%`
                                    color: Theme.blue
                                    font.pixelSize: Theme.smallFontSize
                                }
                            }
                        }
                    }
                }
            }

            // Now playing.
            Card {
                id: mediaCard

                readonly property var player: Media.active

                Layout.fillWidth: true
                visible: player !== null

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ClippingRectangle {
                        implicitWidth: 52
                        implicitHeight: 52
                        radius: Theme.innerRadius
                        color: Theme.surface1

                        Image {
                            id: art

                            anchors.fill: parent
                            source: mediaCard.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(104, 104)
                            asynchronous: true
                        }

                        Icon {
                            anchors.centerIn: parent
                            visible: art.status !== Image.Ready
                            text: Icons.music
                            color: Theme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: mediaCard.player?.trackTitle || Media.nameOf(mediaCard.player)
                            font.weight: Font.DemiBold
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: mediaCard.player?.trackArtist ?? ""
                            color: Theme.subtext0
                        }

                        // Progress.
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            implicitHeight: 3
                            radius: 1.5
                            visible: Media.hasLength(mediaCard.player)
                            color: Qt.alpha(Theme.text, 0.1)

                            Rectangle {
                                width: parent.width * Math.min(1, (mediaCard.player?.position ?? 0) / Math.max(1, mediaCard.player?.length ?? 1))
                                height: parent.height
                                radius: parent.radius
                                color: Theme.accent
                            }

                            // MPRIS doesn't push position updates.
                            Timer {
                                running: root.visible && (mediaCard.player?.isPlaying ?? false)
                                interval: 1000
                                repeat: true
                                onTriggered: mediaCard.player.positionChanged()
                            }
                        }
                    }

                    IconButton {
                        icon: Icons.previous
                        color: Theme.subtext0
                        enabled: mediaCard.player?.canGoPrevious ?? false
                        onClicked: mediaCard.player.previous()
                    }

                    IconButton {
                        size: 38
                        filled: true
                        icon: mediaCard.player?.isPlaying ? Icons.pause : Icons.play
                        onClicked: mediaCard.player?.togglePlaying()
                    }

                    IconButton {
                        icon: Icons.next
                        color: Theme.subtext0
                        enabled: mediaCard.player?.canGoNext ?? false
                        onClicked: mediaCard.player.next()
                    }
                }
            }

            // System.
            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Item {
                    Layout.fillHeight: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Stat {
                        value: SysStats.cpu
                        icon: Icons.cpu
                        label: `${Math.round(SysStats.cpu * 100)}%`
                        detail: "CPU"
                    }

                    Stat {
                        value: SysStats.memory
                        icon: Icons.memory
                        color: Theme.secondary
                        label: SysStats.formatBytes(SysStats.memUsed)
                        detail: "Memory"
                    }

                    Stat {
                        value: SysStats.disk
                        icon: Icons.disk
                        color: Theme.tertiary
                        label: `${Math.round(SysStats.disk * 100)}%`
                        detail: `of ${SysStats.formatBytes(SysStats.diskTotal)}`
                    }

                    Stat {
                        visible: SysStats.temperature >= 0
                        // 30 °C empty, 100 °C full.
                        value: (SysStats.temperature - 30) / 70
                        icon: Icons.thermometer
                        color: SysStats.temperature >= 85 ? Theme.red : SysStats.temperature >= 70 ? Theme.peach : Theme.green
                        label: `${Math.round(SysStats.temperature)}°`
                        detail: "CPU temp"
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
