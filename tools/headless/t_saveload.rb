require_relative 'play_lib'
$choices = ['NO INFO NEEDED', 'BOY', 'YES']
new_game
play_until("intro done", frames: 20000) { $game_map.map_id == 176 && !$game_temp.player_transferring }
settle
pbAddPokemon(:PIKACHU, 10) rescue log("add failed #{$!.message}")
$player.badges[0] = true
$game_switches[65] = true
path = File.join(System.data_directory, 'headless_test.rxdata')
begin
  ok = Game.save(path)
  puts "save ok=#{ok} exists=#{File.exist?(path)} size=#{File.size(path) rescue 0}"
  data = SaveData.read_from_file(path)
  puts "read keys=#{data.keys.size} player=#{data[:player].name} badges=#{data[:player].badge_count} party=#{data[:player].party.map(&:name)}"
  $player.party.clear; $player.badges[0] = false; $game_switches[65] = false; $game_player.moveto(3, 3)
  SaveData.mark_values_as_unloaded
  Game.load(data)
  puts "loaded: #{where} party=#{$player.party.map { |p| "#{p.name} L#{p.level}" }} sw65=#{$game_switches[65]} badges=#{$player.badge_count}"
rescue Exception => e
  puts "SAVE/LOAD ERROR #{e.class}: #{e.message}\n#{e.backtrace.first(10).join("\n")}"
end
