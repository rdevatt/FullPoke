# Tests FullPoke's core systems without walking around: level system above 100,
# region modes and offsets (the exact examples from the design), independent
# party isolation, enhanced Gym teams, the forest's rare pool, save/load.
#   tools/headless/run.sh t_systems.rb
require_relative 'play_lib'
require_relative 'test_lib'

new_game
$game_switches[61] = true   # skip the intro scene: the tests teleport

section "Growth rates up to level #{FullPoke::MAX_LEVEL}"
GameData::GrowthRate.each do |gr|
  prev = -1
  ok = true
  (1..FullPoke::MAX_LEVEL).each do |lv|
    e = gr.minimum_exp_for_level(lv)
    ok = false if e <= prev && lv > 1
    prev = e
  end
  check("#{gr.id}: exp strictly increases to #{FullPoke::MAX_LEVEL}", ok)
  check("#{gr.id}: continuous at 100 (exp(101) > exp(100))", gr.minimum_exp_for_level(101) > gr.minimum_exp_for_level(100))
  [5, 70, 80, 100, 101, 130, 200, 350, 500, 650, 999].each do |lv|
    e = gr.minimum_exp_for_level(lv)
    fail_msg = "#{gr.id} L#{lv}: level_from_exp(#{e}) = #{gr.level_from_exp(e)}"
    check(fail_msg, gr.level_from_exp(e) == lv && (lv == 1 || gr.level_from_exp(e - 1) == lv - 1), quiet: true)
  end
end

section "Pokémon at high levels"
LEVELS = [5, 70, 80, 130, 200, 350, 500, 650, 999]
prev_stats = nil
pkmn = Pokemon.new(:GARCHOMP, 5)
LEVELS.each do |lv|
  pkmn.level = lv
  pkmn.reset_moves
  pkmn.calc_stats
  dumped = Marshal.load(Marshal.dump(pkmn))
  stats = [pkmn.totalhp, pkmn.attack, pkmn.defense, pkmn.spatk, pkmn.spdef, pkmn.speed]
  check("Garchomp L#{lv}: level #{pkmn.level}, stats #{stats.join('/')}, moves #{pkmn.moves.map(&:id).join(',')}",
        pkmn.level == lv && stats.all? { |s| s.is_a?(Integer) && s > 0 } && pkmn.moves.length > 0)
  check("  survives Marshal (save) round trip", dumped.level == lv && dumped.totalhp == pkmn.totalhp, quiet: true)
  check("  stats rise with level", prev_stats.nil? || stats.zip(prev_stats).all? { |a, b| a > b }, quiet: true)
  prev_stats = stats
end
p = Pokemon.new(:CHARMANDER, 199)
p.exp = p.growth_rate.minimum_exp_for_level(200)
check("Exp to level 200 gives level 200 (#{p.level})", p.level == 200)
p2 = Pokemon.new(:BULBASAUR, 140)
check("Level-up evolution still offered above 100 (Bulbasaur L140 -> #{p2.check_evolution_on_level_up.inspect})",
      p2.check_evolution_on_level_up == :IVYSAUR)

section "Battles above level 100"
on_map(34)   # Route 1, Kanto not started: no offset
[[130, 120], [200, 210], [350, 340], [500, 505], [998, 990]].each do |mine, foe|
  $player.party.clear
  pk = Pokemon.new(:MACHAMP, mine)
  $player.party.push(pk)
  exp_before = pk.exp
  res = quick_wild_battle(:ARCANINE, foe)
  check("Machamp L#{mine} vs Arcanine L#{foe}: outcome #{res}, Machamp now L#{pk.level} HP #{pk.hp}/#{pk.totalhp}, exp +#{pk.exp - exp_before}",
        [1, 2, 4, 5].include?(res) && pk.level >= mine && pk.totalhp > 0 && (res != 1 || pk.exp > exp_before))
end

