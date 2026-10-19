import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// The clock's panel: a giant clock, weather with an hourly temperature curve
// and the next days, calendar, now playing and system gauges.
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

    minWidth: 800
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
        id: card

        default property alias content: inner.data
        property alias spacing: inner.spacing
        // Aurora light falling in from the top.
        property bool glow: false

        implicitWidth: inner.implicitWidth + 32
        implicitHeight: inner.implicitHeight + 32
        radius: 22
        color: Theme.card

        Rectangle {
            anchors.fill: parent
            visible: card.glow
            radius: parent.radius
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.alpha(Theme.accent2, Theme.dark ? 0.16 : 0.22)
                }
                GradientStop {
                    position: 0.6
                    color: "transparent"
                }
            }
        }

        ColumnLayout {
            id: inner

            anchors.fill: parent
            anchors.margins: 16
            spacing: 8
        }
    }

    component Chip: Rectangle {
        property alias icon: chipIcon.text
        property alias text: chipText.text

        implicitWidth: chipRow.implicitWidth + 18
        implicitHeight: 26
        radius: height / 2
        color: Theme.well

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: 5

            Icon {
                id: chipIcon

                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                size: 13
                color: Theme.accent
            }

            StyledText {
                id: chipText

                anchors.verticalCenter: parent.verticalCenter
                color: Theme.subtext1
                font.pixelSize: Theme.smallFontSize
                font.weight: Font.Medium
            }
        }
    }

    // A cell that shares its row's width equally (a ColumnLayout wouldn't
    // grow past its children's width).
    component Stat: Item {
        property alias value: gauge.value
        property alias icon: statIcon.text
        property alias color: gauge.color
        property alias label: gauge.text
        property alias detail: statDetail.text

        Layout.fillWidth: true
        implicitHeight: statColumn.implicitHeight

        Column {
            id: statColumn

            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Gauge {
                id: gauge

                anchors.horizontalCenter: parent.horizontalCenter
                size: 64
                thickness: 6
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Icon {
                    id: statIcon

                    anchors.verticalCenter: parent.verticalCenter
                    size: 12
                    color: gauge.color
                }

                StyledText {
                    id: statDetail

                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.subtext0
                    font.pixelSize: Theme.smallFontSize
                    font.weight: Font.Medium
                }
            }
        }
    }

    // Next hours as a smooth temperature curve over a fading fill, with the
    // temperature above each point and the hour and sky below.
    component TempCurve: Item {
        id: curve

        property var points: []
        readonly property int n: points.length
        readonly property real lo: n ? Math.min(...points.map(p => p.temp)) : 0
        readonly property real hi: n ? Math.max(...points.map(p => p.temp)) : 1
        readonly property real plotTop: 20
        readonly property real plotHeight: 34

        function px(i) {
            return (i + 0.5) * width / Math.max(1, n);
        }
        function py(t) {
            return plotTop + (hi - lo < 0.5 ? 0.5 : 1 - (t - lo) / (hi - lo)) * plotHeight;
        }
        // Catmull-Rom through the points, as cubic Béziers.
        function path(closed) {
            if (n < 2)
                return "";
            const P = points.map((p, i) => [px(i), py(p.temp)]);
            let d = `M ${P[0][0]} ${P[0][1]}`;
            for (let i = 0; i < n - 1; i++) {
                const p0 = P[Math.max(0, i - 1)], p1 = P[i], p2 = P[i + 1], p3 = P[Math.min(n - 1, i + 2)];
                d += ` C ${p1[0] + (p2[0] - p0[0]) / 6} ${p1[1] + (p2[1] - p0[1]) / 6} ${p2[0] - (p3[0] - p1[0]) / 6} ${p2[1] - (p3[1] - p1[1]) / 6} ${p2[0]} ${p2[1]}`;
            }
            if (closed)
                d += ` L ${P[n - 1][0]} ${plotTop + plotHeight + 14} L ${P[0][0]} ${plotTop + plotHeight + 14} Z`;
            return d;
        }

        implicitHeight: plotTop + plotHeight + 56

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillGradient: LinearGradient {
                    y1: curve.plotTop
                    y2: curve.plotTop + curve.plotHeight + 14

                    GradientStop {
                        position: 0
                        color: Qt.alpha(Theme.accent, 0.3)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.alpha(Theme.accent, 0)
                    }
                }

                PathSvg {
                    path: curve.path(true)
                }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.accent
                strokeWidth: 2.5
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg {
                    path: curve.path(false)
                }
            }
        }

        Repeater {
            model: curve.points

            Item {
                id: pt

                required property var modelData
                required property int index

                x: curve.px(index) - 20
                width: 40
                height: curve.height

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: curve.py(pt.modelData.temp) - 20
                    text: `${Math.round(pt.modelData.temp)}°`
                    font.family: Theme.displayFont
                    font.pixelSize: Theme.smallFontSize + 1
                    font.weight: pt.index === 0 ? Font.ExtraBold : Font.DemiBold
                    color: pt.index === 0 ? Theme.text : Theme.subtext1
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: curve.py(pt.modelData.temp) - height / 2
                    width: pt.index === 0 ? 9 : 6
                    height: width
                    radius: width / 2
                    color: pt.index === 0 ? Theme.accent : Theme.base
                    border.width: 2
                    border.color: Theme.accent
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    spacing: 2

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Weather.glyph(pt.modelData.code, pt.modelData.day)
                        size: 16
                        color: pt.index === 0 ? Theme.accent : Theme.subtext1
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.hourLabel(pt.modelData.time, pt.index)
                        color: pt.index === 0 ? Theme.text : Theme.overlay1
                        font.pixelSize: 10
                        font.weight: pt.index === 0 ? Font.Bold : Font.Medium
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Greeting, giant clock, date and a few facts.
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            glow: true

            RowLayout {
                id: hero

                spacing: 10

                Avatar {
                    size: 34
                }

                StyledText {
                    Layout.fillWidth: true
                    text: `${root.greeting(root.now.getHours())}, ${Power.user}`
                    color: Theme.subtext1
                    font.weight: Font.Medium
                }
            }

            Item {
                Layout.fillHeight: true
                implicitHeight: 6
            }

            Row {
                spacing: 6

                StyledText {
                    id: bigTime

                    text: Qt.formatTime(root.now, Settings.d.clock24h ? "HH:mm" : "h:mm")
                    font.family: Theme.displayFont
                    font.pixelSize: 84
                    font.weight: Font.Black
                    font.letterSpacing: -3
                    font.features: {
                        "tnum": 1
                    }
                }

                StyledText {
                    anchors.baseline: bigTime.baseline
                    visible: !Settings.d.clock24h
                    text: Qt.formatTime(root.now, "AP")
                    color: Theme.subtext0
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
            }

            StyledText {
                Layout.topMargin: -8
                text: Qt.formatDate(root.now, "dddd · d MMMM").toUpperCase()
                color: Theme.accent
                font.pixelSize: 12
                font.weight: Font.Bold
                font.letterSpacing: 2.2
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 14
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
            Layout.preferredWidth: 380
            Layout.fillHeight: true
            visible: Settings.d.weather

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Icon {
                    text: Weather.icon
                    size: 44
                    color: Theme.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -2

                    StyledText {
                        text: Weather.temp
                        font.family: Theme.displayFont
                        font.pixelSize: 40
                        font.weight: Font.Black
                        font.letterSpacing: -1
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Weather.available ? Weather.condition : Weather.loading ? "Loading weather…" : Weather.error || "No weather yet"
                        color: Theme.subtext0
                        font.weight: Font.Medium
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 3

                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 4

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.location
                            size: 13
                            color: Theme.accent
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, 130)
                            text: Weather.place || "—"
                            color: Theme.text
                            font.pixelSize: Theme.smallFontSize + 1
                            font.weight: Font.DemiBold
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

            TempCurve {
                Layout.fillWidth: true
                visible: Weather.hours.length > 1
                points: Weather.hours.slice(0, 7)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Card {
            Layout.preferredWidth: 300
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
                        model: Weather.days.slice(0, 6)

                        Item {
                            id: day

                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: dayColumn.implicitHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -6
                                visible: day.index === 0
                                radius: 14
                                color: Qt.alpha(Theme.accent, 0.12)
                            }

                            Column {
                                id: dayColumn

                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: (day.index === 0 ? "Today" : Qt.formatDate(day.modelData.date, "ddd")).toUpperCase()
                                    color: day.index === 0 ? Theme.accent : Theme.overlay2
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.2
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
                                        font.family: Theme.displayFont
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Font.ExtraBold
                                    }

                                    StyledText {
                                        text: `${Math.round(day.modelData.min)}°`
                                        color: Theme.overlay1
                                        font.family: Theme.displayFont
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Font.Medium
                                    }
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    // Only worth showing when rain is likely.
                                    opacity: day.modelData.rain >= 30 ? 1 : 0
                                    text: `${day.modelData.rain}%`
                                    color: Theme.blue
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
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
                    spacing: 14

                    ClippingRectangle {
                        implicitWidth: 56
                        implicitHeight: 56
                        radius: 14
                        color: Theme.surface1

                        Image {
                            id: art

                            anchors.fill: parent
                            source: mediaCard.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(112, 112)
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
                            font.weight: Font.Bold
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: mediaCard.player?.trackArtist ?? ""
                            color: Theme.accent
                            font.pixelSize: Theme.smallFontSize + 1
                            font.weight: Font.Medium
                        }

                        // Progress.
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            implicitHeight: 4
                            radius: 2
                            visible: Media.hasLength(mediaCard.player)
                            color: Theme.well

                            Rectangle {
                                width: parent.width * Math.min(1, (mediaCard.player?.position ?? 0) / Math.max(1, mediaCard.player?.length ?? 1))
                                height: parent.height
                                radius: parent.radius
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
                        size: 42
                        iconSize: 20
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
