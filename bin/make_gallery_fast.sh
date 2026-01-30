#!/bin/sh
# Strictly POSIX compliant gallery generator

set -e

# Detect ImageMagick
IMG_TOOL=$(command -v magick || command -v convert)
if [ -z "$IMG_TOOL" ]; then
    printf "Error: ImageMagick not found\n" >&2
    exit 1
fi

# Detect Sort (macOS gsort vs Linux sort)
if [ "$(uname)" = "Darwin" ] && command -v gsort >/dev/null 2>&1; then
    SORT_CMD="gsort -V"
elif sort -V /dev/null >/dev/null 2>&1; then
    SORT_CMD="sort -V"
else
    SORT_CMD="sort"
fi

mv thumbnails thumbnails_old 2>/dev/null || :
mkdir -p thumbnails

printf "## My current wallpaper rotation\n\n" > README.md

# Get total count (Standard POSIX wc)
total=$(git ls-files papes/ --cached --others --exclude-standard | wc -l | tr -d ' ')
i=0
bar_size=20

printf "🚀 Generating Gallery...\n"

# Pure POSIX - No forks, no sed, no basename
for src in $files; do
    i=$((i + 1))

    # Fast string manipulation (Built-in)
    filename=${src#papes/}
    target="thumbnails/$filename"
    old_thumb="thumbnails_old/$filename"

    # Only run sed if the filename actually has a space
    case "$filename" in
        *" "*) esc_name=$(printf '%s' "$filename" | sed 's/ /%20/g') ;;
        *)     esc_name=$filename ;;
    esac

    [ -f "$old_thumb" ] && mv "$old_thumb" "$target" || "$IMG_TOOL" "$src" -resize 200x "$target"

    printf "[![%s](thumbnails/%s)](papes/%s)\n" "$filename" "$esc_name" "$esc_name" >> README.md
done

printf "\n\033[0;32m✅ Gallery Complete!\033[0m\n"
rm -rf thumbnails_old

# --- Git Logic ---
git add -A .
added=$(git status --porcelain | grep -c '^[AM]' || :)
deleted=$(git status --porcelain | grep -c '^D ' || :)

if git diff --cached --quiet; then
    printf "✨ Gallery is already up to date.\n"
else
    # POSIX Random Emoji Logic
    set -- "🏞️" "🌄" "🎨" "📷" "🌅" "🖼️" "🌟" "✨"
    seed=$(date +%s)
    shift $((seed % $#))
    RAND_EMOJI=$1

    TIME=$(date +'%Y-%m-%d %H:%M')
    MSG="$RAND_EMOJI | 🟢 +$added; 🔴 -$deleted | $TIME"
    git commit -m "$MSG"
    printf "Committed: %s\n" "$MSG"
fi