section "Region modes and level offsets (design examples)"
$fullpoke = FullPoke::Progress.new
on_map(23)   # Pallet Town (Kanto)
check("Kanto starts at offset 0", FullPoke.begin_region(:kanto, :continuous) && FullPoke.state(:kanto).offset == 0)
check("Mode can't be changed once chosen", !FullPoke.begin_region(:kanto, :independent) && FullPoke.region_mode(:kanto) == :continuous)
$player.party.clear
$player.party.push(Pokemon.new(:VENUSAUR, 70))
FullPoke.record_party_levels(:kanto)
check("Completing Kanto counts once", FullPoke.complete_region(:kanto) && !FullPoke.complete_region(:kanto) && FullPoke.completed_count == 1)
check("Next continuous offset is 70 - 5 = 65", FullPoke.progress.current_continuous_offset == 65)
FullPoke.begin_region(:johto, :continuous)
on_map(93)   # Route 29 (Johto)
[[2, 67], [3, 68], [5, 70], [8, 73], [15, 80], [30, 95], [50, 115], [65, 130]].each do |orig, want|
  check("Johto: level #{orig} -> #{FullPoke.scale_level(orig)} (want #{want})", FullPoke.scale_level(orig) == want)
end
wild = pbGenerateWildPokemon(:SENTRET, 2)
check("Wild Sentret L2 on Route 29 -> #{wild.speciesName} L#{wild.level} (L67, evolved)", wild.level == 67 && wild.species == :FURRET)
wild = pbGenerateWildPokemon(:HOOTHOOT, 3)
check("Wild Hoothoot L3 -> #{wild.speciesName} L#{wild.level}", wild.level == 68 && wild.species == :NOCTOWL)
$player.party.first.level = 72
FullPoke.record_party_levels
check("Offset fixed at region start even when the party levels up", FullPoke.state(:johto).offset == 65)

section "Independent adventure isolation"
main_party_ids = $player.party.map(&:object_id)
FullPoke.begin_region(:hoenn, :independent)
on_map(129)   # Route 101 (Hoenn)
check("Entering Hoenn (independent) swaps to an empty party", $player.party.empty? && FullPoke.progress.active_context == :hoenn)
check("Level cap is 100 in the independent adventure (#{GameData::GrowthRate.max_level})", GameData::GrowthRate.max_level == 100)
check("Hoenn offset is 0 (#{FullPoke.active_offset})", FullPoke.active_offset == 0)
w = pbGenerateWildPokemon(:ZIGZAGOON, 3)
check("Wild Zigzagoon stays L3 #{w.speciesName} L#{w.level}", w.level == 3 && w.species == :ZIGZAGOON)
FullPoke.give_starter(:hoenn, :MUDKIP)
check("Starter Mudkip L5 in Hoenn party", $player.party.length == 1 && $player.party[0].species == :MUDKIP && $player.party[0].level == 5)
check("Second starter refused", FullPoke.give_starter(:hoenn, :TORCHIC).nil? && $player.party.length == 1)
pbStorePokemon(Pokemon.new(:PIDGEY, 5))
check("Non-Hoenn Pidgey is sent to the main PC, not the Hoenn party", $player.party.length == 1)
pbStorePokemon(Pokemon.new(:WURMPLE, 5))
check("Hoenn-dex Wurmple joins the party", $player.party.length == 2)
on_map(93)   # back to Johto (continuous -> main set)
check("Returning to Johto restores the main party exactly", $player.party.map(&:object_id) == main_party_ids)
check("Level cap back to #{FullPoke::MAX_LEVEL}", GameData::GrowthRate.max_level == FullPoke::MAX_LEVEL)
check("No Pokémon duplicated across sets", FullPoke.duplicate_pokemon.empty?)
total_before = FullPoke.all_pokemon.length
on_map(129)
$player.party[0].level = 50
FullPoke.record_party_levels
check("Completing Hoenn (independent)", FullPoke.complete_region(:hoenn))
check("Hoenn team merged into the main party (#{$player.party.map(&:name).join(', ')})",
      $player.party.map(&:species).include?(:MUDKIP) && FullPoke.progress.active_context == :main)
check("Nothing lost or duplicated in the merge (#{total_before} -> #{FullPoke.all_pokemon.length})",
      FullPoke.all_pokemon.length == total_before && FullPoke.duplicate_pokemon.empty?)
check("Independent completion doesn't change the continuous offset (#{FullPoke.progress.current_continuous_offset})",
      FullPoke.progress.current_continuous_offset == 65)

