# Boots like a player's (non-debug) launch: messages, plugins, Compiler.main (a no-op
# outside Debug), then the splash/title screen and load screen, choosing New Game.
require_relative 'play_lib'
raise "run with HEADLESS_DEBUG=0" if $DEBUG
MessageTypes.load_default_messages if FileTest.exist?("Data/messages_core.dat")
PluginManager.runPlugins
Compiler.main
Game.initialize
Game.set_up_system
$choices = ['NO INFO NEEDED', 'BOY', 'YES']
$input_auto_confirm = true          # press Use through the splash, title and load screens
Graphics.frame_budget = Graphics.frame_count + 30000
$scene = Scene_Intro.new   # what Main's pbCallTitle returns outside Debug mode
puts "title scene: #{$scene.class}"
$scene.main until $scene.nil? || $scene.is_a?(Scene_Map)
puts "reached: #{$scene.class}"
$input_auto_confirm = false
play_until("intro done", frames: 20000) { $game_map.map_id == 176 && !$game_temp.player_transferring }
puts "RELEASE BOOT OK: #{where} player=#{$player.name} plugins=#{PluginManager.plugins rescue '?'}"
