# Lists the openings on each edge of outdoor maps (runs of walkable or surfable
# tiles along the border), to line up map connections.
#   tools/headless/rb.sh edges.rb /game/Data 34 35 173 ...
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV.shift
TS = load_rx("#{dir}/Tilesets.rxdata")
INFOS = load_rx("#{dir}/MapInfos.rxdata")

# :land, :water or nil (blocked)
def kind(m, x, y)
  ts = TS[m.tileset_id]
  [2, 1, 0].each do |z|
    t = m.data[x, y, z]
    next if t.nil? || t == 0
    tag = ts.terrain_tags[t]
    return :water if [5, 6, 7, 16].include?(tag)   # surfable (blocked on foot)
    return nil if ts.passages[t] & 0x0f == 0x0f
    return :land if ts.priorities[t] == 0
  end
  (0..2).any? { |z| m.data[x, y, z].to_i > 0 } ? :land : nil
end

def runs(cells)
  out = []
  cells.each_with_index do |k, i|
    next if k.nil?
    if out.last && out.last[2] == k && out.last[1] == i - 1
      out.last[1] = i
    else
      out << [i, i, k]
    end
  end
  out.map { |a, b, k| "#{a}-#{b}#{k == :water ? 'w' : ''}" }.join(' ')
end

ARGV.map(&:to_i).each do |id|
  m = load_rx(format('%s/Map%03d.rxdata', dir, id))
  w, h = m.width, m.height
  puts "#{id} #{INFOS[id]&.name} (#{w}x#{h})"
  puts "  N: #{runs((0...w).map { |x| kind(m, x, 0) })}"
  puts "  S: #{runs((0...w).map { |x| kind(m, x, h - 1) })}"
  puts "  W: #{runs((0...h).map { |y| kind(m, 0, y) })}"
  puts "  E: #{runs((0...h).map { |y| kind(m, w - 1, y) })}"
end
