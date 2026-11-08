#===============================================================================
# Stronger teams for continuous adventures.
#
# From the second continuous region on, important trainers replace their
# traditional team:
#   Gym Leaders (and Alola/Galar/Paldea equivalents): exactly 5 Pokémon
#   Elite Four, Champions, villain bosses: 6 Pokémon
#   Rivals: 4-6 Pokémon depending on how far into the region the battle is
# Every replacement Pokémon is fully evolved and, for specialists, has the
# specialty type (dual types count). The leader's signature Pokémon leads the
# list when its final form keeps the type. Teams get stronger with each Gym and
# with each continuous region: higher base-stat species, better IVs/EVs, held
# items and the AI's best skill. Levels follow the traditional team's top level
# plus the region's offset, so the original Gym progression is kept.
#
# Trainers are registered with FullPoke::Teams.register (see 1xx_Data_*.rb).
# The same definition gives the traditional team for independent adventures.
#===============================================================================
module FullPoke
  module Teams
    ROLE_SIZES     = { gym: 5, e4: 6, champion: 6, boss: 6, rival: 6 }
    ENHANCED_ROLES = ROLE_SIZES.keys
    MIN_BST        = 420
    EXCLUDED_FLAGS = ["Legendary", "Mythical", "UltraBeast", "Paradox"]
    BAD_MOVE_FUNCTIONS = /^TwoTurnAttack|AttackAndSkipNextTurn|UserFaints|FailsIfUserDamagedThisTurn|^OHKO|FixedDamage|FailsIfNotUserFirstTurn|Bide|RandomlyDamageOrHeal|LowerUserSpAtk2|UserLosesHalfOfTotalHP/
    STATUS_MOVES = {
      physical: [:SWORDSDANCE, :DRAGONDANCE, :BULKUP, :SHELLSMASH, :HONECLAWS],
      special:  [:NASTYPLOT, :CALMMIND, :QUIVERDANCE, :TAILGLOW],
      support:  [:ROOST, :RECOVER, :SLACKOFF, :SOFTBOILED, :MOONLIGHT, :SYNTHESIS,
                 :WILLOWISP, :THUNDERWAVE, :TOXIC, :LEECHSEED, :STEALTHROCK, :SPIKES]
    }
    TYPE_ITEMS = {
      NORMAL: :SILKSCARF, FIRE: :CHARCOAL, WATER: :MYSTICWATER, GRASS: :MIRACLESEED,
      ELECTRIC: :MAGNET, ICE: :NEVERMELTICE, FIGHTING: :BLACKBELT, POISON: :POISONBARB,
      GROUND: :SOFTSAND, FLYING: :SHARPBEAK, PSYCHIC: :TWISTEDSPOON, BUG: :SILVERPOWDER,
      ROCK: :HARDSTONE, GHOST: :SPELLTAG, DRAGON: :DRAGONFANG, DARK: :BLACKGLASSES,
      STEEL: :METALCOAT, FAIRY: :FAIRYFEATHER
    }
    SUPPORT_ITEMS = [:LEFTOVERS, :SITRUSBERRY, :LUMBERRY, :EXPERTBELT, :FOCUSSASH, :LIFEORB]

    @by_key  = {}
    @by_type = {}

    module_function

    # defn keys:
    #   key        unique Symbol
    #   region     region id
    #   role       :gym, :e4, :champion, :boss, :rival or :trainer
    #   tr_type    trainer type ID
    #   name       trainer name (nil: rival name rules apply)
    #   party      traditional team, e.g. "GEODUDE:12 ONIX:14" (FullPoke trainers)
    #   types      specialty types (nil = any)
    #   signature  species the leader is known for
    #   tier       1-8 for Gyms, 9 Elite Four, 10 Champion…
    #   size       override team size
    #   rival_starter  true: the rival's ace is the starter strong against the player's
    #   lose_text, items
    # A definition can also describe a PBS trainer (no :party): the PBS team is
    # used traditionally and replaced when enhanced.
    def register(defn)
      raise ArgumentError, "trainer definition needs :key" if !defn[:key]
      @by_key[defn[:key]] = defn
      @by_type[defn[:tr_type]] = defn if defn[:tr_type] && !defn[:party]
      return defn
    end

    def get(key)
      return @by_key[key]
    end

    def all
      return @by_key.values
    end

    def for_trainer_type(tr_type)
      return @by_type[tr_type]
    end

    def counter_starter(region_id, player_starter)
      reg = FullPoke.region(region_id)
      return reg.starters[1] if !player_starter || !reg
      idx = reg.starters.index(player_starter) || reg.starters.index(GameData::Species.get(player_starter).get_baby_species) || 0
      return reg.starters[(idx + 1) % 3]
    end

    # Adjusts a loaded trainer for the given (or current) region.
    def adjust_trainer!(trainer, defn = nil, region_id = nil)
      region_id ||= defn ? defn[:region] : FullPoke.current_map_region
      defn ||= for_trainer_type(trainer.trainer_type)
      offset = region_offset(region_id)
      if defn && ENHANCED_ROLES.include?(defn[:role]) && FullPoke.enhanced_teams?(region_id)
        top = (trainer.party.map { |p| p.level }.max || 50) + offset
        trainer.party = enhanced_party(defn, region_id, top.clamp(1, FullPoke.level_cap), trainer)
        trainer.fullpoke_skill = 100
      elsif offset > 0
        trainer.party.each do |pkmn|
          level = (pkmn.level + offset).clamp(1, FullPoke.level_cap)
          species = FullPoke::Evolution.stage_for(pkmn.species, level, pkmn.form)
          FullPoke.retarget_pokemon(pkmn, species, level)
        end
      end
      return trainer
    end

    def region_offset(region_id)
      return 0 if !region_id
      return FullPoke.progress.current_continuous_offset if region_id == :forest
      st = FullPoke.state(region_id)
      return st.continuous? ? st.offset : 0
    end

    #---------------------------------------------------------------------------
    # Enhanced team building
    #---------------------------------------------------------------------------
    def team_size(defn)
      return defn[:size] if defn[:size]
      return ROLE_SIZES[defn[:role]] || 6
    end

    def power(defn, region_id)
      st = FullPoke.state(region_id)
      return (defn[:tier] || 1) + (4 * [st.continuous_index - 2, 0].max)
    end

    def rng_for(defn, region_id)
      st = FullPoke.state(region_id)
      return Random.new(Zlib.crc32("#{defn[:key]}/#{region_id}/#{st.continuous_index}"))
    end

    def enhanced_species(defn, region_id)
      size  = team_size(defn)
      pwr   = power(defn, region_id)
      rng   = rng_for(defn, region_id)
      types = defn[:types]
      chosen = []
      signature_list(defn, region_id).each do |sp|
        finals = FullPoke::Evolution.final_forms(sp).select { |f| eligible?(f, types, true) }
        next if finals.empty?
        regional = finals.select { |f| in_region_family?(f, region_id) }
        pick = (regional.empty? ? finals : regional).first
        chosen.push(pick) if !chosen.include?(pick)
        break if chosen.length >= [size - 1, 2].min
      end
      pool = candidate_pool(types, region_id, chosen)
      pool = candidate_pool(types, nil, chosen) if pool.length < size - chosen.length
      need = size - chosen.length
      if need > 0 && pool.length > 0
        # Later Gyms (and later continuous regions) draw from stronger species:
        # the ones nearest a target position in the pool (sorted weakest first).
        target = ((0.35 + (0.08 * pwr)).clamp(0.3, 1.0) * (pool.length - 1)).round
        nearest = (0...pool.length).sort_by { |i| [(i - target).abs, -i] }.first(need + 1)
        chosen.concat(nearest.map { |i| pool[i] }.shuffle(random: rng).first(need))
        chosen.concat((pool - chosen).last(size - chosen.length)) if chosen.length < size
      end
      # Ace (first signature) goes last
      ace = chosen.shift
      chosen.push(ace) if ace
      return chosen.first(size)
    end

    def signature_list(defn, region_id)
      ret = []
      if defn[:rival_starter]
        st = FullPoke.state(region_id)
        ret.push(counter_starter(region_id, st.starter))
      end
      ret.concat(defn[:signature] || [])
      return ret
    end

    def eligible?(species, types, allow_legendary = false)
      data = GameData::Species.get(species)
      return false if !allow_legendary && EXCLUDED_FLAGS.any? { |f| data.has_flag?(f) }
      return false if types && (data.types & types).empty?
      return true
    end

    def in_region_family?(species, region_id)
      reg = FullPoke.region(region_id)
      return true if !reg || !reg.dex
      dex = pbLoadRegionalDexes[reg.dex]
      return true if !dex
      sp = GameData::Species.get(species).species
      3.times do
        return true if dex.include?(sp)
        prev = GameData::Species.get(sp).get_previous_species
        break if prev == sp
        sp = prev
      end
      return false
    end

    # Fully evolved, non-legendary species of the types, weakest first.
    def candidate_pool(types, region_id, exclude)
      ret = []
      GameData::Species.each_species do |data|
        next if exclude.include?(data.species)
        next if data.base_stat_total < MIN_BST
        next if !FullPoke::Evolution.fully_evolved?(data.species)
        next if !eligible?(data.species, types)
        next if region_id && !in_region_family?(data.species, region_id)
        ret.push(data)
      end
      ret.sort_by! { |d| [d.base_stat_total, d.species.to_s] }
      return ret.map { |d| d.species }
    end

    def enhanced_party(defn, region_id, top_level, trainer)
      species = enhanced_species(defn, region_id)
      pwr = power(defn, region_id)
      rng = rng_for(defn, region_id)
      drops = [3, 2, 2, 1, 1, 0]
      party = []
      species.each_with_index do |sp, i|
        level = top_level - (i == species.length - 1 ? 0 : drops[i] || 1)
        level = level.clamp(1, FullPoke.level_cap)
        pkmn = Pokemon.new(sp, level, trainer, false)
        build_competitive!(pkmn, pwr, i == species.length - 1, rng)
        party.push(pkmn)
      end
      return party
    end

    def build_competitive!(pkmn, pwr, ace, rng)
      data = pkmn.species_data
      bs = data.base_stats
      physical = bs[:ATTACK] >= bs[:SPECIAL_ATTACK]
      fast = bs[:SPEED] >= 80
      # IVs/EVs
      iv = [18 + (pwr * 2), Pokemon::IV_STAT_LIMIT].min
      GameData::Stat.each_main { |s| pkmn.iv[s.id] = iv; pkmn.ev[s.id] = 0 }
      ev = [32 * pwr, Pokemon::EV_STAT_LIMIT].min
      pkmn.ev[physical ? :ATTACK : :SPECIAL_ATTACK] = ev
      pkmn.ev[fast ? :SPEED : :HP] = ev
      rest = [Pokemon::EV_LIMIT - (ev * 2), 0].max
      pkmn.ev[fast ? :HP : :DEFENSE] = [rest, Pokemon::EV_STAT_LIMIT].min
      pkmn.nature = physical ? (fast ? :JOLLY : :ADAMANT) : (fast ? :TIMID : :MODEST)
      pkmn.ability = best_ability(data)
      pkmn.forget_all_moves
      best_moves(pkmn, physical, rng).each { |m| pkmn.learn_move(m) }
      pkmn.item = pick_item(pkmn, ace, rng)
      pkmn.calc_stats
      pkmn.hp = pkmn.totalhp
    end

    def best_ability(data)
      choices = (data.abilities + data.hidden_abilities).uniq
      return choices.first if !defined?(Battle::AI::BASE_ABILITY_RATINGS)
      rating = {}
      Battle::AI::BASE_ABILITY_RATINGS.each_pair do |val, list|
        list.each { |ab| rating[ab] = val }
      end
      return choices.max_by { |ab| rating[ab] || 4 }
    end

    def learnable_moves(pkmn)
      data = pkmn.species_data
      level = [pkmn.level, 100].min
      ret = data.moves.select { |m| m[0] <= level }.map { |m| m[1] }
      ret.concat(data.tutor_moves)
      ret.concat(data.get_egg_moves) if data.respond_to?(:get_egg_moves)
      return ret.uniq.select { |m| GameData::Move.exists?(m) }
    end

    def best_moves(pkmn, physical, rng)
      types = pkmn.types
      moves = learnable_moves(pkmn)
      score = lambda do |m|
        md = GameData::Move.get(m)
        next 0 if md.category == 2 || md.power <= 1
        next 0 if md.function_code.to_s =~ BAD_MOVE_FUNCTIONS
        s = md.power * ((md.accuracy == 0) ? 1.0 : md.accuracy / 100.0)
        s *= 1.5 if types.include?(md.type)
        s *= ((md.category == 0) == physical) ? 1.0 : 0.55
        next s
      end
      damaging = moves.select { |m| score.call(m) > 0 }.sort_by { |m| -score.call(m) }
      chosen = []
      # Best STAB move of each of the Pokémon's types
      types.each do |t|
        m = damaging.find { |d| GameData::Move.get(d).type == t && !chosen.include?(d) }
        chosen.push(m) if m
      end
      # Coverage: best moves of types not yet covered
      damaging.each do |m|
        break if chosen.length >= 3
        t = GameData::Move.get(m).type
        next if chosen.any? { |c| GameData::Move.get(c).type == t }
        chosen.push(m)
      end
      # One status move: setup for attackers, otherwise support
      status = (STATUS_MOVES[physical ? :physical : :special] + STATUS_MOVES[:support]).find { |m| moves.include?(m) }
      chosen.push(status) if status && chosen.length < Pokemon::MAX_MOVES
      damaging.each do |m|
        break if chosen.length >= Pokemon::MAX_MOVES
        chosen.push(m) if !chosen.include?(m)
      end
      if chosen.empty?   # Nothing scored (e.g. Ditto); fall back to level-up moves
        pkmn.reset_moves
        return pkmn.moves.map { |m| m.id }
      end
      return chosen.first(Pokemon::MAX_MOVES)
    end

    def pick_item(pkmn, ace, rng)
      if ace
        item = TYPE_ITEMS[pkmn.types.first]
        return item if item && GameData::Item.exists?(item)
        return :LIFEORB
      end
      list = SUPPORT_ITEMS.select { |i| GameData::Item.exists?(i) }
      return list[rng.rand(list.length)]
    end
  end
end
