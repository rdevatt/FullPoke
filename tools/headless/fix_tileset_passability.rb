# Fills in a tileset's missing passability, priority and terrain tags by matching
# each of its tiles pixel-for-pixel against tilesets that do have that data.
# The map pack's "Ouside Caves" tileset (26: Mt. Moon, Rock Tunnel, Victory
# Road, Route 23, Indigo Plateau...) shipped with every tile walkable.
#   FULLPOKE_RUBY_IMAGE=fullpoke-ruby tools/headless/rb.sh fix_tileset_passability.rb /game 26 1 6 27 28 23 2 3
#   APPLY=1 ... to write Data/Tilesets.rxdata (otherwise report only)
# Unmatched tiles are listed (ids) and left as they are, except fully transparent
# tiles, which are passable. Autotile data is set from the autotile names.
#
# --unblock-only: for a tileset whose data is mostly right (2, the interiors),
# only clear tiles marked solid that every matching source says are walkable
# (the Pokémon Tower, S.S. Anne and Silph Co. floors were solid).
require 'chunky_png'
require 'digest'
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
unblock_only = !ARGV.delete('--unblock-only').nil?
game, target, *sources = ARGV
target = target.to_i
path = "#{game}/Data/Tilesets.rxdata"
tilesets = load_rx(path)

def find_img(dir, name)
  Dir.glob("#{dir}/*").find { |f| File.basename(f, '.*').casecmp?(name) && f =~ /\.png$/i }
end

def tile_hashes(game, ts)
  img = ChunkyPNG::Image.from_file(find_img("#{game}/Graphics/Tilesets", ts.tileset_name))
  rows = img.height / 32
  out = {}
  (0...rows * 8).each do |i|
    x0 = (i % 8) * 32; y0 = (i / 8) * 32
    px = []
    32.times { |dy| px.concat(img.row(y0 + dy)[x0, 32]) }
    # fully transparent pixels compare equal whatever their colour bits
    px.map! { |c| ChunkyPNG::Color.a(c) == 0 ? 0 : c }
    out[384 + i] = px.all?(&:zero?) ? :empty : Digest::MD5.hexdigest(px.pack('N*'))
  end
  out
end

votes = Hash.new { |h, k| h[k] = Hash.new(0) }
by_index = {}   # source tileset id => {tile id => hash}
sources.map(&:to_i).each do |sid|
  ts = tilesets[sid]
  by_index[sid] = tile_hashes(game, ts)
  by_index[sid].each do |t, h|
    next if h == :empty || t >= ts.passages.xsize
    votes[h][[ts.passages[t], ts.priorities[t], ts.terrain_tags[t]]] += 1
  end
end

ts = tilesets[target]
mine = tile_hashes(game, ts)
matched = 0; empty = 0; aligned = 0; unmatched = []; conflicts = []
# Tiles used on maps that have no twin elsewhere, classified by eye from contact
# sheets. Tiles that only ever appear on the top layer are overhead decoration.
MANUAL = {
  # Silph Co. and Rocket Hideout floors (2)
  2 => { blocked: [], passable: [2078, 2079, 2216, 2217, 2224, 2232, 2233, 2254] },
  26 => {
    blocked: [700, 701, 702, 703, 704, 705, 708, 709, 710, 711, 717, 718, 719, 721, 722, 725, 726, 727, 729,
              730, 733, 734, 735, 737, 738, 1556, 7418, 7419, 7424, 7426, 7432, 7434, 7440, 7447, 7448, 7450,
              7455, 7458, 7459, 7466, 7470, 7493, 7495, 7574, 7664, 7666, 7672, 7674, 7680, 7682, 8042, 8044,
              8058, 8067, 8135, 8151, 8159, 8164, 8165, 8166, 8321],
    passable: [743, 1638, 1639, 1646, 1647, 2623, 2631, 2639, 2643, 2644, 2645, 2651, 2652, 2656, 2657, 2658,
               2688, 2689, 2690, 2691, 2693, 2694, 4622, 4623, 4630, 4631, 4638, 4639, 4645, 4646, 4653, 4671,
               4745, 7430, 7438, 7469, 8016, 8041, 8049, 8052, 8168, 8169, 8170, 8347, 8348, 8349, 8355, 8357,
               8363, 8364, 8365]
  }
}
if unblock_only
  fixed = []
  mine.each do |t, h|
    next if t >= ts.passages.xsize || h == :empty || !votes.key?(h)
    next if ts.passages[t] & 0x0f != 0x0f
    verdicts = votes[h].keys
    next if verdicts.any? { |p, _, _| p & 0x0f == 0x0f }
    pass, prio, tag = votes[h].max_by { |_, n| n }[0]
    ts.passages[t] = pass; ts.priorities[t] = prio; ts.terrain_tags[t] = tag
    fixed << t
  end
  (MANUAL.dig(target, :passable) || []).each { |t| ts.passages[t] = 0; ts.priorities[t] = 0; ts.terrain_tags[t] = 0 }
  puts "tileset #{target} #{ts.name} (#{ts.tileset_name}): #{fixed.size} solid tiles made walkable"
  File.write(File.join(__dir__, "unblocked_tiles_#{target}.txt"), fixed.join("\n")) if ENV['APPLY'] != '1'
  File.open(path, 'wb') { |f| Marshal.dump(tilesets, f) } if ENV['APPLY'] == '1'
  exit
