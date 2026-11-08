#===============================================================================
# Level scaling for continuous adventures.
#
# Every level-based encounter in a continuous region is raised by the region's
# offset (fixed when the region was begun), so the region keeps its normal
# progression (route 1 low, Champion high) on top of the player's previous
# achievement. Wild and trainer Pokémon whose scaled level is past their
# evolution level are evolved, so late routes aren't full of level-90
# Caterpie. The forest's rare Pokémon keep their species.
#===============================================================================
module FullPoke
  module Evolution
    # Level used for evolutions that don't depend on level (stones, trade,
    # friendship…), by evolution stage.
    NON_LEVEL_THRESHOLDS = [30, 45]

    module_function

    def threshold(method, param, stage)
      m = GameData::Evolution.try_get(method)
      return param if m && m.parameter == Integer && !m.any_level_up && param.is_a?(Integer)
      return NON_LEVEL_THRESHOLDS[[stage, NON_LEVEL_THRESHOLDS.length - 1].min]
    end

    # The species a Pokémon of this species would plausibly be at this level.
    # Branching evolutions are picked at random (rng) or, with rng nil, the
    # first listed one.
    def stage_for(species, level, form = 0, rng = nil)
      data = GameData::Species.get_species_form(species, form) || GameData::Species.get(species)
      stage = 0
      prev_threshold = 0
      loop do
        evos = data.get_evolutions(true).select { |e| GameData::Species.exists?(e[0]) }
        break if evos.empty?
        ready = evos.select do |e|
          level >= [threshold(e[1], e[2], stage), prev_threshold + 1].max
        end
        break if ready.empty?
        pick = rng ? ready[rng.rand(ready.length)] : ready.first
        prev_threshold = [threshold(pick[1], pick[2], stage), prev_threshold + 1].max
        stage += 1
        data = GameData::Species.get_species_form(pick[0], data.form) || GameData::Species.get(pick[0])
      end
      return data.species
    end

    # Final evolutions reachable from the species (itself if it doesn't evolve).
    def final_forms(species)
      data = GameData::Species.get(species)
      evos = data.get_evolutions(true).select { |e| GameData::Species.exists?(e[0]) }
      return [data.species] if evos.empty?
      return evos.map { |e| final_forms(e[0]) }.flatten.uniq
    end

    def fully_evolved?(species)
      return GameData::Species.get(species).get_evolutions(true).none? { |e| GameData::Species.exists?(e[0]) }
    end
  end

  @skip_wild_scaling = false
  class << self
    attr_accessor :skip_wild_scaling
  end

  module_function

  # Changes a Pokémon's species/level and refreshes its moves and stats.
  def retarget_pokemon(pkmn, species, level, reset_moves = true)
    pkmn.species = species if species && GameData::Species.get(species).species != pkmn.species
    pkmn.level = level.clamp(1, level_cap)
    pkmn.reset_moves if reset_moves
    pkmn.calc_stats
    pkmn.hp = pkmn.totalhp
    return pkmn
  end

  def scale_wild_pokemon(pkmn)
    return if skip_wild_scaling
    offset = active_offset
    return if offset <= 0
    level = (pkmn.level + offset).clamp(1, level_cap)
    species = pkmn.species
    species = Evolution.stage_for(species, level, pkmn.form, Random.new(pkmn.personalID)) if !in_forest?
    retarget_pokemon(pkmn, species, level)
  end
end

EventHandlers.add(:on_wild_pokemon_created, :fullpoke_scaling,
  proc { |pkmn| FullPoke.scale_wild_pokemon(pkmn) }
)

# Trainers defined in PBS (e.g. the Kanto ones) are adjusted when loaded.
# FullPoke's own trainers (FullPoke.trainer_battle) are adjusted when built.
EventHandlers.add(:on_trainer_load, :fullpoke_scaling,
  proc { |trainer| FullPoke::Teams.adjust_trainer!(trainer) if trainer }
)

class NPCTrainer
  attr_accessor :fullpoke_skill   # Overrides the trainer type's AI skill

  alias __fullpoke__skill_level skill_level unless method_defined?(:__fullpoke__skill_level)
  def skill_level
    return @fullpoke_skill if @fullpoke_skill
    return __fullpoke__skill_level
  end
end
