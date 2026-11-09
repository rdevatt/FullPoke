# Lists the rooms on a composite interior map (connected areas of drawn tiles)
# with their bounding boxes and the warp events inside them.
#   tools/headless/rb.sh room_list.rb /game/Data <map id>
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir, id = ARGV
m = load_rx(format('%s/Map%03d.rxdata', dir, id.to_i))
counts = Hash.new(0)
m.height.times { |y| m.width.times { |x| counts[m.data[x, y, 0]] += 1 } }
bg = counts.max_by { |_, c| c }[0]
void = ->(x, y) { m.data[x, y, 0] == bg && m.data[x, y, 1] == 0 && m.data[x, y, 2] == 0 }
seen = {}
warps = m.events.values.select { |e| e.pages.any? { |p| p.list.any? { |c| c.code == 201 } } }
m.height.times do |y|
  m.width.times do |x|
    next if seen[[x, y]] || void.(x, y)
    st = [[x, y]]; minx = maxx = x; miny = maxy = y; n = 0
    until st.empty?
      px, py = st.pop
      next if px < 0 || py < 0 || px >= m.width || py >= m.height || seen[[px, py]] || void.(px, py)
      seen[[px, py]] = true; n += 1
      minx = [minx, px].min; maxx = [maxx, px].max; miny = [miny, py].min; maxy = [maxy, py].max
      [[1, 0], [-1, 0], [0, 1], [0, -1]].each { |dx, dy| st << [px + dx, py + dy] }
    end
    next if n < 30
    w = maxx - minx + 1; h = maxy - miny + 1
    ws = warps.select { |e| e.x >= minx - 1 && e.x <= maxx + 1 && e.y >= miny - 1 && e.y <= maxy + 1 }
    puts "room #{minx},#{miny} #{w}x#{h} tiles=#{n} warps=#{ws.map { |e| "#{e.name}@#{e.x},#{e.y}" }.join(' ')}"
  end
end
puts "background tile #{bg}"
