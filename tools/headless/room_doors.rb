# For composite interior maps: each room (connected area) with its exit warps,
# where they lead, and whether the destination map has a warp back into it.
#   tools/headless/rb.sh room_doors.rb /game/Data <map ids...>
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir, *ids = ARGV
infos = load_rx("#{dir}/MapInfos.rxdata")
@maps = {}
def map(dir, id) = (@maps[id] ||= (load_rx(format('%s/Map%03d.rxdata', dir, id)) rescue nil))
warps_of = lambda do |m|
  out = []
  m.events.each_value do |e|
    e.pages.each do |pg|
      c = pg.list.find { |cc| cc.code == 201 && cc.parameters[0] == 0 }
      (out << [e.x, e.y, c.parameters[1], c.parameters[2], c.parameters[3], e.name]; break) if c
    end
  end
  out
end
ids.map(&:to_i).each do |id|
  m = map(dir, id)
  counts = Hash.new(0)
  m.height.times { |y| m.width.times { |x| counts[m.data[x, y, 0]] += 1 } }
  bg = counts.max_by { |_, c| c }[0]
  void = ->(x, y) { m.data[x, y, 0] == bg && m.data[x, y, 1] == 0 && m.data[x, y, 2] == 0 }
  seen = {}; rooms = []
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
      rooms << [minx, miny, maxx - minx + 1, maxy - miny + 1, n] if n >= 30
    end
  end
  ws = warps_of.(m)
  puts "== #{id} #{infos[id]&.name} (#{m.width}x#{m.height}) rooms #{rooms.length}"
  rooms.each do |rx, ry, w, h, n|
    exits = ws.select { |x, y, *| x >= rx - 1 && x <= rx + w && y >= ry - 1 && y <= ry + h }
    desc = exits.map do |x, y, dm, dx, dy, nm|
      dmap = map(dir, dm)
      back = dmap && warps_of.(dmap).any? { |_, _, bm, bx, by| bm == id && bx >= rx - 1 && bx <= rx + w && by >= ry - 1 && by <= ry + h }
      "#{nm}@#{x},#{y}->#{dm}(#{infos[dm]&.name.to_s.strip[0, 18]}) #{dx},#{dy} back=#{back ? 'Y' : 'N'}"
    end
    puts "  room #{rx},#{ry} #{w}x#{h}: #{desc.empty? ? 'NO EXIT' : desc.join(' | ')}"
  end
end
