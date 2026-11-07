pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Rinka owns rendering; Yuki consumes change-driven stills through its
// existing Material You pipeline. The socket guards against stale exports
// after a crash, including a manifest from a previous host process.
Singleton {
    id: root

    readonly property string socketPath: Quickshell.env("RINKA_SOCKET") || (Quickshell.env("XDG_RUNTIME_DIR") ? Quickshell.env("XDG_RUNTIME_DIR") + "/rinka/host.sock" : "")
    property int hostPid: 0
    property var manifest: ({})
    readonly property var outputs: host.connected && hostPid > 0 && manifest.version === 1 && manifest.pid === hostPid ? (manifest.outputs ?? {}) : ({})

    function imageFor(screenName) {
        const image = outputs[screenName]?.image;
        return typeof image === "string" && image.startsWith("/") ? image : "";
    }

    FileView {
        id: file

        path: root.socketPath ? root.socketPath.replace(/(?:\.[^/.]*)?$/, ".wallpapers.json") : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.manifest = JSON.parse(text());
            } catch (e) {
                root.manifest = {};
            }
        }
        onLoadFailed: root.manifest = {}
    }

    Socket {
        id: host

        path: root.socketPath
        connected: root.socketPath !== "" && root.manifest.version === 1
        onConnectedChanged: {
            root.hostPid = 0;
            if (connected) {
                write('{"id":1,"cmd":"hello","protocol":1,"client":"yuki"}\n');
                flush();
            }
        }

        parser: SplitParser {
            onRead: line => {
                try {
                    const reply = JSON.parse(line);
                    if (reply.id === 1 && reply.ok && reply.result?.protocol === 1) {
                        root.hostPid = reply.result.pid;
                        file.reload();
                    }
                } catch (e) {
                    console.warn("Rinka: invalid hello reply", e);
                }
            }
        }
    }

    Timer {
        // FileView may start before the host's runtime directory exists.
        // Once it has a manifest, file changes and the socket drive updates.
        interval: 5000
        repeat: true
        running: root.socketPath !== "" && root.manifest.version !== 1
        onTriggered: file.reload()
    }
}
