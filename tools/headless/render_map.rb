# Renders an RMXP map to PNG (tile layers + event markers) for inspection.
#   ruby render_map.rb <game_dir> <map_id> <out.png> [x0 y0 w h] [scale]
require 'chunky_png'
require_relative 'rpg_classes'
game, id, out, x0, y0, w, h, scale = ARGV
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
map = load_rx(format('%s/Data/Map%03d.rxdata', game, id.to_i))
ts = load_rx("#{game}/Data/Tilesets.rxdata")[map.tileset_id]
x0 = (x0 || 0).to_i; y0 = (y0 || 0).to_i
w = (w || map.width).to_i; h = (h || map.height).to_i
w = [w, map.width - x0].min; h = [h, map.height - y0].min
TS = (scale || 16).to_i   # output pixels per tile
def find_img(dir, name)
  return nil if name.nil? || name.empty?
  Dir.glob("#{dir}/*").find { |f| File.basename(f, '.*').casecmp?(name) && f =~ /\.png$/i }
end
@cache = {}
def img(path) = (@cache[path] ||= ChunkyPNG::Image.from_file(path))
tileset = img(find_img("#{game}/Graphics/Tilesets", ts.tileset_name))
autotiles = ts.autotile_names.map { |n| (p = find_img("#{game}/Graphics/Autotiles", n)) ? img(p) : nil }
# Pre-scale each needed 32x32 tile down to TS x TS (nearest neighbour).
@tilecache = {}
def tile_pixels(src, sx, sy)
  key = [src.object_id, sx, sy]
  @tilecache[key] ||= begin
    Array.new(TS * TS) do |i|
      px = sx + (i % TS) * 32 / TS; py = sy + (i / TS) * 32 / TS
      (px < src.width && py < src.height) ? src[px, py] : 0
    end
  end
end
canvas = ChunkyPNG::Image.new(w * TS, h * TS, ChunkyPNG::Color.rgb(0, 0, 0))
blit = lambda do |pix, cx, cy|
  pix.each_with_index do |c, i|
    next if ChunkyPNG::Color.a(c) == 0
    x = cx + i % TS; y = cy + i / TS
    canvas[x, y] = ChunkyPNG::Color.a(c) == 255 ? c : ChunkyPNG::Color.compose(c, canvas[x, y])
  end
end
3.times do |z|
  h.times do |ty|
    w.times do |tx|
      t = map.data[x0 + tx, y0 + ty, z]
      next if t.nil? || t < 48
      if t >= 384
        i = t - 384
        blit.call(tile_pixels(tileset, (i % 8) * 32, (i / 8) * 32), tx * TS, ty * TS)
      else
        a = autotiles[t / 48 - 1]
        next unless a
        # Use the autotile's interior fill block as a representative tile.
        blit.call(tile_pixels(a, 32, 64), tx * TS, ty * TS) if a.height >= 96
        blit.call(tile_pixels(a, 0, 0), tx * TS, ty * TS) if a.height < 96
      end
    end
  end
end
# Event markers: magenta outline; transfer events cyan; event IDs listed in a sidecar file.
File.open(out.sub(/\.png$/, '.txt'), 'w') do |f|
  map.events.values.sort_by(&:id).each do |ev|
    next unless ev.x.between?(x0, x0 + w - 1) && ev.y.between?(y0, y0 + h - 1)
    transfer = ev.pages.any? { |pg| pg.list.any? { |c| c.code == 201 } }
    col = transfer ? ChunkyPNG::Color.rgb(0, 255, 255) : ChunkyPNG::Color.rgb(255, 0, 255)
    px = (ev.x - x0) * TS; py = (ev.y - y0) * TS
    canvas.rect(px, py, px + TS - 1, py + TS - 1, col)
    canvas.rect(px + 1, py + 1, px + TS - 2, py + TS - 2, col)
    f.puts "ev#{ev.id} '#{ev.name}' (#{ev.x},#{ev.y})#{transfer ? ' [transfer]' : ''} gfx=#{ev.pages.map { |pg| pg.graphic.character_name }.uniq.join('/')}"
  end
end
# Passability overlay: red cross on blocked tiles, orange corner on counter tiles.
if ENV['PASS'] == '1'
  red = ChunkyPNG::Color.rgba(255, 0, 0, 200); org = ChunkyPNG::Color.rgba(255, 160, 0, 255)
  h.times do |ty|
    w.times do |tx|
      blocked = false; counter = false
      [2, 1, 0].each do |z|
        t = map.data[x0 + tx, y0 + ty, z]
        next if t.nil? || t == 0
        counter ||= (ts.passages[t] & 0x80) != 0
        if (ts.passages[t] & 0x0f) == 0x0f then blocked = true; break end
        break if ts.priorities[t] == 0
      end
      px = tx * TS; py = ty * TS
      if blocked
        canvas.line(px + 3, py + 3, px + TS - 4, py + TS - 4, red); canvas.line(px + TS - 4, py + 3, px + 3, py + TS - 4, red)
      end
      canvas.rect(px + 1, py + 1, px + 5, py + 5, org, org) if counter
    end
  end
end
# grid lines every 5 tiles to help read coordinates
(0...w).step(5) { |gx| canvas.line(gx * TS, 0, gx * TS, h * TS - 1, ChunkyPNG::Color.rgba(255, 255, 0, 90)) }
(0...h).step(5) { |gy| canvas.line(0, gy * TS, w * TS - 1, gy * TS, ChunkyPNG::Color.rgba(255, 255, 0, 90)) }
canvas.save(out)
puts "rendered map #{id} region (#{x0},#{y0}) #{w}x#{h} -> #{out}"
