# The map pack's own interior rooms used as buildings (pack_rooms.rb): a room on
# another region's composite map counts as its own region's ground (party set,
# respawn point), its nurse heals, and the Celadon Department Store's elevator
# runs between its floors.
#   tools/headless/run.sh t_pack_rooms.rb
require_relative 'play_lib'
require_relative 'test_lib'
require_relative 'world_route'
Dir[File.join(__dir__, 'geo', '*.rb')].sort.each { |f| require f }
$stdout.sync = true

new_game
$game_switches[61] = true   # skip the intro scene: the tests teleport

def events_named(prefix, map = $game_map) = map.events.values.select { |e| e.name.start_with?(prefix) }
def talk_to(ev)
  spots = [[0, 1, 8], [0, -1, 2], [1, 0, 4], [-1, 0, 6], [0, 2, 8]].map { |dx, dy, f| [ev.x + dx, ev.y + dy, f] }
  spot = spots.find { |x, y, _| ($game_player.x == x && $game_player.y == y) || find_path(x, y) } or
    raise "can't reach #{ev.name} at (#{ev.x},#{ev.y}) from #{where}"
  go_to(spot[0], spot[1])
  $game_player.turn_generic(spot[2])
  press_use(20000)
  settle(4000)
end

section 'A Johto Pokémon Center on Kanto\'s map 182'
FullPoke.begin_region(:kanto, :independent)
FullPoke.begin_region(:johto, :independent)
cherry = GEO_SPEC[:johto][:maps][:cherrygrove]
on_map(cherry)
check("Cherrygrove is Johto (party set #{FullPoke.progress.active_context})", FullPoke.current_map_region == :johto && FullPoke.progress.active_context == :johto)
pbAddPokemonSilent(:CYNDAQUIL, 10)
door = events_named('FP: Door pc').first or raise 'no Pokémon Center door in Cherrygrove'
on_map(cherry, door.x, door.y + 1)
go_to(door.x, door.y)
settle(4000)
check("the door leads into map 182 (#{where})", $game_map.map_id == 182)
check("inside, the region is Johto (#{FullPoke.current_map_region.inspect})", FullPoke.current_map_region == :johto)
check("... and the party is still Johto's (#{FullPoke.progress.active_context})", FullPoke.progress.active_context == :johto && $player.party.length == 1)
$player.party[0].hp = 1
nurse = $game_map.events.values.select { |e| e.name == 'FP: EV007' || e.name.start_with?('FP: Nurse') }
          .min_by { |e| (e.x - $game_player.x).abs + (e.y - $game_player.y).abs } or raise 'no nurse'
$choices = [0]
talk_to(nurse)
check("the nurse heals (HP #{$player.party[0].hp}/#{$player.party[0].totalhp})", $player.party[0].hp == $player.party[0].totalhp)
check("the respawn point is this Pokémon Center (#{$PokemonGlobal.pokecenterMapId})", $PokemonGlobal.pokecenterMapId == 182)
x, y = $game_player.x, $game_player.y
stairs = events_named('FP: Stairs').min_by { |e| (e.x - x).abs + (e.y - y).abs }
go_to(stairs.x, stairs.y)
settle(4000)
check("the stairs lead upstairs, still Johto (#{where})", $game_map.map_id == 182 && FullPoke.region_at(182, $game_player.x, $game_player.y) == :johto)
on_map(cherry)
check('back in Cherrygrove the respawn point is kept', $PokemonGlobal.pokecenterMapId == 182)
on_map(182, 30, 37)   # Pewter's Pokémon Center
check("Pewter's Pokémon Center on the same map is Kanto (#{FullPoke.progress.active_context})",
      FullPoke.current_map_region == :kanto && FullPoke.progress.active_context == :kanto && $player.party.empty?)

section 'Celadon Department Store'
on_map(29, 14, 18)
go_to(14, 17)
settle(4000)
check("Celadon's store door leads to 1F (#{where})", $game_map.map_id == 181 && $game_player.y > 53 && $game_player.y < 69 && $game_player.x < 20)
lift = $game_map.events.values.find { |e| e.x == 9 && e.y == 54 }
go_to(lift.x, lift.y)
settle(4000)
check("the elevator door leads into the elevator (#{where})", $game_map.map_id == 181 && $game_player.x.between?(27, 31) && $game_player.y.between?(58, 64))
panel = $game_map.events.values.find { |e| e.x == 27 && e.y == 60 }
$choices = [3, 1]   # Higher, 5
talk_to(panel)
go_to(29, 64)
settle(4000)
check("riding to 5F (#{where})", $game_map.map_id == 181 && $game_player.x.between?(132, 145))
clerk = events_named('FP: Clerk').min_by { |e| (e.x - $game_player.x).abs + (e.y - $game_player.y).abs }
check('5F has a clerk', clerk && clerk.x.between?(132, 145))

finish
