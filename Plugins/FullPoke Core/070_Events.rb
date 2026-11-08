#===============================================================================
# Script calls used by FullPoke's map events: choosing the starting region and
# mode, the forest gates, starters, badges and region completion.
#===============================================================================
module FullPoke
  module_function

  # Moves the player like a Transfer Player event command (with a fade).
  def transfer(map_id, x, y, direction = 2)
    return false if !valid_destination?(map_id, x, y)
    pbCancelVehicles
    $game_temp.player_transferring   = true
    $game_temp.player_new_map_id     = map_id
    $game_temp.player_new_x          = x
    $game_temp.player_new_y          = y
    $game_temp.player_new_direction  = direction
    Graphics.freeze
    $game_temp.transition_processing = true
    $game_temp.transition_name       = ""
    return true
  end

  def mode_name(mode)
    return (mode == :continuous) ? _INTL("Continuous") : _INTL("Independent")
  end

  # Asks which mode to play the region in. Returns :independent, :continuous
  # or nil if the player backs out. Doesn't start the region.
  def choose_mode(region_id)
    reg = region(region_id)
    st = state(region_id)
    return st.mode if st.started?
    offset = progress.current_continuous_offset
    pbMessage(_INTL("How do you want to play the {1} region?", reg.name))
    pbMessage(_INTL("Independent: a traditional adventure. You start at level 5 with a {1} starter and only {1} Pokémon. Your other Pokémon wait safely until you finish.", reg.name))
    if offset > 0
      pbMessage(_INTL("Continuous: bring your team. Everything in {1} is {2} levels higher than usual, matching your last completed continuous region.",
                      reg.name, offset))
    else
      pbMessage(_INTL("Continuous: keep the Pokémon you've trained. {1} starts at its usual levels until you've completed a region in continuous mode.",
                      reg.name))
    end
    loop do
      cmd = pbMessage(_INTL("Which mode?"),
                      [_INTL("Independent"), _INTL("Continuous"), _INTL("Cancel")], 3)
      return nil if cmd < 0 || cmd == 2
      mode = (cmd == 0) ? :independent : :continuous
      if pbConfirmMessage(_INTL("Play {1} in {2} mode? This can't be changed later.", reg.name, mode_name(mode)))
        return mode
      end
    end
  end

  # Forest gate event: asks for the mode if needed and takes the player to the
  # region's starting town.
  def forest_gate(region_id)
    reg = region(region_id)
    if !reg.available?
      pbMessage(_INTL("The path to {1} is overgrown. (This region needs data that isn't installed yet.)", reg.name))
      return false
    end
    dest = World.arrival(region_id)
    if !dest
      pbMessage(_INTL("The path to {1} isn't finished yet.", reg.name))
      return false
    end
    st = state(region_id)
    if st.started?
      label = st.completed ? _INTL("completed") : mode_name(st.mode)
      return false if !pbConfirmMessage(_INTL("This path leads to {1} in {2} ({3}). Go there?",
                                              reg.start_town, reg.name, label))
    else
      pbMessage(_INTL("This path leads to {1} in the {2} region.", reg.start_town, reg.name))
      mode = choose_mode(region_id)
      return false if !mode
      begin_region(region_id, mode)
    end
    return transfer(*dest)
  end

  # Region-side gate back to the forest.
  def gate_to_forest(region_id)
    dest = World.forest_exit(region_id)
    if !dest
      pbMessage(_INTL("The forest path isn't finished yet."))
      return false
    end
    return false if !pbConfirmMessage(_INTL("This path leads into the Interregional Forest. Go in?"))
    return transfer(*dest)
  end

  # Gives the region's starter (once). Returns the species or nil.
  def give_starter(region_id, species = nil)
    reg = region(region_id)
    st = state(region_id)
    return nil if st.starter
    if !species
      names = reg.starters.map { |sp| GameData::Species.get(sp).name }
      loop do
        cmd = pbMessage(_INTL("Which Pokémon will you choose?"), names, -1)
        next if cmd < 0
        species = reg.starters[cmd]
        break if pbConfirmMessage(_INTL("So, you want {1}?", names[cmd]))
      end
    end
    level = scale_level(BASE_START_LEVEL, region_id)
    pkmn = Pokemon.new(species, level)
    st.starter = pkmn.species
    pbAddPokemon(pkmn)
    return pkmn.species
  end

  def badge!(region_id, n)
    $player.badges[region(region_id).badge_index(n)] = true
  end

  def badge?(region_id, n)
    return $player.badges[region(region_id).badge_index(n)] == true
  end

  def region_badge_count(region_id)
    return region(region_id).badge_range.count { |i| $player.badges[i] == true }
  end

  #-----------------------------------------------------------------------------
  # New game: choosing where to begin.
  #-----------------------------------------------------------------------------
  def available_regions
    return REGIONS.select { |r| r.available? && (r.id == :kanto || World.home(r.id)) }
  end

  # Asks which region to start in and in which mode, and begins it. Returns the
  # region id. Kanto continues with the existing Kanto opening.
  def intro_choose_region
    regions = available_regions
    loop do
      names = regions.map { |r| _INTL("{1} ({2})", r.name, r.start_town) }
      cmd = pbMessage(_INTL("Where will your journey begin?"), names, -1)
      next if cmd < 0
      reg = regions[cmd]
      mode = choose_mode(reg.id)
      next if !mode
      begin_region(reg.id, mode)
      return reg.id
    end
  end

  # Sends a new game to its chosen (non-Kanto) region's starting point.
  def intro_go_to_start_region
    region_id = progress.start_region
    home = World.home(region_id)
    return false if !home
    return transfer(*home)
  end
