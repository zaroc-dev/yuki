import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components

// Themed replacement for a tray item's native (DBusMenu) context menu.
// Submenus open in place, with a back row on top.
BarPopup {
    id: root

    property var handle: null
    // Submenu entries we descended into; the last one is shown.
    property var stack: []
    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : handle

    function openFor(item, menuHandle) {
        if (visible && handle === menuHandle) {
            close();
            return;
        }
        target = item;
        handle = menuHandle;
        stack = [];
        toggle();
    }

    padding: 6
    spacing: 1
    minWidth: 220
    onVisibleChanged: {
        if (!visible)
            stack = [];
    }

    QsMenuOpener {
        id: opener

        menu: root.current
    }

    // Back row for submenus.
    MouseArea {
        id: back

        Layout.fillWidth: true
        implicitHeight: 32
        visible: root.stack.length > 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.stack = root.stack.slice(0, -1)

        Rectangle {
            anchors.fill: parent
            radius: Theme.innerRadius
            color: back.containsMouse ? Theme.hover : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 10
            spacing: 8

            Icon {
                text: Icons.chevronLeft
                color: Theme.subtext0
            }

            StyledText {
                Layout.fillWidth: true
                text: root.current?.text ?? ""
                font.weight: Font.DemiBold
                color: Theme.subtext1
            }
        }
    }

    Repeater {
        model: opener.children

        Loader {
            id: entryLoader

            required property var modelData

            Layout.fillWidth: true
            sourceComponent: modelData.isSeparator ? separator : entry

            Component {
                id: separator

                Item {
                    implicitHeight: 9

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Theme.surface1
                    }
                }
            }

            Component {
                id: entry

                MouseArea {
                    id: row

                    readonly property var e: entryLoader.modelData
                    readonly property bool checkable: e.buttonType !== QsMenuButtonType.None

                    implicitHeight: 32
                    implicitWidth: content.implicitWidth + 20
                    enabled: e.enabled
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (e.hasChildren) {
                            root.stack = [...root.stack, e];
                        } else {
                            e.triggered();
                            root.close();
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.innerRadius
                        color: row.containsMouse ? Qt.alpha(Theme.accent, 0.16) : "transparent"
                    }

                    RowLayout {
                        id: content

                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        opacity: row.enabled ? 1 : 0.4

                        // Check box / radio indicator.
                        Rectangle {
                            visible: row.checkable
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: row.e.buttonType === QsMenuButtonType.RadioButton ? 8 : 4
                            color: row.e.checkState === Qt.Checked ? Theme.accent : "transparent"
                            border.width: row.e.checkState === Qt.Checked ? 0 : 1.5
                            border.color: Theme.overlay1

                            Icon {
                                anchors.centerIn: parent
                                visible: row.e.checkState === Qt.Checked
                                text: row.e.buttonType === QsMenuButtonType.RadioButton ? "" : Icons.check
                                size: 12
                                color: Theme.onAccent
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                visible: row.e.checkState === Qt.Checked && row.e.buttonType === QsMenuButtonType.RadioButton
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.onAccent
                            }
                        }

                        IconImage {
                            visible: row.e.icon !== ""
                            implicitSize: 16
                            source: row.e.icon
                            asynchronous: true
                        }

                        StyledText {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 320
                            text: row.e.text.replace(/_(?!_)/g, "")
                            color: row.containsMouse ? Theme.accent : Theme.text
                        }

                        Icon {
                            visible: row.e.hasChildren
                            text: Icons.chevronRight
                            color: Theme.overlay1
                        }
                    }
                }
            }
        }
    }
}
