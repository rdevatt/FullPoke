# Travelling across maps in tests: plans a route over walkable tiles, map
# connections, doors/gates (warp events) and water (when the player can Surf),
# then walks it with real input, surfing where the route crosses water.
#   travel_to(map_id)          # anywhere on that map
#   travel_to(map_id, x, y)    # a particular tile (or an event there)
module Route
  TS = load_data('Data/Tilesets.rxdata')
  @maps = {}
  @events = {}

  module_function

  def rx(id) = (@maps[id] ||= (load_data(format('Data/Map%03d.rxdata', id)) rescue nil))

  def water?(m, x, y)
    ts = TS[m.tileset_id]
    [2, 1, 0].each do |z|
      t = m.data[x, y, z]
      next if t.nil? || t == 0
      tag = ts.terrain_tags[t]
      return true if [5, 6, 7].include?(tag)
      return false if ts.passages[t] & 0x0f == 0x0f || ts.priorities[t] == 0
    end
    false
  end

  # :land, :water or nil (blocked)
  def tile(m, x, y)
    return nil if x < 0 || y < 0 || x >= m.width || y >= m.height
    ts = TS[m.tileset_id]
    bridge = false
    [2, 1, 0].each do |z|
      t = m.data[x, y, z]
      next if t.nil? || t == 0
      tag = ts.terrain_tags[t]
      # Bridges are ignored unless you're up on one (a BridgeOn event): read
      # what's underneath, and count the bridge as a walkway only over ground
      # you couldn't otherwise cross (Fortree's treetop walkways)
      if tag == 15
        bridge = true
        next
      end
      return :water if [5, 6, 7].include?(tag)
      return (bridge ? :land : nil) if ts.passages[t] & 0x0f == 0x0f
      return :land if ts.priorities[t] == 0
    end
    :land
  end

  def ledge?(m, x, y)
    ts = TS[m.tileset_id]
    (0..2).any? { |z| (t = m.data[x, y, z]) && t > 0 && ts.terrain_tags[t] == 1 }
  end

  # [solid tiles, warps {[x, y] => [map, x, y]}] from the live map when it's the
  # current one (so erased events don't count), otherwise from the data file.
  def events_of(id)
    solid = {}; warps = {}
    m = rx(id)
    m.events.each_value do |e|
      live = ($game_map.map_id == id) ? $game_map.events[e.id] : nil
      next if live && live.instance_variable_get(:@erased)
      pg = live ? live.instance_variable_get(:@page) : e.pages[0]
      next if !pg
      if pg.graphic.character_name != '' && !pg.through && pg.trigger != 1
        solid[[e.x, e.y]] = true
      end
      pg.list.each do |c|
        if c.code == 201 && c.parameters[0] == 0
          warps[[e.x, e.y]] = [c.parameters[1], c.parameters[2], c.parameters[3]]
          break
        end
      end
    end
    [solid, warps]
  end

  # RPG Maker's per-direction blocking: a tile can stop you leaving or entering
  # it in one direction (shores, fences, ledges). bit: down 1, left 2, right 4, up 8.
  # DIRECTIONAL=0 turns it off (e.g. to find which tile blocks a route).
  DIRECTIONAL = ENV['DIRECTIONAL'] != '0'
  def dir_ok?(m, x, y, d)
    ts = TS[m.tileset_id]
    bit = 1 << (d / 2 - 1)
    # A bridge over ground you can't otherwise cross is a walkway: its own
    # flags decide (as when a BridgeOn event has put you up on it)
    bridge = [2, 1, 0].map { |z| m.data[x, y, z] }.find { |t| t && t > 0 && ts.terrain_tags[t] == 15 }
    if bridge
      under = [1, 0].map { |z| m.data[x, y, z] }.select { |t| t && t > 0 && ts.terrain_tags[t] != 15 }
      return ts.passages[bridge] & bit == 0 if under.any? { |t| ts.passages[t] & 0x0f == 0x0f }
    end
    [2, 1, 0].each do |z|
      t = m.data[x, y, z]
      next if t.nil? || t == 0
      next if ts.terrain_tags[t] == 15
      return true if [5, 6, 7].include?(ts.terrain_tags[t])   # surfable water ignores direction flags
      return true if ts.terrain_tags[t] == 1                  # ledges are jumped (downward only, see plan)
      return false if ts.passages[t] & bit != 0
      return true if ts.priorities[t] == 0
    end
    true
  end

  # Areas the player isn't allowed into yet (badges, starter) are avoided.
  def allowed?(id) = FullPoke::World.map_rule_ok?(id) && !avoided.include?(id)

  # Maps a travel found it can't cross the planned way (entering them again is
  # avoided until the travel ends; moving within the current map still works)
  def avoided = (@avoided ||= [])

  def neighbour_map(id, nx, ny)
    res = $map_factory.getNewMap(nx, ny, id) rescue nil
    res ? [res[0].map_id, res[1], res[2]] : nil
  end

  # Breadth-first plan; returns a list of [state, how] where how is :step,
  # [:warp, x, y] (walk into the warp tile at x, y) or [:edge, dir].
  def plan(goal_map, gx = nil, gy = nil, surf: false, directional: DIRECTIONAL)
    start = [$game_map.map_id, $game_player.x, $game_player.y]
    prev = { start => nil }
    queue = [start]
    found = nil
    until queue.empty?
      cur = queue.shift
      id, x, y = cur
      if id == goal_map && (gx.nil? || (x == gx && y == gy) || (gx && (x - gx).abs + (y - gy).abs == 1 && events_of(id)[1][[gx, gy]].nil? && rx(id).events.values.any? { |e| e.x == gx && e.y == gy }))
        found = cur
        break
      end
      m = rx(id)
      solid, warps = events_of(id)
      { 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0], 8 => [0, -1] }.each do |d, (dx, dy)|
        nx, ny = x + dx, y + dy
        if (w = warps[[nx, ny]]) && rx(w[0])
          nxt = [w[0], w[1], w[2]]
          next if prev.key?(nxt) || !allowed?(w[0])
          prev[nxt] = [cur, [:warp, nx, ny]]
          queue << nxt
          next
        end
        if nx < 0 || ny < 0 || nx >= m.width || ny >= m.height
          nb = neighbour_map(id, nx, ny)
          next if !nb || prev.key?(nb) || !rx(nb[0]) || !allowed?(nb[0])
          kind = tile(rx(nb[0]), nb[1], nb[2])
          next if !kind || (kind == :water && !surf)
          prev[nb] = [cur, [:edge, d]]
          queue << nb
          next
        end
        nxt = [id, nx, ny]
        next if prev.key?(nxt) || solid[[nx, ny]]
        kind = tile(m, nx, ny)
        next if !kind || (kind == :water && !surf)
        next if directional && (!dir_ok?(m, x, y, d) || !dir_ok?(m, nx, ny, 10 - d))
        next if ledge?(m, nx, ny) && d != 2
        prev[nxt] = [cur, :step]
        queue << nxt
      end
    end
    return nil if !found
    steps = []
    cur = found
    while (p = prev[cur])
      steps.unshift([cur, p[1]])
      cur = p[0]
    end
    steps
  end
