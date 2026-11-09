# Plays a region built from the map pack's real maps (geo/<region>.rb) on foot:
# forest gate -> mode -> the professor's lab -> every Gym town in order over the
# real routes, gates, caves and sea (surfing with the badge field skill), the
# story battles, badge-gated areas (checked to push the player back), Victory
# Road, the League and the Hall of Fame.
#   REGIONS=johto MODE=continuous tools/headless/run.sh t_geo.rb
# The AI plays the player's side, so the party's level is raised before each
# Gym Leader and story battle (a test setting; t_balance.rb plays without it).
require_relative 'play_lib'
require_relative 'test_lib'
require_relative 'world_route'
Dir[File.join(__dir__, 'geo', '*.rb')].sort.each { |f| require f }

$stdout.sync = true
$SHOW_BATTLE = ENV['VERBOSE']
REGION = (ENV['REGIONS'] || 'johto').split(',').first.to_sym
MODE = (ENV['MODE'] || 'continuous').to_sym
SPEC = GEO_SPEC[REGION]
ID = ->(key) { SPEC[:maps][key] }

def events_named(prefix, map = $game_map) = map.events.values.select { |e| e.name.start_with?(prefix) }

def talk_to_event(ev)
  spots = [[0, 1, 8], [0, -1, 2], [1, 0, 4], [-1, 0, 6]].map { |dx, dy, f| [ev.x + dx, ev.y + dy, f] }
  spots.sort_by! { |x, y, _| (x - $game_player.x).abs + (y - $game_player.y).abs }
  spot = spots.find { |x, y, _| ($game_player.x == x && $game_player.y == y) || find_path(x, y) } or
    raise "can't reach #{ev.name} at (#{ev.x},#{ev.y}) from #{where}"
  go_to(spot[0], spot[1])
  $game_player.turn_generic(spot[2])
  press_use(60000)   # long battles run inside
  settle(20000)
end

# Walks to an event on another map (through the right door) and talks to it.
def visit_and_talk(map_id, name_prefix)
  m = load_data(format('Data/Map%03d.rxdata', map_id))
  target = m.events.values.find { |e| e.name.start_with?(name_prefix) } or raise "no #{name_prefix} on map #{map_id}"
  travel_to(map_id, target.x, target.y)
  ev = $game_map.events[target.id]
  talk_to_event(ev)
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

def leader_top(key) = FullPoke::Circuit.leader_top_level(key) + FullPoke.state(REGION).offset

new_game
$game_switches[61] = true
section "#{REGION} on the map pack's maps (#{MODE})"
exit_map, ex, ey, = FullPoke::World.forest_exit(REGION)
on_map(exit_map, ex, ey)
settle
$choices = [MODE == :independent ? 0 : 1, 0]
gate = events_named("FP: Gate #{REGION}").first
go_to(gate.x, gate.y)
settle(4000)
start = SPEC[:start]
check("forest gate leads to #{INFO = load_data('Data/MapInfos.rxdata'); INFO[ID.(start[:town])].name.strip} (#{where})", $game_map.map_id == ID.(start[:town]))
check("mode #{MODE} recorded", FullPoke.region_mode(REGION) == MODE)

# Before the starter, the first route turns the player back
first_route = SPEC[:requires].find { |_, r| r.is_a?(Hash) && r[:starter] }&.first
if first_route
  begin
    travel_to(ID.(first_route), tries: 1)
  rescue RuntimeError
  end
  check("without a starter, #{first_route} sends the player back (#{where})", $game_map.map_id != ID.(first_route))
end

# The professor's lab
interiors = FullPoke::World.home(REGION)[0]
$choices = [0, 0]
visit_and_talk(interiors, "FP: #{FullPoke.region(REGION).professor}")
st = FullPoke.state(REGION)
check("starter #{st.starter.inspect} at L#{$player.party[0]&.level}", !st.starter.nil?)
# Test-only: strong regional teammates so the AI wins reliably
FullPoke::Teams.candidate_pool(nil, REGION, []).last(5).each { |sp| pbAddPokemonSilent(sp, 5) }

