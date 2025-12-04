  GNU nano 6.2                                           radio.liq                                              M     
# Log to stdout
set("log.stdout", true)
set("server.telnet", false)

# Playlist of all files in the directory
music = playlist("/home/gavinadamsdev/radio/music")

# If title is empty or 'Unknown', use the filename (without extension)
def fix_metadata(m) =
  t = m["title"]
  # If we already have a decent title, keep it
  if t != "" and t != "Unknown" then
    [("title", t)]
  else
    # Use the 'filename' field from metadata (Liquidsoap sets this)
    f = m["filename"]
    base_name = f

    [("title", base_name)]
  end
end

# Apply metadata fix, then make it infallible
radio = mksafe(map_metadata(fix_metadata, music))# Make the source infallible (adds silence if nothing to play)
radio = mksafe(music)

# Stream to Icecast as MP3
output.icecast(
  %mp3(bitrate=128),
  host = "localhost",
  port = 8000,
  password = "vienna",  # <source-password> from /etc/icecast2/icecast.xml
  mount = "/radio.mp3",
  name = "Gavin Cloud Radio",
  description = "A simple looping station on Google Cloud",
  genre = "Various",
  radio
)