section "Enhanced Gym Leader teams (second continuous region)"
on_map(93)
$player.party.first.level = 110
FullPoke.record_party_levels
FullPoke.complete_region(:johto)
check("Offset after Johto: 110 - 5 = 105", FullPoke.progress.current_continuous_offset == 105)
FullPoke.state(:kanto).instance_variable_set(:@completed, false)   # pretend Kanto is next
FullPoke.progress.completion_order.delete(:kanto)
st = FullPoke.state(:kanto)
st.mode = nil
FullPoke.begin_region(:kanto, :continuous)
on_map(23)
check("Kanto is now the 3rd continuous region (index #{st.continuous_index}), offset #{st.offset}", st.continuous_index >= 2 && st.offset == 105)
st.starter = :BULBASAUR
brock = pbLoadTrainer(:KANTOLEADER_Brock, "Brock")
EventHandlers.trigger(:on_trainer_load, brock)
describe_team("Brock", brock)
check("Brock has exactly 5 Pokémon", brock.party.length == 5)
check("All are Rock type", brock.party.all? { |pk| pk.types.include?(:ROCK) })
check("All fully evolved", brock.party.all? { |pk| FullPoke::Evolution.fully_evolved?(pk.species) })
check("Ace level = 14 + 105 = #{brock.party.last.level}", brock.party.last.level == 119)
check("Every Pokémon has 4 moves and an item", brock.party.all? { |pk| pk.moves.length == 4 && pk.item })
giovanni = FullPoke.build_trainer(:kanto_giovanni)
describe_team("Giovanni", giovanni)
check("Giovanni: 5 Ground types, fully evolved, ace L155", giovanni.party.length == 5 &&
      giovanni.party.all? { |pk| pk.types.include?(:GROUND) && FullPoke::Evolution.fully_evolved?(pk.species) } &&
      giovanni.party.last.level == 155)
# Strength apart from level: species, IVs, EVs and nature, compared at level 100.
strength = lambda do |tr|
  tr.party.sum do |pk|
    c = Marshal.load(Marshal.dump(pk))
    c.level = 100
    c.calc_stats
    c.totalhp + c.attack + c.defense + c.spatk + c.spdef + c.speed
  end / tr.party.length
end
check("Late Gym stronger than first Gym at equal level (#{strength.call(giovanni)} vs #{strength.call(brock)}), and higher level",
      strength.call(giovanni) > strength.call(brock) * 1.05 && giovanni.party.last.level > brock.party.last.level)
lance = FullPoke.build_trainer(:kanto_lance)
describe_team("Lance", lance)
check("Elite Four Lance has 6 Dragon types", lance.party.length == 6 && lance.party.all? { |pk| pk.types.include?(:DRAGON) })
champ = FullPoke.build_trainer(:kanto_champion)
describe_team("Champion", champ)
check("Champion: 6 Pokémon, ace is Charizard L#{champ.party.last.level}", champ.party.length == 6 && champ.party.last.species == :CHARIZARD && champ.party.last.level == 168)
check("Enhanced trainers use the best AI (#{champ.skill_level})", champ.skill_level >= 100)
res = quick_trainer_battle(champ, Pokemon.new(:MEWTWO, 200))
check("A battle against the L168 enhanced Champion runs to the end (outcome #{res})", [1, 2].include?(res))

section "Independent and first-continuous Gyms keep traditional teams"
$fullpoke = FullPoke::Progress.new
FullPoke.begin_region(:kanto, :independent)
on_map(23)
brock = pbLoadTrainer(:KANTOLEADER_Brock, "Brock")
EventHandlers.trigger(:on_trainer_load, brock)
check("Independent Brock: Geodude L12, Onix L14", brock.party.map { |pk| [pk.species, pk.level] } == [[:GEODUDE, 12], [:ONIX, 14]])

