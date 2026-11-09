#===============================================================================
# Trainers defined in FullPoke's data files (rather than PBS/trainers.txt).
# Their traditional teams are written as "SPECIES:LEVEL[:ITEM] …" (STARTER
# for a rival's starter line); the battle
# is started with FullPoke.trainer_battle(:key) from an event.
#
# Keeping these out of PBS lets regions whose species need optional data (Gen 9
# for Paldea) be defined without breaking the PBS compiler when that data is
# missing.
#===============================================================================
module FullPoke
  module_function

  def parse_party(text)
    return text.split(/\s+/).reject(&:empty?).map do |entry|
      species, level, item = entry.split(":")
      { species: species.to_sym, level: level.to_i, item: item ? item.to_sym : nil }
    end
  end

  # Builds the trainer for a FullPoke trainer definition, scaled/enhanced for
  # its region.
  def build_trainer(key)
    defn = Teams.get(key)
    raise ArgumentError, "No FullPoke trainer #{key}" if !defn
    name = defn[:name]
    # Rivals named by the player (Settings::RIVAL_NAMES, e.g. Kanto's rival)
    if !name && (rv = Settings::RIVAL_NAMES.find { |tt, _| tt == defn[:tr_type] })
      v = $game_variables ? $game_variables[rv[1]] : nil
      name = v if v.is_a?(String) && !v.empty?
    end
    if !name && defn[:region]
      name = FullPoke.region(defn[:region])&.rival_name
    end
    trainer = NPCTrainer.new(name || "???", defn[:tr_type], defn[:version] || 0)
    trainer.id        = $player.make_foreign_ID
    trainer.items     = (defn[:items] || []).clone
    trainer.lose_text = defn[:lose_text] || "..."
    party = parse_party(defn[:party] || "")
    # "STARTER" in a party stands for the rival's starter line (the one strong
    # against the player's choice), evolved to suit the level.
    party.each do |pd|
      next if pd[:species] != :STARTER
      rival_sp = Teams.counter_starter(defn[:region], FullPoke.state(defn[:region]).starter)
      pd[:species] = FullPoke::Evolution.stage_for(rival_sp, pd[:level], 0)
    end
    party.each do |pd|
      next if !GameData::Species.exists?(pd[:species])
      pkmn = Pokemon.new(pd[:species], pd[:level].clamp(1, FullPoke.level_cap), trainer, false)
      pkmn.reset_moves
      pkmn.item = pd[:item] if pd[:item] && GameData::Item.exists?(pd[:item])
      GameData::Stat.each_main do |s|
        pkmn.iv[s.id] = [pd[:level] / 2, Pokemon::IV_STAT_LIMIT].min
        pkmn.ev[s.id] = [pd[:level] * 3 / 2, Pokemon::EV_LIMIT / 6].min
      end
      pkmn.gender = trainer.male? ? 0 : 1 if !pkmn.singleGendered?
      pkmn.calc_stats
      trainer.party.push(pkmn)
    end
    Teams.adjust_trainer!(trainer, defn, defn[:region])
    return trainer
  end

  # Starts a battle against a FullPoke trainer. Returns true if the player won.
  # Pass can_lose: true for battles that shouldn't black the player out.
  def trainer_battle(key, can_lose: false)
    if $player.able_pokemon_count == 0
      pbMessage(_INTL("You don't have any Pokémon that can battle!"))
      return false
    end
    trainer = build_trainer(key)
    setBattleRule("canLose") if can_lose
    # start_core, not start: start can put this trainer on hold to join a
    # double battle with another trainer who spotted the player at the same
    # time, and then this trainer's own win is never recorded.
    return TrainerBattle.start_core(trainer) == 1
  end
end
