#===============================================================================
# Stops "Transfer Player" commands whose destination doesn't exist (an unfinished
# warp from the map pack) from stranding the player outside a map. The player
# stays put and is told the way isn't finished; in Debug mode the console names
# the event so it can be fixed in RPG Maker XP.
#===============================================================================
module FullPoke
  @map_sizes = {}

  # Returns [width, height] of the given map, or nil if there is no such map.
  def self.map_size(map_id)
    return @map_sizes[map_id] if @map_sizes.key?(map_id)
    filename = sprintf("Data/Map%03d.rxdata", map_id)
    if map_id.is_a?(Integer) && map_id > 0 && pbRgssExists?(filename)
      map = load_data(filename)
      @map_sizes[map_id] = [map.width, map.height]
    else
      @map_sizes[map_id] = nil
    end
    return @map_sizes[map_id]
  end

  def self.valid_destination?(map_id, x, y)
    size = map_size(map_id)
    return false if !size
    return x >= 0 && y >= 0 && x < size[0] && y < size[1]
  end
end

class Interpreter
  alias __fullpoke__command_201 command_201 unless method_defined?(:__fullpoke__command_201)

  def command_201
    if !$game_temp.in_battle && !$game_temp.player_transferring &&
       !$game_temp.message_window_showing && !$game_temp.transition_processing
      if @parameters[0] == 0   # Direct appointment
        map_id, x, y = @parameters[1], @parameters[2], @parameters[3]
      else                     # Appoint with variables
        map_id = $game_variables[@parameters[1]]
        x      = $game_variables[@parameters[2]]
        y      = $game_variables[@parameters[3]]
      end
      if !FullPoke.valid_destination?(map_id, x, y)
        if $DEBUG
          Console.echo_warn(_INTL("Unfinished warp: map {1} event {2} transfers to map {3} ({4},{5}), which doesn't exist.",
                                  @map_id, @event_id, map_id, x, y))
        end
        pbMessage(_INTL("This way isn't finished yet."))
        return true   # Skip the transfer and carry on with the event
      end
    end
    return __fullpoke__command_201
  end
end
