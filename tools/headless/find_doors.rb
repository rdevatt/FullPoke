# Finds doors drawn on a map that have no warp: a walkable tile set into the
# bottom wall of a building (solid building tiles above, left and right, open
# ground below) with no event on it.
#   tools/headless/rb.sh find_doors.rb <map ids...>
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
    return true if ts.priorities[t] == 0
  end
  map.data[x, y, 0].to_i > 0
end
require_relative 'geo_lib'
ARGV.map(&:to_i).each do |id|
  m = load_data(format('Data/Map%03d.rxdata', id))
  ev = m.events.values.to_h { |e| [[e.x, e.y], true] }
  wall = ->(x, y) { x >= 0 && y >= 0 && x < m.width && y < m.height && Geo.solid_deco?(m, x, y) }
  spots = []
  (1...m.height - 1).each do |y|
    (1...m.width - 1).each do |x|
      next if ev[[x, y]] || !passable_tile?(m, x, y) || !passable_tile?(m, x, y + 1)
      spots << "#{x},#{y}" if wall.(x, y - 1) && wall.(x - 1, y) && wall.(x + 1, y)
    end
  end
  puts "map #{id}: #{spots.join('  ')}"
end
