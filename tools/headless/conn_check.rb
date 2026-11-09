# Checks PBS/map_connections.txt lines between the given maps: how many tiles
# line up across each seam (land-land / water-water), so wrong offsets show up.
#   tools/headless/rb.sh conn_check.rb /game 23 34 173 ...   (no ids: every line)
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
game = ARGV.shift
ids = ARGV.map(&:to_i)
TS = load_rx("#{game}/Data/Tilesets.rxdata")
INFOS = load_rx("#{game}/Data/MapInfos.rxdata")
@maps = {}
def map(id) = (@maps[id] ||= (load_rx(format('%s/Data/Map%03d.rxdata', ARGV[0] || '', id)) rescue nil))
def rx(game, id) = (@maps[id] ||= (load_rx(format('%s/Data/Map%03d.rxdata', game, id)) rescue nil))

def kind(m, x, y)
  return nil if x < 0 || y < 0 || x >= m.width || y >= m.height
  ts = TS[m.tileset_id]
  [2, 1, 0].each do |z|
    t = m.data[x, y, z]
    next if t.nil? || t == 0
    tag = ts.terrain_tags[t]
    return :water if [5, 6, 7, 16].include?(tag)
    return nil if ts.passages[t] & 0x0f == 0x0f
    return :land if ts.priorities[t] == 0
  end
  (0..2).any? { |z| m.data[x, y, z].to_i > 0 } ? :land : nil
end

# tiles along A's edge and the B tile next to each
def seam(a, b, edge, pa, pb)
  out = []
  case edge
  when 'North', 'South'
    ya = edge == 'North' ? 0 : a.height - 1
    yb = edge == 'North' ? b.height - 1 : 0
    (0...a.width).each { |x| out << [kind(a, x, ya), kind(b, x - pa + pb, yb)] }
  else
    xa = edge == 'West' ? 0 : a.width - 1
    xb = edge == 'West' ? b.width - 1 : 0
    (0...a.height).each { |y| out << [kind(a, xa, y), kind(b, xb, y - pa + pb)] }
  end
  out
end

File.foreach("#{game}/PBS/map_connections.txt").with_index(1) do |line, ln|
  next if line.start_with?('#') || line.strip.empty?
  f = line.strip.split(',')
  next if f.length < 6
  m1, e1, p1, m2, e2, p2 = f[0].to_i, f[1], f[2].to_i, f[3].to_i, f[4], f[5].to_i
  next if !ids.empty? && !(ids.include?(m1) || ids.include?(m2))
  a = rx(game, m1); b = rx(game, m2)
  if !a || !b
    puts "#{ln}: #{line.strip}  -> missing map"
    next
  end
  e1 = { 'N' => 'North', 'S' => 'South', 'E' => 'East', 'W' => 'West' }[e1] || e1
  s = seam(a, b, e1, p1, p2)
  land = s.count { |x, y| x == :land && y == :land }
  water = s.count { |x, y| x == :water && y == :water }
  dead = s.count { |x, y| x && !y }
  puts format('%4d: %-24s %s(%s) %s -> %s(%s)  land %d water %d dead-ends %d', ln, line.strip, m1, INFOS[m1]&.name, e1, m2, INFOS[m2]&.name, land, water, dead)
end
