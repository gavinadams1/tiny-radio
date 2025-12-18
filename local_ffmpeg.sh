ffmpeg -loop 1 -i background.jpg \
  -vf "scale=640:360,fps=8" \
  -c:v libx264 -preset slow -tune stillimage \
  -b:v 2500k -maxrate 2500k -bufsize 5000k \
  -pix_fmt yuv420p \
  -t 300 \
  loop.mp4