pragma Singleton

import QtQuick
import Quickshell

// Screenshots use niri's own tools; the shell adds a toast with the result.
Singleton {
    id: root

    function region() {
        Niri.action("Screenshot", {
            show_pointer: false
        });
    }

    function screen() {
        Niri.action("ScreenshotScreen", {
            write_to_disk: true,
            show_pointer: false
        });
    }

    function window() {
        Niri.action("ScreenshotWindow", {
            write_to_disk: true
        });
    }

    Connections {
        target: Niri

        function onScreenshotCaptured(path: string): void {
            const dir = path.slice(0, path.lastIndexOf("/"));
            Notifs.notify({
                appName: "Screenshot",
                appIcon: "camera-photo",
                summary: path ? "Screenshot saved" : "Screenshot copied",
                body: path ? path.split("/").pop() : "Copied to the clipboard",
                image: path ? "file://" + path : "",
                timeout: 6,
                actions: path ? [
                    {
                        identifier: "default",
                        text: "Open",
                        run: () => Quickshell.execDetached(["xdg-open", path])
                    },
                    {
                        text: "Open",
                        run: () => Quickshell.execDetached(["xdg-open", path])
                    },
                    {
                        text: "Show folder",
                        run: () => Quickshell.execDetached(["xdg-open", dir])
                    }
                ] : []
            });
        }
    }
}
