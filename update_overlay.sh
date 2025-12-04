#!/usr/bin/env bash

STATUS_URL="http://localhost:8000/status-json.xsl"
OUT_DIR="/home/gavinadamsdev/radio"
NOW_FILE="$OUT_DIR/nowplaying.txt"
TIME_FILE="$OUT_DIR/time.txt"

mkdir -p "$OUT_DIR"

while true; do
  # Update time in HH:MM format
  date +"%H:%M" > "$TIME_FILE"

  # Fetch current title from Icecast JSON
  title=$(curl -s "$STATUS_URL" | jq -r '
    .icestats.source as $s
    | (if ($s | type) == "array" then $s[0] else $s end).title // empty
  ')

  # Fallback if missing or "Unknown"
  if [ -z "$title" ] || [ "$title" = "Unknown" ]; then
    title="tinyradio.net"
  fi

  echo "$title" > "$NOW_FILE"

  # Update every 5 seconds (change if you like)
  sleep 5
done