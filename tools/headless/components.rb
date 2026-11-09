# Walkable areas of a map (4-connected passable tiles; with SURF=1 water joins
# them), largest first, each with its bounding box and the given marker tiles
# (ladders, holes, warps...) and warp events it contains.
#   SURF=1 SOLID=<ids> tools/headless/rb.sh components.rb <map> [min size] [marker tile ids...]
require_relative 'rpg_classes'
def load_data(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
Dir.chdir('/game')
TILESETS = load_data('Data/Tilesets.rxdata')
SOLID = ENV['SOLID'].to_s.split(',').map(&:to_i)   # tiles to treat as solid (planned fixes)
def passable_tile?(map, x, y)
  return false if x < 0 || y < 0 || x >= map.width || y >= map.height
  ts = TILESETS[map.tileset_id]
  [2, 1, 0].each do |z|
    t = map.data[x, y, z]
    next if t.nil? || t == 0
    return ENV['SURF'] == '1' if [5, 6, 7].include?(ts.terrain_tags[t])
    return false if ts.passages[t] & 0x0f == 0x0f || SOLID.include?(t)
    return true if ts.priorities[t] == 0
  end
  false
end
id, min, *marks = ARGV.map(&:to_i)
min ||= 10
m = load_data(format('Data/Map%03d.rxdata', id))
ev = {}
m.events.each_value do |e|
  c = e.pages.flat_map(&:list).find { |cc| cc.code == 201 }
  ev[[e.x, e.y]] = c ? "#{e.name}->#{c.parameters[1]}(#{c.parameters[2]},#{c.parameters[3]})" : e.name
end
seen = {}
comps = []
m.height.times do |y|
  m.width.times do |x|
    next if seen[[x, y]] || !passable_tile?(m, x, y)
    q = [[x, y]]; seen[[x, y]] = true; g = []
    until q.empty?
      c = q.shift; g << c
      [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
        n = [c[0] + dx, c[1] + dy]
        next if seen[n] || !passable_tile?(m, *n)
        seen[n] = true; q << n
      end
    end
    comps << g
  end
end
comps.select { |g| g.length >= min }.sort_by { |g| -g.length }.each do |g|
  xs = g.map(&:first); ys = g.map(&:last)
  set = g.to_h { |p| [p, true] }
  near = ->(p) { set[p] || [[1, 0], [-1, 0], [0, 1], [0, -1]].any? { |dx, dy| set[[p[0] + dx, p[1] + dy]] } }
  mk = []
  m.height.times { |y| m.width.times { |x| mk << "#{m.data[x, y, 1] == 0 ? m.data[x, y, 2] : m.data[x, y, 1]}@#{x},#{y}" if (1..2).any? { |z| marks.include?(m.data[x, y, z]) } && near.([x, y]) } }
  evs = ev.select { |p, _| near.(p) }.map { |p, n| "#{n}@#{p.join(',')}" }
  puts format('%5d tiles at %s  x %d-%d y %d-%d  %s %s', g.length, g.first.join(','), xs.min, xs.max, ys.min, ys.max, mk.join(' '), evs.join(' '))
end
