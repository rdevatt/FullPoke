# Tile inspection for a map: terrain-tag counts of its tileset, its commonest
# tiles, and (with x,y pairs) the tiles at those spots.
#   tools/headless/rb.sh ts_probe.rb <map> [x,y ...]
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
map_id = ARGV[0].to_i
m = load_rx(format('/game/Data/Map%03d.rxdata', map_id))
ts = load_rx('/game/Data/Tilesets.rxdata')[m.tileset_id]
h = Hash.new(0); (0...ts.terrain_tags.xsize).each { |t| h[ts.terrain_tags[t]] += 1 }
puts "tileset #{m.tileset_id} terrain tags: #{h.inspect}"
desc = ->(t) { "#{t}(tag#{ts.terrain_tags[t]},pass#{ts.passages[t]},prio#{ts.priorities[t]})" }
if ARGV.length > 1
  ARGV[1..].each do |xy|
    x, y = xy.split(',').map(&:to_i)
    puts "#{x},#{y}: " + (0..2).map { |z| desc.(m.data[x, y, z]) }.join(' | ')
  end
else
  c = Hash.new(0); m.height.times { |y| m.width.times { |x| [0, 1, 2].each { |z| c[[z, m.data[x, y, z]]] += 1 } } }
  puts c.sort_by { |_, v| -v }.first(14).map { |(z, t), v| "L#{z}:#{desc.(t)}x#{v}" }.join(' ')
end
