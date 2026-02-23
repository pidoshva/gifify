#!/usr/bin/env bash
# gifify — convert videos to optimized GIFs using ffmpeg's two-pass palette technique
# https://github.com/pidoshva/gifify

GIFIFY_VERSION="1.1.0"

_gifify_ensure_ffmpeg() {
    command -v ffmpeg >/dev/null 2>&1 && return 0

    echo "Error: ffmpeg is not installed." >&2
    echo "" >&2

    local pkg_cmd=""
    if command -v brew >/dev/null 2>&1; then
        pkg_cmd="brew install ffmpeg"
    elif command -v apt-get >/dev/null 2>&1; then
        pkg_cmd="sudo apt-get update && sudo apt-get install -y ffmpeg"
    elif command -v dnf >/dev/null 2>&1; then
        pkg_cmd="sudo dnf install -y ffmpeg"
    elif command -v pacman >/dev/null 2>&1; then
        pkg_cmd="sudo pacman -S --noconfirm ffmpeg"
    fi

    if [ -n "$pkg_cmd" ]; then
        printf "Install ffmpeg now with: %s ? [y/N] " "$pkg_cmd" >&2
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            eval "$pkg_cmd" || { echo "ffmpeg installation failed." >&2; return 1; }
            return 0
        fi
    fi

    echo "Please install ffmpeg manually and try again." >&2
    return 1
}

gifify() {
    # ── Help & version ──────────────────────────────────────────────
    local _gifify_usage
    _gifify_usage="Usage: gifify <video_file> [options]

Options:
  -o, --output <path>   Output file path (default: ~/Desktop/gifified/<name>.gif)
  --fps <n>             Frames per second (default: 15)
  --1080p               Scale to 1920px width (default)
  --720p                Scale to 1280px width
  --480p                Scale to 854px width
  --360p                Scale to 640px width
  -h, --help            Show this help message
  -v, --version         Show version"

    # ── Parse arguments ─────────────────────────────────────────────
    local input="" output="" fps=15 width=1920

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                echo "$_gifify_usage"
                return 0
                ;;
            -v|--version)
                echo "gifify $GIFIFY_VERSION"
                return 0
                ;;
            -o|--output)
                if [ -z "${2:-}" ]; then
                    echo "Error: --output requires a path argument." >&2
                    return 1
                fi
                output="$2"
                shift 2
                ;;
            --fps)
                if [ -z "${2:-}" ]; then
                    echo "Error: --fps requires a numeric argument." >&2
                    return 1
                fi
                fps="$2"
                shift 2
                ;;
            --1080p) width=1920; shift ;;
            --720p)  width=1280; shift ;;
            --480p)  width=854;  shift ;;
            --360p)  width=640;  shift ;;
            -*)
                echo "Error: unknown option '$1'" >&2
                echo "$_gifify_usage" >&2
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                else
                    echo "Error: unexpected argument '$1'" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done

    # ── Validate input ──────────────────────────────────────────────
    if [ -z "$input" ]; then
        echo "$_gifify_usage" >&2
        return 1
    fi

    if [ ! -e "$input" ]; then
        echo "Error: file not found: $input" >&2
        return 1
    fi

    if [ ! -f "$input" ]; then
        echo "Error: not a regular file: $input" >&2
        return 1
    fi

    # ── Check ffmpeg ────────────────────────────────────────────────
    _gifify_ensure_ffmpeg || return 1

    # ── Resolve output path ─────────────────────────────────────────
    if [ -z "$output" ]; then
        local filename name output_dir
        filename="$(basename "$input")"
        name="${filename%.*}"
        output_dir="$HOME/Desktop/gifified"
        mkdir -p "$output_dir"
        output="${output_dir}/${name}.gif"
    fi

    # ── Safe temp file with trap ────────────────────────────────────
    local palette
    palette="$(mktemp "${TMPDIR:-/tmp}/gifify_palette_XXXXXX.png")"

    # Save any existing EXIT trap, set ours, restore after
    local _old_trap
    _old_trap="$(trap -p EXIT)"
    trap 'rm -f "$palette"' EXIT

    # ── Pass 1: generate palette ────────────────────────────────────
    echo "[1/2] Generating palette..."
    if ! ffmpeg -y -i "$input" \
        -vf "fps=${fps},scale=${width}:-1:flags=lanczos,palettegen" \
        "$palette" \
        -loglevel error -stats; then
        echo "Error: palette generation failed." >&2
        rm -f "$palette"
        eval "$_old_trap"
        return 1
    fi

    # ── Pass 2: create GIF ──────────────────────────────────────────
    echo "[2/2] Creating GIF..."
    if ! ffmpeg -y -i "$input" -i "$palette" \
        -filter_complex "fps=${fps},scale=${width}:-1:flags=lanczos[x];[x][1:v]paletteuse" \
        "$output" \
        -loglevel error -stats; then
        echo "Error: GIF creation failed." >&2
        rm -f "$palette"
        eval "$_old_trap"
        return 1
    fi

    # ── Cleanup & report ────────────────────────────────────────────
    rm -f "$palette"
    eval "$_old_trap"

    local size
    if stat --version >/dev/null 2>&1; then
        # GNU stat
        size="$(stat -c%s "$output" 2>/dev/null)"
    else
        # BSD stat (macOS)
        size="$(stat -f%z "$output" 2>/dev/null)"
    fi

    if [ -n "$size" ]; then
        local human_size
        if [ "$size" -ge 1048576 ]; then
            human_size="$(awk "BEGIN {printf \"%.1f MB\", $size/1048576}")"
        else
            human_size="$(awk "BEGIN {printf \"%.0f KB\", $size/1024}")"
        fi
        echo "Done! $output ($human_size)"
    else
        echo "Done! $output"
    fi
}

# Allow running as a script: ./gifify.sh [args]
if [ "${BASH_SOURCE[0]}" = "$0" ] 2>/dev/null; then
    gifify "$@"
fi
