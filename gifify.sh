GIFIFY_VERSION="1.0.0"

gifify() {
  if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed! Installing ffmpeg..."
    brew install ffmpeg
  fi

  if [[ -z "$1" ]]; then
    echo "Usage: gifify <video_file> [--1080p|--720p|--480p]"
    return 1
  fi

  local input="$1"
  local filename=$(basename "$input")
  local name="${filename%.*}"
  local output_dir="$HOME/Desktop/gifified"
  mkdir -p "$output_dir"
  local output="${output_dir}/${name}.gif"

  local width="1920"  # Default: 1080p width

  if [[ "$*" == *"--720p"* ]]; then
    width="1280"
  elif [[ "$*" == *"--480p"* ]]; then
    width="854"
  fi

  echo "Generating GIF from $input with width $width..."

  # Generate a color palette for accurate colors
  ffmpeg -y -i "$input" -vf "fps=15,scale=${width}:-1:flags=lanczos,palettegen" /tmp/palette.png

  # Create the GIF using the generated palette
  ffmpeg -y -i "$input" -i /tmp/palette.png -filter_complex "fps=15,scale=${width}:-1:flags=lanczos[x];[x][1:v]paletteuse" "$output"

  echo "GIF created at: $output"
}
