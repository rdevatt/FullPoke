# Walks the world on foot (no Surf, Cut, Strength or other field moves) from a
# starting point and reports which maps can be reached: through map connections,
# warps (doors, stairs, gates) and FullPoke's scripted gates. Used to audit the
# map pack's Kanto connections and the generated circuits.
#   tools/headless/run.sh t_reach.rb [map x y] [target map ids...]
# Ledges are treated as one-way (downwards); NPCs and other solid events block.
require_relative 'play_lib'

start_map, sx, sy = (ARGV[0] ? ARGV[0..2].map(&:to_i) : [23, 13, 9])
SURF = ENV['SURF'] == '1'   # water counts as walkable (the player can Surf)
targets = ARGV[3..]&.map(&:to_i) || []
new_game   # sets up $map_factory and the game state the engine's map helpers need
# RULES=<region>:<badges> respects FullPoke's badge-gated areas with that many of
# the region's badges (and its story battles done), e.g. RULES=johto:3
RULES = ENV['RULES'] && ENV['RULES'].split(':').then { |r, b| [r.to_sym, b.to_i] }
if RULES
  FullPoke.begin_region(RULES[0], :continuous)
  FullPoke.state(RULES[0]).starter = FullPoke.region(RULES[0]).starters[0]
  RULES[1].times { |i| FullPoke.badge!(RULES[0], i) }
  FullPoke::Circuit.get(RULES[0])[:stages].each { |st| (st[:extras] || []).each { |k| FullPoke.set_flag(RULES[0], :"beat_#{k}") } }
end
def rule_ok?(id) = !RULES || FullPoke::World.map_rule_ok?(id)

TS = load_data('Data/Tilesets.rxdata')
INFOS = load_data('Data/MapInfos.rxdata')
@maps = {}
def rx_map(id) = (@maps[id] ||= (load_data(format('Data/Map%03d.rxdata', id)) rescue nil))

def tile_ok?(m, x, y)
  return false if x < 0 || y < 0 || x >= m.width || y >= m.height
  ts = TS[m.tileset_id]
  [2, 1, 0].each do |z|
    t = m.data[x, y, z]
    next if t.nil? || t == 0
    tag = ts.terrain_tags[t]
    return true if tag == 15   # bridge: walkable once a BridgeOn event puts you up on it
    if [5, 6, 7, 16].include?(tag)   # water (needs Surf)
      return SURF && ts.passages[t] & 0x0f != 0x0f || SURF && z == 0
    end
    return false if ts.passages[t] & 0x0f == 0x0f
    return true if ts.priorities[t] == 0
  end
  true
end

def ledge?(m, x, y)
  ts = TS[m.tileset_id]
  (0..2).any? { |z| (t = m.data[x, y, z]) && t > 0 && ts.terrain_tags[t] == 1 }
end

@ev_cache = {}
def events_of(id)
  @ev_cache[id] ||= begin
    m = rx_map(id)
    solid = {}; warps = {}
    m.events.each_value do |e|
      pg = e.pages[0]
      next if !pg
      if pg.graphic.character_name != '' && !pg.through && pg.trigger != 1
        solid[[e.x, e.y]] = true
      end
      pg.list.each do |c|
        if c.code == 201 && c.parameters[0] == 0
          warps[[e.x, e.y]] = [c.parameters[1], c.parameters[2], c.parameters[3]]
          break
        end
        if c.code == 355 && c.parameters[0] =~ /FullPoke\.(forest_gate|gate_to_forest)\(:(\w+)\)/
          dest = ($1 == 'forest_gate') ? FullPoke::World.arrival($2.to_sym) : FullPoke::World.forest_exit($2.to_sym)
          warps[[e.x, e.y]] = dest[0, 3] if dest
          break
        end
      end
    end
    [solid, warps]
  end
end

