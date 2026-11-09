# Kanto's story after Misty, played through its events in FireRed/LeafGreen
# order: Bill -> S.S. Anne -> Cut -> Route 9 / Rock Tunnel -> Lavender ->
# Rocket Hideout -> Pokémon Tower -> Snorlax -> Saffron's gates -> Silph Co.
# -> HMs. The player is placed at the entrance of each area (t_kanto_reach.rb
# checks the areas connect on foot) and walks, talks and battles from there;
# every gate is tried before and after its requirement.
#   tools/headless/run.sh t_kanto_story.rb
# The party's levels are raised before some areas (printed as "boost") so the
# AI-played battles are won; that's a test setting, not balance.
require_relative 'play_lib'
require_relative 'test_lib'
$stdout.sync = true
$SHOW_BATTLE = true if ENV['VERBOSE']

def evs(name) = $game_map.events.values.select { |e| e.name == name }
def ev_named(name, near: nil)
  list = evs(name)
  raise "no event '#{name}' on #{where}" if list.empty?
  near ||= [$game_player.x, $game_player.y]
  list.min_by { |e| (e.x - near[0]).abs + (e.y - near[1]).abs }
end

def ev_at(x, y) = $game_map.events.values.find { |e| e.x == x && e.y == y } || raise("no event at (#{x},#{y}) on #{where}")

def talk_to(ev)
  spots = [[0, 1, :up], [0, -1, :down], [1, 0, :left], [-1, 0, :right]].map { |dx, dy, f| [ev.x + dx, ev.y + dy, f] }
  spots.reject! { |x, y, _| $game_map.events.values.any? { |e| e.x == x && e.y == y && !e.through && e.character_name != '' } }
  spots.sort_by! { |x, y, _| (x - $game_player.x).abs + (y - $game_player.y).abs }
  spot = spots.find { |x, y, _| ($game_player.x == x && $game_player.y == y) || find_path(x, y) } or raise "can't reach #{ev.name} from #{where}"
  go_to(spot[0], spot[1])
  $game_player.send("turn_#{spot[2]}")
  press_use
  settle(20000)
end

def enter(ev)
  map = $game_map.map_id
  pos = [$game_player.x, $game_player.y]
  go_to(ev.x, ev.y)
  settle(6000)
  [$game_map.map_id, $game_player.x, $game_player.y] != [map, *pos]
end

def boost(level, why)
  low = $player.party.select { |pk| pk.level < level }
  return if low.empty?
  puts "  boost: party to L#{level} for #{why}"
  low.each { |pk| pk.level = level; pk.reset_moves; pk.calc_stats }
end

def heal = $player.heal_party

# Talks to every trainer on the map that is reachable and not yet beaten
# (a trainer whose line of sight the path missed still has to be fought).
def fight_trainers
  $game_map.events.values.select { |e| e.name.start_with?('FP: Trainer') }.each do |e|
    key = e.list.to_a.map { |c| c.parameters.to_s[/extra_battle\(:kanto, :(\w+)\)/, 1] }.compact.first
    next if !key || FullPoke.flag?(:kanto, :"beat_#{key}")
    next if [[0, 1], [0, -1], [1, 0], [-1, 0]].none? { |dx, dy| find_path(e.x + dx, e.y + dy) }
    talk_to(e)
    heal
  end
end
def flag?(f) = FullPoke.flag?(:kanto, f)

new_game
$game_switches[61] = true
$game_switches[65] = true
$game_variables[27] = 'Blue'   # the rival's name, from the intro
FullPoke.begin_region(:kanto, :continuous)
FullPoke.state(:kanto).starter = :BULBASAUR
$player.party.replace([Pokemon.new(:VENUSAUR, 24), Pokemon.new(:PIDGEOT, 22), Pokemon.new(:NIDOKING, 22)])
FullPoke.badge!(:kanto, 0); FullPoke.badge!(:kanto, 1)   # Boulder and Cascade (t_journey / t_kanto)
$PokemonGlobal.repel = 99_999   # wild encounters are out of scope here

section 'Bill -> S.S. Ticket'
on_map(58, 51, 9)
check('Bill\'s Sea Cottage door works', enter(ev_at(51, 8)) && $game_map.map_id == 179)
talk_to(ev_named('FP: Bill'))
check('Bill gives the S.S. Ticket', $bag.has?(:SSTICKET))

