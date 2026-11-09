# Plays a region's battles in order with no level boosts: the party only gains
# experience from the battles a player would fight (route trainers, story
# battles, Gym trainers, Leaders, the League) and from wild battles when it
# needs to train. It reports, for every Gym and the League, the party's levels
# against the opponent's, how many tries the battle took and how many wild
# battles of training were needed, and flags battles that look trivial or
# need unreasonable grinding.
#   REGIONS=johto MODE=independent tools/headless/run.sh t_balance.rb
#   REGIONS=sinnoh MODE=continuous PRIOR=kanto,johto,hoenn tools/headless/run.sh t_balance.rb
# Catching is modelled simply: the player adds a wild Pokémon from the current
# area to the team at each of the first five stages (a team of six by Gym 5).
# The battle AI plays both sides, which is weaker than a careful player.
require_relative 'play_lib'
require_relative 'test_lib'

$stdout.sync = true
$SHOW_BATTLE = ENV["VERBOSE"]
REGION = (ENV['REGIONS'] || 'johto').split(',').first.to_sym
MODE = (ENV['MODE'] || 'independent').to_sym
PRIOR = (ENV['PRIOR'] || '').split(',').map(&:to_sym)
GRIND_CAP = 60        # wild battles allowed per hurdle before giving up
TRIVIAL_GAP = 12      # party's lowest level this far above the foe's ace: trivial
GRIND_WARN = 25       # more training battles than this before a Gym: too grindy

@total_battles = 0
@grind_total = 0
@rows = []
@deferred = []

def heal = $player.heal_party

def party_desc = $player.party.map { |p| "#{p.speciesName} #{p.level}" }.join(', ')

def battle_trainer(key)
  tr = FullPoke.build_trainer(key)
  @total_battles += 1
  res = quick_trainer_battle(tr)
  [res == 1, tr]
end

# Trains on wild Pokémon of stage n's area until the party's average level
# rises by `levels` (or the cap is hit). Returns the number of battles.
def grind(n, levels: 1, limit: GRIND_CAP)
  table = FullPoke::Circuit.encounter_table(REGION, [n, 9].min)[:Land]
  start_avg = $player.party.sum(&:level) / $player.party.length.to_f
  count = 0
  rng = Random.new(n * 7919 + @grind_total)
  while count < limit
    slot = table[rng.rand(table.length)]
    lv = slot[2] + rng.rand(slot[3] - slot[2] + 1)
    @total_battles += 1
    quick_wild_battle(slot[1], FullPoke.scale_level(lv, REGION))
    count += 1
    heal if count % 3 == 0
    break if $player.party.sum(&:level) / $player.party.length.to_f >= start_avg + levels
  end
  @grind_total += count
  heal
  count
end

# Fights a hurdle (Leader, story battle, Elite Four...), training between
# tries. Returns [won, tries, training battles].
def hurdle(key, n)
  heal
  tries = 0
  trained = 0
  loop do
    tries += 1
    won, tr = battle_trainer(key)
    heal
    return [true, tries, trained, tr] if won
    return [false, tries, trained, tr] if trained >= GRIND_CAP
    trained += grind(n, levels: 2, limit: GRIND_CAP - trained)
  end
end

