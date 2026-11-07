require_relative 'play_lib'
load File.join(__dir__, 't_opening.rb') unless $opening_loaded; $opening_loaded = true
# Test-only: the AI fights for the player, so give it a margin; this checks events, not luck.
mon = $player.party[0]; mon.level = 12; mon.calc_stats; mon.heal
cross_edge(:up, 19); puts "STEP route1: #{where}"
raise "expected Route 1" unless $game_map.map_id == 34
cross_edge(:up); puts "STEP viridian: #{where}"
raise "expected Viridian" unless $game_map.map_id == 173
go_to(34, 19); settle(8000); puts "STEP mart: #{where} parcel=#{$bag.has?(:OAKSPACKAGE)} carrying=#{$game_switches[38]}"
raise "didn't get parcel" unless $bag.has?(:OAKSPACKAGE)
go_to(8, 21); settle; puts "STEP left mart: #{where}"
cross_edge(:down); puts "STEP back on route1: #{where}"
cross_edge(:down); puts "STEP back in pallet: #{where} battles=#{$battle_results.inspect}"; $LOG.grep(/BATTLE/).last(40).each { |l| puts "   #{l}" }
go_to(23, 13); settle; puts "STEP lab: #{where}"
go_to(16, 10); $game_player.turn_up; press_use; settle(8000)
puts "STEP oak: pokedex=#{$player.has_pokedex} balls=#{$bag.quantity(:POKEBALL)} parcel=#{$bag.has?(:OAKSPACKAGE)} sw38=#{$game_switches[38]} sw44=#{$game_switches[44]}"
raise "no pokedex" unless $player.has_pokedex
