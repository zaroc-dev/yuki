import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.services

Rectangle {
    id: root

    required property var notif
    // Toasts keep the body shorter.
    property bool toast: false
    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property var defaultAction: notif?.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: notif?.actions.filter(a => a.identifier !== "default") ?? []
    // Icon-theme images (image://icon/<name>) are checked so a missing icon
    // falls back to the app icon instead of Qt's placeholder.
    readonly property string image: {
        const img = notif?.image ?? "";
        return img.startsWith("image://icon/") ? Apps.resolveIcon(img.slice(13)) : img;
    }
    readonly property string appIcon: {
        const icon = (notif?.appIcon ?? "").replace(/^image:\/\/icon\//, "");
        return Apps.iconFor(icon) || Apps.iconFor(notif?.desktopEntry ?? "") || Apps.iconFor(notif?.appName ?? "");
    }
    readonly property alias hovered: hover.containsMouse

    implicitHeight: layout.implicitHeight + 28
    radius: Theme.radius + 4
    color: critical ? Qt.alpha(Theme.red, 0.14) : hover.containsMouse ? Theme.cardHover : Theme.card
    border.width: critical ? 1 : 0
    border.color: Qt.alpha(Theme.red, 0.6)

    Behavior on color {
        ColorAnimation {
            duration: Theme.anim
        }
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.defaultAction) {
                root.defaultAction.invoke();
                root.notif.dismiss();
            }
        }
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Big image if provided (album art, avatars), otherwise the app icon,
        // with the app's icon as a little badge on the image.
        Item {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 44
            implicitHeight: 44

            ClippingRectangle {
                anchors.fill: parent
                radius: 14
                color: root.image ? "transparent" : Theme.well

                Image {
                    anchors.fill: parent
                    visible: root.image !== ""
                    source: root.image
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(88, 88)
                    asynchronous: true
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: !root.image && root.appIcon !== ""
                    implicitSize: 26
                    source: root.appIcon
                    asynchronous: true
                }

                Icon {
                    anchors.centerIn: parent
                    visible: !root.image && root.appIcon === ""
                    text: Icons.bell
                    size: 20
                    color: Theme.accent
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -4
                visible: root.image !== "" && root.appIcon !== ""
                width: 20
                height: 20
                radius: 10
                color: Theme.base

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 14
                    source: root.appIcon
                    asynchronous: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    text: (root.notif?.appName || "Notification").toUpperCase()
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    color: root.critical ? Theme.red : Theme.accent
                }

                StyledText {
                    text: Notifs.timeOf(root.notif)
                    font.pixelSize: Theme.smallFontSize
                    color: Theme.overlay1
                }

                IconButton {
                    size: 22
                    iconSize: 13
                    icon: Icons.close
                    color: Theme.subtext0
                    opacity: hover.containsMouse || containsMouse ? 1 : 0.5
                    onClicked: root.notif.dismiss()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notif?.summary ?? ""
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Bold
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notif?.body ?? ""
                textFormat: Text.StyledText
                color: Theme.subtext1
                wrapMode: Text.Wrap
                maximumLineCount: root.toast ? 4 : 8
                lineHeight: 1.1
                linkColor: Theme.accent
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 8
                visible: root.buttons.length > 0
                spacing: 6

                Repeater {
                    model: root.buttons

                    MouseArea {
                        id: action

                        required property var modelData
                        required property int index

                        width: label.implicitWidth + 26
                        height: 30
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.invoke()

                        // The first action is the primary one.
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: action.containsMouse ? Theme.cardHover : Theme.well
                            gradient: action.index === 0 ? aurora : null

                            Gradient {
                                id: aurora

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

                        StyledText {
                            id: label

                            anchors.centerIn: parent
                            text: action.modelData.text
                            font.pixelSize: Theme.smallFontSize + 1
                            font.weight: Font.DemiBold
                            color: action.index === 0 ? Theme.onAccent : Theme.text
                        }
                    }
                }
            }
        }
    }
}
