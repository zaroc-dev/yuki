import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config

// Blurred, dimmed copy of the wallpaper for niri's overview. The generated
// niri.kdl (see services/Templates) places this namespace "within backdrop",
// so it shows behind the zoomed-out workspaces, not on the desktop.
PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property string path: Wallpapers.pathFor(modelData.name)

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.crust
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-backdrop"

    Image {
        id: img

        anchors.fill: parent
        source: root.path ? "file://" + root.path : ""
        // Small on purpose: it's blurred anyway, and cheap to keep around.
        sourceSize: Qt.size(root.modelData.width / 4, root.modelData.height / 4)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 48
        blur: 1
        brightness: -0.18
        saturation: -0.1
        opacity: img.status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 600
            }
        }
    }

    // Theme tint so the backdrop sits with the palette.
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.crust, 0.35)
    }
}
