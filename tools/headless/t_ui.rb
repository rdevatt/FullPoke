# Opens each major UI screen with scripted button presses; any crash or a screen
# that won't close is reported. Battles here use the real Battle::Scene.
require_relative 'play_lib'
$choices = ['NO INFO NEEDED', 'BOY', 'YES']
new_game
play_until("intro done", frames: 20000) { $game_map.map_id == 176 && !$game_temp.player_transferring }
settle
[[:PIKACHU, 12], [:CHARMANDER, 15], [:GEODUDE, 10], [:ROTOM, 20], [:DRAGAPULT, 50]].each { |sp, lv| pbAddToPartySilent(sp, lv) }
$player.has_pokedex = true
8.times { |i| $player.pokedex.unlock(i) }
[:BULBASAUR, :PIKACHU, :CHIKORITA, :TREECKO, :TURTWIG, :SNIVY, :CHESPIN, :ROWLET, :GROOKEY].each { |s| $player.pokedex.register(s); $player.pokedex.set_owned(s) }
$bag.add(:POTION, 5); $bag.add(:POKEBALL, 10); $bag.add(:TM01, 1) rescue nil; $bag.add(:BICYCLE); $bag.add(:OAKSPACKAGE)
B = Input::BACK; C = Input::USE; D = Input::DOWN; R = Input::RIGHT; L = Input::LEFT
$results = []
def ui(name, inputs, frames: 4000)
  # Idle frames first (fades read input too), then each press followed by a few idle frames.
  $input_script = [nil] * 40 + inputs.flat_map { |i| [i] + [nil] * 8 }
  $input_auto_confirm = false
  Graphics.frame_budget = Graphics.frame_count + frames
  yield
  $results << [name, 'OK']
rescue Graphics::FrameBudgetExceeded
  $results << [name, "TIMEOUT (didn't close; #{$input_script.compact.size} presses left)"]
rescue Exception => e
  $results << [name, "ERROR #{e.class}: #{e.message[0, 150]} @ #{e.backtrace.first(4).join(' | ')}"]
ensure
  Graphics.frame_budget = nil; $input_script = []; $input_auto_confirm = false
end
ui("party (open summary via commands)", [C, C] + [D] * 4 + [B] * 30) { pbFadeOutIn { PokemonPartyScreen.new(PokemonParty_Scene.new, $player.party).pbPokemonScreen } }
ui("summary pages", [D, D, D, D, R, R, R, R, B] + [B] * 10) { pbFadeOutIn { PokemonSummaryScreen.new(PokemonSummary_Scene.new).pbStartScreen($player.party, 0) } }
ui("bag pockets", [R, R, R, R, R, R, R, R, D, D] + [B] * 10) { pbFadeOutIn { PokemonBagScreen.new(PokemonBag_Scene.new, $bag).pbStartScreen } }
ui("pokedex menu -> list -> entry pages", [C, C, R, R, L, L, B, B, D, C, B] + [B] * 15) { pbFadeOutIn { PokemonPokedexMenuScreen.new(PokemonPokedexMenu_Scene.new).pbStartScreen } }
ui("region map", [R, R, D, D, B] + [B] * 5) { pbShowMap(-1, false) }
ui("trainer card", [C, B] + [B] * 5) { pbFadeOutIn { PokemonTrainerCardScreen.new(PokemonTrainerCard_Scene.new).pbStartScreen } }
ui("pc storage", [R, R, D, B] + [B] * 15) { pbFadeOutIn { PokemonStorageScreen.new(PokemonStorageScene.new, $PokemonStorage).pbStartScreen(0) } }
ui("options", [D, D, R, D, R] + [B] * 6) { pbFadeOutIn { PokemonOptionScreen.new(PokemonOption_Scene.new).pbStartScreen } }
ui("poke mart (buy, sell, quit)", [D, D, B] + [B] * 6 + [D, B] + [B] * 6) { $choices = ["I'm here to buy", "I'm here to sell", "No, thanks"]; pbPokemonMart([:POKEBALL, :POTION, :ANTIDOTE]) }
ui("evolution scene", [], frames: 3000) do
  $input_auto_confirm = true
  pk = Pokemon.new(:PIKACHU, 20)
  pbFadeOutInWithMusic { evo = PokemonEvolutionScene.new; evo.pbStartScreen(pk, :RAICHU); evo.pbEvolution; evo.pbEndScreen }
  raise "didn't evolve (#{pk.species})" unless pk.species == :RAICHU
end
# Real battle scene: restore the stock scene for these two battles; the AI still picks moves.
module BattleCreationHelperMethods
  def self.create_battle_scene = Battle::Scene.new
end
ui("wild battle (real scene)", [], frames: 20000) do
  $input_auto_confirm = true
  WildBattle.start(:PIDGEY, 5)
end
ui("trainer battle (real scene, Brock)", [], frames: 30000) do
  $input_auto_confirm = true
  setBattleRule("canLose")
  TrainerBattle.start(:KANTOLEADER_Brock, "Brock")
end
$results.each { |n, r| puts "UI #{r.start_with?('OK') ? 'PASS' : 'FAIL'} #{n}: #{r}" }
puts "missing image files requested: #{$MISSING_FILES.keys.size}"
$MISSING_FILES.keys.map { |f| f.sub(/\/[^\/]*$/, '/') }.tally.sort_by { -_2 }.first(12).each { |d, n| puts "   #{n} under #{d}" }
