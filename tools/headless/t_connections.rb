# Checks map connections geometrically: dead connections (the two edges never touch)
# and maps that overlap each other along the same edge.
GameData.load_all
infos = pbLoadMapInfos
size = {}
infos.keys.each { |id| m = load_data(sprintf("Data/Map%03d.rxdata", id)); size[id] = [m.width, m.height] }
conns = load_data("Data/map_connections.dat")
puts "connections: #{conns.size}"
# Normalise each connection into: map A, map B, B's top-left position in A's coordinates.
placed = Hash.new { |h, k| h[k] = [] }
dead = []
empty = []
conns.each do |c|
  a, ea, oa, b, eb, ob = c
  next unless size[a] && size[b]
  aw, ah = size[a]; bw, bh = size[b]
  empty << c if [a, b].any? { |m| load_data(sprintf("Data/Map%03d.rxdata", m)).data.raw.all?(&:zero?) }
  e = ea.to_s.upcase[0]
  case e
  when "N" then bx = oa - ob; by = -bh
  when "S" then bx = oa - ob; by = ah
  when "W" then bx = -bw; by = oa - ob
  when "E" then bx = aw;  by = oa - ob
  else next
  end
  horizontal = %w[N S].include?(e)
  touch = horizontal ? [bx, 0].max < [bx + bw, aw].min : [by, 0].max < [by + bh, ah].min
  dead << c unless touch
  placed[a] << [b, bx, by, bw, bh]
  placed[b] << [a, -bx, -by, aw, ah]
end
overlaps = []
placed.each do |a, list|
  list.combination(2).each do |(b1, x1, y1, w1, h1), (b2, x2, y2, w2, h2)|
    next if b1 == b2
    ox = [x1 + w1, x2 + w2].min - [x1, x2].max
    oy = [y1 + h1, y2 + h2].min - [y1, y2].max
    overlaps << [a, b1, b2, ox, oy] if ox > 0 && oy > 0
  end
end
name = ->(m) { "#{m} #{infos[m].name.strip}" }
puts "dead (edges don't touch): #{dead.size}"
dead.first(15).each { |c| puts "  #{name.(c[0])} #{c[1]} #{c[2]} <-> #{name.(c[3])} #{c[4]} #{c[5]}" }
puts "connections touching an empty (no tiles) map: #{empty.size}"
empty.first(10).each { |c| puts "  #{name.(c[0])} <-> #{name.(c[3])}" }
puts "overlapping neighbours: #{overlaps.size}"
overlaps.uniq { |a, b1, b2| [a, [b1, b2].sort] }.first(25).each { |a, b1, b2, ox, oy| puts "  around #{name.(a)}: #{name.(b1)} overlaps #{name.(b2)} (#{ox}x#{oy} tiles)" }
