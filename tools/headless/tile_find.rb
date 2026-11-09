# Positions of the given tile ids on a map (any layer), e.g. to find drawn
# ladders, holes and cave mouths that have no warp event.
#   tools/headless/rb.sh tile_find.rb /game/Data <map> <tile ids...>
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir, id, *ids = ARGV
m = load_rx(format('%s/Map%03d.rxdata', dir, id.to_i))
ids.map(&:to_i).each do |t|
  at = []
  m.height.times { |y| m.width.times { |x| at << "#{x},#{y}" if (0..2).any? { |z| m.data[x, y, z] == t } } }
  puts "#{t}: #{at.join('  ')}"
end
