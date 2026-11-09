# Prints a passability grid of part of a map: '.' walkable, '#' solid,
# '~' water, 'B' solid building/decoration (layer 1/2), 'E' event, ' ' empty.
#   tools/headless/rb.sh pass_grid.rb <map> x y w h
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
require_relative 'geo_lib'
id, x0, y0, w, h = ARGV.map(&:to_i)
m = load_data(format('Data/Map%03d.rxdata', id))
w = [w, m.width - x0].min; h = [h, m.height - y0].min
puts "map #{id} #{m.width}x#{m.height}; columns #{x0}..#{x0 + w - 1}"
puts '     ' + (x0...x0 + w).map { |x| (x % 10).to_s }.join
(y0...y0 + h).each do |y|
  row = (x0...x0 + w).map do |x|
    if m.events.values.any? { |e| e.x == x && e.y == y } then 'E'
    elsif passable_tile?(m, x, y) then '.'
    elsif Geo.water_tile?(m, x, y) then '~'
    elsif (0..2).all? { |z| m.data[x, y, z].to_i == 0 } then ' '
    elsif Geo.solid_deco?(m, x, y) then 'B'
    else '#'
    end
  end
  puts format('%4d ', y) + row.join
end
