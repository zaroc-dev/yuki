pragma Singleton

import QtQuick
import Quickshell
import "../lib/material.mjs" as Material

// Central style source. Every color in the shell binds to a property here, so
// switching flavor/accent (or loading a custom palette) restyles everything live.
Singleton {
    id: root

    readonly property var flavors: ({
        mocha: {
            rosewater: "#f5e0dc", flamingo: "#f2cdcd", pink: "#f5c2e7", mauve: "#cba6f7",
            red: "#f38ba8", maroon: "#eba0ac", peach: "#fab387", yellow: "#f9e2af",
            green: "#a6e3a1", teal: "#94e2d5", sky: "#89dceb", sapphire: "#74c7ec",
            blue: "#89b4fa", lavender: "#b4befe", text: "#cdd6f4", subtext1: "#bac2de",
            subtext0: "#a6adc8", overlay2: "#9399b2", overlay1: "#7f849c", overlay0: "#6c7086",
            surface2: "#585b70", surface1: "#45475a", surface0: "#313244", base: "#1e1e2e",
            mantle: "#181825", crust: "#11111b", dark: true
        },
        macchiato: {
            rosewater: "#f4dbd6", flamingo: "#f0c6c6", pink: "#f5bde6", mauve: "#c6a0f6",
            red: "#ed8796", maroon: "#ee99a0", peach: "#f5a97f", yellow: "#eed49f",
            green: "#a6da95", teal: "#8bd5ca", sky: "#91d7e3", sapphire: "#7dc4e4",
            blue: "#8aadf4", lavender: "#b7bdf8", text: "#cad3f5", subtext1: "#b8c0e0",
            subtext0: "#a5adcb", overlay2: "#939ab7", overlay1: "#8087a2", overlay0: "#6e738d",
            surface2: "#5b6078", surface1: "#494d64", surface0: "#363a4f", base: "#24273a",
            mantle: "#1e2030", crust: "#181926", dark: true
        },
        frappe: {
            rosewater: "#f2d5cf", flamingo: "#eebebe", pink: "#f4b8e4", mauve: "#ca9ee6",
            red: "#e78284", maroon: "#ea999c", peach: "#ef9f76", yellow: "#e5c890",
            green: "#a6d189", teal: "#81c8be", sky: "#99d1db", sapphire: "#85c1dc",
            blue: "#8caaee", lavender: "#babbf1", text: "#c6d0f5", subtext1: "#b5bfe2",
            subtext0: "#a5adce", overlay2: "#949cbb", overlay1: "#838ba7", overlay0: "#737994",
            surface2: "#626880", surface1: "#51576d", surface0: "#414559", base: "#303446",
            mantle: "#292c3c", crust: "#232634", dark: true
        },
        latte: {
            rosewater: "#dc8a78", flamingo: "#dd7878", pink: "#ea76cb", mauve: "#8839ef",
            red: "#d20f39", maroon: "#e64553", peach: "#fe640b", yellow: "#df8e1d",
            green: "#40a02b", teal: "#179299", sky: "#04a5e5", sapphire: "#209fb5",
            blue: "#1e66f5", lavender: "#7287fd", text: "#4c4f69", subtext1: "#5c5f77",
            subtext0: "#6c6f85", overlay2: "#7c7f93", overlay1: "#8c8fa1", overlay0: "#9ca0b0",
            surface2: "#acb0be", surface1: "#bcc0cc", surface0: "#ccd0da", base: "#eff1f5",
            mantle: "#e6e9ef", crust: "#dce0e8", dark: false
        }
    })

    readonly property var accents: ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach",
        "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"]

    readonly property var schemes: Material.schemeNames
    readonly property var settings: Settings.d

    // Where colors come from: wallpaper (Material You), catppuccin, or custom.
    readonly property string source: settings.themeSource
    readonly property string flavor: settings.flavor in flavors && settings.flavor !== "latte" ? settings.flavor : "mocha"
    readonly property bool lightMode: settings.themeMode === "light"
    // Seed color for wallpaper theming, extracted by wallpaper/ColorExtractor.
    readonly property string seed: settings.seeds[Wallpapers.colorSourcePath] ?? ""

    // Shell palette with Catppuccin-shaped keys, whatever the source.
    // "custom" merges settings.custom over mocha, for external generators.
    readonly property var p: {
        if (source === "wallpaper" && seed)
            return Material.palette(seed, settings.scheme, !lightMode);
        if (source === "custom")
            return Object.assign({}, flavors.mocha, settings.custom);
        return lightMode ? flavors.latte : flavors[flavor];
    }
    readonly property bool dynamic: source === "wallpaper" && seed !== ""

    // Material roles for app templates. Catppuccin/custom palettes are mapped
    // onto the same role names.
    readonly property var m3: p.m3 ?? {
        primary: String(accent), onPrimary: String(onAccent), primaryContainer: p.surface1, onPrimaryContainer: p.text,
        secondary: p.lavender, onSecondary: p.crust, secondaryContainer: p.surface1, onSecondaryContainer: p.text,
        tertiary: p.pink, onTertiary: p.crust, tertiaryContainer: p.surface2, onTertiaryContainer: p.text,
        error: p.red, onError: p.crust, errorContainer: p.maroon, onErrorContainer: p.crust,
        background: p.base, onBackground: p.text, surface: p.base, onSurface: p.text,
        surfaceVariant: p.surface1, onSurfaceVariant: p.subtext1, outline: p.overlay0, outlineVariant: p.surface1,
        inverseSurface: p.text, inverseOnSurface: p.base, inversePrimary: String(accent),
        surfaceDim: p.mantle, surfaceBright: p.surface1, surfaceContainerLowest: p.crust, surfaceContainerLow: p.mantle,
        surfaceContainer: p.surface0, surfaceContainerHigh: p.surface1, surfaceContainerHighest: p.surface2,
        shadow: "#000000", scrim: "#000000"
    }

    function previewPalette(scheme, dark) {
        if (seed)
            return Material.palette(seed, scheme, dark);
        const f = dark ? flavors.mocha : flavors.latte;
        return Object.assign({
            primary: f.mauve,
            secondary: f.lavender,
            tertiary: f.pink
        }, f);
    }

    function setSource(name) {
        if (!["wallpaper", "catppuccin", "custom"].includes(name))
            return false;
        settings.themeSource = name;
        return true;
    }

    function setMode(mode) {
        if (mode !== "dark" && mode !== "light")
            return false;
        settings.themeMode = mode;
        return true;
    }

    function toggleMode() {
        setMode(lightMode ? "dark" : "light");
    }

    function setScheme(name) {
        if (!schemes.includes(name))
            return false;
        settings.scheme = name;
        return true;
    }

    function setFlavor(name) {
        if (name === "latte") {
            settings.themeSource = "catppuccin";
            settings.themeMode = "light";
            return true;
        }
        if (!(name in flavors))
            return false;
        settings.themeSource = "catppuccin";
        settings.themeMode = "dark";
        settings.flavor = name;
        return true;
    }

    function setAccent(name) {
        if (!accents.includes(name))
            return false;
        settings.accent = name;
        return true;
    }

    // Right-click on the start button: wallpaper -> mocha -> macchiato -> frappe -> latte -> wallpaper
    function cycleFlavor() {
        if (source !== "catppuccin")
            return setFlavor("mocha");
        if (lightMode)
            return setSource("wallpaper"), setMode("dark");
        const names = ["mocha", "macchiato", "frappe", "latte"];
        setFlavor(names[names.indexOf(flavor) + 1]);
    }

    // ---- palette ----
    readonly property bool dark: p.dark
    readonly property color accent: dynamic ? p.primary : p[settings.accent] ?? p.mauve
    readonly property color base: p.base
    readonly property color mantle: p.mantle
    readonly property color crust: p.crust
    readonly property color surface0: p.surface0
    readonly property color surface1: p.surface1
    readonly property color surface2: p.surface2
    readonly property color overlay0: p.overlay0
    readonly property color overlay1: p.overlay1
    readonly property color overlay2: p.overlay2
    readonly property color text: p.text
    readonly property color subtext0: p.subtext0
    readonly property color subtext1: p.subtext1
    readonly property color red: p.red
    readonly property color peach: p.peach
    readonly property color yellow: p.yellow
    readonly property color green: p.green
    readonly property color teal: p.teal
    readonly property color blue: p.blue
    readonly property color lavender: p.lavender
    readonly property color mauve: p.mauve
    readonly property color pink: p.pink
    readonly property color secondary: p.secondary ?? p.lavender
    readonly property color tertiary: p.tertiary ?? p.pink

    // ---- semantic ----
    // With compositor blur the surfaces can be see-through; without it keep them near-opaque.
    readonly property bool blur: settings.blur
    readonly property real opacity: blur ? settings.opacity : Math.max(settings.opacity, 0.95)
    readonly property color barBg: Qt.alpha(base, opacity)
    readonly property color barBorder: Qt.alpha(surface1, 0.6)
    readonly property color popupBg: Qt.alpha(base, Math.min(1, opacity + 0.06))
    readonly property color hover: Qt.alpha(text, 0.08)
    readonly property color pressed: Qt.alpha(text, 0.14)
    readonly property color onAccent: dynamic ? p.onPrimary : crust

    // ---- metrics ----
    readonly property int barHeight: 36
    readonly property int gap: 8
    readonly property int radius: 12
    readonly property int innerRadius: 8
    readonly property int padding: 6
    readonly property int spacing: 4

    // ---- type ----
    readonly property string font: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int smallFontSize: 11
    readonly property int iconSize: 16

    readonly property int anim: 180
    readonly property int animSlow: 320
}
