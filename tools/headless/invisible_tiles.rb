# Finds, for every tileset the maps use, a tile whose graphic is fully
# transparent and that no map draws: the "invisible wall" the build makes
# solid (INVISIBLE_TILES in build_world.rb) and the pocket seal uses
# (t_reach.rb SEAL=1). Prints a Ruby hash to paste.
#   tools/headless/rb.sh invisible_tiles.rb
require 'zlib'
require_relative 'rpg_classes'

# Minimal PNG reader: 8-bit RGBA/RGB/grey(+alpha) and 1/2/4/8-bit palettes.
# Returns [width, height, alpha(x, y)]
def png_alpha(path)
  data = File.binread(path)
  raise "#{path}: not a PNG" if data[0, 8] != "\x89PNG\r\n\x1a\n".b
  pos = 8
  idat = ''.b
  trns = nil
  w = h = depth = ctype = nil
  while pos < data.size
    len = data[pos, 4].unpack1('N')
    type = data[pos + 4, 4]
    body = data[pos + 8, len]
    case type
    when 'IHDR' then w, h, depth, ctype, _c, _f, interlace = body.unpack('NNCCCCC'); raise "#{path}: interlaced" if interlace != 0
    when 'tRNS' then trns = body
    when 'IDAT' then idat << body
    end
    pos += 12 + len
  end
  raw = Zlib::Inflate.inflate(idat)
  chans = { 0 => 1, 2 => 3, 3 => 1, 4 => 2, 6 => 4 }[ctype]
  bits = chans * depth
  bpp = [bits / 8, 1].max
  stride = (w * bits + 7) / 8
  prev = "\0".b * stride
  rows = []
  h.times do |y|
    f = raw.getbyte(y * (stride + 1))
    line = raw.byteslice(y * (stride + 1) + 1, stride).bytes
    stride.times do |i|
      a = i >= bpp ? line[i - bpp] : 0
      b = prev.getbyte(i)
      c = i >= bpp ? prev.getbyte(i - bpp) : 0
      line[i] = (line[i] + case f
                           when 0 then 0
                           when 1 then a
                           when 2 then b
                           when 3 then (a + b) / 2
                           when 4
                             p = a + b - c
                             pa = (p - a).abs; pb = (p - b).abs; pc = (p - c).abs
                             pa <= pb && pa <= pc ? a : (pb <= pc ? b : c)
                           end) & 0xff
    end
    prev = line.pack('C*')
    rows << line
  end
  alpha = lambda do |x, y|
    line = rows[y]
    case ctype
    when 6 then line[x * 4 + 3]
    when 4 then line[x * 2 + 1]
    when 3
      idx = depth == 8 ? line[x] : (line[x * depth / 8] >> (8 - depth - (x * depth) % 8)) & ((1 << depth) - 1)
      trns && idx < trns.bytesize ? trns.getbyte(idx) : 255
    else 255   # (a tRNS colour key on RGB/grey is ignored: no tileset uses one)
    end
  end
  [w, h, alpha]
end

tilesets = File.open('/game/Data/Tilesets.rxdata', 'rb') { |f| Marshal.load(f) }
used = Hash.new { |hh, k| hh[k] = {} }
Dir['/game/Data/Map[0-9][0-9][0-9].rxdata'].each do |f|
  m = File.open(f, 'rb') { |io| Marshal.load(io) } rescue next
  t = used[m.tileset_id]
  d = m.data
  (0...d.zsize).each { |z| (0...d.ysize).each { |y| (0...d.xsize).each { |x| v = d[x, y, z]; t[v] = true if v && v >= 384 } } }
  m.events.each_value { |e| e.pages.each { |pg| t[pg.graphic.tile_id] = true if pg.graphic.tile_id >= 384 } }
end
out = {}
used.keys.sort.each do |ts_id|
  ts = tilesets[ts_id] or next
  path = Dir["/game/Graphics/Tilesets/#{ts.tileset_name}.png"].first
  next warn("tileset #{ts_id} #{ts.tileset_name}: no image") if !path
  w, h, alpha = png_alpha(path)
  count = (w / 32) * (h / 32)
  pick = (0...count).find do |i|
    t = 384 + i
    next false if used[ts_id][t] || t >= ts.passages.xsize
    tx = (i % (w / 32)) * 32; ty = (i / (w / 32)) * 32
    (0...32).all? { |yy| (0...32).all? { |xx| alpha.(tx + xx, ty + yy) == 0 } }
  end
  if pick
    out[ts_id] = 384 + pick
  else
    warn "tileset #{ts_id} #{ts.tileset_name}: no unused transparent tile"
  end
end
puts "INVISIBLE_TILES = { #{out.map { |k, v| "#{k} => #{v}" }.join(', ')} }"
