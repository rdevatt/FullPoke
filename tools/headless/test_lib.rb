# Small assertion helpers for the headless tests (loaded after play_lib).
$checks = []

def section(title)
  puts "\n== #{title}"
end

def check(desc, ok, quiet: false)
  ok = ok ? true : false
  $checks << [desc, ok]
  puts "  #{ok ? 'PASS' : 'FAIL'} #{desc}" if !quiet || !ok
  ok
end

def finish
  failed = $checks.reject { |_, ok| ok }
  puts "\n#{$checks.length - failed.length}/#{$checks.length} checks passed"
  failed.each { |d, _| puts "  FAILED: #{d}" }
  exit(failed.empty? ? 0 : 1)
end

# Puts the player on a map (as a transfer would), so map-dependent logic
# (region, party set, offset) applies.
def on_map(map_id, x = nil, y = nil)
  m = load_data(format('Data/Map%03d.rxdata', map_id))
  x ||= m.width / 2
  y ||= m.height / 2
  $game_temp.player_transferring  = true
  $game_temp.player_new_map_id    = map_id
  $game_temp.player_new_x         = x
  $game_temp.player_new_y         = y
  $game_temp.player_new_direction = 2
  if !$scene.is_a?(Scene_Map) || !$scene.instance_variable_get(:@spritesets)
    $scene = Scene_Map.new
    $scene.createSpritesets
  end
  $scene.transfer_player
  $game_temp.player_transferring = false
end

def describe_team(name, trainer)
  puts "    #{name}: " + trainer.party.map { |pk|
    "#{pk.speciesName} L#{pk.level} [#{pk.types.join('/')}] @#{pk.item_id} {#{pk.ability_id}} (#{pk.moves.map(&:id).join(',')})"
  }.join("\n      ")
end

# Runs a wild battle to the end with the AI on both sides. Returns the outcome.
def quick_wild_battle(species, level)
  $battle_results.clear
  setBattleRule("canLose")
  WildBattle.start(species, level)
  $battle_results.last
end

def quick_trainer_battle(trainer, *my_pokemon)
  saved = $player.party.clone
  $player.party.replace(my_pokemon) if !my_pokemon.empty?
  $battle_results.clear
  setBattleRule("canLose")
  TrainerBattle.start(trainer)
  $battle_results.last
ensure
  $player.party.replace(saved) if !my_pokemon.empty?
end
