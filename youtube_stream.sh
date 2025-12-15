#!/usr/bin/env bash
set -euo pipefail

VIDEO="/home/gavinadamsdev/radio/youtube/loop.mp4"
ICECAST_URL="http://localhost:8000/radio.mp3"

NOW="/home/gavinadamsdev/radio/nowplaying.txt"
TIME="/home/gavinadamsdev/radio/time.txt"
SCHED="/home/gavinadamsdev/radio/schedule.txt"

FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

RTMP_URL='rtmp://a.rtmp.youtube.com/live2/6s2p-ku56-wqf1-7k40-d4ja'

# how often to check Icecast health (seconds)
CHECK_EVERY=5

is_icecast_up() {
  # Quick health check: status endpoint OR stream endpoint
  curl -fsS --max-time 2 "http://localhost:8000/status-json.xsl" >/dev/null 2>&1
}

run_ffmpeg_normal() {
  echo "[youtube] starting NORMAL mode (Icecast audio)"
  /usr/bin/ffmpeg \
    -hide_banner -loglevel info \
    -stream_loop -1 -re -i "$VIDEO" \
    -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 5 \
    -i "$ICECAST_URL" \
    -filter_complex "\
[0:v]scale=640:360,fps=8[v0]; \
[v0]drawtext=fontfile=${FONT}:textfile=${SCHED}:reload=1:fontcolor=white:fontsize=16:line_spacing=6:x=20:y=40:box=1:boxcolor=black@0.3:boxborderw=10[v1]; \
[v1]drawtext=fontfile=${FONT}:textfile=${NOW}:reload=1:fontcolor=white:fontsize=20:x=(w-text_w)/2:y=h-50:box=1:boxcolor=black@0.0:boxborderw=8[v2]; \
[v2]drawtext=fontfile=${FONT}:textfile=${TIME}:reload=1:fontcolor=white:fontsize=18:x=w-tw-20:y=20:box=1:boxcolor=black@0.4:boxborderw=8[v]" \
    -map "[v]" -map 1:a \
    -c:v libx264 -preset ultrafast -tune stillimage \
    -b:v 250k -maxrate 250k -bufsize 500k \
    -pix_fmt yuv420p \
    -g 32 -keyint_min 32 \
    -c:a aac -b:a 96k -ar 44100 \
    -f flv "$RTMP_URL"
}

run_ffmpeg_fallback() {
  echo "[youtube] starting FALLBACK mode (We'll be back soon + silent audio)"
  /usr/bin/ffmpeg \
    -hide_banner -loglevel info \
    -stream_loop -1 -re -i "$VIDEO" \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
    -filter_complex "\
[0:v]scale=640:360,fps=8[v0]; \
[v0]drawtext=fontfile=${FONT}:textfile=${SCHED}:reload=1:fontcolor=white:fontsize=16:line_spacing=6:x=20:y=40:box=1:boxcolor=black@0.3:boxborderw=10[v1]; \
[v1]drawtext=fontfile=${FONT}:text='We\\'ll be back soon':fontcolor=white:fontsize=28:x=(w-text_w)/2:y=(h-text_h)/2:box=1:boxcolor=black@0.55:boxborderw=14[v2]; \
[v2]drawtext=fontfile=${FONT}:textfile=${TIME}:reload=1:fontcolor=white:fontsize=18:x=w-tw-20:y=20:box=1:boxcolor=black@0.4:boxborderw=8[v]" \
    -map "[v]" -map 1:a \
    -c:v libx264 -preset ultrafast -tune stillimage \
    -b:v 250k -maxrate 250k -bufsize 500k \
    -pix_fmt yuv420p \
    -g 32 -keyint_min 32 \
    -c:a aac -b:a 96k -ar 44100 \
    -f flv "$RTMP_URL"
}

mode=""

while true; do
  if is_icecast_up; then
    new_mode="normal"
  else
    new_mode="fallback"
  fi

  if [[ "$new_mode" != "$mode" ]]; then
    echo "[youtube] switching mode: ${mode:-none} -> $new_mode"
    mode="$new_mode"
  fi

  if [[ "$mode" == "normal" ]]; then
    run_ffmpeg_normal &
  else
    run_ffmpeg_fallback &
  fi

  ffpid=$!

  # Monitor: if Icecast status changes, restart ffmpeg into the other mode
  while kill -0 "$ffpid" >/dev/null 2>&1; do
    sleep "$CHECK_EVERY"
    if is_icecast_up; then
      [[ "$mode" == "fallback" ]] && echo "[youtube] Icecast is back; restarting stream" && kill "$ffpid" && wait "$ffpid" 2>/dev/null || true && break
    else
      [[ "$mode" == "normal" ]] && echo "[youtube] Icecast went down; restarting stream" && kill "$ffpid" && wait "$ffpid" 2>/dev/null || true && break
    fi
  done

  # small delay before restart loop
  sleep 1
done
