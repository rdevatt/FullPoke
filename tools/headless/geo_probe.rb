# Prints the automatic map-connection offsets for a region's geo spec.
#   tools/headless/rb.sh geo_probe.rb johto
require_relative 'rpg_classes'
def load_data(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
Dir.chdir('/game')
TILESETS = load_data('Data/Tilesets.rxdata')
def passable_tile?(map, x, y)
  return false if x < 0 || y < 0 || x >= map.width || y >= map.height
  ts = TILESETS[map.tileset_id]
  [2, 1, 0].each do |z|
    t = map.data[x, y, z]
    next if t.nil? || t == 0
    return false if ts.passages[t] & 0x0f == 0x0f
    return false if ts.terrain_tags[t] == 5 || ts.terrain_tags[t] == 7
    return true if ts.priorities[t] == 0
  end
  map.data[x, y, 0].to_i > 0
end
require_relative 'geo_lib'
require_relative "geo/#{ARGV[0]}"
spec = GEO_SPEC[ARGV[0].to_sym]
spec[:links].each do |a, side, b|
  ma = load_data(format('Data/Map%03d.rxdata', spec[:maps][a])); mb = load_data(format('Data/Map%03d.rxdata', spec[:maps][b]))
  d, match, oa, ob = Geo.best_offset(ma, side, mb)
  flag = (match == 0 ? '  <-- NO MATCH' : (match < [oa, ob].min ? '  <-- partial' : ''))
  puts "#{a}(#{ma.width}x#{ma.height}) #{side} #{b}(#{mb.width}x#{mb.height}): offset #{d}, matched #{match} (open #{oa}/#{ob})#{flag}"
end

puts
spec[:links].each do |a, side, b|
  ma = load_data(format('Data/Map%03d.rxdata', spec[:maps][a])); mb = load_data(format('Data/Map%03d.rxdata', spec[:maps][b]))
  d, match, oa, ob = Geo.best_offset(ma, side, mb)
  next if match >= 3
  ga = Geo.edge_gate(ma, side); gb = Geo.edge_gate(mb, Geo::OPPOSITE[side])
  puts "gate #{a} #{side}: #{ga.inspect}   #{b} #{Geo::OPPOSITE[side]}: #{gb.inspect}"
end
exit if ENV['NOEDGES']
puts
spec[:maps].each do |k, id|
  m = load_data(format('Data/Map%03d.rxdata', id))
  puts "#{k}(#{id} #{m.width}x#{m.height} t#{m.tileset_id}): " + %w[North South West East].map { |sd| "#{sd[0]}[#{Geo.ranges(Geo.edge_open(m, sd))}]" }.join(' ')
end
