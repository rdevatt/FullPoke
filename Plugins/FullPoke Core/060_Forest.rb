#===============================================================================
# Wild Pokémon in the Interregional Forest.
#
# Only rare Pokémon from completed regions appear. A species is rare in a
# region if, on every map and encounter method of that region where it appears,
# its slots add up to RARE_THRESHOLD % or less of that method's table. Summing
# the slots stops one Pokémon from qualifying through several small slots, and
# a Pokémon that's common anywhere in the region (Pidgey on Kanto's Route 1)
# doesn't qualify through a small slot somewhere else. The pool is worked out
# from the region's real encounter tables, so it grows as regions are completed
# and is empty before the first one.
#
# Each species has at most FOREST_SPECIES_CHANCE % per encounter opportunity
# and all together at most FOREST_TOTAL_CHANCE %; the rest of the time nothing
# appears. Grass draws from land/cave rares, water and fishing from water rares.
# Levels come from the source table and get the current continuous offset.
#===============================================================================
module FullPoke
  module Forest
    KIND_OF_TYPE = { land: :land, cave: :land, contest: :land, water: :water, fishing: :water }

    @cache = {}

    module_function

    def clear_cache
      @cache = {}
    end

    def map?(map_id)
      return FullPoke.region_of_map(map_id) == :forest
    end

    def kind_of(enc_type)
      t = GameData::EncounterType.try_get(enc_type)
      return nil if !t
      return KIND_OF_TYPE[t.type]
    end

    # Rare encounters in one region: Array of hashes
    #   { species:, min:, max:, pct:, map:, type:, region: }
    def rare_entries(region_id)
      key = [:region, region_id]
      return @cache[key] if @cache[key]
      ret = []
      common = {}
      maps = FullPoke.maps_of_region(region_id)
      GameData::Encounter.each do |enc|
        next if !maps.include?(enc.map)
        enc.types.each do |type, slots|
          next if !slots || slots.empty?
          total = slots.sum { |s| s[0] }
          next if total <= 0
          by_species = {}
          slots.each do |chance, species, min, max|
            e = (by_species[species] ||= { chance: 0, min: min, max: max || min })
            e[:chance] += chance
            e[:min] = [e[:min], min].min
            e[:max] = [e[:max], max || min].max
          end
          by_species.each do |species, e|
            pct = e[:chance] * 100.0 / total
            if pct > FullPoke::RARE_THRESHOLD
              common[species] = true
              next
            end
            ret.push({ species: species, min: e[:min], max: e[:max], pct: pct,
                       map: enc.map, type: type, region: region_id })
          end
        end
      end
      ret.reject! { |e| common[e[:species]] }
      @cache[key] = ret
      return ret
    end

    # Species excluded from a region's pool because they're common somewhere in it.
    def common_species(region_id)
      key = [:common, region_id]
      return @cache[key] if @cache[key]
      rare = rare_entries(region_id).map { |e| e[:species] }.uniq
      seen = []
      maps = FullPoke.maps_of_region(region_id)
      GameData::Encounter.each do |enc|
        next if !maps.include?(enc.map)
        enc.types.each_value { |slots| (slots || []).each { |s| seen.push(s[1]) } }
      end
      @cache[key] = seen.uniq - rare
      return @cache[key]
    end

    # The forest pool for :land or :water, one entry per species.
    def pool(kind)
      completed = FullPoke.progress.completed_regions
      key = [:pool, kind, completed]
      return @cache[key] if @cache[key]
      by_species = {}
      completed.each do |region_id|
        rare_entries(region_id).each do |e|
          next if kind_of(e[:type]) != kind
          next if !GameData::Species.exists?(e[:species])
          old = by_species[e[:species]]
          by_species[e[:species]] = e if !old || e[:min] < old[:min]
        end
      end
      @cache[key] = by_species.values.sort_by { |e| e[:species].to_s }
      return @cache[key]
    end

    # Chance (%) for each species per encounter opportunity.
    def species_chance(kind)
      n = pool(kind).length
      return 0.0 if n == 0
      return [FullPoke::FOREST_SPECIES_CHANCE, FullPoke::FOREST_TOTAL_CHANCE / n].min
    end

    # [species, level] or nil (nothing appears).
    def choose(enc_type, roll = nil)
      kind = kind_of(enc_type)
      return nil if !kind
      list = pool(kind)
      return nil if list.empty?
      per = species_chance(kind)
      roll ||= rand * 100
      idx = (roll / per).floor
      return nil if idx >= list.length
      e = list[idx]
      level = e[:min] + rand(e[:max] - e[:min] + 1)
      return [e[:species], level]
    end
  end
end

class PokemonEncounters
  alias __fullpoke__choose_wild_pokemon choose_wild_pokemon unless method_defined?(:__fullpoke__choose_wild_pokemon)
  def choose_wild_pokemon(enc_type, chance_rolls = 1)
    if $game_map && FullPoke::Forest.map?($game_map.map_id)
      return FullPoke::Forest.choose(enc_type)
    end
    return __fullpoke__choose_wild_pokemon(enc_type, chance_rolls)
  end
end
