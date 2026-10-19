import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.config
import qs.components
import qs.services

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
        if (visible)
            Power.refresh();
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

    PanelHeader {
        icon: Icons.power
        title: "Power"
        subtitle: `${Power.hostname || "This machine"} · up ${Power.formatUptime(Power.uptime)}`
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

                implicitWidth: 86
                implicitHeight: 100
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.trigger(modelData)

                Rectangle {
                    id: bg

                    anchors.fill: parent
                    radius: 20
                    color: tile.isArmed ? tile.tint : Theme.card
                    border.width: tile.containsMouse && !tile.isArmed ? 1.5 : 0
                    border.color: Qt.alpha(tile.tint, 0.6)
                    scale: tile.pressed ? 0.94 : 1

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

                    // Hover glow rising from the bottom in the action's color.
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: tile.containsMouse && !tile.isArmed ? 1 : 0
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "transparent"
                            }
                            GradientStop {
                                position: 1
                                color: Qt.alpha(tile.tint, 0.28)
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.anim
                            }
                        }
                    }

                    // Countdown until an armed action disarms.
                    Rectangle {
                        id: drain

                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 10
                        height: 3
                        radius: 2
                        color: Theme.onAccent
                        opacity: 0.6
                        visible: tile.isArmed
                        width: 0

                        NumberAnimation on width {
                            running: tile.isArmed
                            from: bg.width - 20
                            to: 0
                            duration: 4000
                        }
                    }
                }

                // Shortcut hint.
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    width: 16
                    height: 16
                    radius: 5
                    color: tile.isArmed ? Qt.alpha(Theme.onAccent, 0.2) : Theme.well

                    StyledText {
                        anchors.centerIn: parent
                        text: tile.modelData.key
                        font.family: Theme.displayFont
                        font.pixelSize: 9
                        font.weight: Font.Black
                        color: tile.isArmed ? Theme.onAccent : Theme.overlay1
                    }
                }

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 2
                    spacing: 10

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.icon
                        size: 28
                        color: tile.isArmed ? Theme.onAccent : tile.containsMouse ? tile.tint : Theme.text
                        scale: tile.containsMouse ? 1.1 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.anim
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.isArmed ? "Confirm" : tile.modelData.label
                        font.pixelSize: Theme.smallFontSize + 1
                        font.weight: Font.DemiBold
                        color: tile.isArmed ? Theme.onAccent : Theme.subtext1
                    }
                }
            }
        }
    }

    // PowerProfiles can block on daemon startup; only touch it when opened.
    Loader {
        Layout.fillWidth: true
        Layout.topMargin: 2
        active: root.visible
        asynchronous: true
        visible: item?.available ?? false

        sourceComponent: ColumnLayout {
            readonly property bool available: PowerProfiles.profile !== undefined

            spacing: 10

            SectionLabel {
                text: "Profile"
            }

            ProfilePicker {
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
