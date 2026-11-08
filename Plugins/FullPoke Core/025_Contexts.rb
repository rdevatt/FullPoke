#===============================================================================
# Separate Pokémon for independent adventures.
#
# Each independent region that hasn't been completed has its own party, PC
# boxes, bag and Day Care. Everything else (the forest, continuous regions,
# completed regions) uses the :main set. Entering a map swaps the active set if
# the map needs a different one. Pokémon are moved, never copied, so nothing can
# be duplicated or lost; FullPoke.all_pokemon lists every Pokémon in every set.
#
# Completing an independent region merges its set into :main.
#===============================================================================
module FullPoke
  class PartyContext
    attr_accessor :party, :boxes, :bag, :day_care

    def initialize(party = [], boxes = nil, bag = nil, day_care = nil)
      @party    = party
      @boxes    = boxes || PokemonStorage.new.boxes
      @bag      = bag || PokemonBag.new
      @day_care = day_care || DayCare.new
    end

    def each_pokemon
      @party.each { |pkmn| yield pkmn if pkmn }
      @boxes.each { |box| box.pokemon.each { |pkmn| yield pkmn if pkmn } }
      FullPoke.day_care_slots(@day_care).each { |slot| yield slot.pokemon if slot.filled? }
    end
  end

  module_function

  # Which party set the given map uses.
  def context_for_map(map_id)
    region_id = region_of_map(map_id)
    return :main if !region_id || region_id == :forest
    st = state(region_id)
    return region_id if st.independent? && !st.completed
    return :main
  end

  # Swaps the live party/boxes/bag/Day Care to the set the current map needs.
  def sync_context(map_id = nil)
    return if !$player || !$PokemonStorage || !$bag || !$PokemonGlobal
    map_id ||= $game_map&.map_id
    return if !map_id
    want = context_for_map(map_id)
    switch_context(want)
  end

  def switch_context(want)
    pr = progress
    return if pr.active_context == want
    pr.contexts[pr.active_context] = capture_context
    incoming = pr.contexts.delete(want) || new_context(want)
    restore_context(incoming)
    pr.active_context = want
    EventHandlers.trigger(:on_fullpoke_context_changed, want)
  end

  def capture_context
    return PartyContext.new($player.party, $PokemonStorage.boxes,
                            $bag, $PokemonGlobal.day_care)
  end

  def restore_context(ctx)
    $player.party = ctx.party
    $PokemonStorage.instance_variable_set(:@boxes, ctx.boxes)
    $PokemonStorage.currentBox = 0
    $bag = ctx.bag
    $PokemonGlobal.day_care = ctx.day_care
  end

  def new_context(id)
    ctx = PartyContext.new
    EventHandlers.trigger(:on_fullpoke_new_context, id, ctx)
    return ctx
  end

  # Moves everything from a completed independent region's set into :main.
  # The region's party stays in front (it is what the player was just using);
  # :main party members that no longer fit go to the PC.
  def merge_context(region_id)
    pr = progress
    src = (pr.active_context == region_id) ? capture_context : pr.contexts.delete(region_id)
    return if !src
    dest = (pr.active_context == :main) ? capture_context : (pr.contexts.delete(:main) || new_context(:main))
    pr.contexts.delete(region_id)
    overflow = []
    party = src.party.compact
    dest.party.compact.each do |pkmn|
      if party.length < Settings::MAX_PARTY_SIZE
        party.push(pkmn)
      else
        overflow.push(pkmn)
      end
    end
    src.boxes.each { |box| box.pokemon.each { |pkmn| overflow.push(pkmn) if pkmn } }
    day_care_slots(src.day_care).each do |slot|
      next if !slot.filled?
      overflow.push(slot.pokemon)
      slot.reset
    end
    dest.party = party
    overflow.each { |pkmn| store_in_boxes(dest.boxes, pkmn) }
    # Bag: add the region's items to the main bag
    src.bag.pockets.each do |pocket|
      next if !pocket
      pocket.each do |item, qty|
        next if !item
        next if GameData::Item.get(item).is_key_item? && dest.bag.has?(item)
        dest.bag.add(item, qty) || dest.bag.add(item, 1)
      end
    end
    # The merged set becomes the live one
    if pr.active_context == region_id || pr.active_context == :main
      restore_context(dest)
      pr.active_context = :main
    else
      pr.contexts[:main] = dest
    end
  end

  # Puts a Pokémon in the first free box slot, adding boxes if all are full so
  # nothing is ever lost.
  def store_in_boxes(boxes, pkmn)
    boxes.each do |box|
      idx = box.pokemon.index(nil)
      next if !idx
      box.pokemon[idx] = pkmn
      return
    end
    box = PokemonBox.new(_INTL("Box {1}", boxes.length + 1), PokemonBox::BOX_SIZE)
    box.pokemon[0] = pkmn
    boxes.push(box)
  end

  def day_care_slots(day_care)
    return [] if !day_care
    return (0...DayCare::MAX_SLOTS).map { |i| day_care[i] }
  end

  # Every Pokémon the player owns, across all sets (used by tests and the Debug
  # check for duplicates).
  def all_pokemon
    ret = []
    capture_context.each_pokemon { |pkmn| ret.push(pkmn) }
    progress.contexts.each_value { |ctx| ctx.each_pokemon { |pkmn| ret.push(pkmn) } }
    return ret
  end

  # Pokémon objects that appear more than once across all sets (should be none).
  def duplicate_pokemon
    seen = {}
    dups = []
    all_pokemon.each do |pkmn|
      dups.push(pkmn) if seen[pkmn.object_id]
      seen[pkmn.object_id] = true
    end
    return dups
  end

  # Independent adventures only allow their region's Pokédex.
  def allowed_in_current_context?(species)
    pr = progress
    return true if pr.active_context == :main
    reg = region(pr.active_context)
    return true if !reg || !reg.dex
    dex = pbLoadRegionalDexes[reg.dex]
    return true if !dex
    sp = GameData::Species.get(species).species
    return dex.include?(sp)
  end

  # Sends a Pokémon that isn't allowed in this independent adventure to the main
  # PC instead, so it is kept but can't be used here.
  def send_to_main_storage(pkmn)
    pr = progress
    main = pr.contexts[:main] ||= new_context(:main)
    store_in_boxes(main.boxes, pkmn)
  end
end

EventHandlers.add(:on_enter_map, :fullpoke_party_context,
  proc { |_old_map_id| FullPoke.sync_context }
)

# Pokémon from outside the region can't join an independent adventure.
alias __fullpoke__pbStorePokemon pbStorePokemon unless defined?(__fullpoke__pbStorePokemon)
def pbStorePokemon(pkmn)
  if !FullPoke.allowed_in_current_context?(pkmn.species)
    FullPoke.send_to_main_storage(pkmn)
    pbMessage(_INTL("{1} isn't from this region, so it was sent to your main PC. It can join you once this adventure is complete.",
                    pkmn.name))
    return
  end
  __fullpoke__pbStorePokemon(pkmn)
end

class Battle
  alias __fullpoke__pbStorePokemon pbStorePokemon unless method_defined?(:__fullpoke__pbStorePokemon)
  def pbStorePokemon(pkmn)
    if !FullPoke.allowed_in_current_context?(pkmn.species)
      FullPoke.send_to_main_storage(pkmn)
      pbDisplayPaused(_INTL("{1} isn't from this region, so it was sent to your main PC.", pkmn.name))
      return
    end
    __fullpoke__pbStorePokemon(pkmn)
  end
end

class PokemonGlobalMetadata
  attr_writer :day_care
end
