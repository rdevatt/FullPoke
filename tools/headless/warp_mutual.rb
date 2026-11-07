# Second pass for warps that have no working way back: pairs two broken warps when
# each one's destination coordinates sit next to the other's location (so only the
# map IDs were wrong), and the match is unique. Report-only unless APPLY=1.
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV[0]
infos = load_rx("#{dir}/MapInfos.rxdata")
maps = {}
infos.keys.each { |id| maps[id] = load_rx(format('%s/Map%03d.rxdata', dir, id)) }
Warp = Struct.new(:map, :ev, :cmd, :x, :y, :dmap, :dx, :dy)
warps = []
maps.each do |id, m|
  m.events.each_value do |ev|
    ev.pages.each do |pg|
      guarded = pg.list.any? { |c| c.code == 111 && c.parameters[0] == 1 }
      next if guarded
      pg.list.each do |c|
        next unless c.code == 201 && c.parameters[0] == 0
        p = c.parameters
        warps << Warp.new(id, ev, c, ev.x, ev.y, p[1], p[2], p[3])
      end
    end
  end
end
near = ->(ax, ay, bx, by) { (ax - bx).abs <= 1 && (ay - by).abs <= 1 }
paired = ->(w) { warps.any? { |r| r.map == w.dmap && near.(r.x, r.y, w.dx, w.dy) && r.dmap == w.map && near.(r.dx, r.dy, w.x, w.y) } }
broken = warps.reject { |w| w.map == w.dmap || paired.(w) }
fixes = {}
broken.each do |w1|
  cands = broken.select do |w2|
    next false if w2.map == w1.map
    near.(w1.dx, w1.dy, w2.x, w2.y) && near.(w2.dx, w2.dy, w1.x, w1.y) &&
      w1.dx < maps[w2.map].width && w1.dy < maps[w2.map].height &&
      w2.dx < maps[w1.map].width && w2.dy < maps[w1.map].height
  end
  next unless cands.map(&:map).uniq.size == 1
  w2 = cands.first
  fixes[w1] = w2.map if w1.dmap != w2.map
end
fixes.each do |w, m|
  puts "#{w.map} #{infos[w.map].name.strip} ev#{w.ev.id} (#{w.x},#{w.y}): map #{w.dmap} #{infos[w.dmap]&.name.to_s.strip} -> #{m} #{infos[m].name.strip} (#{w.dx},#{w.dy})"
end
if ENV['APPLY'] == '1'
  changed = {}
  fixes.each { |w, m| w.cmd.parameters[1] = m; changed[w.map] = true }
  changed.each_key { |id| File.open(format('%s/Map%03d.rxdata', dir, id), 'wb') { |f| Marshal.dump(maps[id], f) } }
  puts "APPLIED to maps #{changed.keys.sort.join(', ')}"
end
