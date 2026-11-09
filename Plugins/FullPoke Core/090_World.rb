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

    # Areas that need badges (or the starter) before you may enter:
    # { map_id => { region:, badges:, starter:, text: } }
    def map_rules
      return data[:map_rules] || {}
    end

    def map_rule_ok?(map_id)
      rule = map_rules[map_id]
      return true if !rule
      region_id = rule[:region]
      return false if rule[:starter] && !FullPoke.state(region_id).starter
      return false if rule[:badges] && FullPoke.region_badge_count(region_id) < rule[:badges]
      return false if rule[:completed] && !FullPoke.completed?(region_id)
      return false if rule[:extras] && !FullPoke::Circuit.stage_extras_done?(region_id, rule[:extras])
      return true
    end

    def map_rule_text(map_id)
      rule = map_rules[map_id] || {}
      return rule[:text] if rule[:text]
      return _INTL("You should get a Pokémon from the professor before going out.") if rule[:starter] && !FullPoke.state(rule[:region]).starter
      return _INTL("Only Champions may go this way.") if rule[:completed]
      if rule[:extras] && !FullPoke::Circuit.stage_extras_done?(rule[:region], rule[:extras])
        return _INTL("Something is still going on in {1}. Better deal with it first.", FullPoke::Circuit.stage(rule[:region], rule[:extras])[:town])
      end
      return _INTL("A guard blocks the way. \"Come back with {1} badges from this region.\"", rule[:badges])
    end

    def register_encounters
      encounters.each do |e|
        next if !e[:map]
        if e[:circuit]
          types = FullPoke::Circuit.encounter_table(*e[:circuit]) rescue {}
          steps = FullPoke::Circuit.encounter_steps(e[:circuit][2] || [:land])
        elsif e[:forest]
          # The forest's real pool comes from FullPoke::Forest; this table only
          # marks its tall grass as an encounter area.
          types = { Land: [[100, :CATERPIE, 3, 3]] }
          steps = { Land: 14 }
        else
          types = e[:types] || {}
          steps = e[:step_chances] || {}
        end
        valid_types = {}
        types.each do |type, slots|
          valid = slots.select { |s| GameData::Species.exists?(s[1]) }
          valid_types[type] = valid if !valid.empty?
        end
        next if valid_types.empty?
        key = sprintf("%s_%d", e[:map], e[:version] || 0).to_sym
        GameData::Encounter::DATA[key] = GameData::Encounter.new({
          id: key, map: e[:map], version: e[:version] || 0,
          step_chances: steps, types: valid_types
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

# Areas that need badges: stepping into one without them sends the player back
# to the last place they were allowed to stand.
module FullPoke
  module World
    @last_ok = nil

    def self.check_position
      return if !$game_map || !$game_player
      map_id = $game_map.map_id
      if map_rule_ok?(map_id)
        @last_ok = [map_id, $game_player.x, $game_player.y, $game_player.direction]
        return
      end
      # Back to the tile behind the player: across the map edge they just
      # crossed, or (after a door or warp) where they last stood
      d = $game_player.direction
      bx = $game_player.x - (d == 6 ? 1 : d == 4 ? -1 : 0)
      by = $game_player.y - (d == 2 ? 1 : d == 8 ? -1 : 0)
      back = nil
      if !$game_map.valid?(bx, by)
        nb = $map_factory.getNewMap(bx, by, map_id) rescue nil
        back = [nb[0].map_id, nb[1], nb[2], d] if nb && map_rule_ok?(nb[0].map_id)
      end
      back ||= @last_ok
      return if !back || back[0] == map_id
      pbMessage(map_rule_text(map_id))
      $game_temp.player_transferring   = true
      $game_temp.player_new_map_id     = back[0]
      $game_temp.player_new_x          = back[1]
      $game_temp.player_new_y          = back[2]
      $game_temp.player_new_direction  = 10 - d
    end

    def self.forget_position
      @last_ok = nil
    end
  end
end

EventHandlers.add(:on_player_step_taken, :fullpoke_map_rules, proc { FullPoke::World.check_position })
EventHandlers.add(:on_enter_map, :fullpoke_map_rules, proc { |_old| FullPoke::World.check_position })

# Essentials only turns a bridge off when the player walks over its BridgeOff
# switch. Leaving a bridge some other way (a map edge, a warp, the Grove
# Compass) left it on, and the next map's paths under bridges were blocked.
# On reaching a different map, the bridge is off unless the player is on one.
module FullPoke
  module World
    @bridge_map = nil

    def self.reset_bridge_on_new_map
      return if !$game_map || !$PokemonGlobal
      map_id = $game_map.map_id
      changed = @bridge_map && @bridge_map != map_id
      @bridge_map = map_id
      return if !changed || $PokemonGlobal.bridge == 0
      return if $game_map.terrain_tag($game_player.x, $game_player.y, true).bridge
      $PokemonGlobal.bridge = 0
    end
  end
end

EventHandlers.add(:on_player_step_taken, :fullpoke_bridge_reset, proc { FullPoke::World.reset_bridge_on_new_map })
EventHandlers.add(:on_enter_map, :fullpoke_bridge_reset, proc { |_old| FullPoke::World.reset_bridge_on_new_map })
