# Lists a map's separate walkable areas (10+ tiles): size, bounding box, the
# top/bottom/left/right-most tiles, and which edges of the map they touch.
#   tools/headless/rb.sh area_list.rb <map ids...>
require_relative 'rpg_classes'
def load_data(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
Dir.chdir('/game')
TILESETS = load_data('Data/Tilesets.rxdata')
def passable_tile?(map, x, y)
  return false if x < 0 || y < 0 || x >= map.width || y >= map.height
  ts = TILESETS[map.tileset_id]
  [2, 1, 0].each do |z|
    t = map.data[x, y, z]
    next if t.nil? || t == 0
    return false if ts.passages[t] & 0x0f == 0x0f
    return false if ts.terrain_tags[t] == 5 || ts.terrain_tags[t] == 7
    return true if ts.priorities[t] == 0
  end
  map.data[x, y, 0].to_i > 0
end
ARGV.each do |id|
  m = load_data(format('Data/Map%03d.rxdata', id.to_i))
  seen = {}; areas = []
  m.height.times do |y|
    m.width.times do |x|
      next if seen[[x, y]] || !passable_tile?(m, x, y)
      q = [[x, y]]; seen[[x, y]] = true; a = [[x, y]]
      until q.empty?
        cx, cy = q.shift
        [[1, 0], [-1, 0], [0, 1], [0, -1]].each { |dx, dy| n = [cx + dx, cy + dy]; next if seen[n] || !passable_tile?(m, *n); seen[n] = true; q << n; a << n }
      end
      areas << a if a.size >= 10
    end
  end
  evs = m.events.values.map { |e| [e.x, e.y, e.name] }
  puts "== map #{id} #{m.width}x#{m.height} t#{m.tileset_id}: #{areas.length} areas"
  areas.sort_by { |a| -a.size }.each_with_index do |a, i|
    xs = a.map(&:first); ys = a.map(&:last)
    edges = []
    edges << 'N' if ys.min == 0; edges << 'S' if ys.max == m.height - 1; edges << 'W' if xs.min == 0; edges << 'E' if xs.max == m.width - 1
    top = a.min_by { |x, y| [y, x] }; bot = a.max_by { |x, y| [y, -x] }
    ev = evs.select { |ex, ey, _| a.include?([ex, ey]) || a.include?([ex, ey + 1]) }.map { |_, _, n| n }.uniq.first(3)
    puts format('  #%-2d %5d tiles  x%3d-%-3d y%3d-%-3d top %s bottom %s edges %s %s', i, a.size, xs.min, xs.max, ys.min, ys.max, top.join(','), bot.join(','), edges.join, ev.empty? ? '' : "events: #{ev.join('; ')}")
  end
end
