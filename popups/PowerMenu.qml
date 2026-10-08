import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services
import Quickshell.Services.UPower

BarPopup {
    id: root

    // Destructive actions arm on first press and run on the second.
    property string armed: ""

    function trigger(action) {
        if (action.confirm && armed !== action.id) {
            armed = action.id;
            return;
        }
        armed = "";
        close();
        Power.run(action.id);
    }

    onVisibleChanged: {
        armed = "";
    }

    onKeyPressed: event => {
        const action = Power.actions.find(a => a.key === event.text.toUpperCase());
        if (action) {
            trigger(action);
            event.accepted = true;
        }
    }

    Timer {
        running: root.armed !== ""
        interval: 4000
        onTriggered: root.armed = ""
    }

    RowLayout {
        spacing: 8

        Repeater {
            model: Power.actions

            MouseArea {
                id: tile

                required property var modelData
                readonly property color tint: Theme[modelData.color]
                readonly property bool isArmed: root.armed === modelData.id

                implicitWidth: 74
                implicitHeight: 82
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.trigger(modelData)

                Rectangle {
                    id: bg

                    anchors.fill: parent
                    radius: Theme.radius
                    color: tile.isArmed ? tile.tint : tile.containsMouse ? Qt.alpha(tile.tint, 0.16) : Qt.alpha(Theme.surface0, 0.7)
                    border.width: 1
                    border.color: tile.containsMouse && !tile.isArmed ? Qt.alpha(tile.tint, 0.5) : "transparent"
                    scale: tile.pressed ? 0.95 : 1

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

                    // Countdown until an armed action disarms.
                    Rectangle {
                        id: drain

                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 8
                        height: 3
                        radius: 2
                        color: Theme.onAccent
                        opacity: 0.5
                        visible: tile.isArmed
                        width: 0

                        NumberAnimation on width {
                            running: tile.isArmed
                            from: bg.width - 16
                            to: 0
                            duration: 4000
                        }
                    }
                }

                // Shortcut hint.
                StyledText {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    text: tile.modelData.key
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: tile.isArmed ? Theme.onAccent : Theme.overlay0
                }

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    spacing: 8

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.icon
                        size: 24
                        color: tile.isArmed ? Theme.onAccent : tile.containsMouse ? tile.tint : Theme.text
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.isArmed ? "Confirm" : tile.modelData.label
                        font.pixelSize: Theme.smallFontSize
                        font.weight: tile.isArmed ? Font.DemiBold : Font.Normal
                        color: tile.isArmed ? Theme.onAccent : Theme.subtext1
                    }
                }
            }
        }
    }

    // Power profile (power-profiles-daemon), handy on desktops too.
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        visible: PowerProfiles.profile !== undefined

        StyledText {
            Layout.fillWidth: true
            text: "Profile"
            color: Theme.subtext0
        }

        ProfilePicker {}
    }
}
