import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.popups

// The middle of the bar: display-weight time over a spaced-out date. Digits
// roll like an odometer when they change.
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

            Row {
                id: time

                readonly property string text: Qt.formatDateTime(clock.date, Settings.d.clock24h ? "HH:mm" : "h:mm")

                Repeater {
                    model: time.text.length

                    Roll {
                        required property int index

                        ch: time.text[index] ?? ""
                    }
                }
            }

            StyledText {
                anchors.bottom: time.bottom
                anchors.bottomMargin: 3
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

    // One character; a new one rises in from below and pushes the old one out.
    component Roll: Item {
        id: roll

        required property string ch
        property real t: 1

        implicitWidth: now.implicitWidth
        implicitHeight: now.implicitHeight
        clip: true
        onChChanged: {
            before.text = now.text;
            now.text = ch;
            spin.restart();
        }

        NumberAnimation {
            id: spin

            target: roll
            property: "t"
            from: 0
            to: 1
            duration: 520
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }

        StyledText {
            id: before

            y: -roll.height * roll.t
            opacity: 1 - roll.t
            font: now.font
        }

        StyledText {
            id: now

            y: roll.height * (1 - roll.t)
            text: roll.ch
            font.family: Theme.displayFont
            font.pixelSize: Settings.d.showDate ? 17 : 18
            font.weight: Font.ExtraBold
            font.features: {
                "tnum": 1
            }
        }
    }
}
