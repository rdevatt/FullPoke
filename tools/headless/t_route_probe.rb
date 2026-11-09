# Plays a real-map region's opening (gate, mode, starter), then gives the
# first N badges and tries one trip with the walkthrough's planner, logging
# every try. For debugging t_geo.rb stalls without replaying the region.
#   DIAG=1 REGIONS=sinnoh PROBE=2,273,22,7,273,37,6 tools/headless/run.sh t_route_probe.rb
#   (badges, start map, x, y, goal map, x, y)
require_relative 'play_lib'
require_relative 'test_lib'
require_relative 'world_route'
Dir[File.join(__dir__, 'geo', '*.rb')].sort.each { |f| require f }

$stdout.sync = true
REGION = (ENV['REGIONS'] || 'sinnoh').split(',').first.to_sym
badges, sm, sx, sy, gm, gx, gy = ENV['PROBE'].split(',').map(&:to_i)

new_game
$game_switches[61] = true
exit_map, ex, ey, = FullPoke::World.forest_exit(REGION)
on_map(exit_map, ex, ey)
settle
$choices = [1, 0]
gate = $game_map.events.values.find { |e| e.name.start_with?("FP: Gate #{REGION}") }
go_to(gate.x, gate.y)
settle(4000)
interiors = FullPoke::World.home(REGION)[0]
$choices = [0, 0]
m = load_data(format('Data/Map%03d.rxdata', interiors))
prof = m.events.values.find { |e| e.name.start_with?("FP: #{FullPoke.region(REGION).professor}") }
travel_to(interiors, prof.x, prof.y)
ev = $game_map.events[prof.id]
spot = [[0, 1, 8], [0, -1, 2], [1, 0, 4], [-1, 0, 6]].map { |dx, dy, f| [ev.x + dx, ev.y + dy, f] }
                                                     .find { |x, y, _| ($game_player.x == x && $game_player.y == y) || find_path(x, y) }
go_to(spot[0], spot[1]); $game_player.turn_generic(spot[2]); press_use(400000); settle(20000)
check("starter", !FullPoke.state(REGION).starter.nil?)
# A party that wins the route battles, and Repel against wild ones
$player.party.each { |pk| pk.level = 70; pk.reset_moves; pk.calc_stats; pk.heal }
$PokemonGlobal.repel = 1_000_000
FullPoke.region(REGION).badge_range.first(badges).each { |i| $player.badges[i] = true }
on_map(sm, sx, sy)
settle
begin
  travel_to(gm, gx, gy)
  check("reached map #{gm} #{gx},#{gy} (#{where})", true)
rescue RuntimeError => e
  check("reached map #{gm} #{gx},#{gy}: #{e.message}", false)
end