section "Forest rare-Pokémon pool"
$fullpoke = FullPoke::Progress.new
check("No completed regions -> empty pool", FullPoke::Forest.pool(:land).empty? && FullPoke::Forest.choose(:Land, 0.0).nil?)
FullPoke.begin_region(:kanto, :continuous)
FullPoke.complete_region(:kanto)
pool = FullPoke::Forest.pool(:land)
kanto_maps = FullPoke.maps_of_region(:kanto)
check("Kanto completed -> #{pool.length} land species: #{pool.map { |e| e[:species] }.join(' ')}", pool.length > 0)
check("Every entry comes from a Kanto map", pool.all? { |e| kanto_maps.include?(e[:map]) })
ok = pool.all? do |e|
  enc = GameData::Encounter.get(e[:map], 0)
  slots = enc.types[e[:type]]
  total = slots.sum { |s| s[0] }
  share = slots.select { |s| s[1] == e[:species] }.sum { |s| s[0] } * 100.0 / total
  share <= FullPoke::RARE_THRESHOLD
end
check("Each species' summed slot share at its source is <= 5%", ok)
check("No duplicates", pool.map { |e| e[:species] }.uniq.length == pool.length)
check("Per-species chance #{FullPoke::Forest.species_chance(:land).round(2)}% <= 5%", FullPoke::Forest.species_chance(:land) <= 5.0)
common = []
kanto_maps.each do |m|
  enc = GameData::Encounter.get(m, 0)
  next if !enc
  enc.types.each_value do |slots|
    total = slots.sum { |s| s[0] }
    slots.map { |s| s[1] }.uniq.each do |sp|
      share = slots.select { |s| s[1] == sp }.sum { |s| s[0] } * 100.0 / total
      common.push(sp) if share > 20
    end
  end
end
always_common = common.uniq.reject { |sp| FullPoke::Forest.rare_entries(:kanto).any? { |e| e[:species] == sp } }
check("Common-only Kanto species are excluded (e.g. #{always_common.first(5).join(', ')})",
      always_common.none? { |sp| pool.any? { |e| e[:species] == sp } })
johto_only = FullPoke::Forest.rare_entries(:johto).select { |e| FullPoke::Forest.kind_of(e[:type]) == :land }.map { |e| e[:species] }.uniq -
             FullPoke::Forest.rare_entries(:kanto).map { |e| e[:species] }
check("Johto-only rares absent before Johto is completed (#{johto_only.first(5).join(', ')})",
      johto_only.none? { |sp| pool.any? { |e| e[:species] == sp } })
FullPoke.begin_region(:johto, :independent)
FullPoke.complete_region(:johto)
pool2 = FullPoke::Forest.pool(:land)
check("Johto completed -> pool grows #{pool.length} -> #{pool2.length}, includes Johto rares",
      pool2.length >= pool.length && johto_only.all? { |sp| pool2.any? { |e| e[:species] == sp } })
counts = Hash.new(0)
n = 20000
n.times { r = FullPoke::Forest.choose(:Land); counts[r ? r[0] : nil] += 1 }
max_share = counts.reject { |k, _| k.nil? }.values.max.to_f * 100 / n
check("Sampled #{n} forest opportunities: nothing #{(counts[nil] * 100.0 / n).round(1)}%, top species #{max_share.round(2)}% (<= ~5%)",
      max_share <= 5.6 && counts[nil] >= n * 0.45)

section "Save and load keep regions and party sets"
$fullpoke = FullPoke::Progress.new
on_map(34)
FullPoke.begin_region(:kanto, :continuous)
$player.party.replace([Pokemon.new(:PIKACHU, 30)])
FullPoke.begin_region(:sinnoh, :independent)
on_map(227)   # Route 201
FullPoke.give_starter(:sinnoh, :PIPLUP)
path = File.join(System.data_directory, 'headless_systems.rxdata')
check("Game saves", Game.save(path))
data = SaveData.read_from_file(path)
SaveData.mark_values_as_unloaded
Game.load(data)
check("After load: Sinnoh party (#{$player.party.map(&:name).join}) and Kanto party stashed",
      $player.party.map(&:species) == [:PIPLUP] && $fullpoke.contexts[:main].party.map(&:species) == [:PIKACHU])
check("Modes kept (kanto #{FullPoke.region_mode(:kanto)}, sinnoh #{FullPoke.region_mode(:sinnoh)})",
      FullPoke.region_mode(:kanto) == :continuous && FullPoke.region_mode(:sinnoh) == :independent)
on_map(34)
check("Walking back into Kanto restores Pikachu", $player.party.map(&:species) == [:PIKACHU])

finish
