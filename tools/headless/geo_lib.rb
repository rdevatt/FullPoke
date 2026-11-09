# Helpers for wiring the map pack's hand-made region maps into a playable
# region (build_world.rb): map connections lined up automatically along the open
# ground of the shared edge, doors to generated interiors, cave and gate warps.
module Geo
  OPPOSITE = { 'North' => 'South', 'South' => 'North', 'East' => 'West', 'West' => 'East' }

  module_function

  def water_tile?(map, x, y)
    return false if x < 0 || y < 0 || x >= map.width || y >= map.height
    ts = TILESETS[map.tileset_id]
    return false if [1, 2].any? { |z| (t = map.data[x, y, z]) > 0 && ts.passages[t] & 0x0f == 0x0f }
    t = map.data[x, y, 0]
    return true if [5, 6, 7].include?(ts.terrain_tags[t])
    t >= 48 && t < 384 && ts.autotile_names[t / 48 - 1].to_s =~ /sea|water/i ? true : false
  end

  def open_tile?(map, x, y) = passable_tile?(map, x, y) || water_tile?(map, x, y)

  # Size of the walkable/surfable area each tile belongs to (cached per map), so
  # map edges line up on real roads rather than small fenced-off pockets.
  def area_size(map, x, y)
    @areas ||= {}
    areas = (@areas[map.object_id] ||= {})
    return areas[[x, y]] if areas.key?([x, y])
    return 0 if !open_tile?(map, x, y)
    seen = { [x, y] => true }; queue = [[x, y]]
    until queue.empty?
      cx, cy = queue.shift
      [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
        n = [cx + dx, cy + dy]
        next if seen[n] || !open_tile?(map, *n)
        seen[n] = true
        queue << n
      end
    end
    seen.each_key { |k| areas[k] = seen.size }
    seen.size
  end

  MIN_AREA = 40

  # Open tiles along one edge of a map (walkable or surfable), on the edge and one step in.
  def edge_open(map, side)
    case side
    when 'North' then (0...map.width).map { |x| open_tile?(map, x, 1) && area_size(map, x, 0) >= MIN_AREA }
    when 'South' then (0...map.width).map { |x| open_tile?(map, x, map.height - 2) && area_size(map, x, map.height - 1) >= MIN_AREA }
    when 'West'  then (0...map.height).map { |y| open_tile?(map, 1, y) && area_size(map, 0, y) >= MIN_AREA }
    when 'East'  then (0...map.height).map { |y| open_tile?(map, map.width - 2, y) && area_size(map, map.width - 1, y) >= MIN_AREA }
    end
  end

  def ranges(bools)
    out = []
    bools.each_with_index { |v, i| next if !v; (out.last && out.last[1] == i - 1) ? out.last[1] = i : out << [i, i] }
    out.map { |a, b| a == b ? a.to_s : "#{a}-#{b}" }.join(',')
  end

  # Offset d (b's coordinate = a's coordinate - d) that lines up the most open
  # tiles, preferring offsets that keep the smaller edge inside the larger one.
  def best_offset(a, side, b)
    ea = edge_open(a, side)
    eb = edge_open(b, OPPOSITE[side])
    best = nil
    (-(eb.length - 1)..(ea.length - 1)).each do |d|
      match = 0; stray = 0
      ea.each_with_index do |open, i|
        next if !open
        j = i - d
        (j >= 0 && j < eb.length && eb[j]) ? match += 1 : stray += 1
      end
      eb.each_with_index { |open, j| stray += 1 if open && !(j + d >= 0 && j + d < ea.length && ea[j + d]) }
      inside = (d >= 0 && d + eb.length <= ea.length) || (d <= 0 && ea.length - d <= eb.length) ? 1 : 0
      score = [match * 4 - stray, inside, -d.abs]
      best = [score, d, match] if !best || (score <=> best[0]) > 0
    end
    [best[1], best[2], ea.count(true), eb.count(true)]
  end

  # "a,Side,pos1,b,Opposite,pos2" for map_connections.txt
  def connection_line(a_id, side, b_id, offset)
    pos1, pos2 = offset >= 0 ? [offset, 0] : [0, -offset]
    "#{a_id},#{side},#{pos1},#{b_id},#{OPPOSITE[side]},#{pos2}"
  end

  # Removes the map pack's connection lines that touch any of the given maps
  # (outside FullPoke's generated block), so they can be replaced.
  def drop_pack_connections(path, map_ids)
    text = File.read(path, encoding: 'bom|utf-8')
    head, gen = text.split(/(?=# >>> FullPoke generated)/, 2)
    kept = head.lines.reject do |l|
      next false if l.start_with?('#') || l.strip.empty?
      a = l.split(',')
      map_ids.include?(a[0].to_i) || map_ids.include?(a[3].to_i)
    end
    File.write(path, kept.join + (gen || ''))
  end

  def solid_deco?(map, x, y)
    return false if x < 0 || y < 0 || x >= map.width || y >= map.height
    !passable_tile?(map, x, y) && [1, 2].any? { |z| map.data[x, y, z] >= 384 }
  end

  # A gatehouse straddling one edge of a map: the building touching that edge
  # and the cells of its inward face (solid, with walkable ground beside them).
  # Returns [[x, y], ...] for the middle of the face (the entrance), inward step
  # direction [dx, dy], or nil.
  def edge_gate(map, side, near: nil)
    horizontal = %w[East West].include?(side)
    len = horizontal ? map.height : map.width
    depth = horizontal ? map.width : map.height
    cell = lambda do |along, inward|   # inward 0 = the edge itself
      case side
      when 'East'  then [map.width - 1 - inward, along]
      when 'West'  then [inward, along]
      when 'South' then [along, map.height - 1 - inward]
      when 'North' then [along, inward]
      end
    end
    spans = []
    len.times do |a|
      ok = solid_deco?(map, *cell.(a, 0))
      if ok
        (spans.last && spans.last[1] == a - 1) ? spans.last[1] = a : spans << [a, a]
      end
    end
    spans.select! { |a, b| b - a >= 2 }
    return nil if spans.empty?
    spans.sort_by! { |a, b| near ? ((a + b) / 2 - near).abs : -(b - a) }
    faces = []
    a, b = spans.first
    (a..b).each do |al|
      (0...[depth, 12].min).each do |i|
        c = cell.(al, i)
        break if !solid_deco?(map, *c)
        n = cell.(al, i + 1)
        if passable_tile?(map, *n)
          faces << [al, c, n]
          break
        end
      end
    end
    return nil if faces.empty?
    mid = faces.length / 2
    pick = faces[[mid - 1, 0].max..[mid + 1, faces.length - 1].min]
    [pick.map { |_, c, _| c }, pick.map { |_, _, n| n }]
  end

  # Building door: the solid tile of the building front nearest to (x, y), with
  # open ground below it to stand on. Players bump into it to go in.
  def snap_door(map, x, y)
    cands = []
    (-3..3).each do |dy|
      (-2..2).each do |dx|
        px, py = x + dx, y + dy
        next if passable_tile?(map, px, py) || !passable_tile?(map, px, py + 1) || !solid_deco?(map, px, py)
        cands << [dx.abs * 2 + dy.abs, px, py]
      end
    end
    raise "no building front near #{x},#{y} on a #{map.width}x#{map.height} map" if cands.empty?
    _, px, py = cands.min
    [px, py]
  end
end