section 'S.S. Anne -> HM01'
$bag.remove(:SSTICKET)
on_map(24, 29, 39)
check('Vermilion Harbor door', enter(ev_at(29, 38)) && $game_map.map_id == 179)
harbor = [$game_map.map_id, $game_player.x, $game_player.y]
talk_to(ev_named('FP: Harbor sailor'))
check('no ticket: the sailor turns the player away', $game_map.map_id == 179)
$bag.add(:SSTICKET)
talk_to(ev_named('FP: Harbor sailor'))
check("with the ticket: aboard the S.S. Anne (#{where})", $game_map.map_id == 345)
boost(26, 'the S.S. Anne')
check('1F stairs -> 2F', enter(ev_named('FP: Stairs')) && $game_player.y < 70)
check('2F passage -> Captain\'s cabin (past the rival)', enter(ev_named('FP: Door', near: [90, 45])) && $game_player.y < 40)
check('the rival battle on the S.S. Anne was fought and won', flag?(:beat_kanto_rival_ssanne))
talk_to(ev_named('FP: Captain'))
check('the Captain gives HM01 Cut', $bag.has?(:HM01))
enter(ev_named('FP: Door'))
enter(ev_named('FP: Stairs', near: [97, 61]))
check("leaving by the gangway (#{where})", enter(ev_named('FP: Gangway')) && $game_map.map_id == 179)
talk_to(ev_named('FP: Harbor sailor'))
check('the S.S. Anne has sailed: no boarding again', flag?(:ss_anne_sailed) && $game_map.map_id == 179)

section 'Cut'
$player.party[0].learn_move(:CUT)
on_map(24, 19, 8)
tree = ev_named('FP: CutTree')
check('Vermilion Gym is behind a small tree', find_path(19, 28).nil?)
$player.badges[FullPoke.region(:kanto).badge_index(1)] = false
$DEBUG = false   # debug mode skips Badge checks
talk_to(tree)
check('one Badge: Cut can\'t be used yet', find_path(19, 28).nil?)
FullPoke.badge!(:kanto, 1)
talk_to(tree)
settle(2000)
check('Cascade Badge + HM01: the tree is cut and the Gym door reached', enter(ev_at(19, 28)) && $game_map.map_id == 177)

section 'Route 9 -> Rock Tunnel -> Lavender Town'
on_map(42, 1, 12)
check('Route 9 is blocked by trees', find_path(10, 12).nil?)
evs('FP: CutTree').each { |t| talk_to(t); settle(2000) }
check('both trees cut: Route 9 open', !find_path(10, 12).nil?)
on_map(43, 8, 25)
boost(26, 'Rock Tunnel')
check('Rock Tunnel entrance', enter(ev_at(8, 24)) && $game_map.map_id == 338)
check('Rock Tunnel 1F has no way through to the exit', find_path(18, 37).nil?)
check('1F -> B1F', enter(ev_at(45, 2)) && $game_player.x > 60)
check('B1F -> 1F (south part)', enter(ev_at(100, 28)) && $game_player.x < 50)
check('Rock Tunnel exit -> Route 10', enter(ev_at(18, 38)) && $game_map.map_id == 43)
go_to(11, 84)
walk(:down)
settle(4000)
check("Route 10 leads south into Lavender Town (#{where})", $game_map.map_id == 27)

section 'Rocket Hideout -> Silph Scope'
on_map(29, 37, 27)
check('Game Corner door', enter(ev_named('FP: Game Corner door')) && $game_map.map_id == 235)
boost(33, 'the Rocket Hideout')
heal
poster = ev_named('FP: Poster')
talk_to(poster)
check('the grunt guards the poster', $game_map.map_id == 235)
talk_to(ev_named('FP: Trainer(3)')) if !flag?(:beat_kanto_rocket_gamecorner)
talk_to(poster)
check('the poster (grunt beaten on the way) opens the stairs', flag?(:beat_kanto_rocket_gamecorner) && $game_map.map_id == 375)
check('B1F -> B3F', enter(ev_named('FP: Stairs', near: [18, 4])) && $game_player.y > 40)
check('B3F -> B4F', enter(ev_named('FP: Stairs', near: [25, 56])) && $game_player.x > 45)
fight_trainers
boost(36, 'Giovanni')
heal
talk_to(ev_named('FP: Giovanni'))
check('Giovanni beaten: Silph Scope', flag?(:hideout_done) && $bag.has?(:SILPHSCOPE))

section 'Pokémon Tower -> Poké Flute'
on_map(27, 18, 7)
boost(40, 'the Pokémon Tower')
heal
check('Pokémon Tower door', enter(ev_at(18, 6)) && $game_map.map_id == 207)
[[19, 9], [30, 10], [73, 10], [84, 10], [128, 10]].each_with_index do |(x, y), i|
  fight_trainers
  check("#{i + 1}F -> #{i + 2}F", enter(ev_at(x, y)))
