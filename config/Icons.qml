pragma Singleton

import Quickshell

// Nerd Font (Material Design) glyphs, verified against nerd-fonts glyphnames.json.
Singleton {
    readonly property string nixos: ""
    readonly property string apps: "\u{f003b}"
    readonly property string search: "\u{f0349}"
    readonly property string close: "\u{f0156}"
    readonly property string check: "\u{f012c}"
    readonly property string chevronLeft: "\u{f0141}"
    readonly property string chevronRight: "\u{f0142}"
    readonly property string calendar: "\u{f00ed}"
    readonly property string palette: "\u{f03d8}"
    readonly property string arrowRight: "\u{f0054}"
    readonly property string keyboard: "\u{f097b}"
    readonly property string alert: "\u{f05d6}"
    readonly property string loading: "\u{f0772}"

    readonly property string power: "\u{f0425}"
    readonly property string sleep: "\u{f0904}"
    readonly property string logout: "\u{f0343}"
    readonly property string restart: "\u{f0709}"
    readonly property string lockOutline: "\u{f0341}"
    readonly property string lockOpen: "\u{f0fc6}"

    readonly property string settings: "\u{f08bb}"
    readonly property string sun: "\u{f05a8}"
    readonly property string moon: "\u{f0594}"
    readonly property string image: "\u{f0976}"
    readonly property string pin: "\u{f0403}"
    readonly property string pinOff: "\u{f0404}"
    readonly property string folder: "\u{f0256}"
    readonly property string info: "\u{f02fd}"
    readonly property string dashboard: "\u{f0a1d}"
    readonly property string paint: "\u{f027c}"
    readonly property string monitor: "\u{f0379}"
    readonly property string reload: "\u{f0453}"
    readonly property string arrowUp: "\u{f005d}"
    readonly property string arrowDown: "\u{f0045}"
    readonly property string bar: "\u{f1513}"
    readonly property string history: "\u{f02da}"

    readonly property string bluetooth: "\u{f00af}"
    readonly property string bluetoothOff: "\u{f00b2}"
    readonly property string bluetoothConnected: "\u{f00b1}"
    readonly property string scan: "\u{f1276}"
    readonly property string clipboard: "\u{f0a38}"
    readonly property string copy: "\u{f018f}"
    readonly property string trash: "\u{f09e7}"
    readonly property string screenshot: "\u{f0e51}"
    readonly property string region: "\u{f0a6d}"
    readonly property string window: "\u{f05af}"
    readonly property string brightness: "\u{f00df}"
    readonly property string powerSaver: "\u{f032a}"
    readonly property string balanced: "\u{f05d1}"
    readonly property string performance: "\u{f14de}"
    readonly property string timer: "\u{f051b}"
    readonly property string awake: "\u{f06d0}"
    readonly property string openExternal: "\u{f03cc}"
    readonly property string text: "\u{f09ed}"

    // BlueZ device icon names -> glyphs
    function device(icon) {
        if (/audio-headset|headset/.test(icon))
            return "\u{f02ce}";
        if (/audio|headphone/.test(icon))
            return "\u{f02cb}";
        if (/mouse/.test(icon))
            return "\u{f037d}";
        if (/keyboard/.test(icon))
            return "\u{f030c}";
        if (/gaming|joystick/.test(icon))
            return "\u{f0297}";
        if (/phone/.test(icon))
            return "\u{f011c}";
        if (/speaker/.test(icon))
            return "\u{f04c3}";
        return "\u{f0fb0}";
    }

    readonly property string music: "\u{f075a}"
    readonly property string play: "\u{f040a}"
    readonly property string pause: "\u{f03e4}"
    readonly property string next: "\u{f04ad}"
    readonly property string previous: "\u{f04ae}"
    readonly property string shuffle: "\u{f049d}"
    readonly property string repeat: "\u{f0456}"

    readonly property string bell: "\u{f009a}"
    readonly property string bellOutline: "\u{f009c}"
    readonly property string bellOff: "\u{f009b}"
    readonly property string bellBadge: "\u{f116b}"
    readonly property string clearAll: "\u{f039f}"

    readonly property string volumeHigh: "\u{f057e}"
    readonly property string volumeMedium: "\u{f0580}"
    readonly property string volumeLow: "\u{f057f}"
    readonly property string volumeOff: "\u{f0581}"
    readonly property string mic: "\u{f036c}"
    readonly property string micOff: "\u{f036d}"
    readonly property string speaker: "\u{f04c3}"
    readonly property string headphones: "\u{f02cb}"

    readonly property string ethernet: "\u{f0200}"
    readonly property string networkOff: "\u{f0c9b}"
    readonly property string wifiOff: "\u{f092e}"
    readonly property string lock: "\u{f033e}"
    readonly property var wifiStrength: ["\u{f092f}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]

    readonly property var battery: ["\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}",
        "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]
    readonly property string batteryCharging: "\u{f0084}"
    readonly property string batteryAlert: "\u{f0083}"

    function volume(level, muted) {
        if (muted || level <= 0)
            return volumeOff;
        if (level < 0.34)
            return volumeLow;
        if (level < 0.67)
            return volumeMedium;
        return volumeHigh;
    }

    function wifi(strength) {
        return wifiStrength[Math.max(0, Math.min(4, Math.round(strength * 4)))];
    }

    function batteryLevel(percent, charging) {
        if (charging)
            return batteryCharging;
        if (percent < 0.05)
            return batteryAlert;
        return battery[Math.max(0, Math.min(9, Math.ceil(percent * 10) - 1))];
    }
}