# Encounters and trainers exist on every staged area
staged = SPEC[:stages].keys
no_enc = staged.reject { |k| GameData::Encounter.get(ID.(k), 0) }
check("wild Pokémon on all #{staged.length} routes/caves#{no_enc.empty? ? '' : " (missing: #{no_enc.join(', ')})"}", no_enc.empty?)
no_tr = staged.reject { |k| load_data(format('Data/Map%03d.rxdata', ID.(k))).events.values.any? { |e| e.name =~ /Trainer\(/ } }
check("trainers on routes (none on: #{no_tr.join(', ')})", no_tr.length <= 3)

gym_map = FullPoke::World.region_data(REGION)[:league][0]
(1..8).each do |n|
  stage = FullPoke::Circuit.stage(REGION, n)
  # Story battles that belong to this town
  SPEC[:story].select { |s| s[:kind] == :battle && (stage[:extras] || []).include?(s[:key]) }.each do |s|
    train_party(leader_top(s[:key]) + 15)
    if s[:interior]
      town = s[:interior][0]
      travel_to(ID.(town))
      ev = (events_named('FP: Door', $game_map).find { |e| (e.x - s[:interior][1]).abs <= 2 && (e.y - s[:interior][2]).abs <= 3 }) or raise "no door for #{s[:interior]}"
      go_to(ev.x, ev.y); settle(4000)
      foe = events_named('FP: ').find { |e| e.character_name.start_with?('trainer_') }
      talk_to_event(foe)
    else
      defn = FullPoke::Teams.get(s[:key])
      visit_and_talk(ID.(s[:at][0]), "FP: #{defn[:name] || FullPoke.region(REGION).rival_name}")
    end
    check("stage #{n}: story battle #{s[:key]} won", FullPoke.flag?(REGION, :"beat_#{s[:key]}"))
  end
  leader = FullPoke::Teams.get(stage[:leader])
  train_party(leader_top(stage[:leader]) + 12)
  visit_and_talk(gym_map, "FP: Leader #{leader[:name]}")
  check("stage #{n}: #{stage[:badge]} from #{leader[:name]} in #{stage[:town]}", FullPoke.badge?(REGION, n - 1))
  if n == 1
    # Badge-gated areas push the player back until earned
    gated = SPEC[:requires].find { |_, r| (r.is_a?(Integer) ? r : r[:badges].to_i) == 2 }&.first
    if gated
      saved = $player.badges.dup
      begin
        travel_to(ID.(gated), tries: 1)
      rescue RuntimeError
      end
      check("#{gated} needs 2 badges: pushed back (#{where})", $game_map.map_id != ID.(gated))
    end
  end
end

vr = FullPoke::World.region_data(REGION)[:league]
train_party(leader_top(FullPoke::Circuit.get(REGION)[:champion]) + 15)
vr_map = load_data('Data/MapInfos.rxdata').find { |id, info| info.name == "#{FullPoke.region(REGION).name} Victory Road" }&.first
travel_to(vr_map)
check("Victory Road reached on foot (#{where})", $game_map.map_id == vr_map)
if (rv = events_named('FP: ').find { |e| e.character_name.start_with?('trainer_') && e.name !~ /Trainer\(/ })
  talk_to_event(rv)
end
entrance = events_named('FP: League entrance').first
go_to(entrance.x, entrance.y)
settle(4000)
count = FullPoke::Circuit.league_count(REGION)
count.times do |i|
  train_party(leader_top(FullPoke::Circuit.get(REGION)[:champion]) + 15)
  target = (i == 5) ? events_named('FP: Final').first : events_named('FP: League battle').min_by { |e| (e.x - $game_player.x).abs + (e.y - $game_player.y).abs }
  talk_to_event(target)
  check("League battle #{i + 1}/#{count} (#{target.name.sub('FP: League battle ', '')})", FullPoke::Circuit.league_cleared?(REGION, i))
  next if i >= 4
  door = events_named('FP: League door').min_by { |e| (e.x - $game_player.x).abs + (e.y - $game_player.y).abs }
  go_to(door.x, door.y)
  settle(4000)
end
check("#{REGION} completed", FullPoke.completed?(REGION))
hof = events_named('FP: Hall of Fame').first
go_to(hof.x, hof.y)
settle(4000)
check("Hall of Fame -> home (#{where})", $game_map.map_id == FullPoke::World.arrival(REGION)[0])
check("no duplicated Pokémon", FullPoke.duplicate_pokemon.empty?)
finish
