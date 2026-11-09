# Helpers for driving a real game session headlessly (loaded after the game scripts).
# Message boxes are logged instead of drawn; choices come from $choices.
$LOG = []
$choices = []
class PlayStop < Exception; end
def log(s) = ($LOG << s; puts "  | #{s}")

alias _orig_pbMessage pbMessage
def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
  text = message.to_s.gsub(/\\[a-zA-Z]+\[[^\]]*\]|\\[a-zA-Z]|<\/?\w+>/, '').gsub(/\s+/, ' ').strip
  if commands && !commands.empty?
    pick = $choices.empty? ? defaultCmd : $choices.shift
    pick = commands.index(pick) if pick.is_a?(String)
    raise "no choice #{pick.inspect} in #{commands.inspect}" if pick.nil? || pick >= commands.length
    log "MSG: #{text}  {#{commands.join(' / ')}} -> #{commands[pick]}"
    return pick
  end
  log "MSG: #{text}"
  return 0
end
def pbConfirmMessage(message, &block) = pbMessage(message, [_INTL("Yes"), _INTL("No")]) == 0
def pbConfirmMessageSerious(message, &block) = pbConfirmMessage(message)
def pbEnterPlayerName(*_a) = (log("ENTER PLAYER NAME -> Red"); "Red")
def pbEnterText(help, *_a) = (log("ENTER TEXT '#{help}' -> Blue"); "Blue")
def pbEnterPokemonName(*_a) = ""

# Interpreter "Show Choices" goes through pbShowCommands, not pbMessage.
class Interpreter
  alias _orig_command_102 command_102
  def command_102
    cmds = @list[@index].parameters[0]
    pick = $choices.empty? ? 0 : $choices.shift
    pick = cmds.index(pick) if pick.is_a?(String)
    raise "no choice #{pick.inspect} in #{cmds.inspect}" if pick.nil? || pick >= cmds.length
    log "CHOICE {#{cmds.join(' / ')}} -> #{cmds[pick]}"
    @message_waiting = false
    @branch[@list[@index].indent] = pick
    Input.update
    return true
  end
end

def new_game
  PluginManager.runPlugins unless $plugins_ran
  $plugins_ran = true
  Game.initialize
  Game.set_up_system
  Game.start_new
end

# Runs Scene_Map frame by frame until the block returns true (or the budget runs out).
# The stop condition is only checked at the start of Scene_Map#update (between frames),
# never from inside Graphics.update, so engine code (transfers, messages) can't be cut off.
class Scene_Map
  alias_method :_hl_update, :update
  alias_method :_hl_main, :main
  # Only the update called directly by main's loop is a safe stopping point;
  # update is also re-entered from inside engine sequences (battle intros etc.).
  def main
    $hl_in_main = true
    _hl_main
  ensure
    $hl_in_main = false
  end
  def update
    outer = $hl_in_main && !$hl_in_update
    raise PlayStop if outer && $headless_stop&.call
    $hl_in_update = true if outer
    _hl_update
  ensure
    $hl_in_update = false if outer
  end
end
def play_until(desc, frames: 6000, &cond)
  start = Graphics.frame_count
  $headless_stop = cond
  $headless_on_frame = lambda do |f|
    raise "TIMEOUT waiting for: #{desc} (map #{$game_map.map_id} at #{$game_player.x},#{$game_player.y})" if f - start > frames
  end
  begin
    $scene.main while $scene.is_a?(Scene_Map)
    raise "scene changed to #{$scene.class}" unless $scene.is_a?(Scene_Map)
  rescue PlayStop
    log "OK: #{desc} (map #{$game_map.map_id} #{$game_player.x},#{$game_player.y}, #{Graphics.frame_count - start} frames)" if ENV["VERBOSE"]
  ensure
    $headless_on_frame = nil
    $headless_stop = nil
  end
end

# Holds a direction until the player has taken one step (or clearly can't).
def walk(*dirs)
  dirs.flatten.each do |d|
    code = { down: Input::DOWN, left: Input::LEFT, right: Input::RIGHT, up: Input::UP }[d]
    start = [$game_player.x, $game_player.y, $game_map.map_id]
    started = Graphics.frame_count
    $input_script = [code] * 12
    play_until("step #{d}", frames: 900) do
      # A transfer (door, boat) ends the step: don't keep walking on the new map
      $input_script.clear if $game_temp.player_transferring || $game_map.map_id != start[2]
      pos = [$game_player.x, $game_player.y, $game_map.map_id]
      done_moving = !$game_player.moving? && !$game_temp.player_transferring && !pbMapInterpreterRunning?
      (pos != start && done_moving) || (Graphics.frame_count - started > 30 && $input_script.empty? && done_moving)
    end
    $input_script = []
  end
end
def busy?
  pbMapInterpreterRunning? || $game_player.moving? || $game_temp.player_transferring ||
    $game_temp.message_window_showing ||
    $game_map.events.values.any?(&:starting) || $game_temp.common_event_id > 0
