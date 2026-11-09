# The tile ids of a rectangle of a map, layer by layer.
#   tools/headless/rb.sh ts_rect.rb <map> x y w h
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
mid, x0, y0, w, h = ARGV.map(&:to_i)
m = load_rx(format('/game/Data/Map%03d.rxdata', mid))
(0..2).each do |z|
  puts "layer #{z}"
  (y0...y0 + h).each { |y| puts format('%3d ', y) + (x0...x0 + w).map { |x| format('%5d', m.data[x, y, z]) }.join }
end
