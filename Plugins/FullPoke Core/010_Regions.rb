#===============================================================================
# The nine regions, the Interregional Forest that joins them, and which maps
# belong to which region.
#
# A map belongs to the region whose root folder (in RPG Maker XP's map tree) it
# sits under. FullPoke::REGION_ROOTS lists those folders; generated content adds
# its own folders through FullPoke::World (see 090_World.rb).
#===============================================================================
module FullPoke
  # Highest level a Pokémon can reach. Independent (traditional) adventures cap
  # at TRADITIONAL_MAX_LEVEL instead; see 030_Levels.rb.
  MAX_LEVEL             = 999
  TRADITIONAL_MAX_LEVEL = 100
  BASE_START_LEVEL      = 5     # A normal adventure starts at this level
  RARE_THRESHOLD        = 5.0   # % per location/method for a species to count as rare
  FOREST_SPECIES_CHANCE = 5.0   # Max % per forest encounter opportunity per species
  FOREST_TOTAL_CHANCE   = 50.0  # Max % of forest encounter opportunities that find anything
  BADGE_SLOTS           = 32    # $player.badges indices reserved per region

  class RegionInfo
    attr_reader :id, :index, :name, :dex, :starters, :professor, :start_town,
                :rival_name, :needs_species

    def initialize(id, index, name, dex, starters, professor, start_town, rival_name, needs_species = nil)
      @id            = id
      @index         = index
      @name          = name
      @dex           = dex
      @starters      = starters
      @professor     = professor
      @start_town    = start_town
      @rival_name    = rival_name
      @needs_species = needs_species
    end

    # False if the game data this region needs isn't installed (Paldea needs the
    # Generation 9 species).
    def available?
      return true if !@needs_species
      return @needs_species.all? { |sp| GameData::Species.exists?(sp) }
    end

    def badge_range
      return (@index * BADGE_SLOTS)...((@index + 1) * BADGE_SLOTS)
    end

    def badge_index(n)
      return (@index * BADGE_SLOTS) + n
    end
  end

  REGIONS = [
    RegionInfo.new(:kanto,  0, "Kanto",  0, [:BULBASAUR, :CHARMANDER, :SQUIRTLE], "Prof. Oak", "Pallet Town", nil),
    RegionInfo.new(:johto,  1, "Johto",  1, [:CHIKORITA, :CYNDAQUIL, :TOTODILE], "Prof. Elm", "New Bark Town", "Silver"),
    RegionInfo.new(:hoenn,  2, "Hoenn",  2, [:TREECKO, :TORCHIC, :MUDKIP], "Prof. Birch", "Littleroot Town", "May"),
    RegionInfo.new(:sinnoh, 3, "Sinnoh", 3, [:TURTWIG, :CHIMCHAR, :PIPLUP], "Prof. Rowan", "Twinleaf Town", "Barry"),
    RegionInfo.new(:unova,  4, "Unova",  4, [:SNIVY, :TEPIG, :OSHAWOTT], "Prof. Juniper", "Nuvema Town", "Cheren"),
    RegionInfo.new(:kalos,  5, "Kalos",  5, [:CHESPIN, :FENNEKIN, :FROAKIE], "Prof. Sycamore", "Vaniville Town", "Shauna"),
    RegionInfo.new(:alola,  6, "Alola",  6, [:ROWLET, :LITTEN, :POPPLIO], "Prof. Kukui", "Iki Town", "Hau"),
    RegionInfo.new(:galar,  7, "Galar",  7, [:GROOKEY, :SCORBUNNY, :SOBBLE], "Prof. Magnolia", "Postwick", "Hop"),
    RegionInfo.new(:paldea, 8, "Paldea", 8, [:SPRIGATITO, :FUECOCO, :QUAXLY], "Director Clavell", "Cabo Poco", "Nemona",
                   [:SPRIGATITO, :FUECOCO, :QUAXLY])
  ]

  # Map tree folders that hold each region's maps (from the map pack). Generated
  # maps add more in FullPoke::World::REGION_ROOTS.
  REGION_ROOTS = {
    2   => :kanto,
    3   => :johto,
    4   => :hoenn,
    408 => :sinnoh,
    32  => :unova,
    396 => :kalos,
    583 => :alola,
    584 => :galar
  }

  module_function

  def region(id)
    return id if id.is_a?(RegionInfo)
    return REGIONS.find { |r| r.id == id }
  end

  def region_ids
    return REGIONS.map { |r| r.id }
  end

  @map_region_cache = {}

  # @return [Symbol, nil] the region (or :forest) the map belongs to
  def region_of_map(map_id)
    return nil if !map_id || map_id <= 0
    return @map_region_cache[map_id] if @map_region_cache.key?(map_id)
    roots = REGION_ROOTS.merge(World.region_roots)
    infos = pbLoadMapInfos
    ret = nil
    id = map_id
    seen = {}
    while id && id > 0 && !seen[id]
      seen[id] = true
      if roots[id]
        ret = roots[id]
        break
      end
      id = infos[id]&.parent_id
    end
    @map_region_cache[map_id] = ret
    return ret
  end

  def clear_map_region_cache
    @map_region_cache = {}
  end

  # @return [Array<Integer>] every map ID belonging to the region
  def maps_of_region(region_id)
    return pbLoadMapInfos.keys.select { |id| region_of_map(id) == region_id }.sort
  end

  def current_map_region
    return nil if !$game_map
    return region_of_map($game_map.map_id)
  end

  def in_forest?
    return current_map_region == :forest
  end
end