seen = {}
queue = [[start_map, sx, sy]]
seen[[start_map, sx, sy]] = true
reached = { start_map => [sx, sy] }
until queue.empty?
  id, x, y = queue.shift
  m = rx_map(id)
  next if !m
  solid, warps = events_of(id)
  if (w = warps[[x, y]]) && rx_map(w[0]) && rule_ok?(w[0])
    st = [w[0], w[1], w[2]]
    if !seen[st]
      seen[st] = true
      reached[w[0]] ||= [w[1], w[2]]
      queue << st
    end
  end
  [[0, 1], [0, -1], [1, 0], [-1, 0]].each do |dx, dy|
    nx, ny = x + dx, y + dy
    if nx < 0 || ny < 0 || nx >= m.width || ny >= m.height
      res = $map_factory.getNewMap(nx, ny, id) rescue nil
      next if !res
      nm = res[0].map_id
      next if !rule_ok?(nm)
      st = [nm, res[1], res[2]]
      next if seen[st] || !tile_ok?(rx_map(nm), res[1], res[2])
      seen[st] = true
      reached[nm] ||= [res[1], res[2]]
      queue << st
      next
    end
    # Doors and gates on solid tiles trigger when walked into
    if (w = warps[[nx, ny]]) && !tile_ok?(m, nx, ny) && rx_map(w[0]) && rule_ok?(w[0])
      st = [w[0], w[1], w[2]]
      if !seen[st]
        seen[st] = true
        reached[w[0]] ||= [w[1], w[2]]
        queue << st
      end
      next
    end
    next if solid[[nx, ny]] && !warps[[nx, ny]]
    next if !tile_ok?(m, nx, ny)
    next if ledge?(m, nx, ny) && dy != 1
    st = [id, nx, ny]
    next if seen[st]
    seen[st] = true
    queue << st
  end
end
puts "Reachable on foot from map #{start_map} (#{sx},#{sy}): #{reached.size} maps"
reached.keys.sort.each { |id| puts format('  %4d %s', id, INFOS[id]&.name) } if ENV['VERBOSE']
if !targets.empty?
  targets.each do |t|
    tiles = seen.keys.select { |k| k[0] == t }
    ext = tiles.empty? ? '' : format('x %d-%d, y %d-%d (%d tiles)', tiles.map { |k| k[1] }.min, tiles.map { |k| k[1] }.max,
                                     tiles.map { |k| k[2] }.min, tiles.map { |k| k[2] }.max, tiles.size)
    puts format('  %-4s %4d %-28s %s', reached[t] ? 'OK' : 'NO', t, INFOS[t]&.name, ext)
  end
end

# GRID=<map> prints which tiles of that map were reached ('o') over its walkable tiles ('.')
if ENV['GRID']
  gm = ENV['GRID'].to_i
  m = rx_map(gm)
  m.height.times do |y|
    puts format('%4d ', y) + (0...m.width).map { |x| seen[[gm, x, y]] ? 'o' : (tile_ok?(m, x, y) ? '.' : '#') }.join
  end
end

