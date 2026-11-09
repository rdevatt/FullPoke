#===============================================================================
# Field moves (Cut, Surf…) need a number of the current region's Badges.
# Essentials has one global setting per move (Settings::BADGE_FOR_*); a region
# listed here uses its own numbers instead, e.g. Kanto follows FireRed/LeafGreen:
# Flash after the 1st Badge, Cut 2nd, Fly 3rd, Strength 4th, Surf 5th.
# Regions not listed keep the global settings.
#===============================================================================
module FullPoke
  FIELD_MOVE_BADGES = {
    kanto: { FLASH: 1, CUT: 2, FLY: 3, STRENGTH: 4, SURF: 5, ROCKSMASH: 6, DIVE: 7, WATERFALL: 8 }
  }

  module_function

  # The move whose global setting has this value (the settings are distinct).
  def field_move_for_setting(badge)
    @field_setting_moves ||= {
      Settings::BADGE_FOR_CUT => :CUT, Settings::BADGE_FOR_FLASH => :FLASH,
      Settings::BADGE_FOR_ROCKSMASH => :ROCKSMASH, Settings::BADGE_FOR_SURF => :SURF,
      Settings::BADGE_FOR_FLY => :FLY, Settings::BADGE_FOR_STRENGTH => :STRENGTH,
      Settings::BADGE_FOR_DIVE => :DIVE, Settings::BADGE_FOR_WATERFALL => :WATERFALL
    }
    return @field_setting_moves[badge]
  end

  def field_move_badges(badge)
    return badge if !$fullpoke || badge < 0
    table = FIELD_MOVE_BADGES[current_map_region]
    move = field_move_for_setting(badge)
    return (table && move && table[move]) || badge
  end
end

alias __fullpoke__pbCheckHiddenMoveBadge pbCheckHiddenMoveBadge unless defined?(__fullpoke__pbCheckHiddenMoveBadge)
def pbCheckHiddenMoveBadge(badge = -1, showmsg = true)
  return __fullpoke__pbCheckHiddenMoveBadge(FullPoke.field_move_badges(badge), showmsg)
end
