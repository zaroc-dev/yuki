import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services

// The user's picture: AccountsService's (what SDDM shows), else ~/.face.icon
// or ~/.face, else their initial. GIFs animate while it's visible.
ClippingRectangle {
    id: root

    property real size: 40
    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property var sources: !Accounts.ready ? [] : (Accounts.iconFile ? [`file://${Accounts.iconFile}`] : []).concat([`file://${Quickshell.env("HOME")}/.face.icon`, `file://${Quickshell.env("HOME")}/.face`])
    property int sourceIdx: 0

    // Start over when the daemon reports a (possibly replaced) picture.
    onSourcesChanged: sourceIdx = 0
    Connections {
        target: Accounts

        function onRevisionChanged() {
            root.sourceIdx = 0;
        }
    }

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

    // AnimatedImage also shows still formats (PNG, JPEG). It renders on the
    // GUI thread, so it only plays while shown.
    AnimatedImage {
        id: img

        anchors.fill: parent
        // The revision makes a picture replaced under the same path reload.
        source: root.sources[root.sourceIdx] ? `${root.sources[root.sourceIdx]}#${Accounts.revision}` : ""
        cache: false
        fillMode: Image.PreserveAspectCrop
        // Pictures are often 500 px or more, shown at 26-98 px.
        mipmap: true
        playing: root.visible && QsWindow.window?.visible === true
        asynchronous: true
        // Walk down the candidate list until one loads.
        onStatusChanged: {
            if (status === Image.Error && root.sourceIdx < root.sources.length)
                root.sourceIdx++;
        }
    }
}
