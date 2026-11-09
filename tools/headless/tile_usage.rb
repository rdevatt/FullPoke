# Which maps draw the given tiles of a tileset, and how many times (on any layer),
# to check whether a tile can be made solid without walling off another region.
#   tools/headless/rb.sh tile_usage.rb /game/Data <tileset> <tile ids...>
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir, ts_id, *ids = ARGV
ts_id = ts_id.to_i; ids = ids.map(&:to_i)
infos = load_rx("#{dir}/MapInfos.rxdata")
Dir.glob("#{dir}/Map[0-9][0-9][0-9].rxdata").sort.each do |f|
  id = f[/(\d+)\.rxdata/, 1].to_i
  m = load_rx(f)
  next if m.tileset_id != ts_id
  counts = Hash.new(0)
  m.width.times { |x| m.height.times { |y| 3.times { |z| t = m.data[x, y, z]; counts[t] += 1 if ids.include?(t) } } }
  next if counts.empty?
  puts format('%4d %-30s %s', id, infos[id]&.name.to_s[0, 30], counts.sort.map { |t, c| "#{t}:#{c}" }.join(' '))
end
