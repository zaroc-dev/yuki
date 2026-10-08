import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.components

BarPopup {
    id: root

    property date today: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()

    function shift(delta) {
        const d = new Date(year, month + delta, 1);
        month = d.getMonth();
        year = d.getFullYear();
    }

    onVisibleChanged: {
        if (visible) {
            month = today.getMonth();
            year = today.getFullYear();
        }
    }

    StyledText {
        Layout.fillWidth: true
        text: Qt.formatDateTime(root.today, "dddd, d MMMM yyyy")
        color: Theme.subtext0
        font.pixelSize: Theme.smallFontSize + 1
    }

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            Layout.fillWidth: true
            text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        IconButton {
            size: 28
            icon: Icons.chevronLeft
            onClicked: root.shift(-1)
        }

        IconButton {
            size: 28
            icon: Icons.chevronRight
            onClicked: root.shift(1)
        }
    }

    DayOfWeekRow {
        Layout.fillWidth: true
        locale: grid.locale

        delegate: StyledText {
            required property string shortName

            text: shortName.slice(0, 2)
            horizontalAlignment: Text.AlignHCenter
            color: Theme.overlay1
            font.pixelSize: Theme.smallFontSize
        }
    }

    MonthGrid {
        id: grid

        Layout.preferredWidth: 280
        month: root.month
        year: root.year
        locale: Qt.locale()

        delegate: Item {
            id: day

            required property var model

            implicitWidth: 36
            implicitHeight: 32

            Rectangle {
                anchors.centerIn: parent
                width: 30
                height: 30
                radius: 15
                color: day.model.today ? Theme.accent : "transparent"
            }

            StyledText {
                anchors.centerIn: parent
                text: day.model.day
                color: day.model.today ? Theme.onAccent : day.model.month === grid.month ? Theme.text : Theme.surface2
                font.weight: day.model.today ? Font.Bold : Font.Normal
            }
        }
    }
}
