# Where a range of tile ids is drawn on some maps (to find stairs, ledges...).
#   tools/headless/rb.sh ts_scan.rb <first tile> <last tile> <map> [map ...]
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
lo, hi, *maps = ARGV.map(&:to_i)
tss = load_rx('/game/Data/Tilesets.rxdata')
maps.each do |mid|
  m = load_rx(format('/game/Data/Map%03d.rxdata', mid))
  ts = tss[m.tileset_id]
  found = Hash.new { |h, k| h[k] = [] }
  m.height.times { |y| m.width.times { |x| (0..2).each { |z| t = m.data[x, y, z]; found[t] << [x, y] if t.between?(lo, hi) } } }
  found.sort.each { |t, xy| puts "map #{mid} tile #{t} pass#{ts.passages[t]} tag#{ts.terrain_tags[t]}: #{xy.length}x #{xy.first(6).map { |a| a.join(',') }.join(' ')}" }
end
