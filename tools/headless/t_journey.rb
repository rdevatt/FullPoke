require_relative 'play_lib'
load File.join(__dir__, 't_parcel.rb')
mon = $player.party[0]
mon.level = 20; mon.calc_stats; mon.heal      # make the AI's wins reliable; this tests events, not luck
def expect_map(id, label)
  raise "#{label}: expected map #{id}, got #{where}" unless $game_map.map_id == id
  puts "STEP #{label}: #{where}"
end
go_to(13, 19); settle                      # leave lab
cross_edge(:up, 19); expect_map(34, 'route 1')
cross_edge(:up); expect_map(173, 'viridian')
cross_edge(:up); expect_map(35, 'route 2 (south)')
go_to(19, 53); settle; expect_map(12, 'forest gate (south)')
go_to(17, 48); settle; expect_map(326, 'viridian forest')
before = $battle_results.size
go_to(10, 9); settle(20000); expect_map(12, 'forest gate (north)')
puts "  forest trainer battles: #{$battle_results.size - before} results=#{$battle_results.last(6).inspect}"
go_to(43, 48); settle; expect_map(35, 'route 2 (north)')
cross_edge(:up); expect_map(25, 'pewter')
mon.hp = 1
go_to(20, 35); settle; expect_map(182, 'pewter pokecenter')
nurse = $game_map.events.values.select { |e| e.character_name == 'NPC 16' }.min_by { |e| (e.x - $game_player.x).abs + (e.y - $game_player.y).abs }
go_to(nurse.x, nurse.y + 1); $game_player.turn_up
$choices = ['YES']
press_use; settle(4000)
puts "  after nurse: HP #{mon.hp}/#{mon.totalhp} pokecenter=#{$PokemonGlobal.pokecenterMapId.inspect}"
raise "nurse didn't heal" unless mon.hp == mon.totalhp
go_to(30, 38); settle; expect_map(25, 'pewter (left center)')
go_to(18, 25); settle; expect_map(177, 'pewter gym')
brock = $game_map.events.values.find { |e| e.name =~ /BROCK/i }
puts "  brock event at #{brock.x},#{brock.y}"
before = $battle_results.size
go_to(brock.x, brock.y + 1); $game_player.turn_up
press_use; settle(30000)
puts "  gym battles: #{$battle_results[before..].inspect} badges=#{$player.badges.each_index.select { |i| $player.badges[i] }}"
$LOG.grep(/Brock|BATTLE: You (defeated|got)|badge|Badge/i).last(8).each { |l| puts "   #{l}" }
raise "no Boulder Badge" unless $player.badges[0]
# Save and reload.
FileUtils.mkdir_p(System.data_directory) rescue nil
ok = Game.save(File.join(System.data_directory, 'headless_test.rxdata'))
data = SaveData.read_from_file(File.join(System.data_directory, 'headless_test.rxdata'))
puts "STEP save: ok=#{ok} keys=#{data.keys.size} player=#{data[:player].name} badges=#{data[:player].badge_count} party=#{data[:player].party.map(&:name)}"
Game.load(data)
puts "STEP load: #{where} party=#{$player.party.map { |p| "#{p.name} L#{p.level}" }} pokedex=#{$player.has_pokedex}"
