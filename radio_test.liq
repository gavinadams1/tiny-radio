# Log to stdout
set("log.stdout", true)
set("server.telnet", true)
set("server.telnet.bind_addr", "127.0.0.1")
set("server.telnet.port", 1234)

# Base folder
base = "/home/gavinadamsdev/radio/music"

# Playlists
general   = playlist(mode="random", reload_mode="watch", base ^ "/general_rotation")
classical = playlist(mode="random", reload_mode="watch", base ^ "/classical")
wake_up   = playlist(mode="random", reload_mode="watch", base ^ "/wake_up")
streets_of_paris = playlist(mode="random", reload_mode="watch", base ^ "/streets_of_paris")

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

# --- LIVE DJ INPUT ---
# This opens a small HTTP server inside Liquidsoap.
# Your DJ client (on your laptop) will connect here.
dj_live = input.harbor(
  "live",                     # mount name (for Liquidsoap, not Icecast)
  port = 8005,                # choose a free port on the VM
  password = "djpassword",    # set a password for your DJ client
  icy = true,
)

# When dj_live is sending audio, we use it.
# Otherwise we fall back to the scheduled music.
mixed =
  fallback(
    track_sensitive = false,  # switch immediately when live connects/disconnects
    [dj_live, radio_sched]
  )

# Make the source infallible
radio = mksafe(mixed)


output.file(
  %wav,
  "test_output.wav",
  radio,
  fallible=false
)