end

def surf_ready? = $PokemonGlobal.surfing || !$player.get_pokemon_with_move(:SURF).nil? &&
                  pbCheckHiddenMoveBadge(Settings::BADGE_FOR_SURF, false)

# Walks (and surfs) to a map / tile. Raises if there's no way there.
def travel_to(map_id, x = nil, y = nil, tries: 6)
  Route.avoided.clear
  tries.times do |t|
    return true if $game_map.map_id == map_id && (x.nil? || ($game_player.x == x && $game_player.y == y))
    # Strict plan first; if per-direction blocking (which bridges and ladders make
    # approximate) leaves no way, let the real movement decide
    steps = Route.plan(map_id, x, y, surf: surf_ready?) || Route.plan(map_id, x, y, surf: surf_ready?, directional: false) or
      raise "no route to map #{map_id} #{x},#{y} from #{where}"
    before = [$game_map.map_id, $game_player.x, $game_player.y]
    ok = (follow(steps) rescue (log("follow: #{$!.message}"); false))
    # The plan crossed this map a way that doesn't work in the game (one-way
    # slopes, bridges): plan around it next time
    if !ok && [$game_map.map_id, $game_player.x, $game_player.y] == before
      log "no progress through map #{$game_map.map_id}; planning around it"
      Route.avoided << $game_map.map_id
    end
    return true if ok && $game_map.map_id == map_id && (x.nil? || ($game_player.x - x).abs + ($game_player.y - y).abs <= 1)
    # Didn't get there: let things settle and step aside before planning again
    settle(600)
    dir = [:down, :left, :right, :up][t % 4]
    walk(dir)
    settle(200)
  end
  near = $game_map.events.values.select { |e| (e.x - $game_player.x).abs + (e.y - $game_player.y).abs <= 3 }
                .map { |e| "#{e.name}@#{e.x},#{e.y}#{e.through ? ' through' : ''}#{e.starting ? ' starting' : ''}" }
  raise "couldn't travel to map #{map_id} #{x},#{y}; stuck at #{where} (surfing=#{$PokemonGlobal.surfing}, " \
        "bicycle=#{$PokemonGlobal.bicycle}, interpreter=#{pbMapInterpreterRunning?}, moving=#{$game_player.moving?}, " \
        "forcing=#{$game_player.move_route_forcing}, msg=#{$game_temp.message_window_showing}, " \
        "passable up=#{$game_player.passable?($game_player.x, $game_player.y, 8)}, near=#{near.join('; ')})"
