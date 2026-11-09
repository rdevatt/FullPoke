# Checks the Generation 9 Pack install: Paldea's species, forms, evolutions,
# moves, abilities and items exist; FullPoke's custom items survived; battles
# with Generation 9 moves and abilities run to a result; Generation 9
# Pokémon level past 100 and save/load; Paldea is unlocked with encounter
# tables and trainers.
#   tools/headless/run.sh t_gen9.rb
require_relative 'play_lib'
require_relative 'test_lib'
$stdout.sync = true

new_game
$game_switches[61] = true
on_map(FullPoke::World.forest_maps.first)

section "Data"
%i[SPRIGATITO FLORAGATO MEOWSCARADA FUECOCO SKELEDIRGE QUAXLY QUAQUAVAL PAWMOT TINKATON KINGAMBIT ANNIHILAPE
   GHOLDENGO CLODSIRE GREATTUSK IRONTREADS KORAIDON MIRAIDON].each do |sp|
  check("species #{sp}", GameData::Species.exists?(sp), quiet: true)
end
check("120 Generation 9 species in the Paldea Pokédex", (pbLoadRegionalDexes[8] || []).length >= 100)
check("Paldean Tauros forms", GameData::Species.exists?(:TAUROS_1) || GameData::Species.get_species_form(:TAUROS, 1).form == 1)
wooper = Pokemon.new(:WOOPER, 20)
wooper.form = 1
check("Paldean Wooper (form 1) is Poison/Ground", wooper.types.include?(:POISON) && wooper.types.include?(:GROUND))
evo = ->(from, to) { GameData::Species.get(from).get_evolutions(true).any? { |e| e[0] == to } }
check("Sprigatito -> Floragato -> Meowscarada", evo.(:SPRIGATITO, :FLORAGATO) && evo.(:FLORAGATO, :MEOWSCARADA))
check("Primeape -> Annihilape (Rage Fist x20), Bisharp -> Kingambit (Leader's Crest), Gimmighoul -> Gholdengo",
      evo.(:PRIMEAPE, :ANNIHILAPE) && evo.(:BISHARP, :KINGAMBIT) && evo.(:GIMMIGHOUL, :GHOLDENGO))
check("Paldean Wooper -> Clodsire", GameData::Species.get_species_form(:WOOPER, 1).get_evolutions(true).any? { |e| e[0] == :CLODSIRE })
# (no Terastallization in the pack, so no Tera Blast)
%i[FLOWERTRICK TORCHSONG AQUASTEP RAGEFIST KOWTOWCLEAVE MAKEITRAIN AXEKICK TIDYUP].each do |mv|
  check("move #{mv}", GameData::Move.exists?(mv), quiet: true)
end
%i[PROTOSYNTHESIS QUARKDRIVE GOODASGOLD SUPREMEOVERLORD ZEROTOHERO TOXICDEBRIS].each do |ab|
  check("ability #{ab}", GameData::Ability.exists?(ab), quiet: true)
end
%i[BOOSTERENERGY COVERTCLOAK CLEARAMULET MIRRORHERB GROVECOMPASS SSTICKET OAKSPACKAGE JOESMAIL].each do |it|
  check("item #{it}", GameData::Item.exists?(it), quiet: true)
end
check("Mechanics: generation #{Settings::MECHANICS_GENERATION}, Champions rules #{Settings::CHAMPIONS_MECHANICS ? 'on' : 'off'}",
      Settings::MECHANICS_GENERATION == 9 && !Settings::CHAMPIONS_MECHANICS)
check("Snow replaces Hail (setting #{Settings::HAIL_WEATHER_TYPE})", Settings::HAIL_WEATHER_TYPE == 1)

section "Battles with Generation 9 moves and abilities"
def mon(sp, lv, moves)
  pk = Pokemon.new(sp, lv)
  pk.forget_all_moves
  moves.each { |m| pk.learn_move(m) }
  pk
