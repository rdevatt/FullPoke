require_relative 'play_lib'
require_relative 'battle_trace'
$SHOW_BATTLE = ENV['SHOW_BATTLE'] == '1'
starter = (ENV['STARTER'] || '0').to_i      # ball index 0 Bulbasaur, 1 Charmander, 2 Squirtle
$choices = ['NO INFO NEEDED', 'BOY', 'YES']
new_game
play_until("intro done", frames: 20000) { $game_map.map_id == 176 && !$game_temp.player_transferring }
settle
puts "STEP house: #{where}"
go_to(12, 9)          # stairs down
settle
puts "STEP downstairs: #{where}"
go_to(8, 36); settle
puts "STEP outside: #{where}"
raise "expected Pallet Town" unless $game_map.map_id == 23
go_to(19, 1); walk(:up); settle(3000)
puts "STEP after Oak: #{where} lab_scene=#{$game_switches[63]} choosing=#{$game_switches[64]}"
raise "expected Oak's Lab" unless $game_map.map_id == 175
settle(6000)
puts "STEP choosing: choosing=#{$game_switches[64]}"
ball_x = 15 + starter
go_to(ball_x, 11)
$game_player.turn_up
$choices = ['Yes', 'No']   # take the Pokémon, decline nickname
press_use; settle(20000)
puts "STEP after starter: party=#{$player.party.map { |p| "#{p.species} L#{p.level} HP#{p.hp}/#{p.totalhp}" }} battles=#{$battle_results.inspect}"
puts "  switches: has_starter=#{$game_switches[65]} rival_done=#{$game_switches[66]} errand=#{$game_switches[44]} chose=#{[40, 41, 42].map { |s| $game_switches[s] }}"
raise "no starter" if $player.party.empty?
raise "rival battle didn't happen" if $battle_results.empty?
# Leave the lab and confirm Oak no longer stops the player.
go_to(13, 19); settle
puts "STEP left lab: #{where}"
go_to(19, 1); walk(:up); settle(3000)
puts "STEP north exit: #{where}"
