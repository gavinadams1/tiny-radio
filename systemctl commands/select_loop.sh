#!/usr/bin/env bash

HOUR=$(date +%H)

if [ "$HOUR" -ge 7 ] && [ "$HOUR" -lt 19 ]; then
  echo "/home/gavinadamsdev/radio/youtube/loop_day.mp4"
else
  echo "/home/gavinadamsdev/radio/youtube/loop_night.mp4"
fi
