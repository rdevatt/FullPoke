# Prints the map tree (MapInfos) with size, tileset, event count and how much of the
# map has tiles, so empty placeholders and unfinished maps are easy to spot.
#   tools/headless/rb.sh map_tree.rb /game/Data [--tsv]
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV.shift
tsv = ARGV.include?('--tsv')
infos = load_rx("#{dir}/MapInfos.rxdata")
enc_maps = {}
pbs = File.join(dir, '..', 'PBS', 'encounters.txt')
File.foreach(pbs) { |l| enc_maps[$1.to_i] = true if l =~ /^\[(\d+)/ } if File.exist?(pbs)
children = Hash.new { |h, k| h[k] = [] }
infos.each { |id, info| children[info.parent_id] << id }
children.each_value { |a| a.sort_by! { |id| infos[id].order } }
stat = lambda do |id|
  path = format('%s/Map%03d.rxdata', dir, id)
  return nil unless File.exist?(path)
  m = load_rx(path)
  w, h = m.width, m.height
  filled = 0
  (0...h).each { |y| (0...w).each { |x| filled += 1 if (0..2).any? { |z| m.data[x, y, z].to_i > 0 } } }
  warps = m.events.values.count { |e| e.pages.any? { |p| p.list.any? { |c| c.code == 201 } } }
  [w, h, m.tileset_id, m.events.size, (100.0 * filled / (w * h)).round, warps]
end
walk = lambda do |pid, depth|
  children[pid].each do |id|
    s = stat.call(id) || []
    if tsv
      puts [id, infos[id].parent_id, depth, infos[id].name, *s, enc_maps[id] ? 1 : 0].join("\t")
    else
      puts format('%s%3d %-34s %3sx%-3s ts%-3s ev%-3s fill%3s%% warps%-3s%s', '  ' * depth, id, infos[id].name, *s.map(&:to_s), enc_maps[id] ? ' ENC' : '')
    end
    walk.call(id, depth + 1)
  end
end
walk.call(0, 0)
