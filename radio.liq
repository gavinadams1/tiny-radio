# Log to stdout
set("log.stdout", true)
set("server.telnet", true)
set("server.telnet.bind_addr", "127.0.0.1")
set("server.telnet.port", 1234)

# Base folder
base = "/home/gavinadamsdev/radio/music"

# Playlists
general   = playlist(mode="randomize", reload_mode="watch", base ^ "/general_rotation")
classical = playlist(mode="randomize", reload_mode="watch", base ^ "/classical")
wake_up   = playlist(mode="randomize", reload_mode="watch", base ^ "/wake_up")
streets_of_paris = playlist(mode="randomize", reload_mode="watch", base ^ "/streets_of_paris")

# Fix metadata for files with missing titles
def fix_metadata(m) =
  t = m["title"]
  if t != "" and t != "Unknown" then
    [("title", t)]
  else
    [("title", m["filename"])]
  end
end

general_fixed   = map_metadata(fix_metadata, general)
classical_fixed = map_metadata(fix_metadata, classical)
wake_up_fixed = map_metadata(fix_metadata, wake_up)
streets_of_paris_fixed = map_metadata(fix_metadata, streets_of_paris)

# Time-based schedule:
# 15:00–17:00 → classical
# everything else → general rotation
radio_sched =
  switch(track_sensitive=true, [
    ({05h-08h}, wake_up_fixed),
    ({13h-15h}, streets_of_paris_fixed),
    ({15h-17h}, classical_fixed),
    ({23h-24h}, wake_up_fixed),
    ({00h-24h}, general_fixed)
  ])

# Your scheduled music source
music = radio_sched

# Live DJ input (harbor)
dj_live = input.harbor(
  "live",
  port = 8005,
  password = "djpassword",
  icy = true
)

# Talkover: DJ on top, music ducks to e.g. 25% while DJ is connected
radio_talkover =
  smooth_add(
    p = 0.15,          # 0.25 = -12 dB-ish bed; try 0.2–0.4
    normal = music,
    special = dj_live
  )

radio = mksafe(radio_talkover)

# Stream to Icecast as MP3
output.icecast(
  %mp3(bitrate=128),
  host = "localhost",
  port = 8000,
  password = "vienna",
  mount = "/radio.mp3",
  name = "Gavin Cloud Radio",
  description = "A simple looping station on Google Cloud",
  genre = "Various",
  radio
)