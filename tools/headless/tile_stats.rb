# Lists tile usage on a map: per layer, each tile id with count, terrain tag and
# passability (from the map's tileset), to find the ids for grass, trees, paths…
#   tools/headless/rb.sh tile_stats.rb /game/Data <map> [x y w h [layer to print as a grid]]
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir, id, x0, y0, w, h, grid = ARGV
m = load_rx(format('%s/Map%03d.rxdata', dir, id.to_i))
ts = load_rx("#{dir}/Tilesets.rxdata")[m.tileset_id]
x0 = (x0 || 0).to_i; y0 = (y0 || 0).to_i; w = (w || m.width).to_i; h = (h || m.height).to_i
puts "tileset #{m.tileset_id} #{ts.name} autotiles=#{ts.autotile_names.inspect}"
3.times do |z|
  counts = Hash.new(0)
  (y0...y0 + h).each { |y| (x0...x0 + w).each { |x| counts[m.data[x, y, z]] += 1 } }
  puts "layer #{z}: " + counts.sort_by { |_, c| -c }.first(40).map { |t, c| "#{t}(#{c},tt#{ts.terrain_tags[t]},p#{ts.passages[t]},pr#{ts.priorities[t]})" }.join(' ')
end
if grid
  z = grid.to_i
  (y0...y0 + h).each { |y| puts (x0...x0 + w).map { |x| format('%4d', m.data[x, y, z]) }.join }
end
