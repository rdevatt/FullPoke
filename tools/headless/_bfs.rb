# Strict bridge BFS on one map from a tile (SURF=1: water too), with switches
require_relative '/tools/rpg_classes'
require_relative '/tools/bridge_lib'
ts_all = File.open('/game/Data/Tilesets.rxdata','rb'){|f| Marshal.load(f)}
id, sx, sy, sl = ARGV[0].split(',').map(&:to_i)
m = File.open(format('/game/Data/Map%03d.rxdata', id),'rb'){|f| Marshal.load(f)}
ts = ts_all[m.tileset_id]
sw = BridgeLib.switches(m)
ok = lambda do |x, y, lv|
  return false if x < 0 || y < 0 || x >= m.width || y >= m.height
  [2, 1, 0].each do |z|
    t = m.data[x, y, z]; next if t.nil? || t == 0
    tag = ts.terrain_tags[t]
    if tag == 15 then next if lv == 0; return ts.passages[t] & 0x0f != 0x0f end
    return ENV['SURF'] == '1' if [5, 6, 7, 16].include?(tag)
    return false if ts.passages[t] & 0x0f == 0x0f
    return true if ts.priorities[t] == 0
  end
  true
end
seen = {}; q = [[sx, sy, sl]]; seen[[sx, sy, sl]] = true
until q.empty?
  x, y, lv = q.shift
  { 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0], 8 => [0, -1] }.each do |d, (dx, dy)|
    nx, ny = x + dx, y + dy
    next if BridgeLib.side_ok(ts, m, x, y, d, lv) == false || BridgeLib.side_ok(ts, m, nx, ny, 10 - d, lv) == false
    next if !ok.(nx, ny, lv)
    st = [nx, ny, BridgeLib.level_after(ts, m, sw, nx, ny, lv)]
    next if seen[st]
    seen[st] = true; q << st
  end
end
x0, x1, y0, y1 = ARGV[1].split(',').map(&:to_i)
(y0..y1).each do |y|
  puts format('%3d ', y) + (x0..x1).map { |x| a = seen[[x, y, 0]]; b = seen[[x, y, 1]]; sw[[x, y]] ? (sw[[x, y]] == 1 ? 'N' : 'F') : a && b ? 'X' : a ? 'o' : b ? 'b' : BridgeLib.tile(ts, m, x, y) ? 'B' : (ok.(x, y, 0)) ? '.' : '#' }.join
end
