pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Clipboard history backed by cliphist. The shell records new entries itself
// (wl-paste --watch) unless disabled in settings.
Singleton {
    id: root

    // [{ id, preview, isImage, info }] newest first
    property var entries: []
    readonly property string cacheDir: Quickshell.cachePath("clipboard")
    // id -> decoded image path
    property var thumbs: ({})

    function refresh() {
        list.running = true;
    }

    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", `cliphist decode '${entry.id}' | wl-copy`]);
    }

    function remove(entry) {
        Quickshell.execDetached(["sh", "-c", `printf '%s\\t%s\\n' '${entry.id}' "$1" | cliphist delete`, "sh", entry.raw]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        entries = [];
    }

    // Decodes an image entry to the cache once, for thumbnails.
    function thumb(entry) {
        if (entry.id in thumbs)
            return;
        const path = `${cacheDir}/${entry.id}.${entry.ext}`;
        const t = Object.assign({}, thumbs);
        t[entry.id] = "";
        thumbs = t;
        const p = decoder.createObject(root, {
            command: ["sh", "-c", `mkdir -p '${cacheDir}' && cliphist decode '${entry.id}' > '${path}'`]
        });
        p.exited.connect(() => {
            const u = Object.assign({}, root.thumbs);
            u[entry.id] = "file://" + path;
            root.thumbs = u;
            p.destroy();
        });
        p.running = true;
    }

    function search(query) {
        query = query.trim().toLowerCase();
        return query ? entries.filter(e => e.preview.toLowerCase().includes(query)) : entries;
    }

    Process {
        id: list

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const id = line.slice(0, tab);
                    const preview = line.slice(tab + 1);
                    // e.g. "[[ binary data 52 KiB png 1920x1080 ]]"
                    const img = preview.match(/^\[\[ binary data (.+?) (png|jpe?g|webp|gif|bmp) (\d+x\d+) \]\]$/);
                    out.push({
                        id: id,
                        raw: preview,
                        preview: img ? `Image · ${img[3]} · ${img[1]}` : preview,
                        isImage: !!img,
                        ext: img ? img[2] : ""
                    });
                }
                root.entries = out;
            }
        }
    }

    Component {
        id: decoder

        Process {}
    }

    // Record new clipboard contents (text and images).
    Process {
        running: Settings.d.clipboardWatch
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    }

    Process {
        running: Settings.d.clipboardWatch
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    }
}
