import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Background layer for one output. New wallpapers fade in while settling
// from a slight zoom.
PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property string path: Wallpapers.pathFor(modelData.name)
    property Image front: a

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.crust
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "yuki-wallpaper"

    onPathChanged: {
        const back = front === a ? b : a;
        back.source = path ? "file://" + path : "";
    }
    Component.onCompleted: a.source = path ? "file://" + path : ""

    component Layer: Image {
        id: img

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.modelData.width * 1.1, root.modelData.height * 1.1)
        asynchronous: true
        cache: false
        smooth: true
        opacity: 0
        onStatusChanged: {
            if (status !== Image.Ready)
                return;
            if (img === root.front && opacity === 0) {
                opacity = 1; // first load: no transition
                return;
            }
            if (img !== root.front)
                swap.start();
        }
    }

    // Clicking the desktop closes any open bar popup.
    MouseArea {
        anchors.fill: parent
        z: 10
        acceptedButtons: Qt.AllButtons
        onPressed: mouse => {
            Ui.activePopup?.close();
            mouse.accepted = false;
        }
    }

    Layer {
        id: a
    }

    Layer {
        id: b
    }

    ParallelAnimation {
        id: swap

        readonly property Image incoming: root.front === a ? b : a

        onStarted: incoming.z = 1, root.front.z = 0
        onFinished: {
            const old = root.front;
            root.front = incoming;
            old.opacity = 0;
            old.source = "";
        }

        NumberAnimation {
            target: swap.incoming
            property: "opacity"
            from: 0
            to: 1
            duration: 700
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: swap.incoming
            property: "scale"
            from: 1.06
            to: 1
            duration: 1100
            easing.type: Easing.OutCubic
        }
    }
}
