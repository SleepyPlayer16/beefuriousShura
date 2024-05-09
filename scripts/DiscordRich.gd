extends Node

func _ready():
  DiscordRPC.app_id = 1233014845591388192 # Application ID
  DiscordRPC.state = "Menú principal."
  DiscordRPC.large_image = "beefuriousicon" # Image key from "Art Assets"

  DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
  # DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"

  DiscordRPC.refresh() # Always refresh after changing the values!
