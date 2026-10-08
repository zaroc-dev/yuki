// Material You color extraction + schemes, backed by Google's
// material-color-utilities 0.3.0 (Apache-2.0, vendored in ./mcu).
import { Hct } from "./mcu/hct/hct.js";
import { QuantizerCelebi } from "./mcu/quantize/quantizer_celebi.js";
import { Score } from "./mcu/score/score.js";
import { Blend } from "./mcu/blend/blend.js";
import { TonalPalette } from "./mcu/palettes/tonal_palette.js";
import { MaterialDynamicColors } from "./mcu/dynamiccolor/material_dynamic_colors.js";
import { SchemeTonalSpot } from "./mcu/scheme/scheme_tonal_spot.js";
import { SchemeContent } from "./mcu/scheme/scheme_content.js";
import { SchemeExpressive } from "./mcu/scheme/scheme_expressive.js";
import { SchemeFidelity } from "./mcu/scheme/scheme_fidelity.js";
import { SchemeFruitSalad } from "./mcu/scheme/scheme_fruit_salad.js";
import { SchemeMonochrome } from "./mcu/scheme/scheme_monochrome.js";
import { SchemeNeutral } from "./mcu/scheme/scheme_neutral.js";
import { SchemeRainbow } from "./mcu/scheme/scheme_rainbow.js";
import { SchemeVibrant } from "./mcu/scheme/scheme_vibrant.js";
import { argbFromHex, hexFromArgb } from "./mcu/utils/string_utils.js";

const schemes = {
    "tonal-spot": SchemeTonalSpot,
    "content": SchemeContent,
    "expressive": SchemeExpressive,
    "fidelity": SchemeFidelity,
    "fruit-salad": SchemeFruitSalad,
    "monochrome": SchemeMonochrome,
    "neutral": SchemeNeutral,
    "rainbow": SchemeRainbow,
    "vibrant": SchemeVibrant
};

export const schemeNames = Object.keys(schemes);

export const m3Roles = ["primary", "onPrimary", "primaryContainer", "onPrimaryContainer",
    "secondary", "onSecondary", "secondaryContainer", "onSecondaryContainer",
    "tertiary", "onTertiary", "tertiaryContainer", "onTertiaryContainer",
    "error", "onError", "errorContainer", "onErrorContainer",
    "background", "onBackground", "surface", "onSurface", "surfaceVariant", "onSurfaceVariant",
    "outline", "outlineVariant", "inverseSurface", "inverseOnSurface", "inversePrimary",
    "surfaceDim", "surfaceBright", "surfaceContainerLowest", "surfaceContainerLow",
    "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "shadow", "scrim"];

// RGBA byte array (e.g. Canvas getImageData().data) -> best seed color hex.
export function seedFromPixels(data) {
    const pixels = [];
    for (let i = 0; i < data.length; i += 4) {
        if (data[i + 3] < 255)
            continue;
        pixels.push(((255 << 24) | (data[i] << 16) | (data[i + 1] << 8) | data[i + 2]) >>> 0);
    }
    if (pixels.length === 0)
        return "";
    const ranked = Score.score(QuantizerCelebi.quantize(pixels, 128));
    return hexFromArgb(ranked[0]);
}

// Builds a palette with the shell's (Catppuccin-shaped) keys from a seed.
// Surfaces follow the neutral tonal ramps at Catppuccin-like lightness steps,
// so every widget keeps its contrast; named hues are harmonized to the seed.
export function palette(seedHex, schemeName, dark) {
    const Scheme = schemes[schemeName] ?? SchemeTonalSpot;
    const seed = argbFromHex(seedHex);
    const s = new Scheme(Hct.fromInt(seed), dark, 0);
    const role = name => hexFromArgb(MaterialDynamicColors[name].getArgb(s));
    const n = t => hexFromArgb(s.neutralPalette.tone(t));
    const nv = t => hexFromArgb(s.neutralVariantPalette.tone(t));
    const ramp = dark
        ? { crust: 5, mantle: 8, base: 11, surface0: 18, surface1: 26, surface2: 34, overlay0: 46, overlay1: 54, overlay2: 62, subtext0: 72, subtext1: 80, text: 92 }
        : { crust: 88, mantle: 92, base: 96, surface0: 90, surface1: 84, surface2: 78, overlay0: 64, overlay1: 56, overlay2: 48, subtext0: 38, subtext1: 30, text: 12 };
    const hueTone = dark ? 80 : 45;
    const hue = (hex) => {
        const harmonized = Blend.harmonize(argbFromHex(hex), seed);
        const h = Hct.fromInt(harmonized);
        return hexFromArgb(TonalPalette.fromHueAndChroma(h.hue, Math.max(36, Math.min(h.chroma, 60))).tone(hueTone));
    };
    const out = {
        dark: dark,
        primary: role("primary"),
        onPrimary: role("onPrimary"),
        secondary: role("secondary"),
        tertiary: role("tertiary"),
        rosewater: hue("#f5e0dc"), flamingo: hue("#f2cdcd"), pink: hue("#f5c2e7"),
        red: role("error"), maroon: hue("#eba0ac"), peach: hue("#fab387"), yellow: hue("#f9e2af"),
        green: hue("#a6e3a1"), teal: hue("#94e2d5"), sky: hue("#89dceb"), sapphire: hue("#74c7ec"),
        blue: hue("#89b4fa"), lavender: hue("#b4befe"),
        // The scheme's own accents take the "mauve" (default accent) slot.
        mauve: role("primary")
    };
    for (const [k, t] of Object.entries(ramp))
        out[k] = ["crust", "mantle", "base", "text"].includes(k) ? n(t) : nv(t);
    // Full Material role set, for app templates (GTK, kitty, niri, ...).
    out.m3 = {};
    for (const r of m3Roles)
        out.m3[r] = role(r);
    return out;
}
