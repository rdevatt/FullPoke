# Compiles plugins, then walks into a known-unfinished warp and checks the player isn't stranded.
PluginManager.runPlugins
require_relative 'play_lib'
$choices = ['NO INFO NEEDED', 'BOY', 'YES']
new_game
play_until("intro done", frames: 20000) { $game_map.map_id == 176 && !$game_temp.player_transferring }
settle
# Map 338 (Rock Tunnel) event 5 at (45,2) transfers to map 72 (38,28): out of bounds.
$game_temp.player_new_map_id = 338; $game_temp.player_new_x = 45; $game_temp.player_new_y = 3
$game_temp.player_new_direction = 8; $game_temp.player_transferring = true
settle
puts "before: #{where}"
ev = $game_map.events.values.find { |e| e.x == 45 && e.y == 2 }
ev.start
settle(2000)
puts "after: #{where} msgs=#{$LOG.grep(/finished/).inspect}"
