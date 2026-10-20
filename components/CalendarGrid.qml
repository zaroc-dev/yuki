import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

// Month view with navigation; today is filled with the accent. Clicking the
// month title jumps back to the current month.
ColumnLayout {
    id: root

    property date today: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()
    readonly property bool onCurrentMonth: month === today.getMonth() && year === today.getFullYear()

    function shift(delta) {
        const d = new Date(year, month + delta, 1);
        month = d.getMonth();
        year = d.getFullYear();
    }

    function reset() {
        today = new Date();
        month = today.getMonth();
        year = today.getFullYear();
    }

    spacing: 6

    RowLayout {
        Layout.fillWidth: true

        MouseArea {
            Layout.fillWidth: true
            implicitHeight: monthTitle.implicitHeight
            cursorShape: root.onCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: root.reset()

            StyledText {
                id: monthTitle

                width: parent.width
                text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
                font.family: Theme.displayFont
                font.pixelSize: 17
                font.weight: Font.ExtraBold
            }
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

            text: shortName.slice(0, 2).toUpperCase()
            horizontalAlignment: Text.AlignHCenter
            color: Theme.overlay1
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 1
        }
    }

    MonthGrid {
        id: grid

        Layout.fillWidth: true
        month: root.month
        year: root.year
        locale: Qt.locale()

        delegate: Item {
            id: day

            required property var model
            readonly property bool weekend: model.date.getDay() === 0 || model.date.getDay() === 6

            implicitWidth: 32
            implicitHeight: 30

            Rectangle {
                anchors.centerIn: parent
                width: 30
                height: 30
                radius: 11
                visible: day.model.today
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
            }

            StyledText {
                anchors.centerIn: parent
                text: day.model.day
                color: day.model.today ? Theme.onAccent : day.model.month !== grid.month ? Theme.surface2 : day.weekend ? Theme.subtext0 : Theme.text
                font.weight: day.model.today ? Font.Black : Font.Normal
            }
        }
    }
}
