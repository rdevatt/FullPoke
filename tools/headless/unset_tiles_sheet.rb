# Draws the most-used layer-1/2 tiles of some maps that have no passability set
# (blocking 0, priority 0, terrain 0) on a numbered sheet, to decide by eye
# which are trees/rocks. Prints "index: tile id (uses)".
#   docker run ... fullpoke-ruby ruby unset_tiles_sheet.rb /game <Tilesets.rxdata> <out.png> <maps...>
require 'chunky_png'
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
game, tsfile, out, *ids = ARGV
tilesets = load_rx(tsfile)
counts = Hash.new(0)
ts = nil
ids.each do |id|
  m = load_rx(format('%s/Data/Map%03d.rxdata', game, id.to_i))
  ts = tilesets[m.tileset_id]
  m.height.times do |y|
    m.width.times do |x|
      [1, 2].each do |z|
        t = m.data[x, y, z]
        next if t < 384 || ts.passages[t] != 0 || ts.priorities[t] != 0 || ts.terrain_tags[t] != 0
        counts[t] += 1
      end
    end
  end
end
img = ChunkyPNG::Image.from_file(Dir.glob("#{game}/Graphics/Tilesets/*").find { |f| File.basename(f, '.*') == ts.tileset_name })
list = counts.sort_by { |_, c| -c }.first(64)
sheet = ChunkyPNG::Image.new(8 * 36, 8 * 36, ChunkyPNG::Color::WHITE)
list.each_with_index do |(t, c), i|
  sx = ((t - 384) % 8) * 32; sy = ((t - 384) / 8) * 32
  32.times { |dy| 32.times { |dx| sheet[(i % 8) * 36 + dx, (i / 8) * 36 + dy] = img[sx + dx, sy + dy] } }
  puts "#{i}: #{t} (#{c})"
end
sheet.save(out)
