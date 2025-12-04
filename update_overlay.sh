#!/usr/bin/env bash

STATUS_URL="http://localhost:8000/status-json.xsl"
OUT_DIR="/home/gavinadamsdev/radio"
NOW_FILE="$OUT_DIR/nowplaying.txt"
TIME_FILE="$OUT_DIR/time.txt"
SCHED_FILE="$OUT_DIR/schedule.txt"

mkdir -p "$OUT_DIR"

while true; do
  # --- Time (HH:MM) ---
  date +"%H:%M" > "$TIME_FILE"

  # --- Now playing (title from Icecast JSON) ---
  title=$(curl -s "$STATUS_URL" | jq -r '
    .icestats.source as $s
    | (if ($s | type) == "array" then $s[0] else $s end).title // empty
  ')

  if [ -z "$title" ] || [ "$title" = "Unknown" ]; then
    title="tinyradio.net"
  fi

  echo "$title" > "$NOW_FILE"

  # --- Schedule with ▶ for current show ---
  HOUR=$(date +%H)

  if   [ "$HOUR" -ge 0  ] && [ "$HOUR" -lt 5  ]; then CURRENT="Nightshift"
  elif [ "$HOUR" -ge 5  ] && [ "$HOUR" -lt 8  ]; then CURRENT="Wake Up"
  elif [ "$HOUR" -ge 8  ] && [ "$HOUR" -lt 11 ]; then CURRENT="Daytime 1"
  elif [ "$HOUR" -ge 11 ] && [ "$HOUR" -lt 13 ]; then CURRENT="Daytime 2"
  elif [ "$HOUR" -ge 13 ] && [ "$HOUR" -lt 15 ]; then CURRENT="Daytime 3"
  elif [ "$HOUR" -ge 15 ] && [ "$HOUR" -lt 17 ]; then CURRENT="Classical"
  elif [ "$HOUR" -ge 17 ] && [ "$HOUR" -lt 19 ]; then CURRENT="Jazz"
  elif [ "$HOUR" -ge 19 ] && [ "$HOUR" -lt 21 ]; then CURRENT="Blues"
  elif [ "$HOUR" -ge 21 ] && [ "$HOUR" -lt 23 ]; then CURRENT="Piano Lounge"
  else CURRENT="Wind Down"
  fi

  write_line() {
    local label="$1"
    local text="$2"
    if [ "$label" = "$CURRENT" ]; then
      echo "▶ $text"
    else
      echo "  $text"
    fi
  }

  {
    write_line "Nightshift"    "00–05  Nightshift"
    write_line "Wake Up"       "05–08  Wake Up"
    write_line "Daytime 1"     "08–11  Daytime 1"
    write_line "Daytime 2"     "11–13  Daytime 2"
    write_line "Daytime 3"     "13–15  Daytime 3"
    write_line "Classical"     "15–17  Classical"
    write_line "Jazz"          "17–19  Jazz"
    write_line "Blues"         "19–21  Blues"
    write_line "Piano Lounge"  "21–23  Piano Lounge"
    write_line "Wind Down"     "23–24  Wind Down"
  } > "$SCHED_FILE"

  # Update every 5 seconds
  sleep 5
done