end
check('the rival on 2F was fought', flag?(:beat_kanto_rival_tower))
ghost = ev_named('FP: Ghost')
$bag.remove(:SILPHSCOPE)
talk_to(ghost)
check('without the Silph Scope the ghost can\'t be faced', !flag?(:ghost_calmed))
$bag.add(:SILPHSCOPE)
heal
talk_to(ghost)
check('with the Silph Scope: Marowak\'s spirit is calmed', flag?(:ghost_calmed))
check('6F -> 7F', enter(ev_at(147, 16)) && $game_player.x > 160)
fuji = ev_named('FP: Mr. Fuji')
talk_to(fuji)
check('no Poké Flute while Rockets remain', (1..3).all? { |i| flag?(:"beat_kanto_rocket_tower#{i}") } || !$bag.has?(:POKEFLUTE))
fight_trainers
talk_to(fuji) if !flag?(:got_pokeflute)
check('Rockets beaten, Mr. Fuji rescued: Poké Flute', (1..3).all? { |i| flag?(:"beat_kanto_rocket_tower#{i}") } && $bag.has?(:POKEFLUTE))

section 'Snorlax'
boost(36, 'Snorlax')
heal
on_map(45, 14, 60)
check('Route 12: Snorlax blocks the way south', find_path(14, 75).nil?)
talk_to(ev_named('FP: Snorlax'))
settle(2000)
check('Poké Flute: Snorlax woke and the road is open', flag?(:snorlax_route12) && !find_path(14, 75).nil?)
heal
on_map(49, 71, 23)
check('Route 16: Snorlax blocks the Cycling Road gate', find_path(53, 23).nil?)
talk_to(ev_named('FP: Snorlax'))
settle(2000)
check('Route 16 open', flag?(:snorlax_route16) && !find_path(53, 23).nil?)

section 'Saffron City and Silph Co.'
on_map(38, 25, 31)
enter(ev_at(25, 32))
check('Route 5 gatehouse', $game_map.map_id == 12)
door = ev_at(80, 16)
go_to(door.x, door.y)
settle(4000)
check('two Badges: the guard keeps Saffron closed', $game_map.map_id == 12)
FullPoke.badge!(:kanto, 2); FullPoke.badge!(:kanto, 3)
walk(:up)
settle
go_to(door.x, door.y) if $game_map.map_id == 12
settle(4000)
check("four Badges: through the gate (#{where})", $game_map.map_id == 38)
on_map(31, 23, 24)
check('Silph Co. door', enter(ev_at(23, 23)) && $game_map.map_id == 258)
boost(50, 'Silph Co.')
heal
$choices = ['7F']
enter(ev_named('FP: Elevator'))
check("elevator to 7F (#{where})", $game_player.y > 100 && $game_player.y < 125)
emp = ev_named('FP: Silph employee')
talk_to(emp)
check('no Lapras before the rival is beaten', flag?(:beat_kanto_rival_silph) || !flag?(:got_lapras))
fight_trainers
talk_to(emp) if !flag?(:got_lapras)
check('rival beaten on 7F; Lapras received', flag?(:beat_kanto_rival_silph) && $player.party.any? { |pk| pk.species == :LAPRAS })
heal
$choices = ['11F']
enter(ev_named('FP: Elevator'))
check("elevator to 11F (#{where})", $game_player.y > 170)
check('Sabrina refuses while Silph is occupied', !FullPoke::KantoStory.gym_open?(6))
fight_trainers
boost(56, 'Giovanni at Silph Co.')
heal
talk_to(ev_named('FP: Giovanni'))
check('Giovanni beaten at Silph', flag?(:silph_done))
talk_to(ev_named('FP: President'))
check('the President gives the Master Ball', $bag.has?(:MASTERBALL))
check('Sabrina\'s Gym is open now', FullPoke::KantoStory.gym_open?(6))

section 'HMs'
on_map(12, 37, 7)
talk_to(ev_named('FP: Oak\'s aide'))
check('Oak\'s aide (Route 2 gate): HM05 Flash', $bag.has?(:HM05))
on_map(49, 60, 17)
talk_to(ev_named('FP: Fly girl'))
check('Route 16: HM02 Fly', $bag.has?(:HM02))
on_map(12, 83, 54)
talk_to(ev_named('FP: Safari Warden'))
check('Safari Zone gate: HM03 Surf and HM04 Strength', $bag.has?(:HM03) && $bag.has?(:HM04))
check('Viridian Gym stays shut below seven Badges', !FullPoke::KantoStory.gym_open?(8))
finish