end
mine.each do |t, h|
  next if t >= ts.passages.xsize
  # A source whose graphic has the same tile at the same index is the one this
  # tileset was copied from: take its data as is.
  src = sources.map(&:to_i).find { |sid| by_index[sid][t] == h && t < tilesets[sid].passages.xsize }
  if src && h != :empty
    s = tilesets[src]
    ts.passages[t] = s.passages[t]; ts.priorities[t] = s.priorities[t]; ts.terrain_tags[t] = s.terrain_tags[t]
    aligned += 1
  elsif h == :empty
    ts.passages[t] = 0; ts.priorities[t] = 0; ts.terrain_tags[t] = 0
    empty += 1
  elsif votes.key?(h)
    pass, prio, tag = votes[h].max_by { |_, n| n }[0]
    conflicts << [t, votes[h]] if votes[h].keys.map { |p, _, _| p & 0x0f == 0x0f }.uniq.size > 1
    ts.passages[t] = pass; ts.priorities[t] = prio; ts.terrain_tags[t] = tag
    matched += 1
  else
    unmatched << t
  end
end

if (man = MANUAL[target])
  man[:blocked].each { |t| ts.passages[t] = 15; ts.priorities[t] = 0; ts.terrain_tags[t] = 0 }
  man[:passable].each { |t| ts.passages[t] = 0; ts.priorities[t] = 0; ts.terrain_tags[t] = 0 }
  unmatched -= man[:blocked] + man[:passable]
end
# Remaining unmatched tiles: overhead (passable, drawn above the player)
unmatched.each { |t| ts.passages[t] = 0; ts.priorities[t] = 1; ts.terrain_tags[t] = 0 }

# Autotiles (ids 48..383, 48 per autotile) by name
AUTO = {   # name => [passage, terrain tag]
  /^sea deep/i => [15, 5], /^sea/i => [15, 7], /^still water/i => [15, 6], /^shallow water/i => [0, 16],
  /^water rock/i => [15, 0], /^sand shore/i => [0, 3], /^flowers/i => [0, 0], /^lava/i => [15, 0],
  /^waterfall crest/i => [15, 9], /^waterfall bottom/i => [15, 7], /^waterfall/i => [15, 8], /^black/i => [15, 0]
}
ts.autotile_names.each_with_index do |name, a|
  next if name.nil? || name.empty?
  rule = AUTO.find { |re, _| name =~ re }
  next if !rule
  ((a + 1) * 48...(a + 2) * 48).each { |t| ts.passages[t] = rule[1][0]; ts.priorities[t] = 0; ts.terrain_tags[t] = rule[1][1] }
end

total = mine.size
puts "tileset #{target} #{ts.name} (#{ts.tileset_name}): #{total} tiles, #{aligned} same-index copies, #{matched} matched elsewhere, #{empty} empty, #{unmatched.size} unmatched"
File.write(File.join(__dir__, "unmatched_tiles_#{target}.txt"), unmatched.join("\n")) if ENV['APPLY'] != '1'
File.write(File.join(__dir__, "conflict_tiles_#{target}.txt"), conflicts.map { |t, v| "#{t} #{v.map { |k, n| "#{k.join('/')}x#{n}" }.join(' ')}" }.join("\n")) if ENV['APPLY'] != '1'
if ENV['APPLY'] == '1'
  File.open(path, 'wb') { |f| Marshal.dump(tilesets, f) }
  puts "written #{path}"
end
