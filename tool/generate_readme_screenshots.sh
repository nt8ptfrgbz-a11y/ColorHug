#!/bin/sh

set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"

flutter test tool/readme_screenshot_test.dart --update-goldens

for screen_name in island palette detective repair studio gallery guardian ultra-camp monster-select monster-battle ultra-radar ultra-beam ultra-rescue; do
  ffmpeg \
    -y \
    -v error \
    -i docs/images/color-hug-home.png \
    -i "docs/images/.raw-color-hug-${screen_name}.png" \
    -filter_complex \
      '[0:v]format=rgba[frame];[1:v]format=rgba[screen];[frame][screen]overlay=56:70:format=auto,format=rgba' \
    -frames:v 1 \
    "docs/images/color-hug-${screen_name}.png"
done

rm -f \
  docs/images/.raw-color-hug-island.png \
  docs/images/.raw-color-hug-palette.png \
  docs/images/.raw-color-hug-detective.png \
  docs/images/.raw-color-hug-repair.png \
  docs/images/.raw-color-hug-studio.png \
  docs/images/.raw-color-hug-gallery.png \
  docs/images/.raw-color-hug-guardian.png \
  docs/images/.raw-color-hug-ultra-camp.png \
  docs/images/.raw-color-hug-monster-select.png \
  docs/images/.raw-color-hug-monster-battle.png \
  docs/images/.raw-color-hug-ultra-radar.png \
  docs/images/.raw-color-hug-ultra-beam.png \
  docs/images/.raw-color-hug-ultra-rescue.png

echo "README screenshots updated in docs/images/."
