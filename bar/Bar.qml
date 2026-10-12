import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

PanelWindow {
    id: root

    required property ShellScreen modelData

    // Width left for the two elastic titles (media, active window) once every
    // pill's fixed part fits; narrow (portrait) outputs would overlap otherwise.
    // Summed from parts whose width doesn't depend on the titles: measuring the
    // pills themselves feeds the result back and the layout never settles.
    readonly property bool mediaShown: Media.active !== null && Settings.d.showMedia
    readonly property real titleBudget: {
        let centerFixed = Theme.padding * 2 + clock.implicitWidth + Theme.spacing * 2 + workspacesSep.implicitWidth + workspaces.implicitWidth;
        if (activeWindow.shown)
            centerFixed += Theme.spacing * 2 + windowSep.implicitWidth + activeWindow.fixedWidth;
        const mediaFixed = mediaShown ? Theme.gap + Theme.padding * 2 + media.fixedWidth : 0;
        return width - Theme.gap * 4 - left.naturalWidth - right.naturalWidth - centerFixed - mediaFixed;
    }
    // Fair split: each title gets half, or more if the other needs less.
    readonly property real mediaTitleMax: mediaShown ? Math.min(media.titleNatural, Math.max(titleBudget / 2, titleBudget - (activeWindow.shown ? activeWindow.titleNatural : 0))) : 0

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
        visible: root.mediaShown
        MediaWidget {
            id: media

            titleMax: root.mediaTitleMax
        }
    }

    Pill {
        id: center

        readonly property real minX: (mediaPill.visible ? mediaPill.x + mediaPill.width : left.x + left.width) + Theme.gap
        readonly property real maxX: right.x - Theme.gap - width

        // Centered while there is room, else pushed into the gap between its neighbours.
        x: Math.round(Math.max(minX, Math.min((parent.width - width) / 2, maxX)))
        y: Theme.gap
        Clock {
            id: clock
        }
        Separator {
            id: workspacesSep
        }
        Workspaces {
            id: workspaces

            output: root.modelData.name
        }
        Separator {
            id: windowSep

            visible: activeWindow.visible
        }
        ActiveWindow {
            id: activeWindow

            output: root.modelData.name
            titleMax: root.titleBudget - root.mediaTitleMax
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
