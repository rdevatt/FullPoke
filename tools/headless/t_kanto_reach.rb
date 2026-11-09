# Kanto on foot: which places can be reached from Pallet Town at each stage of
# the story, through map connections, doors, stairs, ladders and gates (every
# destination of a multi-choice event such as Silph Co.'s elevator counts).
#   tools/headless/run.sh t_kanto_reach.rb
# Stages:
#   start   no field moves, story obstacles in place (Snorlax, Cut trees, ghost)
#   story   obstacles cleared (Poké Flute, Cut, Silph Scope), still no Surf
#   surf    plus Surf
# Ledges are one-way (downwards); NPCs and other solid events block; doors and
# stairs on solid tiles count (the player bumps into them).
require_relative 'play_lib'
require_relative 'test_lib'
$stdout.sync = true
new_game

TS = load_data('Data/Tilesets.rxdata')
INFOS = load_data('Data/MapInfos.rxdata')
CLEARED = /\AFP: (Snorlax|CutTree|Ghost|Giovanni)\z/
@maps = {}
def rx_map(id) = (@maps[id] ||= (load_data(format('Data/Map%03d.rxdata', id)) rescue nil))

def tile_ok?(m, x, y, surf)
  return false if x < 0 || y < 0 || x >= m.width || y >= m.height
  ts = TS[m.tileset_id]
  [2, 1, 0].each do |z|
    t = m.data[x, y, z]
    next if t.nil? || t == 0
    return surf if [5, 6, 7].include?(ts.terrain_tags[t])
    return false if ts.passages[t] & 0x0f == 0x0f
    return true if ts.priorities[t] == 0
  end
  true
end

def ledge?(m, x, y)
  ts = TS[m.tileset_id]
  (0..2).any? { |z| (t = m.data[x, y, z]) && t > 0 && ts.terrain_tags[t] == 1 }
end

def events_of(id, story)
  m = rx_map(id)
  solid = {}; warps = Hash.new { |h, k| h[k] = [] }
  m.events.each_value do |e|
    pg = e.pages[0]
    next if !pg
    next if story && e.name =~ CLEARED
    solid[[e.x, e.y]] = true if (pg.graphic.character_name != '' || pg.graphic.tile_id > 0) && !pg.through && pg.trigger != 1
    pg.list.each do |c|
      warps[[e.x, e.y]] << c.parameters[1, 3] if c.code == 201 && c.parameters[0] == 0
      if c.code == 355 && c.parameters[0] =~ /FullPoke\.(forest_gate|gate_to_forest)\(:(\w+)\)/
        dest = ($1 == 'forest_gate') ? FullPoke::World.arrival($2.to_sym) : FullPoke::World.forest_exit($2.to_sym)
        warps[[e.x, e.y]] << dest[0, 3] if dest
      end
    end
  end
  [solid, warps]
end

def reach(start, story:, surf:, trace: nil)
  cache = {}
  seen = { start => true }
  prev = {}
  queue = [start]
  until queue.empty?
    id, x, y = queue.shift
    m = rx_map(id) or next
    solid, warps = (cache[id] ||= events_of(id, story))
    warps[[x, y]].each do |w|
      next if !rx_map(w[0]) || seen[w]
      seen[w] = true
      prev[w] = [id, x, y]
      queue << w
    end
    [[0, 1], [0, -1], [1, 0], [-1, 0]].each do |dx, dy|
      nx, ny = x + dx, y + dy
      if nx < 0 || ny < 0 || nx >= m.width || ny >= m.height
        res = $map_factory.getNewMap(nx, ny, id) rescue nil
        next if !res
        st = [res[0].map_id, res[1], res[2]]
        next if seen[st] || !tile_ok?(rx_map(st[0]), st[1], st[2], surf)
        seen[st] = true
        prev[st] = [id, x, y]
        queue << st
        next
      end
      next if solid[[nx, ny]] && !warps.key?([nx, ny])
      next if !tile_ok?(m, nx, ny, surf) && !warps.key?([nx, ny])
      next if ledge?(m, nx, ny) && dy != 1
      st = [id, nx, ny]
      next if seen[st]
      seen[st] = true
      prev[st] = [id, x, y]
      queue << st
    end
  end
  if trace && (hit = seen.keys.find { |k| k[0] == trace })
    chain = []
    c = hit
    while c
      chain.unshift(c) if chain.empty? || chain[0][0] != c[0] || prev[chain[0]] == c && c[0] != chain[0][0]
      c = prev[c]
    end
    hops = []
    c = hit
    while (p = prev[c])
      hops.unshift("#{p[0]}(#{p[1]},#{p[2]})->#{c[0]}(#{c[1]},#{c[2]})") if p[0] != c[0]
      c = p
    end
    puts "  path to #{trace}: #{hops.join('  ')}"
  end
  seen.keys.map(&:first).uniq
end

PALLET = [23, 13, 9]
start = reach(PALLET, story: false, surf: false, trace: ENV['VERBOSE'] ? 30 : nil)
reach(PALLET, story: false, surf: false, trace: 172) if ENV['VERBOSE']
story = reach(PALLET, story: true, surf: false)
surf  = reach(PALLET, story: true, surf: true)
name = ->(id) { "#{INFOS[id]&.name&.strip} (#{id})" }

section 'Before the story obstacles are cleared'
[24, 25, 26, 29, 31, 173, 345].each { |id| check("reach #{name.(id)}", start.include?(id)) }
check("Lavender Town (27) is reachable before the Poké Flute (via Rock Tunnel)", start.include?(27))
check("Fuchsia City (30) is cut off by the two Snorlax", !start.include?(30))
check("Route 13 (46) is cut off by Snorlax", !start.include?(46))
check("Route 17 (50) is cut off by Snorlax", !start.include?(50))
check("Cinnabar Island (172) needs Surf", !story.include?(172))
check("Indigo Plateau (33) needs Surf (Route 23) and Victory Road", !story.include?(33))

section 'With the Poké Flute, Cut and the Silph Scope'
[27, 338, 45, 46, 47, 48, 30, 49, 50, 51, 52, 207, 235, 375, 258].each { |id| check("reach #{name.(id)}", story.include?(id)) }

section 'With Surf'
[53, 172, 54, 56, 335, 33, 292].each { |id| check("reach #{name.(id)}", surf.include?(id)) }
finish
