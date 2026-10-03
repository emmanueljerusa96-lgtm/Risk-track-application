#!/usr/bin/env bash
# Draws the browser/PWA icons from the Risk Track brand colours, so `web/`
# does not need binary artwork in the repository history.
#
# Requires ImageMagick (`convert`). Run from the repository root:
#
#   bash scripts/make-web-icons.sh
#
# The same rounded teal square and white map pin used by lib/widgets/risk_logo.dart
# are reproduced here. Re-run it after changing AppColors in lib/utils/constants.dart.
set -euo pipefail

out="web"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

teal="#0E9184"
deep_teal="#075F59"

mkdir -p "$out/icons"

# Gradient square used behind the pin.
convert -size 512x512 "gradient:${teal}-${deep_teal}" "$tmp/gradient.png"

# Rounded corners for the normal (non-maskable) icons.
convert -size 512x512 xc:none -fill white \
  -draw "roundrectangle 0,0,511,511,150,150" "$tmp/round_mask.png"

convert "$tmp/gradient.png" "$tmp/round_mask.png" \
  -alpha off -compose CopyOpacity -composite "$tmp/rounded.png"

# Colour sitting inside the pin's eye, sampled from the gradient.
eye_colour="$(convert "$tmp/gradient.png" -format '%[pixel:p{256,205}]' info:)"

# The white pin: round head, tapered body, transparent-look eye.
convert -size 512x512 xc:none -fill white \
  -draw "polygon 172,215 340,215 256,428" \
  -draw "circle 256,205 256,103" \
  -fill "$eye_colour" \
  -draw "circle 256,205 256,163" "$tmp/pin.png"

# Full-bleed gradient for maskable icons (Android/browser may crop to a circle).
convert -size 512x512 "gradient:${teal}-${deep_teal}" "$tmp/full.png"
convert "$tmp/pin.png" -resize 300x300 "$tmp/pin_small.png"

convert "$tmp/rounded.png" "$tmp/pin.png" -compose Over -composite "$tmp/icon.png"
convert "$tmp/full.png" "$tmp/pin_small.png" -gravity center -compose Over \
  -composite "$tmp/icon_maskable.png"

convert "$tmp/icon.png" -resize 512x512 "$out/icons/Icon-512.png"
convert "$tmp/icon.png" -resize 192x192 "$out/icons/Icon-192.png"
convert "$tmp/icon_maskable.png" -resize 512x512 "$out/icons/Icon-maskable-512.png"
convert "$tmp/icon_maskable.png" -resize 192x192 "$out/icons/Icon-maskable-192.png"
convert "$tmp/icon.png" -resize 64x64 "$out/favicon.png"

echo "Wrote:"
ls -1 "$out/favicon.png" "$out"/icons/*.png