end
# Waits until nothing has been happening for several consecutive frames.
def settle(frames = 400, min_frames: 20)
  quiet = 0
  start = Graphics.frame_count
  play_until("events settle", frames: frames) do
    quiet = busy? ? 0 : quiet + 1
    quiet >= 4 && Graphics.frame_count - start >= min_frames
  end
end
def press_use(frames = 6000)
  $input_script = [Input::USE]
  quiet = 0
  play_until("interact", frames: frames) { quiet = ($input_script.empty? && !busy?) ? quiet + 1 : 0; quiet >= 4 }
end
def where = "map #{$game_map.map_id} (#{$game_player.x},#{$game_player.y}) dir #{$game_player.direction}"

# Battles run with the real battle engine, but no visuals and the AI choosing for both sides.
module BattleCreationHelperMethods
  module_function
  def create_battle_scene = Battle::DebugSceneNoVisuals.new(true)
  class << self
    alias_method :_orig_prepare_battle, :prepare_battle
    def prepare_battle(battle)
      _orig_prepare_battle(battle)
      battle.controlPlayer = true
    end
  end
end
module PBDebug
  def self.log_message(msg) = ($LOG << "BATTLE: #{msg}"; puts "  | BATTLE: #{msg}" if $SHOW_BATTLE)
end
$battle_results = []
EventHandlers.add(:on_end_battle, :headless_record, proc { |outcome, _canLose| $battle_results << outcome })

# Breadth-first path on the current map using the engine's own passability checks.
# Tiles holding other events' touch triggers are avoided (except the goal).
def find_path(gx, gy)
  sx, sy = $game_player.x, $game_player.y
  avoid = {}
  $game_map.events.each_value do |e|
    next if e.x == gx && e.y == gy
    avoid[[e.x, e.y]] = true if [1, 2].include?(e.trigger) && e.list && e.list.length > 1
  end
  prev = { [sx, sy] => nil }
  queue = [[sx, sy]]
  dirs = { 2 => [0, 1, :down], 4 => [-1, 0, :left], 6 => [1, 0, :right], 8 => [0, -1, :up] }
  until queue.empty?
    cx, cy = queue.shift
    break if cx == gx && cy == gy
    dirs.each do |d, (ox, oy, _)|
      nx, ny = cx + ox, cy + oy
      next if prev.key?([nx, ny]) || avoid[[nx, ny]]
      # An event on the goal tile (a door, an NPC) is reached by walking into it.
      goal_event = nx == gx && ny == gy && $game_map.events.values.any? { |e| e.x == gx && e.y == gy }
      next unless $game_player.passable?(cx, cy, d) || (goal_event && $game_map.valid?(nx, ny))
      prev[[nx, ny]] = [cx, cy, d]
      queue << [nx, ny]
    end
  end
  return nil unless prev.key?([gx, gy])
  path = []
  cur = [gx, gy]
  while (p = prev[cur])
    path.unshift(dirs[p[2]][2]); cur = [p[0], p[1]]
  end
  path
end

# Walks to (x, y) on the current map, re-planning when something (an NPC, a trainer
# who walked over) gets in the way; stops early on a transfer.
def go_to(x, y)
  map = $game_map.map_id
  12.times do
    return true if $game_player.x == x && $game_player.y == y
    path = find_path(x, y) or raise "no path to (#{x},#{y}) from #{where}"
    path.each do |d|
      before = [$game_player.x, $game_player.y]
      walk(d)
      settle(8000)
      jumped = ($game_player.x - before[0]).abs + ($game_player.y - before[1]).abs > 1
      return true if $game_map.map_id != map || jumped
      break if [$game_player.x, $game_player.y] == before   # blocked: re-plan
    end
    return true if $game_player.x == x && $game_player.y == y
    # Reached an event goal by bumping into it (doors, NPCs): done.
    return true if $game_map.events.values.any? { |e| e.x == x && e.y == y } &&
                   ($game_player.x - x).abs + ($game_player.y - y).abs == 1
  end
  raise "couldn't reach (#{x},#{y}); stuck at #{where}"
end

# Crosses to the neighbouring map over a map connection: walks to the edge tile and steps off.
def cross_edge(dir, along = nil)
  w, h = $game_map.width, $game_map.height
  candidates = case dir
               when :up then (0...w).map { |x| [x, 0] }
               when :down then (0...w).map { |x| [x, h - 1] }
               when :left then (0...h).map { |y| [0, y] }
               when :right then (0...h).map { |y| [w - 1, y] }
               end
  candidates.sort_by! { |(x, y)| along ? ((dir == :up || dir == :down) ? (x - along).abs : (y - along).abs) : 0 }
  map = $game_map.map_id
  candidates.each do |(x, y)|
    next unless (path = find_path(x, y))
    go_to(x, y)
    walk(dir); settle
    return true if $game_map.map_id != map
  end
  raise "couldn't cross #{dir} edge from #{where}"
end

class Scene_Map
  alias_method :_hl_transfer_player, :transfer_player
  def transfer_player(*args)
    from = "#{$game_map.map_id}(#{$game_player.x},#{$game_player.y})"
    _hl_transfer_player(*args)
    log "TRANSFER #{from} -> #{$game_map.map_id}(#{$game_player.x},#{$game_player.y})"
  end
end
