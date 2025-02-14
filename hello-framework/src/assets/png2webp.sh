#!/bin/zsh
# Convert all PNG files in a directory to WebP
for file in "$1"/*.png; do
  [ -f "$file" ] || continue
  output="${file%.png}.webp"
  cwebp "$file" -o "$output"
done
# Remove all PNG files in the directory
rm "$1"/*.png
