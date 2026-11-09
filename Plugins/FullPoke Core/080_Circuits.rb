#===============================================================================
# Region "circuits": the playable route through each region outside Kanto.
#
# A circuit is: start town -> 8 stages (route + town with a Gym or equivalent)
# -> Victory Road -> League (Elite Four rooms + Champion). Each region's data
# (1xx_Data_*.rb) lists its stages and important trainers; route trainers and
# wild Pokémon are generated from the region's Pokédex so every route has
# region-appropriate species at the right level (see stage_levels).
#
# Generated content is deterministic (seeded by region and stage), so it is the
# same every time the game runs and for every save.
#===============================================================================
module FullPoke
  module Circuit
    STAGES = 8
    # Encounter slot chances (%), commonest first. The last two are rare (<= 5%).
    SLOT_CHANCES = [25, 20, 15, 15, 10, 10, 5]
    TRAINER_CLASSES = [
      [:YOUNGSTER, "trainer_YOUNGSTER", %w[Joey Ben Tim Mikey Dan Sam]],
      [:LASS, "trainer_LASS", %w[Dana Ellen Robin Ali Kay Mia]],
      [:BUGCATCHER, "trainer_BUGCATCHER", %w[Rick Doug Wade Al Benny Ken]],
      [:CAMPER, "trainer_CAMPER", %w[Liam Shane Jeff Ethan Todd Drew]],
      [:PICNICKER, "trainer_PICNICKER", %w[Gina Liz Erin Tanya Kim Joy]],
      [:HIKER, "trainer_HIKER", %w[Russ Daniel Anthony Bailey Tim Eric]],
      [:BIRDKEEPER, "trainer_BIRDKEEPER", %w[Toby Perry Bret Hank Vance Roy]],
      [:BEAUTY, "trainer_BEAUTY", %w[Bridget Olivia Lola Sheila Grace Tamia]],
      [:BLACKBELT, "trainer_BLACKBELT", %w[Kenji Lao Nob Yoshi Kiyo Hitoshi]],
      [:COOLTRAINER_M, "trainer_COOLTRAINER_M", %w[Gaven Jake Aaron Cody Mike Paul]],
      [:COOLTRAINER_F, "trainer_COOLTRAINER_F", %w[Cara Beth Irene Jenn Kate Megan]],
      [:PSYCHIC_M, "trainer_PSYCHIC_M", %w[Mark Nathan Phil Richard Gregory Jared]],
      [:POKEMANIAC, "trainer_POKEMANIAC", %w[Larry Andrew Calvin Shane Ron Brent]],
      [:SCIENTIST, "trainer_SCIENTIST", %w[Ted Jose Marc Rich Gideon Lowell]]
    ]

    @regions = {}

    module_function

    # Registers a region's circuit:
    #   stages:  Array of { town:, leader: trainer key, badge:, totem: [species, level],
    #                       extras: [trainer keys battled in that town] }
    #   league:  Array of trainer keys for the Elite Four rooms
    #   champion: trainer key; final: optional trainer key battled after the Champion
    #   rivals:  { stage index => trainer key } (0 = in the start town)
    #   legendary: [species, level]
    #   require_extras: true if every :extras battle must be won before the final
    def define(region_id, data)
      @regions[region_id] = data
    end

    def get(region_id) = @regions[region_id]
    def defined?(region_id) = @regions.key?(region_id)
    def region_ids = @regions.keys

    def stage(region_id, n) = get(region_id)[:stages][n - 1]

    #---------------------------------------------------------------------------
    # Levels (traditional, before any continuous offset)
    #---------------------------------------------------------------------------
    def leader_top_level(key)
      defn = Teams.get(key)
      return 5 if !defn || !defn[:party]
      return FullPoke.parse_party(defn[:party]).map { |p| p[:level] }.max || 5
    end

    # [min, max] wild level on the route leading to stage n (n = 1..8, 9 = Victory Road)
    def stage_levels(region_id, n)
      return [2, 5] if n <= 1
      prev = leader_top_level(stage(region_id, n - 1)[:leader])
      lo = [(prev * 0.8).round, 2].max
      hi = [prev + 1, lo + 2].max
      return [lo, hi]
    end

    #---------------------------------------------------------------------------
    # Species
    #---------------------------------------------------------------------------
    # The region's Pokédex as base species, in Pokédex order.
    def base_species(region_id)
      @base_cache ||= {}
      return @base_cache[region_id] if @base_cache[region_id]
      reg = FullPoke.region(region_id)
      list = nil
      if reg && reg.dex
        dex = pbLoadRegionalDexes[reg.dex]
        list = dex if dex && !dex.empty?
      end
      if !list && region_id == :paldea
        list = []
        GameData::Species.each_species { |sp| list.push(sp.species) if sp.generation == 9 }
      end
      list ||= []
      ret = []
      list.each do |sp|
        next if !GameData::Species.exists?(sp)
        data = GameData::Species.get(sp)
        next if Teams::EXCLUDED_FLAGS.any? { |f| data.has_flag?(f) }
        base = data.get_baby_species
        base = data.get_previous_species while GameData::Species.get(base).get_previous_species != base
        ret.push(base) if !ret.include?(base)
      end
      @base_cache[region_id] = ret
      return ret
    end

    # Seven species for the route before stage n, evolved to suit its levels.
    def route_species(region_id, n)
      pool = base_species(region_id)
      return [] if pool.empty?
      rng = Random.new(Zlib.crc32("#{region_id}/route/#{n}"))
      size = pool.length
      lo = ((n - 1) * size / (STAGES + 1.5)).floor
      hi = [(((n + 1.5) * size) / (STAGES + 1.5)).ceil, size].min
      window = pool[lo...hi]
      window = pool if window.length < SLOT_CHANCES.length
      picks = window.shuffle(random: rng).first(SLOT_CHANCES.length)
      _min, max = stage_levels(region_id, n)
      return picks.map { |sp| FullPoke::Evolution.stage_for(sp, max, 0) }.uniq
    end

    # Types that suit each kind of area, so caves get cave Pokémon and water
    # routes get water Pokémon.
    KIND_TYPES = { cave: %i[ROCK GROUND POISON DARK STEEL FIGHTING ICE GHOST],
                   water: %i[WATER] }
    KIND_STEPS = { land: [:Land, 21], cave: [:Cave, 8], water: [:Water, 2] }

    # Wild Pokémon for an area of stage n. kinds: :land (tall grass), :cave and/or
    # :water; water areas also get fishing.
    def encounter_table(region_id, n, kinds = [:land])
      ret = {}
      Array(kinds).each do |kind|
        species = route_species(region_id, n)
        if KIND_TYPES[kind]
          fits = base_species(region_id).select { |sp| (GameData::Species.get(sp).types & KIND_TYPES[kind]).any? }
          rng = Random.new(Zlib.crc32("#{region_id}/#{kind}/#{n}"))
          pool = fits.each_slice([fits.length / 4, 1].max).to_a
          window = (pool[[n * pool.length / 10, pool.length - 1].min] || []) + (pool[[n * pool.length / 10 + 1, pool.length - 1].min] || [])
          window = fits if window.length < 4
          _min, max = stage_levels(region_id, n)
          picked = window.shuffle(random: rng).first(SLOT_CHANCES.length).map { |sp| FullPoke::Evolution.stage_for(sp, max, 0) }.uniq
          species = picked if !picked.empty?
        end
        min, max = stage_levels(region_id, n)
        slots = []
        species.each_with_index { |sp, i| slots.push([SLOT_CHANCES[i] || 5, sp, min, max]) }
        used = slots.sum { |sl| sl[0] }
        slots[0][0] += 100 - used if slots[0] && used < 100
        type = KIND_STEPS[kind][0]
        ret[type] = slots
        if kind == :water
          rod = species.first(3)
          ret[:OldRod] = rod.each_with_index.map { |sp, i| [[70, 20, 10][i], sp, [min - 5, 2].max, [min, 2].max] } if !rod.empty?
          ret[:GoodRod] = rod.each_with_index.map { |sp, i| [[60, 30, 10][i], sp, [min, 2].max, max] } if !rod.empty?
        end
      end
      return ret
    end

    def encounter_steps(kinds = [:land])
      ret = {}
      Array(kinds).each { |k| ret[KIND_STEPS[k][0]] = KIND_STEPS[k][1] }
      ret[:OldRod] = ret[:GoodRod] = 100 if Array(kinds).include?(:water)
      return ret
    end

    #---------------------------------------------------------------------------
    # Route trainers
    #---------------------------------------------------------------------------
    def route_trainer_key(region_id, n, idx) = :"#{region_id}_route#{n}_t#{idx}"

    def route_trainer_class(region_id, n, idx)
      rng = Random.new(Zlib.crc32("#{region_id}/trainer/#{n}/#{idx}"))
      cls = TRAINER_CLASSES[rng.rand(TRAINER_CLASSES.length)]
      return [cls[0], cls[1], cls[2][rng.rand(cls[2].length)]]
    end

    def route_trainer_defn(region_id, n, idx)
      key = route_trainer_key(region_id, n, idx)
      return Teams.get(key) if Teams.get(key)
      tr_type, _gfx, name = route_trainer_class(region_id, n, idx)
      rng = Random.new(Zlib.crc32("#{region_id}/party/#{n}/#{idx}"))
      species = route_species(region_id, n)
      _min, max = stage_levels(region_id, n)
      count = [1 + rng.rand(n >= 4 ? 3 : 2), species.length].min
      party = species.shuffle(random: rng).first(count).map.with_index do |sp, i|
        "#{sp}:#{max + i}"
      end.join(" ")
      return Teams.register(key: key, region: region_id, role: :trainer, tr_type: tr_type,
                            name: name, party: party, lose_text: "You're strong!")
    end

    def route_trainer_battle(region_id, n, idx)
      route_trainer_defn(region_id, n, idx)
      return FullPoke.trainer_battle(route_trainer_key(region_id, n, idx))
    end

    #---------------------------------------------------------------------------
    # Challenges
    #---------------------------------------------------------------------------
    # Battles the stage's leader; on a win, awards the badge. Returns true on a win.
    def challenge(region_id, n)
      st = stage(region_id, n)
      if FullPoke.badge?(region_id, n - 1)
        pbMessage(_INTL("You already have the {1}. Good luck on your journey!", st[:badge]))
        return true
      end
      if st[:totem] && !FullPoke.flag?(region_id, :"totem#{n}")
        return false if !totem_battle(region_id, n)
      end
      return false if !FullPoke.trainer_battle(st[:leader])
      FullPoke.badge!(region_id, n - 1)
      pbMEPlay("Badge get") rescue nil
      pbMessage(_INTL("\\PN received the {1}!", st[:badge]))
      return true
    end

    # Alola's Totem Pokémon and Paldea's Titans: a strengthened wild battle.
    def totem_battle(region_id, n)
      st = stage(region_id, n)
      species, level = st[:totem]
      return true if !GameData::Species.exists?(species)
      pbMessage(_INTL("A powerful {1} appears!", GameData::Species.get(species).name))
      setBattleRule("canLose")
      setBattleRule("cannotRun")
      setBattleRule("disablePokeBalls")
      FullPoke.instance_variable_set(:@totem_next, true)
      # WildBattle.start is true unless the player lost (running and catching
      # are disabled here, so true means the Totem was defeated)
      won = WildBattle.start(species, level) ? true : false
      FullPoke.set_flag(region_id, :"totem#{n}") if won
      return won
    end

    # Extra story battles in a stage (rival, villain, Team Star bases…).
    def extra_battle(region_id, key)
      flag = :"beat_#{key}"
      if FullPoke.flag?(region_id, flag)
        return true
      end
      won = FullPoke.trainer_battle(key)
      FullPoke.set_flag(region_id, flag) if won
      return won
    end

    def stage_extras_done?(region_id, n)
      return (stage(region_id, n)[:extras] || []).all? { |k| FullPoke.flag?(region_id, :"beat_#{k}") }
    end

    def extras_done?(region_id)
      data = get(region_id)
      keys = data[:stages].map { |s| s[:extras] || [] }.flatten
      return keys.all? { |k| FullPoke.flag?(region_id, :"beat_#{k}") }
    end

    def all_badges?(region_id)
      return (0...STAGES).all? { |i| FullPoke.badge?(region_id, i) }
    end

    # League rooms: battle number idx (0-3 Elite Four, 4 Champion, 5 final).
    def league_battle(region_id, idx)
      data = get(region_id)
      keys = data[:league] + [data[:champion]]
      keys.push(data[:final]) if data[:final]
      key = keys[idx]
      flag = :"league#{idx}"
      return true if FullPoke.flag?(region_id, flag)
      if idx == keys.length - 1 && data[:require_extras] && !extras_done?(region_id)
        pbMessage(_INTL("There's still unfinished business in {1}. Come back when every challenge is complete.",
                        FullPoke.region(region_id).name))
        return false
      end
      return false if !FullPoke.trainer_battle(key)
      FullPoke.set_flag(region_id, flag)
      if idx == keys.length - 1
        FullPoke.complete_region(region_id)
        pbMessage(_INTL("Congratulations! You've completed the {1} region!", FullPoke.region(region_id).name))
      end
      return true
    end

    def league_count(region_id)
      data = get(region_id)
      return data[:league].length + 1 + (data[:final] ? 1 : 0)
    end

    def league_cleared?(region_id, idx) = FullPoke.flag?(region_id, :"league#{idx}")

    # The region's legendary, available once the region is completed.
    def legendary(region_id)
      species, level = get(region_id)[:legendary]
      return if !GameData::Species.exists?(species)
      if !FullPoke.completed?(region_id)
        pbMessage(_INTL("A mysterious presence... It seems to be waiting for a true Champion."))
        return
      end
      return if FullPoke.flag?(region_id, :legendary)
      pbMessage(_INTL("{1} appeared!", GameData::Species.get(species).name))
      setBattleRule("canLose")
      # Caught or defeated: either way the encounter is over
      FullPoke.set_flag(region_id, :legendary) if WildBattle.start(species, level)
    end
  end

  # Totem/Titan Pokémon are tougher than their level suggests.
  EventHandlers.add(:on_wild_pokemon_created, :fullpoke_totem,
    proc { |pkmn|
      next if !FullPoke.instance_variable_get(:@totem_next)
      FullPoke.instance_variable_set(:@totem_next, false)
      GameData::Stat.each_main { |s| pkmn.iv[s.id] = Pokemon::IV_STAT_LIMIT; pkmn.ev[s.id] = 120 }
      pkmn.item = :SITRUSBERRY if GameData::Item.exists?(:SITRUSBERRY)
      pkmn.calc_stats
      pkmn.hp = pkmn.totalhp
    }
  )

  # After the Hall of Fame: back to the region's first town.
  def self.go_home(region_id)
    dest = World.home(region_id) || World.arrival(region_id)
    return false if !dest
    return transfer(*dest)
  end

  # Route trainer events call this.
  def self.route_trainer_battle(region_id, n, idx)
    return Circuit.route_trainer_battle(region_id, n, idx)
  end
end
