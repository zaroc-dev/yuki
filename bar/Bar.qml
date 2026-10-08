import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + Theme.gap
    color: "transparent"
    WlrLayershell.namespace: "yuki-bar"

    // Frosted glass behind each pill.
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    Region {
        id: blurRegion

        Region {
            item: left
            radius: Theme.radius
        }
        Region {
            item: mediaPill.visible ? mediaPill : null
            radius: Theme.radius
        }
        Region {
            item: center
            radius: Theme.radius
        }
        Region {
            item: right
            radius: Theme.radius
        }
    }

    // Only the pills take input; clicks between them reach the windows below.
    mask: Region {
        Region {
            item: left
        }
        Region {
            item: mediaPill.visible ? mediaPill : null
        }
        Region {
            item: center
        }
        Region {
            item: right
        }
    }

    // Snapshot of this output for the lock screen background. Rendered
    // invisibly and grabbed at half resolution (it gets blurred anyway).
    Loader {
        active: Lock.capturing
        sourceComponent: ScreencopyView {
            id: snap

            width: root.modelData.width
            height: root.modelData.height
            opacity: 0
            captureSource: root.modelData
            live: false
            onHasContentChanged: {
                if (hasContent)
                    Qt.callLater(() => snap.grabToImage(result => Lock.snapshotReady(root.modelData.name, result), Qt.size(width / 2, height / 2)));
            }
        }
    }

    // Sees every press first (without taking it) to dismiss open popups.
    MouseArea {
        anchors.fill: parent
        z: 1000
        acceptedButtons: Qt.AllButtons
        onPressed: mouse => {
            Ui.dismissPopup(this, mouse.x, mouse.y);
            mouse.accepted = false;
        }
    }

    Pill {
        id: left

        x: Theme.gap
        y: Theme.gap
        StartButton {}
        LauncherButton {}
    }

    // Now playing, as its own island next to the start pill.
    Pill {
        id: mediaPill

        x: left.x + left.width + Theme.gap
        y: Theme.gap
        // Not media.visible: that reports effective visibility, which stays
        // false while this pill is hidden, so it could never reappear.
        visible: Media.active !== null && Settings.d.showMedia
        MediaWidget {
            id: media
        }
    }

    Pill {
        id: center

        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.gap
        Clock {}
        Separator {}
        Workspaces {
            output: root.modelData.name
        }
        Separator {
            visible: activeWindow.visible
        }
        ActiveWindow {
            id: activeWindow

            output: root.modelData.name
        }
    }

    Pill {
        id: right

        anchors.right: parent.right
        anchors.rightMargin: Theme.gap
        y: Theme.gap
        Tray {
            id: tray
        }
        Separator {
            visible: tray.visible
        }
        NotificationButton {}
        Separator {}
        BluetoothWidget {}
        NetworkWidget {}
        VolumeWidget {}
        BatteryWidget {}
        Separator {}
        PowerButton {}
    }
}
