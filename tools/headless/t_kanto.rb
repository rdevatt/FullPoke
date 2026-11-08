# Kanto after Brock: Gyms 2-8 through the towns' real Gym doors, then Route 23 ->
# Indigo Plateau -> Elite Four -> Champion -> Hall of Fame. Towns are reached
# by teleporting next to each Gym door (t_reach.rb checks they're connected on
# foot); everything from the door on is walked and battled.
#   MODE=continuous tools/headless/run.sh t_kanto.rb
require_relative 'play_lib'
require_relative 'test_lib'
$stdout.sync = true
MODE = (ENV['MODE'] || 'continuous').to_sym

def ev_named(prefix)
  evs = $game_map.events.values.select { |e| e.name.start_with?(prefix) }
  raise "no event '#{prefix}' on #{where}" if evs.empty?
  evs.sort_by { |e| (e.x - $game_player.x).abs + (e.y - $game_player.y).abs }.find { |e| find_path(e.x, e.y) || [[0, 1], [0, -1], [1, 0], [-1, 0]].any? { |dx, dy| find_path(e.x + dx, e.y + dy) } } || evs.first
end

def talk_to(ev)
  spots = [[0, 1, :up], [0, -1, :down], [1, 0, :left], [-1, 0, :right]].map { |dx, dy, f| [ev.x + dx, ev.y + dy, f] }
  spots.sort_by! { |x, y, _| (x - $game_player.x).abs + (y - $game_player.y).abs }
  spot = spots.find { |x, y, _| ($game_player.x == x && $game_player.y == y) || find_path(x, y) } or raise "can't reach #{ev.name} from #{where}"
  go_to(spot[0], spot[1])
  $game_player.send("turn_#{spot[2]}")
  press_use
  settle(20000)
end

def train(level)
  $player.party.each { |pk| pk.level = [level, pk.level].max; pk.reset_moves; pk.calc_stats }
  $player.heal_party
end

GYM_DOORS = { 2 => [26, 31, 21], 3 => [24, 19, 28], 4 => [29, 14, 33], 5 => [30, 14, 32], 6 => [31, 30, 5], 7 => [172, 21, 28], 8 => [173, 35, 10] }

new_game
$game_switches[61] = true
FullPoke.begin_region(:kanto, MODE)
on_map(25, 23, 45)
FullPoke.state(:kanto).starter = :BULBASAUR
$player.party.replace([Pokemon.new(:VENUSAUR, 30)])
FullPoke::Teams.candidate_pool(nil, :kanto, []).last(5).each { |sp| $player.party.push(Pokemon.new(sp, 30)) }
$player.badges[0] = true
section "Kanto Gyms 2-8 (#{MODE})"
(2..8).each do |n|
  map, dx, dy = GYM_DOORS[n]
  on_map(map, dx, dy + 1)
  settle
  go_to(dx, dy)
  settle(4000)
  check("Gym #{n}: the door leads into the Gym (#{where})", $game_map.map_id == 177)
  train(FullPoke::Circuit.leader_top_level(FullPoke::Circuit.stage(:kanto, n)[:leader]) + 12)
  leader = ev_named('FP: Leader')
  talk_to(leader)
  check("Gym #{n}: #{FullPoke::Circuit.stage(:kanto, n)[:badge]} from #{leader.name.sub('FP: Leader ', '')}", FullPoke.badge?(:kanto, n - 1))
end
section "Route 23 -> Indigo Plateau -> League"
r23 = load_data('Data/Map056.rxdata').events.values.find { |e| e.name == 'FP: To Indigo Plateau' }
on_map(56, r23.x, r23.y + 2)
settle
go_to(r23.x, r23.y)
settle(4000)
check("Route 23 gate (8 badges) leads to the Indigo Plateau (#{where})", $game_map.map_id == 33)
door = $game_map.events.values.find { |e| e.list&.any? { |c| c.code == 201 } }
go_to(door.x, door.y)
settle(4000)
check("Indigo Plateau door leads into the League (#{where})", $game_map.map_id == 292)
5.times do |i|
  train(FullPoke::Circuit.leader_top_level(:kanto_champion) + FullPoke.state(:kanto).offset + 15)
  target = ev_named('FP: League battle')
  talk_to(target)
  check("League battle #{i + 1}/5 (#{target.name.sub('FP: League battle ', '')})", FullPoke::Circuit.league_cleared?(:kanto, i))
  next if i == 4
  d = ev_named('FP: League door')
  go_to(d.x, d.y)
  settle(4000)
end
check("Kanto completed", FullPoke.completed?(:kanto))
hof = ev_named('FP: Hall of Fame')
go_to(hof.x, hof.y)
settle(4000)
check("Hall of Fame -> Pallet Town (#{where})", $game_map.map_id == 23)
finish
