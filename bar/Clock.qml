import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.popups

// Lives in the bar's hanging tab: display-weight time over a spaced-out date.
BarButton {
    id: root

    hPadding: 12
    active: popup.visible
    onClicked: popup.toggle()

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: -2

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3

            StyledText {
                id: time

                text: Qt.formatDateTime(clock.date, Settings.d.clock24h ? "HH:mm" : "h:mm")
                font.family: Theme.displayFont
                font.pixelSize: Settings.d.showDate ? 17 : 18
                font.weight: Font.ExtraBold
                font.features: {
                    "tnum": 1
                }
            }

            StyledText {
                anchors.baseline: time.baseline
                visible: !Settings.d.clock24h
                text: Qt.formatDateTime(clock.date, "AP")
                font.pixelSize: 9
                font.weight: Font.Bold
                color: Theme.subtext0
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Settings.d.showDate
            text: Qt.formatDateTime(clock.date, "ddd d MMM").toUpperCase()
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 1.6
            color: Theme.accent
        }
    }

    Dashboard {
        id: popup

        name: "dashboard"
        target: root
        now: clock.date
    }
}