end

DIR_SYM = { 2 => :down, 4 => :left, 6 => :right, 8 => :up }

# Follows a plan until it's done or something changes the situation (a battle,
# a push-back, a transfer we didn't expect); returns true if it reached the end.
def follow(steps)
  i = 0
  while i < steps.length
    (state, how) = steps[i]
    map_id = $game_map.map_id
    return false if state[0] != map_id && how == :step
    case how
    when :step
      # Gather the run of steps on this map with the same footing
      j = i
      m = Route.rx(map_id)
      footing = Route.tile(m, state[1], state[2])
      j += 1 while j + 1 < steps.length && steps[j + 1][1] == :step &&
                   Route.tile(m, steps[j + 1][0][1], steps[j + 1][0][2]) == footing
      tx, ty = steps[j][0][1], steps[j][0][2]
      if footing == :water && !$PokemonGlobal.surfing
        # Face the first water tile and Surf
        dx = state[1] - $game_player.x; dy = state[2] - $game_player.y
        dir = dy > 0 ? 2 : dy < 0 ? 8 : dx > 0 ? 6 : 4
        $game_player.turn_generic(dir)
        $choices = [0]
        press_use
        settle(2000)
        return false if !$PokemonGlobal.surfing
        i += 1 if [$game_player.x, $game_player.y] == [state[1], state[2]]
        next
      end
      begin
        go_to(tx, ty)
      rescue RuntimeError
        # The engine's own pathfinding can't see walkways that a BridgeOn
        # event opens on the way: walk the planned steps one by one instead
        (i..j).each do |k|
          px, py = $game_player.x, $game_player.y
          sx, sy = steps[k][0][1], steps[k][0][2]
          d = sy > py ? :down : sy < py ? :up : sx > px ? :right : :left
          walk(d)
          settle(2000)
          break if $game_map.map_id != map_id || [$game_player.x, $game_player.y] != [sx, sy]
        end
      end
      return false if $game_map.map_id != map_id || [$game_player.x, $game_player.y] != [tx, ty]
      i = j + 1
    when Array
      kind = how[0]
      if kind == :warp
        go_to(how[1], how[2])
        settle(4000)
      else
        walk(DIR_SYM[how[1]])
        settle(2000)
      end
      return false if $game_map.map_id != state[0] || [$game_player.x, $game_player.y] != [state[1], state[2]]
      i += 1
    end
  end
  true
end
