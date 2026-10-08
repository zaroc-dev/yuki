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
    // Toasts get their own background and a tighter body.
    property bool toast: false
    // When set, the card registers a rounded blur rect of itself in this region.
    property Region blurRegion: null
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

    implicitHeight: layout.implicitHeight + 24
    radius: Theme.radius
    color: toast ? Theme.popupBg : Qt.alpha(Theme.surface0, 0.6)
    border.width: 1
    border.color: critical ? Theme.red : toast ? Theme.barBorder : "transparent"

    Region {
        id: blurRect

        item: root
        radius: root.radius
    }

    Component.onCompleted: {
        if (blurRegion)
            blurRegion.regions.push(blurRect);
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
        anchors.margins: 12
        spacing: 12

        // Big image if provided (album art, avatars), otherwise the app icon.
        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: Theme.innerRadius
            color: root.image ? "transparent" : Qt.alpha(Theme.accent, 0.15)

            Image {
                anchors.fill: parent
                visible: root.image !== ""
                source: root.image
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(80, 80)
                asynchronous: true
            }

            IconImage {
                anchors.centerIn: parent
                visible: !root.image && root.appIcon !== ""
                implicitSize: 24
                source: root.appIcon
                asynchronous: true
            }

            Icon {
                anchors.centerIn: parent
                visible: !root.image && root.appIcon === ""
                text: Icons.bell
                color: Theme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    text: root.notif?.appName || "Notification"
                    font.pixelSize: Theme.smallFontSize
                    color: Theme.subtext0
                }

                StyledText {
                    text: Notifs.timeOf(root.notif)
                    font.pixelSize: Theme.smallFontSize
                    color: Theme.overlay1
                }

                IconButton {
                    size: 20
                    iconSize: 13
                    icon: Icons.close
                    color: Theme.subtext0
                    onClicked: root.notif.dismiss()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notif?.summary ?? ""
                font.weight: Font.DemiBold
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
                linkColor: Theme.accent
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: root.buttons.length > 0
                spacing: 6

                Repeater {
                    model: root.buttons

                    MouseArea {
                        id: action

                        required property var modelData

                        width: label.implicitWidth + 20
                        height: 26
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.invoke()

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.innerRadius
                            color: action.containsMouse ? Qt.alpha(Theme.accent, 0.25) : Theme.surface1
                        }

                        StyledText {
                            id: label

                            anchors.centerIn: parent
                            text: action.modelData.text
                            font.pixelSize: Theme.smallFontSize + 1
                        }
                    }
                }
            }
        }
    }
}
