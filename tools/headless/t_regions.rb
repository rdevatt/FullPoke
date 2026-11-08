# Plays regions of the generated world from the forest gate to the region's
# completion: mode choice, starter, every stage (route trainers, Gym trainers,
# Leader, story battles), Victory Road, the League and the Hall of Fame.
#   REGIONS=johto,kalos MODE=independent tools/headless/run.sh t_regions.rb
# The AI plays the player's side, so the test raises the team's level before
# each Gym (a test setting, not a game change).
require_relative 'play_lib'
require_relative 'test_lib'

$stdout.sync = true
$SHOW_BATTLE = ENV['VERBOSE']
REGION_LIST = (ENV['REGIONS'] || 'johto').split(',').map(&:to_sym)
MODES = (ENV['MODE'] || 'independent').split(',').map(&:to_sym)

def ev_named(prefix, near: nil)
  evs = $game_map.events.values.select { |e| e.name.start_with?(prefix) }
  raise "no event '#{prefix}' on #{where}" if evs.empty?
  near ||= [$game_player.x, $game_player.y]
  # Prefer events the player can actually walk to (rooms on one map are walled off)
  evs = evs.sort_by { |e| (e.x - near[0]).abs + (e.y - near[1]).abs }
  evs.find { |e| reachable_event?(e) } || evs.first
end

def reachable_event?(e)
  return true if find_path(e.x, e.y)
  [[0, 1], [0, -1], [1, 0], [-1, 0]].any? { |dx, dy| find_path(e.x + dx, e.y + dy) }
end

def talk_to(ev)
  spots = [[0, 1, :up], [0, -1, :down], [1, 0, :left], [-1, 0, :right]].map { |dx, dy, face| [ev.x + dx, ev.y + dy, face] }
  spots.sort_by! { |x, y, _| (x - $game_player.x).abs + (y - $game_player.y).abs }
  spot = spots.find { |x, y, _| ($game_player.x == x && $game_player.y == y) || find_path(x, y) }
  raise "can't reach #{ev.name} at (#{ev.x},#{ev.y}) from #{where}" if !spot
  go_to(spot[0], spot[1])
  { up: -> { $game_player.turn_up }, down: -> { $game_player.turn_down },
    left: -> { $game_player.turn_left }, right: -> { $game_player.turn_right } }[spot[2]].call
  log "talk_to #{ev.name} from #{where}"
  press_use
  settle(20000)
end

def enter(ev, same_map: false)
  map = $game_map.map_id
  go_to(ev.x, ev.y)
  settle(4000)
  moved = same_map ? ($game_player.x - ev.x).abs + ($game_player.y - ev.y).abs > 1 : $game_map.map_id != map
  raise "#{ev.name} didn't warp (still #{where})" if !moved
end

def train_party(level)
  $player.party.each do |pk|
    next if pk.level >= level
    pk.level = [level, FullPoke.level_cap].min
    pk.reset_moves
    pk.calc_stats
  end
  $player.heal_party
end

def leader_level(region, n) = FullPoke::Teams.get(FullPoke::Circuit.stage(region, n)[:leader])[:party] ?
  FullPoke::Circuit.leader_top_level(FullPoke::Circuit.stage(region, n)[:leader]) + FullPoke.state(region).offset : 50

