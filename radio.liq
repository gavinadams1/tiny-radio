# Log to stdout
set("log.stdout", true)
set("server.telnet", false)

# Base folder
base = "/home/gavinadamsdev/radio/music"

# General rotation playlist
general = playlist(base ^ "/general_rotation")

# Classical playlist
classical = playlist(base ^ "/classical")

# Wake Up / Wind Down playlist
wake_up = playlist(base ^ "/wake_up")

# Streets of Paris playlist
streets_of_paris = playlist(base ^ "/streets_of_paris")

# Fix metadata for files with missing titles
def fix_metadata(m) =
  t = m["title"]
  if t != "" and t != "Unknown" then
    [("title", t)]
  else
    base_name = m["filename"]
    [("title", base_name)]
  end
end

# Apply metadata fix to both sources
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

# Make the source infallible
radio = mksafe(radio_sched)

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
