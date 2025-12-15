#!/usr/bin/env bash

ffmpeg \
  -hide_banner -loglevel info \
  -stream_loop -1 -re -i loop.mp4 \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -filter_complex "[0:v]scale=640:360,fps=8,drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='Be back soon':fontcolor=white:fontsize=28:x=(w-text_w)/2:y=(h-text_h)/2:box=1:boxcolor=black@0.6:boxborderw=14[v]" \
  -map "[v]" -map 1:a \
  -r 8 \
  -c:v libx264 -preset ultrafast -tune stillimage \
  -b:v 250k -maxrate 250k -bufsize 500k \
  -pix_fmt yuv420p \
  -g 32 -keyint_min 32 \
  -c:a aac -b:a 96k -ar 44100 \
  -f flv "rtmp://b.rtmp.youtube.com/live2/6s2p-ku56-wqf1-7k40-d4ja?backup=1&"

