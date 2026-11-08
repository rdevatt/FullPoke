#===============================================================================
# Where things are in the world: forest gates, region arrival points, generated
# map folders and wild encounter tables for generated maps.
#
# FullPoke::WORLD_DATA is written by tools/headless/build_world.rb into
# 091_World_Generated.rb. Without it (before the world is built) the regions
# simply have no gates.
#===============================================================================
module FullPoke
  module World
    module_function

    def data
      return FullPoke.const_defined?(:WORLD_DATA) ? FullPoke::WORLD_DATA : {}
    end

    # Map tree folders of generated maps: { map_id => region id or :forest }
    def region_roots
      return data[:roots] || {}
    end

    def region_data(region_id)
      return (data[:regions] || {})[region_id]
    end

    # [map, x, y, direction] where the player arrives in the region from the forest
    def arrival(region_id)
      return region_data(region_id)&.dig(:arrival)
    end

    # [map, x, y, direction] where the player arrives in the forest from the region
    def forest_exit(region_id)
      return (data[:forest_exits] || {})[region_id]
    end

    # [map, x, y, direction] where a new game that starts in this region begins
    def home(region_id)
      return region_data(region_id)&.dig(:home)
    end

    def forest_maps
      return data[:forest_maps] || []
    end

    # Encounter tables for generated maps, in GameData::Encounter's format.
    def encounters
      return data[:encounters] || []
    end

    def register_encounters
      encounters.each do |e|
        next if !e[:map]
        types = {}
        e[:types].each do |type, slots|
          valid = slots.select { |s| GameData::Species.exists?(s[1]) }
          types[type] = valid if !valid.empty?
        end
        next if types.empty?
        key = sprintf("%s_%d", e[:map], e[:version] || 0).to_sym
        GameData::Encounter::DATA[key] = GameData::Encounter.new({
          id: key, map: e[:map], version: e[:version] || 0,
          step_chances: e[:step_chances], types: types
        })
      end
    end
  end
end

# Generated encounter tables are added whenever the compiled ones are loaded.
module GameData
  class Encounter
    class << self
      alias __fullpoke__load load unless method_defined?(:__fullpoke__load)
      def load
        __fullpoke__load
        FullPoke::World.register_encounters
      end
    end
  end
end
