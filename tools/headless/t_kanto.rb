# Kanto after Brock: Gyms 2-8 through the towns' real Gym doors (past the Gym
# trainers), then the Route 22 gate (8 Badges) -> Route 23 (Surf) -> Victory
# Road -> Indigo Plateau -> Elite Four -> Champion -> Hall of Fame. Towns are
# reached by teleporting next to each Gym door (t_kanto_reach.rb checks they're
# connected on foot); everything from the door on is walked and battled. The
# story between Gyms is t_kanto_story.rb.
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

# Walks to (gx, gy) on the current map, surfing across water on the way: a
# breadth-first path over walkable and surfable tiles; Surf starts the real
# way (face the water, press Use) and ends by stepping ashore.
def water?(x, y)
  return false if !$game_map.valid?(x, y) || !$game_map.terrain_tag(x, y).can_surf || $game_map.terrain_tag(x, y).waterfall
  # rocks and other solid tiles drawn over the water
  [2, 1].none? { |z| (t = $game_map.data[x, y, z]) > 0 && $game_map.passages[t] & 0x0f == 0x0f }
end
def land?(x, y) = $game_map.valid?(x, y) && !water?(x, y) && $game_map.passable?(x, y, 0)
DIRS = { down: [0, 1, 2], up: [0, -1, 8], left: [-1, 0, 4], right: [1, 0, 6] }
def travel(gx, gy)
  start = [$game_player.x, $game_player.y]
  prev = { start => nil }
  q = [start]
  until q.empty?
    c = q.shift
    break if c == [gx, gy]
    DIRS.each do |name, (dx, dy, _)|
      n = [c[0] + dx, c[1] + dy]
      next if prev.key?(n)
      ev = $game_map.events.values.find { |e| e.x == n[0] && e.y == n[1] && e.character_name != '' && !e.through }
      next if ev || !(water?(*n) || land?(*n) || n == [gx, gy])
      prev[n] = [c, name]
      q << n
    end
  end
  raise "travel: no way to (#{gx},#{gy}) from #{where}" if !prev.key?([gx, gy])
  steps = []
  c = [gx, gy]
  (steps.unshift(prev[c][1]); c = prev[c][0]) while prev[c]
  map = $game_map.map_id
  steps.each do |d|
    nx, ny = $game_player.x + DIRS[d][0], $game_player.y + DIRS[d][1]
    if water?(nx, ny) && !$PokemonGlobal.surfing
      $game_player.send("turn_#{d}")
      press_use
      settle(2000)
      raise "travel: couldn't start surfing at #{where}" if !$PokemonGlobal.surfing
      next
    end
    walk(d)
    settle(4000)
    return if $game_map.map_id != map
  end
end

GYM_DOORS ={ 2 => [26, 31, 21], 3 => [24, 19, 28], 4 => [29, 14, 33], 5 => [30, 14, 32], 6 => [31, 30, 5], 7 => [172, 21, 28], 8 => [173, 35, 10] }

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
  # Sabrina waits until Silph Co. is free (the story itself: t_kanto_story.rb)
  FullPoke.set_flag(:kanto, :silph_done) if n == 6
  leader = ev_named('FP: Leader')
  talk_to(leader)
  check("Gym #{n}: #{FullPoke::Circuit.stage(:kanto, n)[:badge]} from #{leader.name.sub('FP: Leader ', '')}", FullPoke.badge?(:kanto, n - 1))
end
section "Route 22 gate -> Route 23 (Surf) -> Victory Road -> Indigo Plateau -> League"
$player.party[0].learn_move(:SURF)
on_map(55, 16, 16)
settle
go_to(16, 15)
settle(4000)
check("Route 22's League gate leads into the gatehouse (#{where})", $game_map.map_id == 12)
gate = ev_named('FP: To Route 23')
go_to(gate.x, gate.y)
settle(4000)
check("the gatehouse checks 8 Badges and lets the player onto Route 23 (#{where})", $game_map.map_id == 56)
cave = $game_map.events.values.select { |e| e.name == 'FP: Cave' }.min_by(&:x)   # the west mouth is the way in
travel(cave.x, cave.y)
check("Surf across Route 23's water to Victory Road (#{where})", $game_map.map_id == 335)
%w[Ladder Ladder Hole].each do |kind|
  target = $game_map.events.values.select { |e| e.name == "FP: #{kind}" }
                    .select { |e| find_path(e.x, e.y) }
                    .reject { |e| ($game_player.x - e.x).abs + ($game_player.y - e.y).abs <= 1 }
                    .max_by { |e| e.x }
  raise "Victory Road: no #{kind} reachable from #{where}" if !target
  go_to(target.x, target.y)
  settle(4000)
end
exit_cave = $game_map.events.values.select { |e| e.name == 'FP: Cave' }.find { |e| find_path(e.x, e.y) }
go_to(exit_cave.x, exit_cave.y)
settle(4000)
check("Victory Road 1F -> 2F -> 3F -> 2F -> exit onto upper Route 23 (#{where})", $game_map.map_id == 56 && $game_player.y < 60)
r23 = ev_named('FP: To Indigo Plateau')
go_to(r23.x, r23.y)
settle(4000)
check("Route 23 leads to the Indigo Plateau (#{where})", $game_map.map_id == 33)
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