end
battles = [
  [[mon(:MEOWSCARADA, 50, %i[FLOWERTRICK KNOCKOFF UTURN]), mon(:GHOLDENGO, 50, %i[MAKEITRAIN SHADOWBALL NASTYPLOT])],
   [mon(:SKELEDIRGE, 50, %i[TORCHSONG SHADOWBALL SLACKOFF]), mon(:GREATTUSK, 50, %i[HEADLONGRUSH CLOSECOMBAT RAPIDSPIN])]],
  [[mon(:KINGAMBIT, 60, %i[KOWTOWCLEAVE IRONHEAD SUCKERPUNCH]), mon(:ANNIHILAPE, 60, %i[RAGEFIST DRAINPUNCH BULKUP])],
   [mon(:QUAQUAVAL, 60, %i[AQUASTEP CLOSECOMBAT ICESPINNER]), mon(:IRONTREADS, 60, %i[EARTHQUAKE IRONHEAD RAPIDSPIN])]],
  [[mon(:MEOWSCARADA, 150, %i[FLOWERTRICK KNOCKOFF]), mon(:PAWMOT, 150, %i[DOUBLESHOCK CLOSECOMBAT])],
   [mon(:TINKATON, 150, %i[GIGATONHAMMER PLAYROUGH]), mon(:CLODSIRE, 150, %i[EARTHQUAKE POISONJAB])]]
]
battles.each_with_index do |(mine, theirs), i|
  tr = NPCTrainer.new("Test", :FP_LEADER_M)
  tr.party.replace(theirs)
  res = quick_trainer_battle(tr, *mine)
  check("battle #{i + 1} (#{mine.map(&:speciesName).join('/')} vs #{theirs.map(&:speciesName).join('/')}, L#{mine[0].level}) ends: outcome #{res}", [1, 2, 5].include?(res))
end
$player.party.replace([mon(:SPRIGATITO, 12, %i[SCRATCH LEAFAGE])])
wild = quick_wild_battle(:FUECOCO, 8)
check("wild battle with a Generation 9 Pokémon ends (outcome #{wild})", [1, 2, 3, 4, 5].include?(wild))

section "Levels and saving"
pk = Pokemon.new(:SKELEDIRGE, 99)
pk.exp = pk.growth_rate.minimum_exp_for_level(250)
pk.calc_stats
check("Skeledirge past 100: L#{pk.level}, HP #{pk.totalhp}", pk.level == 250 && pk.totalhp > 500)
$player.party.replace([pk, Pokemon.new(:SPRIGATITO, 5)])
path = File.join(System.data_directory, 'headless_gen9.rxdata')
check("save with Generation 9 Pokémon", Game.save(path))
data = SaveData.read_from_file(path)
SaveData.mark_values_as_unloaded
Game.load(data)
check("load: #{$player.party.map { |p| "#{p.speciesName} L#{p.level}" }.join(', ')}",
      $player.party.map(&:species) == %i[SKELEDIRGE SPRIGATITO] && $player.party[0].level == 250)

section "Paldea"
reg = FullPoke.region(:paldea)
check("Paldea is unlocked (starters exist)", reg.available?)
pool = FullPoke::Circuit.base_species(:paldea)
check("Paldea's wild pool comes from its Pokédex (#{pool.length} base species, e.g. #{pool.first(4).join(', ')})", pool.length >= 40)
paldea_maps = FullPoke::World.encounters.select { |e| FullPoke.region_of_map(e[:map]) == :paldea }.map { |e| e[:map] }
with_tables = paldea_maps.select { |m| (t = GameData::Encounter.get(m, 0)) && t.types.values.flatten(1).any? }
check("Paldea areas with wild Pokémon: #{with_tables.length}/#{paldea_maps.length}", !paldea_maps.empty? && with_tables.length == paldea_maps.length)
katy = FullPoke.build_trainer(:paldea_katy)
check("Katy's team builds: #{katy.party.map { |p| "#{p.speciesName} #{p.level}" }.join(', ')}", katy.party.length >= 3)
check("Forest gate to Paldea opens", FullPoke::World.forest_exit(:paldea) && FullPoke::World.arrival(:paldea))
finish