# AUDIT=<map ids, comma-separated> lists, for each map, walkable tiles the walk
# never reached (every tile should be reachable). Empty cells (nothing drawn)
# don't count; tiles under events don't count. Unreached tiles are grouped
# into areas: "areas" are groups of 10+ tiles, "pockets" smaller ones.
# (AUDIT=@file reads the ids from a file in tools/headless)
ENV['AUDIT'] = File.read(File.join(__dir__, ENV['AUDIT'][1..])).strip if ENV['AUDIT']&.start_with?('@')
if ENV['AUDIT']
  totals = Hash.new(0)
  ENV['AUDIT'].split(',').map(&:to_i).each do |am|
    m = rx_map(am) or next
    solid_ev, warp_ev = events_of(am)
    drawn = ->(x, y) { (0..2).any? { |z| m.data[x, y, z].to_i > 0 } }
    walk = 0; miss = {}
    m.height.times do |y|
      m.width.times do |x|
        next if !drawn.(x, y) || !tile_ok?(m, x, y) || solid_ev[[x, y]] || warp_ev[[x, y]]
        walk += 1
        miss[[x, y]] = true if !seen[[am, x, y]]
      end
    end
    groups = []
    left = miss.dup
    until left.empty?
      start, = left.first
      left.delete(start); q = [start]; g = [start]
      until q.empty?
        cx, cy = q.shift
        [[1, 0], [-1, 0], [0, 1], [0, -1]].each { |dx, dy| n = [cx + dx, cy + dy]; next if !left.delete(n); q << n; g << n }
      end
      groups << g
    end
    areas = groups.select { |g| g.length >= 10 }
    pockets = groups.reject { |g| g.length >= 10 }
    totals[:area] += areas.sum(&:length); totals[:pocket] += pockets.sum(&:length); totals[:walk] += walk
    next if miss.empty?
    puts format('AUDIT %4d %-34s walkable %6d unreached %6d (areas %d: %d tiles; pockets %d: %d tiles) %s', am, INFOS[am]&.name.to_s[0, 34], walk, miss.length,
                areas.length, areas.sum(&:length), pockets.length, pockets.sum(&:length), areas.max_by(&:length)&.first&.join(','))
    # AUDIT_AREAS=1 also lists each area's size, bounds, a tile in it, its
    # commonest ground tiles and the closest pair of (area tile, reached tile)
    areas.sort_by { |g| -g.length }.each do |g|
      xs = g.map(&:first); ys = g.map(&:last)
      ground = g.map { |x, y| m.data[x, y, 0] }.tally.max_by(3) { |_, c| c }.map { |t, c| "#{t}x#{c}" }.join(' ')
      # (land tiles only: a passage can't drop the player into water)
      wet = ->(x, y) { (0..2).any? { |z| (t = m.data[x, y, z]) && t > 0 && [5, 6, 7, 16].include?(TS[m.tileset_id].terrain_tags[t]) } }
      dry = g.reject { |x, y| wet.(x, y) }
      from = {}; g.each { |t| from[t] = t }
      q = dry.dup; near = nil
      until q.empty? || near
        c = q.shift
        [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
          n = [c[0] + dx, c[1] + dy]
          next if from[n] || n[0] < 0 || n[1] < 0 || n[0] >= m.width || n[1] >= m.height
          from[n] = from[c]
          (near = n; break) if seen[[am, n[0], n[1]]] && !wet.(*n) && !solid_ev[n] && !warp_ev[n]
          q << n
        end
      end
      link = near ? "link #{from[near].join(',')} #{near.join(',')}" : (dry.empty? ? 'all water' : '')
      puts format('        area %5d tiles  x %d-%d  y %d-%d  at %-8s ground %s %s', g.length, xs.min, xs.max, ys.min, ys.max, g.min_by { |x, y| [y, x] }.join(','), ground, link)
    end if ENV['AUDIT_AREAS']
  end
  # AUDIT_TILES=1: per bottom-layer tile, how often it was reached vs left in
  # unreached areas (to find cliff-top tiles drawn walkable)
  if ENV['AUDIT_TILES']
    stats = Hash.new { |h, k| h[k] = [0, 0] }
    ENV['AUDIT'].split(',').map(&:to_i).each do |am|
      m = rx_map(am) or next
      m.height.times do |y|
        m.width.times do |x|
          next if !tile_ok?(m, x, y) || (0..2).all? { |z| m.data[x, y, z].to_i == 0 }
          key = [m.tileset_id, m.data[x, y, 0], [1, 2].map { |z| m.data[x, y, z] }.max]
          seen[[am, x, y]] ? stats[key][0] += 1 : stats[key][1] += 1
        end
      end
    end
    stats.sort_by { |_, (r, u)| -u }.first(60).each { |(ts, l0, top), (r, u)| puts format('TILES ts%d layer0 %5d top %5d  reached %6d  unreached %6d', ts, l0, top, r, u) }
  end
  puts "AUDIT total walkable #{totals[:walk]}, unreached: #{totals[:area]} in areas, #{totals[:pocket]} in small pockets"
end
