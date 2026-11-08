require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
infos = load_rx('/game/Data/MapInfos.rxdata')
KNOWN = { 1 => { pc: [778], mart: [738], gym: [743, 1685] }, 23 => { pc: [3026, 5474], mart: [3061], gym: [3219] } }
HOUSE = { 1 => [1404,1812,1468,1609,1610,1297,1001,1444,1702,1732,1825,1890,1906,1909,1921,2273,2315,2363,4385,5562,1102,1118,1165,645],
          23 => [9574,6410,6033,6267,6268,7393,5641,9185,7941,3931] }
ARGV.map(&:to_i).each do |mid|
  m = load_rx(format('/game/Data/Map%03d.rxdata', mid))
  k = KNOWN[m.tileset_id]
  unless k then puts "#{mid} #{infos[mid].name}: ts#{m.tileset_id} unknown"; next end
  found = Hash.new { |h, x| h[x] = [] }
  (0...m.height).each do |y|
    (0...m.width).each do |x|
      (1..2).each do |z|
        t = m.data[x, y, z]
        k.each { |kind, ids| found[kind] << [x, y] if ids.include?(t) }
        found[:house] << [x, y] if HOUSE[m.tileset_id].include?(t)
      end
    end
  end
  puts "#{mid} #{infos[mid].name} (#{m.width}x#{m.height} ts#{m.tileset_id}): " + found.map { |kk, v| "#{kk}=#{v.uniq.first(6).inspect}#{v.uniq.size > 6 ? '…' : ''}" }.join(' ')
end
