import QtQuick
import Quickshell
import qs.config
import qs.components
import qs.popups

BarButton {
    id: root

    active: popup.visible
    onClicked: popup.toggle()

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, Settings.d.clock24h ? "HH:mm" : "h:mm AP")
        font.weight: Font.DemiBold
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        visible: Settings.d.showDate
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
        color: Theme.subtext0
    }

    CalendarPopup {
        id: popup

        name: "calendar"
        target: root
        today: clock.date
    }
}
