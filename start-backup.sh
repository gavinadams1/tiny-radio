#!/usr/bin/env bash

STREAM_KEY="YOUR_YOUTUBE_STREAM_KEY"
RTMP_URL="rtmp://b.rtmp.youtube.com/live2/6s2p-ku56-wqf1-7k40-d4ja?backup=1&"
VIDEO="./loop.mp4"
MESSAGE="./message.txt"
FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

ffmpeg \
  -hide_banner -loglevel info \
  -stream_loop -1 -re -i "$VIDEO" \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -filter_complex "\
[0:v]scale=640:360,fps=15,drawtext=fontfile=${FONT}:textfile=${MESSAGE}:reload=1:fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2:box=1:boxcolor=black@0.6:boxborderw=20[v]" \
  -map "[v]" -map 1:a \
  -c:v libx264 \
  -preset ultrafast \
  -tune stillimage \
  -pix_fmt yuv420p \
  -g 60 -keyint_min 60 \
  -b:v 1500k \
  -maxrate 1500k \
  -bufsize 3000k \
  -c:a aac \
  -b:a 128k \
  -ar 44100 \
  -r 8 \
  -f flv "$RTMP_URL"
