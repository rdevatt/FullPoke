#===============================================================================
# Levels above 100.
#
# - The level cap is FullPoke::MAX_LEVEL (999), except in an independent
#   adventure, which keeps the traditional cap of 100.
# - Exp. above level 100 uses each growth rate's own formula, continued past
#   100. Essentials' Fluctuating formula for levels above 100 is wrong (it falls
#   below the level-100 value), so it's replaced with the 36-100 formula.
# - level_from_exp uses a binary search so high caps stay fast.
# - Exp. pacing: in a region offset by N levels, Exp. is converted so a
#   Pokémon needs about as many battles per level as it would N levels lower.
#   Without this, levelling slows down sharply as levels rise (Exp. per battle
#   grows linearly, Exp. per level cubically) and the player falls behind the
#   region's scaled trainers.
#===============================================================================
module FullPoke
  module_function

  def level_cap
    return MAX_LEVEL if !$fullpoke
    return TRADITIONAL_MAX_LEVEL if $fullpoke.active_context != :main
    return MAX_LEVEL
  end

  @exp_context = nil
  class << self
    attr_accessor :exp_context
  end

  # Converts Exp. gained against a defeated Pokémon so the pace matches the
  # region's unscaled levels. See the note at the top of this file.
  def paced_exp(growth_rate, gainer_exp, amount)
    ctx = FullPoke.exp_context
    return amount if !ctx || amount <= 0
    offset = ctx[:offset]
    return amount if !offset || offset <= 0
    gainer_level = growth_rate.level_from_exp(gainer_exp)
    return amount if gainer_level <= offset
    foe_level = ctx[:foe_level]
    orig_gainer = gainer_level - offset
    orig_foe    = [foe_level - offset, 1].max
    mult = orig_foe.to_f / foe_level
    if Settings::SCALED_EXP_FORMULA
      scaled = (((2 * foe_level) + 10.0) / (gainer_level + foe_level + 10.0))**2.5
      orig   = (((2 * orig_foe) + 10.0) / (orig_gainer + orig_foe + 10.0))**2.5
      mult *= orig / scaled
    end
    span_now  = growth_rate.minimum_exp_for_level(gainer_level + 1) - growth_rate.minimum_exp_for_level(gainer_level)
    span_orig = growth_rate.minimum_exp_for_level(orig_gainer + 1) - growth_rate.minimum_exp_for_level(orig_gainer)
    mult *= span_now.to_f / span_orig if span_orig > 0 && span_now > 0
    mult = mult.clamp(0.01, 1000.0)
    return [(amount * mult).round, 1].max
  end
end

module GameData
  class GrowthRate
    class << self
      alias __fullpoke__max_level max_level unless method_defined?(:__fullpoke__max_level)
      def max_level
        return FullPoke.level_cap
      end
    end

    # Binary search; the default walks every level up to the cap.
    def level_from_exp(exp)
      return ArgumentError.new(_INTL("Exp amount {1} is invalid.", exp)) if !exp || exp < 0
      max = GrowthRate.max_level
      return max if exp >= maximum_exp
      lo = 1
      hi = max
      while lo < hi
        mid = (lo + hi + 1) / 2
        if minimum_exp_for_level(mid) <= exp
          lo = mid
        else
          hi = mid - 1
        end
      end
      return lo
    end

    alias __fullpoke__add_exp add_exp unless method_defined?(:__fullpoke__add_exp)
    def add_exp(exp1, exp2)
      exp2 = FullPoke.paced_exp(self, exp1, exp2) if FullPoke.exp_context
      return __fullpoke__add_exp(exp1, exp2)
    end
  end
end

# Fluctuating's formula above 100 in Essentials adds where it should multiply.
# Continue the 36-100 formula instead: n^3 * (32 + n/2) / 50.
GameData::GrowthRate.get(:Fluctuating).instance_variable_set(:@exp_formula,
  proc { |level| next (level**3) * (32 + (level / 2)) / 50 }
)

class Battle
  alias __fullpoke__pbGainExpOne pbGainExpOne unless method_defined?(:__fullpoke__pbGainExpOne)
  def pbGainExpOne(idxParty, defeatedBattler, *args)
    old_ctx = FullPoke.exp_context
    FullPoke.exp_context = { offset: FullPoke.active_offset, foe_level: defeatedBattler.level }
    begin
      __fullpoke__pbGainExpOne(idxParty, defeatedBattler, *args)
    ensure
      FullPoke.exp_context = old_ctx
    end
  end
end
