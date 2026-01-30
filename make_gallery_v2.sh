#!/usr/bin/env bash
set -e

# Usage: ./make_gallery.sh
#
# Run in a directory with a "papes/" subdirectory, and it will create a
# "thumbnails/" subdirectory.

# Detect ImageMagick
IMG_TOOL=$(command -v magick || command -v convert)
[[ -z "$IMG_TOOL" ]] && { echo "Error: ImageMagick not found." >&2; exit 1; }

# Detect the best sort command for natural/version sorting
if [ "$(uname)" = "Darwin" ] && command -v gsort >/dev/null 2>&1; then
    SORT_CMD="gsort -V"
elif sort -V /dev/null >/dev/null 2>&1; then
    SORT_CMD="sort -V"
else
    SORT_CMD="sort"
fi

mv thumbnails thumbnails_old 2>/dev/null || true
mkdir -p thumbnails

printf "# Steve's Wallpaper Collection" >README.md
printf "" >>README.md
printf "I have collected these wallpapers over a number of years. This is my entire wallpaper directory for those that want/need them. Created with a slightly modified version of [make_gallery.sh](https://github.com/jonascarpay/Wallpapers/blob/master/make_gallery.sh) script by Jonas Carpay." >>README.md
printf "## Where did I get these?" >>README.md
printf "I find wallpapers in a number of different locations but good places to check out include [Imgur](https://imgur.com/) and [/wg/](https://boards.4chan.org/wg/). Some of the wallpapers are from other people's wallpaper repos namely [Jonas Carpay](https://github.com/jonascarpay/Wallpapers), [MAKC](https://github.com/makccr/wallpapers), [DistroTube](https://gitlab.com/dwt1/wallpapers), [Christian Chiarulli](https://github.com/ChristianChiarulli/wallpapers), and [Gavin Freeborn](https://github.com/Gavinok/wallpapers). [Some](https://www.eff.org/pages/eff-screen-lock-images-new-logo) are [also](https://www.eff.org/deeplinks/2020/03/cc-backgrounds-video-calls-eff) from the EFF." >>README.md
printf "## Ownership" >>README.md
printf "Since I got these mostly from sites like [Imgur](https://imgur.com/), [/wg/](https://boards.4chan.org/wg/), and [pixiv](https://www.pixiv.net/en/), I have no way of knowing if there is a copyright on these images. If you find an image hosted in this repository that is yours and of limited use, please let me know and I will remove it." >>README.md
printf "" >>README.md
printf "## My current wallpaper rotation" >>README.md
printf "" >>README.md

total=$(git ls-files papes/ --cached --others --exclude-standard | wc -l | tr -d ' ')
i=0
bar_size=20  # Length of the progress bar in characters

echo "🚀 Generating Gallery..."

while read -r -d $'\0' src; do
    i=$((i + 1))
    filename="$(basename "$src")"

    # Calculate progress bar stats
    percent=$(( i * 100 / total ))
    filled=$(( i * bar_size / total ))
    empty=$(( bar_size - filled ))

    # Build the bar string
    bar=$(printf "%${filled}s" | tr ' ' '█')
    dots=$(printf "%${empty}s" | tr ' ' '░')

    # \r = back to start, \033[K = clear line
    # UI: [███░░░] 15% (3/20) Processing: image.jpg
    printf "\r\033[K[%s%s] %3d%% (%d/%d) %s" "$bar" "$dots" "$percent" "$i" "$total" "$filename"

    target="${src/papes/thumbnails}"
    old_thumb="${src/papes/thumbnails_old}"

    if [[ -f "$old_thumb" ]]; then
        mv "$old_thumb" "$target"
    else
        "$IMG_TOOL" "$src" -resize 200x "$target"
    fi

    esc_name="${filename// /%20}"
    printf "[![%s](thumbnails/%s)](papes/%s)\n" "$filename" "$esc_name" "$esc_name" >> README.md

done < <(git ls-files papes/ -z --cached --others --exclude-standard | tr '\0' '\n' | $SORT_CMD | tr '\n' '\0')

printf "\n\033[0;32m✅ Gallery Complete!\033[0m\n"
rm -rf thumbnails_old

# Git Logic {{{
printf "Staging changes..."
# -A to ensure deletions are staged before calculating the count
git add -A .

# Calculate Added/Modified and Deleted counts from the index
# A = Added (including new files staged), D = Deleted
added=$(git status --porcelain | grep -c '^[AM]' || true)
deleted=$(git status --porcelain | grep -c '^D ' || true)

if git diff --cached --quiet; then
    echo "✨ Gallery is already up to date. No changes to commit."
else
    # Choose a random emoji for flavor
    EMOJIS=("🏞️" "🌄" "🎨" "📷" "🌅" "🖼️" "🌟" "✨")
    RAND_EMOJI=${EMOJIS[$RANDOM % ${#EMOJIS[@]}]}

    # Formatting: 🏞️ 🟢 +4  🔴 -2  |  📅 2024-01-30 14:20
    TIME=$(date +'%Y-%m-%d %H:%M')
    MSG="$RAND_EMOJI | 🟢 +$added; 🔴 -$deleted"

    git commit -m "$MSG"
    echo "Committed locally with message: $MSG. Ready to push!"
fi
# }}} "Git logic

# vim: set fdm=marker fmr={{{,}}}:
