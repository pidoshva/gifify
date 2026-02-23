#!/usr/bin/env bash
# gifify — convert videos to optimized GIFs using ffmpeg's two-pass palette technique
# https://github.com/pidoshva/gifify

GIFIFY_VERSION="1.1.0"

# ── Colors (auto-disabled when not a terminal) ─────────────────────
if [ -t 1 ]; then
    _CLR_RESET='\033[0m'
    _CLR_BOLD='\033[1m'
    _CLR_DIM='\033[2m'
    _CLR_RED='\033[0;31m'
    _CLR_GREEN='\033[0;32m'
    _CLR_YELLOW='\033[0;33m'
    _CLR_CYAN='\033[0;36m'
else
    _CLR_RESET='' _CLR_BOLD='' _CLR_DIM=''
    _CLR_RED='' _CLR_GREEN='' _CLR_YELLOW='' _CLR_CYAN=''
fi

_gifify_log()   { printf "${_CLR_CYAN}  ▸${_CLR_RESET} %s\n" "$*"; }
_gifify_ok()    { printf "${_CLR_GREEN}  ✔${_CLR_RESET} %s\n" "$*"; }
_gifify_warn()  { printf "${_CLR_YELLOW}  ⚠${_CLR_RESET} %s\n" "$*" >&2; }
_gifify_err()   { printf "${_CLR_RED}  ✖${_CLR_RESET} %s\n" "$*" >&2; }
_gifify_dim()   { printf "${_CLR_DIM}    %s${_CLR_RESET}\n" "$*"; }
_gifify_step()  { printf "\n${_CLR_BOLD}  [%s]${_CLR_RESET} %s\n" "$1" "$2"; }

_gifify_ensure_ffmpeg() {
    command -v ffmpeg >/dev/null 2>&1 && return 0

    _gifify_err "ffmpeg is not installed"
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
        printf "  Install now with: %s ? [y/N] " "$pkg_cmd" >&2
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            eval "$pkg_cmd" || { _gifify_err "ffmpeg installation failed"; return 1; }
            return 0
        fi
    fi

    _gifify_warn "Please install ffmpeg manually and try again"
    return 1
}

_gifify_human_size() {
    local bytes="$1"
    if [ "$bytes" -ge 1073741824 ]; then
        awk "BEGIN {printf \"%.2f GB\", $bytes/1073741824}"
    elif [ "$bytes" -ge 1048576 ]; then
        awk "BEGIN {printf \"%.1f MB\", $bytes/1048576}"
    elif [ "$bytes" -ge 1024 ]; then
        awk "BEGIN {printf \"%.0f KB\", $bytes/1024}"
    else
        echo "${bytes} B"
    fi
}

_gifify_file_size() {
    if stat --version >/dev/null 2>&1; then
        stat -c%s "$1" 2>/dev/null
    else
        stat -f%z "$1" 2>/dev/null
    fi
}

_gifify_duration() {
    ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$1" 2>/dev/null
}

_gifify_resolution() {
    ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height \
        -of csv=s=x:p=0 "$1" 2>/dev/null
}

_gifify_elapsed() {
    local secs="$1"
    if [ "$secs" -ge 60 ]; then
        printf "%dm %ds" $((secs / 60)) $((secs % 60))
    else
        printf "%ds" "$secs"
    fi
}

_gifify_width_label() {
    case "$1" in
        1920) echo "1080p" ;;
        1280) echo "720p"  ;;
        854)  echo "480p"  ;;
        640)  echo "360p"  ;;
        *)    echo "${1}px" ;;
    esac
}

_gifify_spinner_start() {
    local msg="$1"
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    (
        local i=0
        while true; do
            local frame="${frames:i%${#frames}:1}"
            printf "\r${_CLR_CYAN}  %s${_CLR_RESET} ${_CLR_DIM}%s${_CLR_RESET}" "$frame" "$msg"
            i=$((i + 1))
            sleep 0.08
        done
    ) &
    _GIFIFY_SPINNER_PID=$!
}

_gifify_spinner_update() {
    if [ -n "${_GIFIFY_SPINNER_PID:-}" ] && kill -0 "$_GIFIFY_SPINNER_PID" 2>/dev/null; then
        printf "\r\033[2K${_CLR_CYAN}  ⠿${_CLR_RESET} ${_CLR_DIM}%s${_CLR_RESET}" "$1"
    fi
}

_gifify_spinner_stop() {
    if [ -n "${_GIFIFY_SPINNER_PID:-}" ]; then
        kill "$_GIFIFY_SPINNER_PID" 2>/dev/null
        wait "$_GIFIFY_SPINNER_PID" 2>/dev/null
        unset _GIFIFY_SPINNER_PID
        printf "\r\033[2K"
    fi
}

_gifify_progress_bar() {
    local pct="$1" width=20
    local filled=$((pct * width / 100))
    local empty=$((width - filled))
    local bar=""
    local i
    for ((i = 0; i < filled; i++)); do bar+="█"; done
    for ((i = 0; i < empty; i++)); do bar+="░"; done
    printf "%s %3d%%" "$bar" "$pct"
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
                    _gifify_err "--output requires a path argument"
                    return 1
                fi
                output="$2"
                shift 2
                ;;
            --fps)
                if [ -z "${2:-}" ]; then
                    _gifify_err "--fps requires a numeric argument"
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
                _gifify_err "unknown option '$1'"
                echo "$_gifify_usage" >&2
                return 1
                ;;
            *)
                if [ -z "$input" ]; then
                    input="$1"
                else
                    _gifify_err "unexpected argument '$1'"
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
        _gifify_err "file not found: $input"
        return 1
    fi

    if [ ! -f "$input" ]; then
        _gifify_err "not a regular file: $input"
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

    # ── Banner ──────────────────────────────────────────────────────
    printf "\n${_CLR_BOLD}  gifify${_CLR_RESET} ${_CLR_DIM}v%s${_CLR_RESET}\n" "$GIFIFY_VERSION"
    printf "  %s\n" "─────────────────────────────────────"

    # ── Input details ───────────────────────────────────────────────
    local input_size input_dur input_res
    input_size="$(_gifify_file_size "$input")"
    input_dur="$(_gifify_duration "$input")"
    input_res="$(_gifify_resolution "$input")"

    _gifify_log "Input:      $(basename "$input")"
    if [ -n "$input_size" ]; then
        _gifify_dim "Size:       $(_gifify_human_size "$input_size")"
    fi
    if [ -n "$input_res" ]; then
        _gifify_dim "Resolution: $input_res"
    fi
    if [ -n "$input_dur" ]; then
        local dur_secs
        dur_secs="$(printf '%.0f' "$input_dur" 2>/dev/null)" || dur_secs=""
        if [ -n "$dur_secs" ] && [ "$dur_secs" -gt 0 ] 2>/dev/null; then
            _gifify_dim "Duration:   $(_gifify_elapsed "$dur_secs")"
        fi
    fi

    _gifify_log "Output:     $output"
    _gifify_log "Settings:   $(_gifify_width_label "$width"), ${fps} fps"

    # ── Safe temp file with trap ────────────────────────────────────
    local palette
    palette="$(mktemp "${TMPDIR:-/tmp}/gifify_palette_XXXXXX.png")"

    local _old_trap
    _old_trap="$(trap -p EXIT)"
    trap 'rm -f "$palette"' EXIT

    # Get total duration in microseconds for progress calculation
    local total_us=0
    if [ -n "$input_dur" ]; then
        total_us="$(awk "BEGIN {printf \"%.0f\", $input_dur * 1000000}" 2>/dev/null)" || total_us=0
    fi

    local t_start t_end

    # ── Pass 1: generate palette ────────────────────────────────────
    _gifify_step "1/2" "Generating color palette..."
    _gifify_dim "Analyzing video frames for optimal 256-color palette"
    t_start="$(date +%s)"
    _gifify_spinner_start "Extracting color data..."
    if ! ffmpeg -y -i "$input" \
        -vf "fps=${fps},scale=${width}:-1:flags=lanczos,palettegen" \
        "$palette" \
        -loglevel error -progress pipe:1 2>&1 | while IFS='=' read -r key val; do
            if [ "$key" = "out_time_ms" ] && [ -n "$val" ] && [ "$total_us" -gt 0 ] 2>/dev/null; then
                local pct=$(( (val * 100) / total_us ))
                [ "$pct" -gt 100 ] && pct=100
                _gifify_spinner_update "Palette  $(_gifify_progress_bar "$pct")"
            fi
        done; then
        _gifify_spinner_stop
        _gifify_err "Palette generation failed"
        rm -f "$palette"
        eval "$_old_trap"
        return 1
    fi
    _gifify_spinner_stop
    t_end="$(date +%s)"
    _gifify_ok "Palette ready ($(_gifify_elapsed $((t_end - t_start))))"

    # ── Pass 2: create GIF ──────────────────────────────────────────
    _gifify_step "2/2" "Encoding GIF with palette..."
    _gifify_dim "Applying Lanczos resampling at $(_gifify_width_label "$width")"
    t_start="$(date +%s)"
    _gifify_spinner_start "Encoding frames..."
    if ! ffmpeg -y -i "$input" -i "$palette" \
        -filter_complex "fps=${fps},scale=${width}:-1:flags=lanczos[x];[x][1:v]paletteuse" \
        "$output" \
        -loglevel error -progress pipe:1 2>&1 | while IFS='=' read -r key val; do
            if [ "$key" = "out_time_ms" ] && [ -n "$val" ] && [ "$total_us" -gt 0 ] 2>/dev/null; then
                local pct=$(( (val * 100) / total_us ))
                [ "$pct" -gt 100 ] && pct=100
                _gifify_spinner_update "Encoding $(_gifify_progress_bar "$pct")"
            fi
        done; then
        _gifify_spinner_stop
        _gifify_err "GIF encoding failed"
        rm -f "$palette"
        eval "$_old_trap"
        return 1
    fi
    _gifify_spinner_stop
    t_end="$(date +%s)"
    _gifify_ok "Encoding complete ($(_gifify_elapsed $((t_end - t_start))))"

    # ── Cleanup & report ────────────────────────────────────────────
    rm -f "$palette"
    eval "$_old_trap"

    local output_size
    output_size="$(_gifify_file_size "$output")"

    printf "\n  %s\n" "─────────────────────────────────────"
    if [ -n "$output_size" ]; then
        local human_out
        human_out="$(_gifify_human_size "$output_size")"
        printf "  ${_CLR_GREEN}${_CLR_BOLD}Done!${_CLR_RESET} %s ${_CLR_DIM}(%s)${_CLR_RESET}\n" "$output" "$human_out"

        # Show size comparison if we have input size
        if [ -n "$input_size" ] && [ "$input_size" -gt 0 ] 2>/dev/null; then
            if [ "$output_size" -lt "$input_size" ]; then
                local ratio
                ratio="$(awk "BEGIN {printf \"%.1f\", $input_size/$output_size}" 2>/dev/null)"
                [ -n "$ratio" ] && _gifify_dim "Compressed ${ratio}x from original ($(_gifify_human_size "$input_size"))"
            elif [ "$output_size" -gt "$input_size" ]; then
                local ratio
                ratio="$(awk "BEGIN {printf \"%.1f\", $output_size/$input_size}" 2>/dev/null)"
                [ -n "$ratio" ] && _gifify_dim "GIF is ${ratio}x larger than source ($(_gifify_human_size "$input_size"))"
            fi
        fi
    else
        printf "  ${_CLR_GREEN}${_CLR_BOLD}Done!${_CLR_RESET} %s\n" "$output"
    fi
    echo ""
}

# Allow running as a script: ./gifify.sh [args]
if [ "${BASH_SOURCE[0]}" = "$0" ] 2>/dev/null; then
    gifify "$@"
fi
