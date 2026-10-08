import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// Extracts the Material seed color of the color-source wallpaper once per
// image and caches it in settings (seeds[path]).
Scope {
    id: root

    readonly property string path: Wallpapers.colorSourcePath
    readonly property string url: path ? "file://" + path : ""
    readonly property bool needed: path !== "" && !(path in Settings.d.seeds)
    property string pending: ""

    function run() {
        if (!needed || pending === path || !worker.ready)
            return;
        pending = path;
        watchdog.restart();
        canvas.loadImage(url);
        if (canvas.isImageLoaded(url))
            canvas.requestPaint();
    }

    onNeededChanged: run()
    onPathChanged: run()
    Component.onCompleted: run()

    // If an image never paints (or fails to load), give up and allow a retry.
    Timer {
        id: watchdog

        interval: 8000
        onTriggered: root.pending = ""
    }

    WorkerScript {
        id: worker

        source: "file://" + Quickshell.shellPath("lib/colorworker.mjs")
        onReadyChanged: root.run()
        onMessage: msg => {
            if (msg.seed)
                Settings.setIn("seeds", msg.path, msg.seed);
            if (root.pending === msg.path)
                root.pending = "";
        }
    }

    // Canvas needs a window to paint in; a 1×1 transparent background surface.
    PanelWindow {
        anchors.top: true
        anchors.left: true
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-color-extractor"
        mask: Region {}

        Canvas {
            id: canvas

            width: 128
            height: 128
            opacity: 0
            onImageLoaded: requestPaint()
            onPaint: {
                const url = root.url;
                if (!root.pending || !isImageLoaded(url))
                    return;
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.drawImage(url, 0, 0, width, height);
                const data = Array.from(ctx.getImageData(0, 0, width, height).data);
                unloadImage(url);
                worker.sendMessage({
                    path: root.path,
                    data: data
                });
            }
        }
    }
}
