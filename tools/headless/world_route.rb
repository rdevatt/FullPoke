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
    [2, 1, 0].each do |z|
      t = m.data[x, y, z]
      next if t.nil? || t == 0
      tag = ts.terrain_tags[t]
      return (ts.passages[t] & 0x0f != 0x0f ? :land : nil) if tag == 15   # bridge
      return :water if [5, 6, 7].include?(tag)
      return nil if ts.passages[t] & 0x0f == 0x0f
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

  # Areas the player isn't allowed into yet (badges, starter) are avoided.
  def allowed?(id) = FullPoke::World.map_rule_ok?(id)

  def neighbour_map(id, nx, ny)
    res = $map_factory.getNewMap(nx, ny, id) rescue nil
    res ? [res[0].map_id, res[1], res[2]] : nil
  end

  # Breadth-first plan; returns a list of [state, how] where how is :step,
  # [:warp, x, y] (walk into the warp tile at x, y) or [:edge, dir].
  def plan(goal_map, gx = nil, gy = nil, surf: false)
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
def travel_to(map_id, x = nil, y = nil, tries: 4)
  tries.times do
    return true if $game_map.map_id == map_id && (x.nil? || ($game_player.x == x && $game_player.y == y))
    steps = Route.plan(map_id, x, y, surf: surf_ready?) or raise "no route to map #{map_id} #{x},#{y} from #{where}"
    ok = follow(steps)
    return true if ok && $game_map.map_id == map_id && (x.nil? || ($game_player.x - x).abs + ($game_player.y - y).abs <= 1)
  end
  raise "couldn't travel to map #{map_id} #{x},#{y}; stuck at #{where}"
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
      go_to(tx, ty)
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
