// Runs seed extraction off the UI thread (see wallpaper/ColorExtractor.qml).
import { seedFromPixels } from "./material.mjs";

WorkerScript.onMessage = function (msg) {
    WorkerScript.sendMessage({
        path: msg.path,
        seed: seedFromPixels(msg.data)
    });
};