end

class Player
  alias __fullpoke__badge_count badge_count unless method_defined?(:__fullpoke__badge_count)
  # Badges count per region: Gym/HM checks in a region only see that region's
  # badges. Outside the regions (the forest), all badges count.
  def badge_count
    region_id = $fullpoke ? FullPoke.current_map_region : nil
    reg = (region_id && region_id != :forest) ? FullPoke.region(region_id) : nil
    return __fullpoke__badge_count if !reg
    return reg.badge_range.count { |i| @badges[i] == true }
  end
end

#===============================================================================
# Grove Compass: a key item that returns the player to the forest gate of the
# region they're in, from anywhere outside a building.
#===============================================================================
module FullPoke
  def self.can_use_compass?(show_messages = true)
    region_id = current_map_region
    if !region_id || region_id == :forest
      pbMessage(_INTL("The needle spins lazily. You're already in the forest.")) if show_messages && region_id == :forest
      pbMessage(_INTL("The needle doesn't move here.")) if show_messages && !region_id
      return false
    end
    if !World.forest_exit(region_id)
      pbMessage(_INTL("The needle doesn't move here.")) if show_messages
      return false
    end
    return true
  end

  def self.use_compass
    region_id = current_map_region
    dest = World.forest_exit(region_id)
    return false if !dest
    pbMessage(_INTL("The Grove Compass points the way back to the Interregional Forest."))
    return transfer(*dest)
  end
end

ItemHandlers::UseFromBag.add(:GROVECOMPASS, proc { |item|
  next (FullPoke.can_use_compass?) ? 2 : 0
})
ItemHandlers::UseInField.add(:GROVECOMPASS, proc { |item|
  next false if !FullPoke.can_use_compass?
  next false if !pbConfirmMessage(_INTL("Return to the Interregional Forest?"))
  next FullPoke.use_compass
})

# Everyone carries a Grove Compass (each independent adventure's bag too).
EventHandlers.add(:on_enter_map, :fullpoke_grove_compass,
  proc { |_old_map_id|
    next if !$bag || !GameData::Item.exists?(:GROVECOMPASS)
    $bag.add(:GROVECOMPASS) if !$bag.has?(:GROVECOMPASS)
  }
)