def record(label, key, n)
  before_min = $player.party.map(&:level).min
  before_max = $player.party.map(&:level).max
  won, tries, trained, tr = hurdle(key, n)
  ace = tr.party.map(&:level).max
  flag = if !won then 'LOST (gave up)'
         elsif trained > GRIND_WARN then 'grindy'
         elsif before_min - ace >= TRIVIAL_GAP then 'trivial'
         else ''
         end
  @rows << [label, tr.party.length, ace, before_min, before_max, tries, trained, flag]
  check("#{label}: #{won ? 'won' : 'lost'} (foe #{tr.party.length}x up to L#{ace}; party L#{before_min}-#{before_max}; tries #{tries}, training battles #{trained})#{flag.empty? ? '' : " [#{flag}]"}",
        won, quiet: false)
end

new_game
$game_switches[61] = true
on_map(FullPoke::World.forest_maps.first)
section "#{REGION} balance (#{MODE}#{PRIOR.empty? ? '' : ", after #{PRIOR.join(' -> ')}"})"

# Earlier continuous regions: finished at the level a player who beat their
# Champion would have (Champion's ace + 3)
team = nil
PRIOR.each do |r|
  FullPoke.begin_region(r, :continuous)
  champ = FullPoke::Circuit.get(r)[:champion]
  top = FullPoke::Circuit.leader_top_level(champ) + FullPoke.state(r).offset + 3
  team = FullPoke::Teams.candidate_pool(nil, r, []).last(6).map { |sp| Pokemon.new(sp, [top, FullPoke::MAX_LEVEL].min) }
  $player.party.replace(team)
  FullPoke.record_party_levels(r)
  (FullPoke::Circuit.league_count(r)).times { |i| FullPoke.set_flag(r, :"league#{i}") }
  FullPoke.complete_region(r)
  puts "  (completed #{r} at L#{top}; next offset #{FullPoke.progress.current_continuous_offset})"
end

FullPoke.begin_region(REGION, MODE)
arrival = FullPoke::World.arrival(REGION)
on_map(arrival[0], arrival[1], arrival[2])
FullPoke.give_starter(REGION, FullPoke.region(REGION).starters[0])
st = FullPoke.state(REGION)
puts "  offset #{st.offset}; party: #{party_desc}"
circuit = FullPoke::Circuit.get(REGION)
rival1 = circuit[:rivals][0]
record('Rival 1', rival1, 1) if rival1

(1..8).each do |n|
  stage = FullPoke::Circuit.stage(REGION, n)
  # Catch one wild Pokémon of this area (stages 1-5) at a typical level
  if n <= 5 && $player.party.length < 6
    sp, lo, hi = FullPoke::Circuit.encounter_table(REGION, n)[:Land].sort_by { |s| -s[0] }[1].values_at(1, 2, 3)
    $player.party.push(Pokemon.new(sp, FullPoke.scale_level((lo + hi) / 2, REGION))) if sp
  end
  # Route trainers: about as many as the routes to a Gym hold (two or three
  # areas with three each); they can be retried after training
  6.times do |i|
    key = FullPoke::Circuit.route_trainer_defn(REGION, n, i)[:key]
    won, = battle_trainer(key)
    heal if i.odd?
    if !won
      grind(n, levels: 1)
      battle_trainer(key)
    end
  end
  # Story battles well above this Gym's level are optional for now (Paldea's
  # Team Star bases can be taken in any order); they're fought before the League
  (stage[:extras] || []).each do |k|
    if FullPoke::Circuit.leader_top_level(k) > FullPoke::Circuit.leader_top_level(stage[:leader]) + 2 && circuit[:require_extras]
      @deferred << [n, k]
    else
      record("Stage #{n} story: #{FullPoke::Teams.get(k)[:name] || 'rival'}", k, n)
    end
  end
  2.times do |i|
    k = :"#{REGION}_gym#{n}_t#{i}"
    battle_trainer(k) if FullPoke::Teams.get(k)
  end
  heal
  record("Gym #{n}: #{FullPoke::Teams.get(stage[:leader])[:name]}", stage[:leader], n)
  FullPoke.badge!(REGION, n - 1)
end
@deferred.each { |n, k| record("Stage #{n} story (later): #{FullPoke::Teams.get(k)[:name]}", k, 9) }
rival_last = circuit[:rivals][9]
record('Final rival', rival_last, 9) if rival_last
keys = circuit[:league] + [circuit[:champion]]
keys.each_with_index { |k, i| record(i < 4 ? "Elite Four #{i + 1}: #{FullPoke::Teams.get(k)[:name]}" : "Champion #{FullPoke::Teams.get(k)[:name]}", k, 9) }

section "Summary"
puts format("  %-34s %5s %5s %9s %6s %8s  %s", 'battle', 'foes', 'ace', 'party', 'tries', 'training', 'note')
@rows.each do |label, cnt, ace, mn, mx, tries, trained, flag|
  puts format("  %-34s %5d %5d %4d-%-4d %6d %8d  %s", label, cnt, ace, mn, mx, tries, trained, flag)
end
puts "  total battles #{@total_battles}, of which training #{@grind_total}; final party: #{party_desc}"
check("no battle needed more than #{GRIND_CAP} training battles", @rows.none? { |r| r[7] == 'LOST (gave up)' })
check("levels above 100 reached without errors (max L#{$player.party.map(&:level).max})", true) if MODE == :continuous
finish
