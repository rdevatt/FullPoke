# Finds tiles that a tileset left unset (no blocking, priority or terrain tag)
# but that another tileset draws with the very same pixels and does set up, and
# prints their settings as JSON for geo/tileset_inherit.json. Used where the map
# pack's tilesets are versions of one image (Outside2WATERSEA = OutsideWorld2.6
# vs Kanto's OutsideWorld2.7).
#   docker run ... fullpoke-ruby ruby tileset_inherit.rb /game <tileset> <from tileset>
# geo/tileset_inherit.json also has hand-written "overrides" per tileset (tiles
# whose pack settings are wrong, e.g. Route 119's bridge edges): keep them when
# regenerating.
require 'chunky_png'
require 'json'
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
game, ts_id, from_id = ARGV[0], ARGV[1].to_i, ARGV[2].to_i
all = load_rx("#{game}/Data/Tilesets.rxdata")
ts = all[ts_id]; src = all[from_id]
img = ->(t) { ChunkyPNG::Image.from_file(Dir.glob("#{game}/Graphics/Tilesets/*").find { |f| File.basename(f, '.*') == t.tileset_name }) }
a = img.(ts); b = img.(src)
rows = [a.height, b.height].min / 32
out = {}
# Mostly-blue opaque tiles are water to surf on, whatever the other tileset says
# (Kanto uses some of them as solid scenery; Hoenn's rivers are drawn with them).
def water_colour?(img, x0, y0)
  n = 0; blue = 0
  (0...32).step(2) do |y|
    (0...32).step(2) do |x|
      c = img[x0 + x, y0 + y]
      next if ChunkyPNG::Color.a(c) < 200
      n += 1
      r, g, b = ChunkyPNG::Color.r(c), ChunkyPNG::Color.g(c), ChunkyPNG::Color.b(c)
      blue += 1 if b > r + 50 && b > g + 10
    end
  end
  n > 200 && blue > n * 0.55
end

(0...rows * 8).each do |i|
  t = 384 + i
  next if ts.passages[t] != 0 || ts.priorities[t] != 0 || ts.terrain_tags[t] != 0
  x0 = (i % 8) * 32; y0 = (i / 8) * 32
  if water_colour?(a, x0, y0)
    out[t] = [0, 0, 7]
    next
  end
  next if src.passages[t] == 0 && src.priorities[t] == 0 && src.terrain_tags[t] == 0
  same = (0...32).all? { |y| (0...32).all? { |x| a[x0 + x, y0 + y] == b[x0 + x, y0 + y] } }
  next if !same
  out[t] = [src.passages[t], src.priorities[t], src.terrain_tags[t]]
end
STDERR.puts "#{out.length} tiles of tileset #{ts_id} take their settings from tileset #{from_id}"
puts JSON.generate({ ts_id.to_s => { 'from' => from_id, 'tiles' => out } })
