#!/bin/bash
#
# setup-wallpapers.sh — point the Third Impact theme at your own wallpaper
# folder (default: ~/Pictures/Wallpapers).
#
# Omarchy looks for a theme's user wallpapers in
#     ~/.config/omarchy/backgrounds/<theme-slug>/
# This script fills that folder with symlinks to the images in your wallpaper
# folder, so the theme cycles through your personal collection.
#
# Usage:
#   ./setup-wallpapers.sh                     # sync from ~/Pictures/Wallpapers
#   WALLPAPER_DIR=/path/to/walls ./setup-wallpapers.sh
#
set -euo pipefail

THEME_SLUG="third-impact"
DEFAULT_SOURCE="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
DEST="${HOME}/.config/omarchy/backgrounds/${THEME_SLUG}"

# Image extensions Omarchy's picker accepts.
IMAGE_EXTS=("jpg" "jpeg" "png" "gif" "bmp" "webp")

if [[ ! -d "$DEFAULT_SOURCE" ]]; then
  echo "error: wallpaper source not found: $DEFAULT_SOURCE" >&2
  echo "pass the correct folder with: WALLPAPER_DIR=/path/to/walls $0" >&2
  exit 1
fi

mkdir -p "$DEST"

# Make sure the theme's own Evangelion wallpapers are in the source folder too,
# so they show up in the rotation even if the user never downloaded them.
for img in "$(dirname "$0")"/backgrounds/*; do
  [[ -f "$img" ]] || continue
  cp -n "$img" "$DEFAULT_SOURCE/" 2>/dev/null || true
done

linked=0
for ext in "${IMAGE_EXTS[@]}"; do
  shopt -s nullglob
  for img in "$DEFAULT_SOURCE"/*."$ext" "$DEFAULT_SOURCE"/*."${ext^^}"; do
    [[ -f "$img" ]] || continue
    name=$(basename "$img")
    ln -sf "$img" "$DEST/$name"
    linked=$((linked + 1))
  done
  shopt -u nullglob
done

if (( linked == 0 )); then
  echo "no images found in $DEFAULT_SOURCE"
  exit 0
fi

echo "linked $linked wallpaper(s) from $DEFAULT_SOURCE"
echo "into $DEST"
echo "re-apply the theme to start a new rotation:"
echo "  omarchy theme set \"Third Impact\""
