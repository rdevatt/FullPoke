# Cross-checks warps against their return warps and proposes repairs for warps whose
# destination has no matching way back. Report-only unless APPLY=1.
#   ruby warp_pairs.rb <Data dir> [map ids to limit repairs to...]
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV.shift
only = ARGV.map(&:to_i)
infos = load_rx("#{dir}/MapInfos.rxdata")
tilesets = load_rx("#{dir}/Tilesets.rxdata")
maps = {}
infos.keys.each { |id| maps[id] = load_rx(format('%s/Map%03d.rxdata', dir, id)) }
Warp = Struct.new(:map, :ev, :page, :cmd, :x, :y, :dmap, :dx, :dy, :guarded)
warps = []
maps.each do |id, m|
  m.events.each_value do |ev|
    ev.pages.each_with_index do |pg, pi|
      depth_guard = false
      pg.list.each do |c|
        depth_guard = true if c.code == 111 && c.parameters[0] == 1   # variable-dependent exits
        next unless c.code == 201 && c.parameters[0] == 0
        p = c.parameters
        warps << Warp.new(id, ev, pi, c, ev.x, ev.y, p[1], p[2], p[3], depth_guard)
      end
    end
  end
end
def passable?(maps, tilesets, mid, x, y)
  m = maps[mid]; return false unless m && x >= 0 && y >= 0 && x < m.width && y < m.height
  ts = tilesets[m.tileset_id]
  [2, 1, 0].each do |z|
    t = m.data[x, y, z]
    next if t.nil? || t == 0
    pass = ts.passages[t]
    return false if pass & 0x0f == 0x0f
    return true if ts.priorities[t] == 0
  end
  true
end
near = ->(ax, ay, bx, by, r = 1) { (ax - bx).abs <= r && (ay - by).abs <= r }
fixes = []; ambiguous = []
warps.each do |w|
  next if w.map == w.dmap   # intra-map stairs etc.
  next if w.guarded
  next unless only.empty? || only.include?(w.map)
  # Does the destination area have a warp leading back to (near) this warp?
  back = warps.select { |r| r.map == w.dmap && near.(r.x, r.y, w.dx, w.dy, 2) && r.dmap == w.map && near.(r.dx, r.dy, w.x, w.y, 2) }
  next unless back.empty?
  dest_ok = maps[w.dmap] && w.dx < maps[w.dmap].width && w.dy < maps[w.dmap].height
  # Candidates: warps elsewhere that lead to exactly this warp's tile (or the tile in front of it).
  cands = warps.select { |r| r.dmap == w.map && r.map != w.map && near.(r.dx, r.dy, w.x, w.y, 1) }
  # Only trust candidates whose own outbound counterpart is missing (i.e. they're the orphaned way back).
  groups = cands.group_by(&:map)
  if groups.size == 1
    rs = groups.values.first.sort_by { |r| [r.x, r.y] }
    r = rs[rs.size / 2]
    # Arrive one step inside the exit: try above, then the other neighbours.
    spot = [[r.x, r.y - 1], [r.x, r.y + 1], [r.x - 1, r.y], [r.x + 1, r.y]].find { |(ax, ay)|
      passable?(maps, tilesets, r.map, ax, ay) && rs.none? { |o| o.x == ax && o.y == ay } &&
        maps[r.map].events.values.none? { |e| e.x == ax && e.y == ay } }
    spot ||= [r.x, r.y - 1]
    # Doors (events with a graphic) step the player out themselves: land on the door.
    spot = [r.x, r.y] if r.ev.pages.any? { |pg| !pg.graphic.character_name.empty? }
    fixes << [w, r.map, spot[0], spot[1], dest_ok]
  else
    ambiguous << [w, groups.keys, dest_ok]
  end
end
fmt = ->(m) { "#{m} #{infos[m]&.name.to_s.strip}" }
puts "PROPOSED FIXES"
fixes.sort_by { |w, *| [w.map, w.ev.id] }.each do |w, m, x, y, ok|
  puts "  #{fmt.(w.map)} ev#{w.ev.id} (#{w.x},#{w.y}): #{fmt.(w.dmap)} (#{w.dx},#{w.dy})#{ok ? '' : ' [OUT OF BOUNDS]'}  =>  #{fmt.(m)} (#{x},#{y})"
end
puts "NO RETURN WARP, CAN'T INFER"
ambiguous.sort_by { |w, *| [w.map, w.ev.id] }.each do |w, ms, ok|
  puts "  #{fmt.(w.map)} ev#{w.ev.id} (#{w.x},#{w.y}): #{fmt.(w.dmap)} (#{w.dx},#{w.dy})#{ok ? '' : ' [OUT OF BOUNDS]'}  candidates=#{ms.map { |m| fmt.(m) }.join(' | ')}"
end
if ENV['APPLY'] == '1'
  changed = {}
  fixes.each do |w, m, x, y, _|
    w.cmd.parameters[1] = m; w.cmd.parameters[2] = x; w.cmd.parameters[3] = y
    changed[w.map] = true
  end
  changed.keys.each { |id| File.open(format('%s/Map%03d.rxdata', dir, id), 'wb') { |f| Marshal.dump(maps[id], f) } }
  puts "APPLIED to maps #{changed.keys.sort.join(', ')}"
end
