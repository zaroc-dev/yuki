import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config

// The user's picture (~/.face.icon, AccountsService) or their initial.
ClippingRectangle {
    id: root

    property real size: 40
    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property var sources: [`file://${Quickshell.env("HOME")}/.face.icon`, `file://${Quickshell.env("HOME")}/.face`, `file:///var/lib/AccountsService/icons/${user}`]
    property int sourceIdx: 0

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: Qt.alpha(Theme.accent, 0.25)

    StyledText {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        text: root.user.charAt(0).toUpperCase()
        font.pixelSize: root.size * 0.42
        font.weight: Font.DemiBold
        color: Theme.accent
    }

    Image {
        id: img

        anchors.fill: parent
        source: root.sources[root.sourceIdx] ?? ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
        // Walk down the candidate list until one loads.
        onStatusChanged: {
            if (status === Image.Error && root.sourceIdx < root.sources.length)
                root.sourceIdx++;
        }
    }
}
