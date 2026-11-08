# Finds the room around a point on a composite interior map (the map pack keeps many
# rooms on one big map, separated by empty tiles) and lists its bounds and events.
#   tools/headless/rb.sh room_at.rb /game/Data <map> <x> <y>
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
def room_bounds(m, sx, sy)
  filled = ->(x, y) { x >= 0 && y >= 0 && x < m.width && y < m.height && (0..2).any? { |z| m.data[x, y, z].to_i > 0 } }
  seen = {}; stack = [[sx, sy]]; minx = maxx = sx; miny = maxy = sy
  until stack.empty?
    x, y = stack.pop
    next if seen[[x, y]] || !filled.(x, y)
    seen[[x, y]] = true
    minx = [minx, x].min; maxx = [maxx, x].max; miny = [miny, y].min; maxy = [maxy, y].max
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each { |dx, dy| stack << [x + dx, y + dy] }
  end
  [minx, miny, maxx - minx + 1, maxy - miny + 1]
end
if $0 == __FILE__
  dir, id, x, y = ARGV
  m = load_rx(format('%s/Map%03d.rxdata', dir, id.to_i))
  b = room_bounds(m, x.to_i, y.to_i)
  puts "room #{b.inspect} (x,y,w,h) tileset #{m.tileset_id}"
  m.events.each_value do |ev|
    next unless ev.x >= b[0] && ev.y >= b[1] && ev.x < b[0] + b[2] && ev.y < b[1] + b[3]
    codes = ev.pages.map { |pg| pg.list.map(&:code).uniq.join(',') }
    puts "  ev#{ev.id} '#{ev.name}' (#{ev.x},#{ev.y}) gfx=#{ev.pages[0].graphic.character_name} pages=#{ev.pages.size} codes=#{codes.inspect[0, 120]}"
  end
end
