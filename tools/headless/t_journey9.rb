# A simulated journey through all nine regions, in a mixed order of modes, with
# assertions at every step: level offsets, wild/trainer scaling, enhanced Gym and
# League teams, a real battle against each region's Champion, forest unlocks,
# completion counting, party isolation and save/load.
#   tools/headless/run.sh t_journey9.rb
#   ORDER=galar:c,kanto:i,... tools/headless/run.sh t_journey9.rb
# It doesn't walk the maps (t_regions.rb does that per region); between
# checkpoints the party's levels are set to what a player would reach.
require_relative 'play_lib'
require_relative 'test_lib'

ORDER = (ENV['ORDER'] || 'kanto:c,johto:c,hoenn:i,sinnoh:c,unova:c,kalos:i,alola:c,galar:c,paldea:c').split(',').map do |s|
  r, m = s.split(':')
  [r.to_sym, m == 'i' ? :independent : :continuous]
end

new_game
$game_switches[61] = true
on_map(FullPoke::World.forest_maps.first)
$player.party.replace([Pokemon.new(:PIKACHU, 5)])   # stand-in main party
expected_offset = 0
last_cont_max = nil
completed = []
save_path = File.join(System.data_directory, 'headless_journey9.rxdata')

ORDER.each_with_index do |(region, mode), step|
  reg = FullPoke.region(region)
  section "#{step + 1}. #{reg.name} (#{mode})"
  if !reg.available?
    check("#{reg.name} is locked until its data is installed (Gen 9 pack)", !FullPoke.forest_gate(region) && !FullPoke.state(region).started?)
    next
  end
  check("begin #{reg.name} in #{mode} mode", FullPoke.begin_region(region, mode))
  st = FullPoke.state(region)
  want = (mode == :continuous) ? (last_cont_max ? last_cont_max - 5 : 0) : 0
  check("offset #{st.offset} (expected #{want})", st.offset == want)
  arrival = FullPoke::World.arrival(region)
  on_map(arrival[0], arrival[1], arrival[2])
  check("party set: #{FullPoke.progress.active_context} (#{$player.party.length} Pokémon)",
        FullPoke.progress.active_context == (mode == :independent ? region : :main))
  check("level cap #{GameData::GrowthRate.max_level}", GameData::GrowthRate.max_level == (mode == :independent ? 100 : FullPoke::MAX_LEVEL))
  sp = FullPoke.give_starter(region, reg.starters[step % 3])
  check("starter #{sp} at L#{$player.party.last.level} (5 + #{st.offset})", $player.party.last.level == 5 + st.offset)
  # Wild and trainer scaling on the first and last stage
  stage_maps = FullPoke::World.encounters.select { |e| e[:circuit] && e[:circuit][0] == region }
  [1, 8].each do |n|
    e = stage_maps.find { |x| x[:circuit][1] == n }
    next if !e
    on_map(e[:map])
    tbl = GameData::Encounter.get(e[:map], 0).types[:Land]
    base = tbl.first
    w = pbGenerateWildPokemon(base[1], base[2])
    check("stage #{n} wild #{base[1]} L#{base[2]} -> #{w.speciesName} L#{w.level} (+#{st.offset})", w.level == [base[2] + st.offset, FullPoke.level_cap].min)
    defn = FullPoke::Circuit.route_trainer_defn(region, n, 0)
    tr = FullPoke.build_trainer(defn[:key])
    orig = FullPoke.parse_party(defn[:party]).map { |p| p[:level] }
    check("stage #{n} route trainer levels #{tr.party.map(&:level)} = #{orig} + #{st.offset}", tr.party.map(&:level) == orig.map { |l| l + st.offset })
  end
  on_map(arrival[0], arrival[1], arrival[2])
  circuit = FullPoke::Circuit.get(region)
  enhanced = FullPoke.enhanced_teams?(region)
  check("enhanced teams: #{enhanced} (continuous region no. #{st.continuous_index})", enhanced == (mode == :continuous && st.continuous_index >= 2))
  # Gyms
  prev_strength = nil
  circuit[:stages].each_with_index do |stg, i|
    tr = FullPoke.build_trainer(stg[:leader]) rescue nil
    next if !tr || tr.party.empty?   # Brock is a PBS trainer (checked in t_systems)
    top = FullPoke::Circuit.leader_top_level(stg[:leader]) + st.offset
    ok = tr.party.last.level == [top, FullPoke.level_cap].min
    if enhanced
      types = FullPoke::Teams.get(stg[:leader])[:types]
      ok &&= tr.party.length == 5
      ok &&= tr.party.all? { |pk| FullPoke::Evolution.fully_evolved?(pk.species) }
      ok &&= tr.party.all? { |pk| (pk.types & types).any? } if types
    end
    check("Gym #{i + 1} #{tr.name}: #{tr.party.map { |p| "#{p.speciesName} #{p.level}" }.join(', ')}", ok, quiet: !ENV['VERBOSE'] && ok)
    FullPoke.badge!(region, i)
  end
  # League (real battle against the Champion)
  champ = FullPoke.build_trainer(circuit[:champion])
  ctop = FullPoke::Circuit.leader_top_level(circuit[:champion]) + st.offset
  check("Champion #{champ.name}: #{champ.party.length} Pokémon, ace L#{champ.party.last.level} (expected #{ctop})",
        champ.party.last.level == [ctop, FullPoke.level_cap].min && (!enhanced || champ.party.length == 6))
  player_max = [ctop + 5, FullPoke.level_cap].min
  $player.party.each { |pk| pk.level = player_max; pk.reset_moves; pk.calc_stats; pk.heal }
  team = $player.party.map { |pk| pk }
  res = quick_trainer_battle(champ, *team)
  check("battle vs Champion at L#{ctop} completes (outcome #{res})", [1, 2, 5].include?(res))
  $player.party.each { |pk| pk.level = player_max; pk.calc_stats; pk.heal }
  FullPoke.record_party_levels(region)
  check("max level recorded #{st.max_level} (= #{player_max})", st.max_level == player_max)
  (circuit[:league].length + 1).times { |i| FullPoke.set_flag(region, :"league#{i}") }
  before = FullPoke::Forest.pool(:land).length
  check("#{reg.name} completed", FullPoke.complete_region(region))
  check("replaying the final battle doesn't count twice", !FullPoke.complete_region(region) && FullPoke.completed_count == completed.length + 1)
  completed << region
  last_cont_max = st.max_level if mode == :continuous
  after = FullPoke::Forest.pool(:land)
  check("forest pool #{before} -> #{after.length} species, all from completed regions",
        after.length >= before && after.all? { |e| completed.include?(e[:region]) })
  check("no duplicated Pokémon (#{FullPoke.all_pokemon.length} owned)", FullPoke.duplicate_pokemon.empty?)
  check("save", Game.save(save_path))
  data = SaveData.read_from_file(save_path)
  SaveData.mark_values_as_unloaded
  Game.load(data)
  check("load: #{FullPoke.completed_count} regions completed, next continuous offset #{FullPoke.progress.current_continuous_offset}",
        FullPoke.completed_count == completed.length &&
        FullPoke.progress.current_continuous_offset == (last_cont_max ? last_cont_max - 5 : 0))
end

section "Journey summary"
puts "  completed: #{completed.map { |r| "#{r}(#{FullPoke.region_mode(r)}, offset #{FullPoke.state(r).offset}, max L#{FullPoke.state(r).max_level})" }.join(' -> ')}"
on_map(FullPoke::World.forest_maps.first)
check("in the forest the main party is active", FullPoke.progress.active_context == :main)
finish
