#===============================================================================
# Saved progress for every region: chosen mode, level offset, completion, story
# flags. Stored in the save file as :fullpoke_progress ($fullpoke).
#
# Modes:
#   :independent  a traditional adventure: starts at level 5 with a separate
#                 party, PC boxes, bag and Day Care (see 025_Contexts.rb), only
#                 the region's Pokédex species, levels capped at 100. The party
#                 joins the main one when the region is completed.
#   :continuous   keeps the main party; the whole region is offset by the
#                 highest level reached in the last completed continuous region.
#===============================================================================
module FullPoke
  class RegionState
    attr_accessor :mode            # nil, :independent or :continuous
    attr_accessor :started_at      # Play order index when the region was begun
    attr_accessor :offset          # Level offset fixed when the region was begun
    attr_accessor :baseline        # Max level the offset was derived from
    attr_accessor :continuous_index  # 1 for the first continuous region, 2 for the next…
    attr_accessor :max_level       # Highest level any party Pokémon reached here
    attr_accessor :completed       # true once the region's final challenge is won
    attr_accessor :completed_at    # Completion order index (1, 2, …)
    attr_accessor :starter         # Species received from the region's professor
    attr_accessor :flags           # Story flags, Hash{Symbol => value}

    def initialize
      @mode             = nil
      @started_at       = nil
      @offset           = 0
      @baseline         = BASE_START_LEVEL
      @continuous_index = 0
      @max_level        = 0
      @completed        = false
      @completed_at     = nil
      @starter          = nil
      @flags            = {}
    end

    def started?;     return !@mode.nil?;            end
    def independent?; return @mode == :independent;  end
    def continuous?;  return @mode == :continuous;   end
  end

  class Progress
    attr_reader   :regions          # Hash{Symbol => RegionState}
    attr_reader   :completion_order # Region ids in the order they were completed
    attr_accessor :contexts         # Stashed parties, see 025_Contexts.rb
    attr_accessor :active_context   # :main or the id of an independent region
    attr_accessor :start_region     # Region chosen at the start of the game
    attr_accessor :play_counter
    attr_accessor :flags            # Global (non-regional) flags

    def initialize
      @regions          = {}
      FullPoke.region_ids.each { |id| @regions[id] = RegionState.new }
      @completion_order = []
      @contexts         = {}
      @active_context   = :main
      @start_region     = nil
      @play_counter     = 0
      @flags            = {}
    end

    def [](region_id)
      @regions[region_id] ||= RegionState.new
      return @regions[region_id]
    end

    def completed_regions
      return @completion_order.clone
    end

    def completed_count
      return @completion_order.length
    end

    # The most recently completed region that was played in continuous mode.
    def last_continuous_completion
      @completion_order.reverse_each do |id|
        return id if self[id].continuous?
      end
      return nil
    end

    # Level offset for a continuous region begun now: the highest level reached
    # in the most recently completed continuous region, minus the normal
    # starting level. Independent completions never change it.
    def current_continuous_offset
      last = last_continuous_completion
      return 0 if !last
      return [self[last].max_level - BASE_START_LEVEL, 0].max
    end

    def continuous_completions
      return @completion_order.count { |id| self[id].continuous? }
    end
  end

  module_function

  def progress
    $fullpoke = Progress.new if !$fullpoke
    return $fullpoke
  end

  def state(region_id)
    return progress[region_id]
  end

  def region_mode(region_id)
    return state(region_id).mode
  end

  def completed?(region_id)
    return state(region_id).completed
  end

  def completed_count
    return progress.completed_count
  end

  # Starts a region in the given mode. The mode can't change once chosen, so
  # this does nothing (and returns false) for a region that has already begun.
  def begin_region(region_id, mode)
    raise ArgumentError, "Unknown region #{region_id}" if !region(region_id)
    raise ArgumentError, "Unknown mode #{mode}" if ![:independent, :continuous].include?(mode)
    st = state(region_id)
    return false if st.started?
    pr = progress
    pr.play_counter += 1
    st.mode       = mode
    st.started_at = pr.play_counter
    if mode == :continuous
      st.offset           = pr.current_continuous_offset
      st.baseline         = st.offset + BASE_START_LEVEL
      st.continuous_index = pr.continuous_completions + 1
    else
      st.offset           = 0
      st.baseline         = BASE_START_LEVEL
      st.continuous_index = 0
    end
    pr.start_region ||= region_id
    EventHandlers.trigger(:on_fullpoke_region_begun, region_id, mode)
    FullPoke.sync_context
    return true
  end

  # Marks the region completed. Counts each region once; replaying the final
  # challenge afterwards changes nothing. Returns true the first time.
  def complete_region(region_id)
    st = state(region_id)
    return false if st.completed || !st.started?
    record_party_levels(region_id)
    pr = progress
    st.completed    = true
    pr.completion_order.push(region_id)
    st.completed_at = pr.completion_order.length
    FullPoke.merge_context(region_id) if st.independent?
    FullPoke.sync_context
    FullPoke::Forest.clear_cache if defined?(FullPoke::Forest)
    EventHandlers.trigger(:on_fullpoke_region_completed, region_id)
    return true
  end

  # Records the highest party level as reached in the given region (or the
  # current map's region).
  def record_party_levels(region_id = nil)
    region_id ||= current_map_region
    return if !region_id || region_id == :forest || !$player
    st = state(region_id)
    return if !st.started? || st.completed
    max = $player.party.reject { |p| p.egg? }.map { |p| p.level }.max || 0
    st.max_level = max if max > st.max_level
  end

  def set_flag(region_id, flag, value = true)
    state(region_id).flags[flag] = value
  end

  def flag?(region_id, flag)
    return state(region_id).flags[flag] ? true : false
  end

  # Level offset for content on the current map:
  #   continuous region -> the offset fixed when that region began
  #   independent region -> 0
  #   the forest -> the current continuous offset
  def active_offset
    region_id = current_map_region
    return 0 if !region_id
    return progress.current_continuous_offset if region_id == :forest
    st = state(region_id)
    return st.continuous? ? st.offset : 0
  end

  # Whether the current region's leaders use the stronger five-Pokémon teams:
  # continuous mode from the second continuous region on.
  def enhanced_teams?(region_id = nil)
    region_id ||= current_map_region
    return false if !region_id || region_id == :forest
    st = state(region_id)
    return st.continuous? && st.continuous_index >= 2
  end

  def scale_level(level, region_id = nil)
    offset = region_id ? (state(region_id).continuous? ? state(region_id).offset : 0) : active_offset
    return (level + offset).clamp(1, level_cap)
  end
end

SaveData.register(:fullpoke_progress) do
  save_value { $fullpoke }
  load_value { |value| $fullpoke = value }
  new_game_value { FullPoke::Progress.new }
end

# Track the highest level reached in the current region.
EventHandlers.add(:on_player_step_taken, :fullpoke_record_levels,
  proc { FullPoke.record_party_levels }
)
EventHandlers.add(:on_end_battle, :fullpoke_record_levels,
  proc { |_outcome, _can_lose| FullPoke.record_party_levels }
)
