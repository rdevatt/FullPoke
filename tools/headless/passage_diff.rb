# Shows where the builder's tileset fixes changed passability on part of a map:
# 'C' changed (made solid), '#' solid in the map pack's tileset, '.' open.
#   tools/headless/rb.sh passage_diff.rb <map> x y w h
require_relative 'rpg_classes'
L = ->(p) { File.open(p, 'rb') { |f| Marshal.load(f) } }
id, x0, y0, w, h = ARGV.map(&:to_i)
m = L.(format('/game/Data/Map%03d.rxdata', id))
base = L.('/tools/tilesets_base.rxdata')[m.tileset_id]
built = L.('/game/Data/Tilesets.rxdata')[m.tileset_id]
puts '     ' + (x0...x0 + w).map { |x| (x % 10).to_s }.join
(y0...y0 + h).each do |y|
  puts format('%4d ', y) + (x0...x0 + w).map { |x|
    ts = (0..2).map { |z| m.data[x, y, z] }
    if ts.any? { |t| t > 0 && base.passages[t] != built.passages[t] } then 'C'
    elsif ts.any? { |t| t > 0 && base.passages[t] & 15 == 15 } then '#'
    else '.'
    end
  }.join
end
