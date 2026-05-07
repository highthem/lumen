#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

for tool in ffprobe ffmpeg afinfo jq shasum; do
  command -v "$tool" >/dev/null || {
    echo "error: missing required tool: $tool" >&2
    exit 1
  }
done

manifest="Apple/lumen/Shared/Resources/Sounds/Sounds.json"
test -f "$manifest"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

jq -c '.sounds[]' "$manifest" | while read -r sound; do
  id="$(jq -r '.id' <<<"$sound")"
  kind="$(jq -r '.kind' <<<"$sound")"
  filename="$(jq -r '.filename' <<<"$sound")"
  expected_duration="$(jq -r '.durationSeconds' <<<"$sound")"
  target_lufs="$(jq -r '.lufsTarget' <<<"$sound")"

  if [[ "$kind" == "alarm" ]]; then
    design_path="Design/sound-kit/alarms/$filename"
    app_path="Apple/lumen/Shared/Resources/Sounds/Alarm/$filename"
    codec_pattern="pcm_s16le"
  else
    design_path="Design/sound-kit/breathing/$filename"
    app_path="Apple/lumen/Shared/Resources/Sounds/Breathing/$filename"
    codec_pattern="aac"
  fi

  for audio_path in "$design_path" "$app_path"; do
    test -f "$audio_path" || {
      echo "error: missing $audio_path" >&2
      exit 1
    }
    size="$(wc -c < "$audio_path" | tr -d ' ')"
    if (( size > 5000000 )); then
      echo "error: $audio_path exceeds 5 MB ($size bytes)" >&2
      exit 1
    fi

    ffprobe -v error \
      -select_streams a:0 \
      -show_entries stream=codec_name,sample_rate,channels \
      -of json "$audio_path" > "$tmp/probe.json"
    codec="$(jq -r '.streams[0].codec_name' "$tmp/probe.json")"
    sample_rate="$(jq -r '.streams[0].sample_rate' "$tmp/probe.json")"
    channels="$(jq -r '.streams[0].channels' "$tmp/probe.json")"
    [[ "$codec" == "$codec_pattern" ]] || {
      echo "error: $audio_path codec is $codec, expected $codec_pattern" >&2
      exit 1
    }
    [[ "$sample_rate" == "44100" ]] || {
      echo "error: $audio_path sample rate is $sample_rate, expected 44100" >&2
      exit 1
    }
    (( channels >= 1 && channels <= 2 )) || {
      echo "error: $audio_path channel count is $channels" >&2
      exit 1
    }

    duration="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$audio_path")"
    awk -v actual="$duration" -v expected="$expected_duration" -v id="$id" 'BEGIN {
      delta = actual - expected
      if (delta < 0) delta = -delta
      if (delta > 0.25) {
        printf("error: %s duration %.3f, expected %.3f\n", id, actual, expected) > "/dev/stderr"
        exit 1
      }
    }'
    afinfo "$audio_path" >/dev/null

    lufs_log="$tmp/$id-lufs.log"
    ffmpeg -hide_banner -nostats -i "$audio_path" -filter_complex ebur128 -f null - >"$lufs_log" 2>&1
    measured="$(awk '/I:/{value=$2} END{print value}' "$lufs_log")"
    awk -v actual="$measured" -v expected="$target_lufs" -v id="$id" 'BEGIN {
      delta = actual - expected
      if (delta < 0) delta = -delta
      if (delta > 1.0) {
        printf("error: %s loudness %.2f LUFS, expected %.2f (+/-1)\n", id, actual, expected) > "/dev/stderr"
        exit 1
      }
    }'
  done
done

if [[ -n "${SUNOAPI_KEY:-}" ]]; then
  if rg -F "$SUNOAPI_KEY" . >/dev/null; then
    echo "error: SUNOAPI_KEY value found in repository files" >&2
    exit 1
  fi
fi

echo "sound kit validation passed"
