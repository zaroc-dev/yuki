import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// Extracts the Material seed color of the color-source wallpaper once per
// image. Local seeds are cached in settings; Rinka runtime seeds stay in
// memory so edits do not grow the settings file.
Scope {
    id: root

    readonly property string path: Wallpapers.colorSourcePath
    readonly property string url: path ? "file://" + path : ""
    readonly property bool needed: path !== "" && Wallpapers.colorSeed === ""
    property string pending: ""
    property double started: 0

    function run() {
        if (!needed || pending === path || !worker.ready || !canvas.available || !canvas.context)
            return;
        pending = path;
        started = Date.now();
        watchdog.restart();
        canvas.loadImage(url);
        if (canvas.isImageLoaded(url))
            extract();
    }

    function extract() {
        const ctx = canvas.context;
        if (!needed || pending !== path || !canvas.available || !ctx || !canvas.isImageLoaded(url))
            return;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.drawImage(url, 0, 0, canvas.width, canvas.height);
        const data = Array.from(ctx.getImageData(0, 0, canvas.width, canvas.height).data);
        canvas.unloadImage(url);
        worker.sendMessage({
            path: path,
            rinka: Wallpapers.managedByRinka(Wallpapers.colorScreen),
            data: data
        });
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
            if (msg.seed) {
                if (msg.path === root.path && Wallpapers.managedByRinka(Wallpapers.colorScreen))
                    Wallpapers.rinkaSeed = { path: msg.path, seed: msg.seed };
                else if (!msg.rinka)
                    Settings.setIn("seeds", msg.path, msg.seed);
                // Only runs for wallpapers without a cached seed (e.g. first start).
                console.info(`ColorExtractor: seed ${msg.seed} in ${Date.now() - root.started} ms`);
            }
            if (root.pending === msg.path) {
                root.pending = "";
                watchdog.stop();
            }
        }
    }

    // Canvas needs an initialized window. A covered background surface may
    // never initialize, so use an input-transparent overlay while extracting.
    PanelWindow {
        visible: root.needed
        anchors.top: true
        anchors.left: true
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "yuki-color-extractor"
        mask: Region {}

        Canvas {
            id: canvas

            // Quantizing is the slow part (QV4): 64² is ~3.5× faster than 128²
            // with practically the same seed; drawImage averages when scaling.
            width: 64
            height: 64
            opacity: 0
            contextType: "2d"
            onAvailableChanged: root.run()
            onContextChanged: root.run()
            onImageLoaded: root.extract()
        }
    }
}
