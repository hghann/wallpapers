#!/usr/bin/env bash
set -e

# Usage: ./make_gallery.sh
#
# Run in a directory with a "papes/" subdirectory, and it will create a
# "thumbnails/" subdirectory.

# Detect ImageMagick version and set the appropriate command
if command -v magick &> /dev/null; then
    IMG_TOOL="magick"
elif command -v convert &> /dev/null; then
    IMG_TOOL="convert"
else
    echo "Error: ImageMagick (magick or convert) is not installed." >&2
    exit 1
fi

# Detect the best sort command for natural/version sorting
if [ "$(uname)" = "Darwin" ] && command -v gsort >/dev/null 2>&1; then
    # On Mac, use gsort (GNU Sort) if installed via Homebrew
    SORT_CMD="gsort -V"
elif sort -V /dev/null >/dev/null 2>&1; then
    # On Linux (and some Macs), check if native sort supports -V
    SORT_CMD="sort -V"
else
    # Fallback to standard sort (will jump from 1 to 10 when generating thumbs)
    SORT_CMD="sort"
fi

mv thumbnails thumbnails_old 2>/dev/null || true
mkdir -p thumbnails

echo "# Steve's Wallpaper Collection" >README.md
echo "" >>README.md
echo "I have collected these wallpapers over a number of years. This is my entire wallpaper directory for those that want/need them. Created with a slightly modified version of [make_gallery.sh](https://github.com/jonascarpay/Wallpapers/blob/master/make_gallery.sh) script by Jonas Carpay. POSIX compliant rewrite can be found in /bin; v2 has a nice progress bar instead of a text dump (working on making it more performant and fixing some parsing errors)." >>README.md
echo "## Where did I get these?" >>README.md
echo "I find wallpapers in a number of different locations but good places to check out include [Imgur](https://imgur.com/) and [/wg/](https://boards.4chan.org/wg/). Some of the wallpapers are from other people's wallpaper repos namely [Jonas Carpay](https://github.com/jonascarpay/Wallpapers), [MAKC](https://github.com/makccr/wallpapers), [DistroTube](https://gitlab.com/dwt1/wallpapers), [Christian Chiarulli](https://github.com/ChristianChiarulli/wallpapers), and [Gavin Freeborn](https://github.com/Gavinok/wallpapers). [Some](https://www.eff.org/pages/eff-screen-lock-images-new-logo) are [also](https://www.eff.org/deeplinks/2020/03/cc-backgrounds-video-calls-eff) from the EFF." >>README.md
echo "## Ownership" >>README.md
echo "Since I got these mostly from sites like [Imgur](https://imgur.com/), [/wg/](https://boards.4chan.org/wg/), and [pixiv](https://www.pixiv.net/en/), I have no way of knowing if there is a copyright on these images. If you find an image hosted in this repository that is yours and of limited use, please let me know and I will remove it." >>README.md
echo "" >>README.md
echo "## My current wallpaper rotation" >>README.md
echo "" >>README.md

# Get the total count first
total=$(git ls-files papes/ | wc -l)

i=0

# Use git ls-files to find images; -z handles filenames with spaces safely
# Include tracked (--cached) and new untracked (--others) files
# sort -V (natural sort) handles the 1, 2, 10, 100 sequence correctly
git ls-files papes/ --cached --others --exclude-standard -z | tr '\0' '\n' | \
    $SORT_CMD | tr '\n' '\0' | while read -r -d $'\0' src; do
	    ((i++)) || true
	    filename="$(basename "$src")"
    	printf '%4d/%d: %s... ' "$i" "$total" "$filename"

    	target="${src/papes/thumbnails}"
    	thumbnail_old="${src/papes/thumbnails_old}"
    	if [[ ! -f "$thumbnail_old" ]]; then
            # IMv6 syntax: convert [options] [input] [output]
            # IMv7 syntax: magick [input] [options] [output], this order also
            # compatible with older IMv6 (convert)
            $IMG_TOOL "$src" -resize 200x "${src/papes/thumbnails}"
    		echo "converted!"
    	else
    		mv "$thumbnail_old" "$target"
    		echo "skipped!"
    	fi

        # URL escaping for the README
    	filename_escaped="${filename// /%20}"
    	thumb_url="thumbnails/$filename_escaped"
    	pape_url="papes/$filename_escaped"

    	echo "[![$filename]($thumb_url)]($pape_url)" >>README.md
done

rm -rf thumbnails_old

# Git Logic {{{
echo "Staging changes..."
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
    MSG="$RAND_EMOJI  |  🟢 +$added;  🔴 -$deleted"

    git commit -m "$MSG"
    echo "Committed locally with message: $MSG. Ready to push!"
fi
# }}} "Git logic

# vim: set fdm=marker fmr={{{,}}}:
