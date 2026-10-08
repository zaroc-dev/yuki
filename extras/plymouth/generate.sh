#!/usr/bin/env bash
# Renders the Plymouth theme's images in a given palette.
# usage: generate.sh <outdir> [accent] [base] [surface] [text] [font-file]
# Needs ImageMagick (magick) and a Nerd Font (for the NixOS glyph).
set -euo pipefail
out=${1:?outdir}
accent=${2:-#b3c5ff}
base=${3:-#121318}
surface=${4:-#292a2f}
text=${5:-#e3e2e9}
font=${6:-$(fc-match -f '%{file}' 'JetBrainsMono Nerd Font')}
mkdir -p "$out"

# NixOS snowflake (Nerd Font U+F313), the same glyph as the start button.
magick -background none -fill "$accent" -font "$font" -pointsize 112 label:$'' \
  -trim +repage -gravity center -extent 128x128 "$out/logo.png"

# Spinner: faint full track + an accent arc that the script rotates.
magick -size 176x176 xc:none -fill none -stroke "${surface}" -strokewidth 3 \
  -draw "circle 88,88 88,4" "$out/track.png"
magick -size 176x176 xc:none -fill none -stroke "$accent" -strokewidth 3 \
  -draw "arc 4,4 172,172 0,100" "$out/arc.png"

# Password pill (lock screen style) and its bullets.
magick -size 340x52 xc:none -fill "${base}cc" -stroke "${accent}e6" -strokewidth 1.5 \
  -draw "roundrectangle 1,1 338,50 25,25" "$out/entry.png"
magick -size 10x10 xc:none -fill "$text" -draw "circle 5,5 5,0" "$out/bullet.png"