def play_region(region, mode)
  section "#{region} (#{mode})"
  t0 = Time.now
  exit_map, ex, ey, = FullPoke::World.forest_exit(region)
  on_map(exit_map, ex, ey)
  settle
  $choices = [mode == :independent ? 0 : 1, 0]
  gate = ev_named("FP: Gate #{region}")
  go_to(gate.x, gate.y)
  settle(4000)
  check("#{region}: forest gate leads to #{FullPoke.region(region).start_town} (#{where})",
        $game_map.map_id == FullPoke::World.arrival(region)[0])
  check("#{region}: mode recorded as #{mode}", FullPoke.region_mode(region) == mode)
  # Professor (outdoors in real start towns, in the lab otherwise)
  if (lab = $game_map.events.values.find { |e| e.name == 'FP: Lab door' })
    enter(lab)
  end
  prof = ev_named('FP: Prof')
  $choices = [0, 0]
  talk_to(prof)
  st = FullPoke.state(region)
  check("#{region}: starter #{st.starter.inspect} L#{$player.party[0]&.level}",
        st.starter == FullPoke.region(region).starters[0] && ($player.party[0]&.level || 0) >= FullPoke.scale_level(5, region))
  # Test-only: two strong regional teammates so the AI wins reliably
  FullPoke::Teams.candidate_pool(nil, region, []).last(5).each { |sp| pbAddPokemonSilent(sp, 5) }
  if (ex_ = $game_map.events.values.find { |e| e.name == 'FP: Lab exit' })
    enter(ex_)
  end
  enter(ev_named('FP: Exit to route'))
  (1..8).each do |n|
    train_party(leader_level(region, n) + 12)
    stage_map = $game_map.map_id
    # Story battles in town
    extras_top = (FullPoke::Circuit.stage(region, n)[:extras] || []).map { |k| FullPoke::Circuit.leader_top_level(k) + st.offset }.max || 0
    train_party([leader_level(region, n), extras_top].max + 20)
    $game_map.events.values.select { |e| e.name.start_with?('FP: ') && e.character_name.start_with?('trainer_') && !e.name.start_with?('FP: Leader') }.each do |e|
      talk_to(e)
      train_party([leader_level(region, n), extras_top].max + 20)
    end
    enter(ev_named('FP: Gym door'))
    leader = ev_named('FP: Leader')
    $choices = []
    talk_to(leader)
    check("#{region} stage #{n}: #{FullPoke::Circuit.stage(region, n)[:badge]} from #{leader.name.sub('FP: Leader ', '')}",
          FullPoke.badge?(region, n - 1))
    train_party(leader_level(region, n) + 12)
    enter(ev_named('FP: Gym exit'))
    enter(ev_named('FP: North exit'))
    check("#{region}: left stage #{n} northwards", $game_map.map_id != stage_map, quiet: true)
  end
  train_party(FullPoke::Circuit.leader_top_level(FullPoke::Circuit.get(region)[:champion]) + st.offset + 15)
  if (rv = $game_map.events.values.find { |e| e.name.start_with?('FP: ') && e.character_name.start_with?('trainer_') })
    talk_to(rv)
  end
  enter(ev_named('FP: League entrance'))
  count = FullPoke::Circuit.league_count(region)
  count.times do |i|
    train_party(FullPoke::Circuit.leader_top_level(FullPoke::Circuit.get(region)[:champion]) + st.offset + 15)
    target = (i == 5) ? ev_named('FP: Final') : ev_named('FP: League battle')
    talk_to(target)
    check("#{region}: League battle #{i + 1}/#{count} (#{target.name.sub('FP: League battle ', '')}) won", FullPoke::Circuit.league_cleared?(region, i))
    next if i >= 4
    enter(ev_named('FP: League door'), same_map: true)
  end
  check("#{region}: region completed (#{FullPoke.completed_count} total)", FullPoke.completed?(region))
  hof = ev_named('FP: Hall of Fame')
  go_to(hof.x, hof.y)
  settle(4000)
  check("#{region}: Hall of Fame sends the player home (#{where})", $game_map.map_id == FullPoke::World.arrival(region)[0])
  check("#{region}: no duplicated Pokémon", FullPoke.duplicate_pokemon.empty?)
  puts "    (#{(Time.now - t0).round}s, party: #{$player.party.map { |p| "#{p.name} L#{p.level}" }.join(', ')})"
end

new_game
$game_switches[61] = true
on_map(FullPoke::World.forest_maps.first)
REGION_LIST.each_with_index { |r, i| play_region(r, MODES[i] || MODES.last) }
finish
