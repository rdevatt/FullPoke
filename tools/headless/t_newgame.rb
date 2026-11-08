# New Game in each region: the intro's region/mode choice sends the player to
# that region's first town with the right mode and party set.
#   REGIONS=johto tools/headless/run.sh t_newgame.rb   (one region per run)
require_relative 'play_lib'
require_relative 'test_lib'
PluginManager.runPlugins unless $plugins_ran
$plugins_ran = true
GameData.load_all
regions = FullPoke.available_regions
want_ids = (ENV['REGIONS'] || 'johto').split(',').map(&:to_sym)
regions.each_with_index do |reg, idx|
  next if !want_ids.include?(reg.id)   # Kanto's start is covered by t_release.rb / t_journey.rb
  mode = idx.even? ? 1 : 0
  $LOG.clear
  new_game
  $choices = ['NO INFO NEEDED', 'BOY', 'YES', idx, mode, 0]
  home = FullPoke::World.home(reg.id)
  play_until("intro -> #{reg.name}", frames: 20000) { $game_map.map_id == home[0] && !$game_temp.player_transferring }
  settle
  want = mode == 1 ? :continuous : :independent
  check("New Game in #{reg.name}: arrive at #{reg.start_town} home (#{where}), #{want} mode, party set #{FullPoke.progress.active_context}",
        $game_map.map_id == home[0] && FullPoke.region_mode(reg.id) == want &&
        FullPoke.progress.active_context == (want == :independent ? reg.id : :main) &&
        FullPoke.progress.start_region == reg.id)
end
finish
