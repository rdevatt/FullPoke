# Prints terrain tags of part of a map (highest non-zero tag over the layers):
# 'L' ledge, 'g' grass, 'b' bridge, 'w' water, '.' none, other tags as digits.
#   tools/headless/rb.sh tag_grid.rb <map> x y w h
require_relative 'rpg_classes'
L = ->(p) { File.open(p, 'rb') { |f| Marshal.load(f) } }
id, x0, y0, w, h = ARGV.map(&:to_i)
m = L.(format('/game/Data/Map%03d.rxdata', id))
ts = L.('/game/Data/Tilesets.rxdata')[m.tileset_id]
sym = { 0 => '.', 1 => 'L', 2 => 'g', 5 => 'w', 6 => 'w', 7 => 'w', 15 => 'b' }
puts '     ' + (x0...x0 + w).map { |x| (x % 10).to_s }.join
(y0...y0 + h).each do |y|
  puts format('%4d ', y) + (x0...x0 + w).map { |x|
    tag = (0..2).map { |z| ts.terrain_tags[m.data[x, y, z]] }.max
    sym[tag] || (tag % 10).to_s
  }.join
end
