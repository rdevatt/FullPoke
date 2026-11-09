# Generates a region that has no hand-made maps in the map pack as a chain of
# separate maps that follow the real region: each town, route, forest, cave and
# sea route is its own map with the real name, joined in the real order by map
# connections. The result is a geo spec (like geo/johto.rb) that GeoRegion then
# wires up: doors and interiors, Gyms, trainers, wild Pokémon, story battles,
# badge requirements, Victory Road and the League.
#
# Plans are in plans/<region>.rb. Maps reuse the map pack's empty placeholder
# maps with the same names where they exist.
Dir[File.join(__dir__, 'plans', '*.rb')].sort.each { |f| require f }

module Gen
  # Building blocks on tileset 1 (copied from Kanto maps): [map, x, y, w, h, door x, door y]
  STAMPS = WG::STAMPS.merge(mart: [25, 29, 25, 4, 4, 2, 3])
  CAVE_TS = 27
  CAVE_FLOOR = 1645
  CAVE_VOID = 391
  SEA = 48 * 2   # tileset 1's "Sea without shore" autotile, centre pattern
  ROAD = 625     # Pewter City's paving
  FLOWERS = 240  # tileset 1's "Flowers1" autotile, centre pattern

  SIZES = {
    town: [42, 34], city: [54, 42], route_ns: [36, 56], route_ew: [64, 30],
    forest: [48, 42], cave: [44, 40], sea_ns: [36, 56], sea_ew: [64, 30]
  }

  module_function

  def side_vec(side) = { 'North' => [0, -1], 'South' => [0, 1], 'West' => [-1, 0], 'East' => [1, 0] }[side]

  # Port: a 3-tile opening on a side, at a position along it (fraction 0..1).
  def port_cells(w, h, side, frac = 0.5)
    case side
    when 'North' then x = ((w - 3) * frac).round / 3 * 3; [x, 0, 3, 4]
    when 'South' then x = ((w - 3) * frac).round / 3 * 3; [x, h - 4, 3, 4]
    when 'West'  then y = ((h - 3) * frac).round; [0, y, 4, 3]
    when 'East'  then y = ((h - 3) * frac).round; [w - 4, y, 4, 3]
    end
  end

  def port_center(w, h, side, frac = 0.5)
    x, y, pw, ph = port_cells(w, h, side, frac)
    [x + pw / 2, y + ph / 2]
  end

  # A winding corridor between two points, carved in 3x3 cells with a random
  # walk biased toward the goal, widened in places, with side clearings.
  def carve_path(cv, rng, a, b, width: 2)
    cx, cy = a[0] / 3, a[1] / 3
    gx, gy = b[0] / 3, b[1] / 3
    cols = (cv.w + 2) / 3; rows = cv.h / 3
    cells = [[cx, cy]]
    guard = 0
    until (cx == gx && cy == gy) || guard > 600
      guard += 1
      dx = gx <=> cx; dy = gy <=> cy
      moves = []
      moves << [dx, 0] if dx != 0
      moves << [0, dy] if dy != 0
      move = if rng.rand < 0.65 && !moves.empty? then moves[rng.rand(moves.length)]
             else [[1, 0], [-1, 0], [0, 1], [0, -1]][rng.rand(4)]
             end
      nx = (cx + move[0]).clamp(1, cols - 2); ny = (cy + move[1]).clamp(1, rows - 2)
      cx, cy = nx, ny
      cells << [cx, cy]
    end
    cells << [gx, gy]
    cells.each do |x, y|
      cv.open(x * 3, y * 3, 3 * width, 3 * width)
    end
    cells
  end

  def clearing(cv, rng, cells, n)
    n.times do
      x, y = cells[rng.rand(cells.length)]
      cv.open((x - 1) * 3, (y - 1) * 3, 9, 9)
    end
  end

  #---------------------------------------------------------------------------
  # Outdoor areas
  #---------------------------------------------------------------------------
  def route(node, ports, rng)
    w, h = node[:size] || SIZES[node[:shape] == :ew ? :route_ew : :route_ns]
    cv = WG::Canvas.new(w, h)
    pts = ports.map { |side, frac| px, py, pw, ph = port_cells(w, h, side, frac); cv.open(px, py, pw, ph); [px + pw / 2, py + ph / 2] }
    hub = [w / 2 + rng.rand(-6..6), h / 2 + rng.rand(-6..6)]
    cells = []
    pts.each { |p| cells += carve_path(cv, rng, p, hub) }
    clearing(cv, rng, cells, node[:clearings] || 3)
    # Tall grass in patches along the way
    (node[:grass] || 4).times do
      x, y = cells[rng.rand(cells.length)]
      cv.grass(x * 3 - 3, y * 3 - 2, 9, 6)
    end
    map = cv.render
    if node[:water]
      pond(map, rng, cells)
    end
    map
  end

  # A pond in one clearing (surfable, with wild water Pokémon).
  def pond(map, rng, cells)
    x, y = cells[cells.length / 2]
    x0 = [x * 3 - 3, 2].max; y0 = [y * 3 - 2, 2].max
    (y0...[y0 + 5, map.height - 2].min).each do |yy|
      (x0...[x0 + 8, map.width - 2].min).each do |xx|
        next if map.data[xx, yy, 0] != WG::GROUND
        map.data[xx, yy, 0] = SEA
        map.data[xx, yy, 1] = 0
      end
    end
  end

  # Sea route: water everywhere except shores near the ports; crossed by Surf.
  def sea(node, ports, rng)
    w, h = node[:size] || SIZES[node[:shape] == :ew ? :sea_ew : :sea_ns]
    cv = WG::Canvas.new(w, h)
    cv.open(0, 0, w, h)
    map = cv.render
    h.times { |y| w.times { |x| map.data[x, y, 0] = SEA } }
    # Islands of land at each port so the player can land there
    ports.each do |side, frac|
      px, py, pw, ph = port_cells(w, h, side, frac)
      (py...py + ph).each { |y| (px...px + pw).each { |x| map.data[x, y, 0] = WG::GROUND } }
    end
    # A few rocky islets with trees
    4.times do
      ix = rng.rand(4..w - 8); iy = rng.rand(4..h - 8)
      (iy...iy + 3).each { |y| (ix...ix + 3).each { |x| map.data[x, y, 0] = WG::TREE_A[x % 3] } }
    end
    map
  end

  # Towns: an open area with a road, buildings in rows. Returns [map, doors].
  def town(node, ports, rng)
    w, h = node[:size] || SIZES[node[:kind] == :city ? :city : :town]
    cv = WG::Canvas.new(w, h)
    cv.open(3, 3, w - 6, h - 6)
    ports.each { |side, frac| cv.open(*port_cells(w, h, side, frac)) }
    buildings = []
    buildings << :pc if node[:pc] != false
    buildings << :mart if node[:mart] != false
    buildings << :gym if node[:gym]
    buildings << :lab if node[:lab]
    buildings << :home if node[:home]
    (node[:houses] || 3).times { buildings << :house }
    doors = []
    x = 5; y = 5
    row_h = 0
    buildings.each_with_index do |b, i|
      stamp = { pc: :pc, mart: :mart, gym: :gym, lab: :house2, home: :house2, house: (i.even? ? :house : :house2) }[b]
      sw, sh = STAMPS[stamp][3], STAMPS[stamp][4]
      if x + sw > w - 5
        x = 5; y += row_h + 3; row_h = 0
      end
      break if y + sh > h - 5
      sm, sx, sy, = STAMPS[stamp]
      dx, dy = place_stamp(cv, stamp, x, y)
      kind = { pc: :pc, mart: :mart, gym: :gym, lab: :lab, home: :home, house: :house }[b]
      doors << [kind, dx, dy, (b == :lab ? node[:lab] : nil), nil, :exact]
      x += sw + 3
      row_h = [row_h, sh].max
    end
    (node[:grass_patch] ? 1 : 0).times { cv.grass(w - 14, h - 9, 9, 4) }
    map = cv.render
    # Streets: one along the front of each row of buildings (every door opens
    # onto it), one down the middle to the north/south exits and one across
    # to the east/west exits
    pave = ->(x, y) { map.data[x, y, 0] = ROAD if x.between?(0, w - 1) && y.between?(0, h - 1) && map.data[x, y, 0] == WG::GROUND && map.data[x, y, 1] == 0 }
    doors.map { |d| d[2] + 1 }.uniq.each { |ry| (4..w - 5).each { |xx| 2.times { |k| pave.(xx, ry + k) } } }
    if ports.any? { |sd, _| %w[North South].include?(sd) }
      (0...h).each { |yy| (w / 2 - 1..w / 2 + 1).each { |xx| pave.(xx, yy) } }
    end
    if ports.any? { |sd, _| %w[East West].include?(sd) }
      (0...w).each { |xx| (h / 2 - 1..h / 2 + 1).each { |yy| pave.(xx, yy) } }
    end
    # Flower beds on the open grass
    14.times do
      fx = rng.rand(4..w - 6); fy = rng.rand(4..h - 6)
      2.times { |i| 2.times { |j| map.data[fx + i, fy + j, 1] = FLOWERS if map.data[fx + i, fy + j, 0] == WG::GROUND && map.data[fx + i, fy + j, 1] == 0 && !cv.blocked[[fx + i, fy + j]] } }
    end
    [map, doors]
  end

  def place_stamp(cv, kind, x, y)
    sm, sx, sy, sw, sh, dx, dy = STAMPS[kind]
    src = WG.src_map(sm)
    sh.times do |j|
      sw.times do |i|
        l1 = src.data[sx + i, sy + j, 1]; l2 = src.data[sx + i, sy + j, 2]
        cv.tile1(x + i, y + j, l1) if l1 > 0
        cv.instance_variable_get(:@layer2)[[x + i, y + j]] = l2 if l2 > 0
        cv.blocked[[x + i, y + j]] = true unless i == dx && j == dy
      end
    end
    [x + dx, y + dy]
  end

  # Forests: the forest maze generator with openings where the ports are.
  def forest(node, ports, rng)
    w, h = node[:size] || SIZES[:forest]
    cv = WG::Canvas.new(w, h)
    pts = ports.map { |side, frac| px, py, pw, ph = port_cells(w, h, side, frac); cv.open(px, py, pw, ph); [px + pw / 2, py + ph / 2] }
    hub = [w / 2, h / 2]
    cells = []
    pts.each { |p| cells += carve_path(cv, rng, p, hub, width: 1) }
    # dead ends and loops
    6.times do
      a = cells[rng.rand(cells.length)]
      b = [rng.rand(2..(w / 3 - 3)) * 3, rng.rand(2..(h / 3 - 3)) * 3]
      cells += carve_path(cv, rng, [a[0] * 3, a[1] * 3], b, width: 1)
    end
    (node[:grass] || 6).times { x, y = cells[rng.rand(cells.length)]; cv.grass(x * 3 - 3, y * 3 - 3, 9, 6) }
    cv.render
  end

  # Caves (tileset 27): floor carved like a forest, black rock elsewhere.
  def cave(node, ports, rng)
    w, h = node[:size] || SIZES[:cave]
    cv = WG::Canvas.new(w, h)
    pts = ports.map { |side, frac| px, py, pw, ph = port_cells(w, h, side, frac); cv.open(px, py, pw, ph); [px + pw / 2, py + ph / 2] }
    hub = [w / 2, h / 2]
    cells = []
    pts.each { |p| cells += carve_path(cv, rng, p, hub, width: 2) }
    clearing(cv, rng, cells, 3)
    map = WG.new_map(w, h, CAVE_TS)
    h.times { |y| w.times { |x| map.data[x, y, 0] = cv.tree?(x, y) ? CAVE_VOID : CAVE_FLOOR } }
    # Rock piles (2x2) in open floor, with a clear tile all round so they never
    # close a passage
    floor = ->(x, y) { x.between?(0, w - 1) && y.between?(0, h - 1) && map.data[x, y, 0] == CAVE_FLOOR && map.data[x, y, 1] == 0 }
    placed = 0
    120.times do
      break if placed >= (node[:rocks] || 6)
      x = rng.rand(2..w - 4); y = rng.rand(2..h - 4)
      next unless (-1..2).all? { |i| (-1..2).all? { |j| floor.(x + i, y + j) } }
      [[0, 0, 1680], [1, 0, 1681], [0, 1, 1688], [1, 1, 1689]].each { |i, j, t| map.data[x + i, y + j, 1] = t }
      placed += 1
    end
    map
  end

  #---------------------------------------------------------------------------
  # Builds every node of a plan and returns a geo spec for GeoRegion.
  #---------------------------------------------------------------------------
  def build(region)
    plan = REGION_PLANS[region]
    root = region_root(region)
    ports = Hash.new { |h, k| h[k] = [] }
    # A link's 4th element: where along the edge the ports open (0..1), or for
    # links with a real map { at: its opening's centre along the edge } or
    # { d: offset } between two real maps
    fr = ->(f) { f.is_a?(Hash) ? (f[:frac] || 0.5) : (f || 0.5) }
    plan[:links].each do |a, side, b, frac|
      ports[a] << [side, fr.(frac)]
      ports[b] << [Geo::OPPOSITE[side], fr.(frac)]
    end
    real = plan[:nodes].select { |_, kind, _, _| kind == :real }.map(&:first)
    ports.each { |key, list| next if real.include?(key); sides = list.map(&:first); dup = sides.select { |sd| sides.count(sd) > 1 }.uniq
                              raise "#{region}: #{key} has more than one neighbour on its #{dup.join('/')} side" if !dup.empty? }
    st = plan[:start]; vr = plan[:victory_road]
    ports[st[:town]] << [st[:gate_side], 0.5] if st[:gate_side]
    ports[vr[:from]] << [vr[:side], 0.5]
    # Gates from a real (map pack) map to a generated one open a port on the generated side
    (plan[:real_gates] || []).each { |_, _, _, gen, side| ports[gen] << [side, 0.5] }
    # Side areas reached only by a warp (a cave off a route): one port for the way in
    plan[:nodes].each { |key, _, _, o| ports[key] << [o[:entrance], 0.5] if o && o[:entrance] }
    # More openings onto a real neighbour's edge: [[side, frac], ...]
    plan[:nodes].each { |key, _, _, o| (o && o[:extra_ports] || []).each { |sd, f| ports[key] << [sd, f] } }
    spec = { maps: {}, links: plan[:links].map { |a, s, b, _| [a, s, b] }, towns: {}, stages: {}, caves: [], tile_fixes: plan[:tile_fixes] || {},
             requires: plan[:requires] || {}, story: plan[:story] || [], names: {}, trainers: plan[:trainers] || {} }
    plan[:nodes].each do |key, kind, name, opts|
      opts ||= {}
      if kind == :real
        # A map pack map used as it is: doors are snapped to building fronts
        spec[:maps][key] = opts[:map]
        spec[:names][key] = name
        spec[:stages][key] = opts[:stage_band] if opts[:stage_band]
        spec[:caves] << key if opts[:cave]
        spec[:towns][key] = { stage: opts[:stage] || 0, doors: opts[:doors] } if opts[:doors]
        next
      end
      placeholder = opts[:placeholder] || name
      mid = IDS.get("#{region}/#{key}", name: placeholder, parent: root, placeholder: placeholder)
      IDS.infos[mid].name = placeholder
      rng = Random.new(Zlib.crc32("gen/#{region}/#{key}"))
      node = opts.merge(kind: kind)
      map = case kind
            when :town, :city
              m, doors = town(node, ports[key], rng)
              spec[:towns][key] = { stage: opts[:stage] || 0, doors: doors }
              m
            when :route then route(node, ports[key], rng)
            when :forest then forest(node, ports[key], rng)
            when :cave then spec[:caves] << key; cave(node, ports[key], rng)
            when :sea then sea(node, ports[key], rng)
            end
      WG.set_bgm(map, opts[:bgm] || (kind == :cave ? 'Cave' : REGION_BGM[region][kind == :town || kind == :city ? 1 : 0]))
      # A trial site (Alola) or other Gym outside a town: a door in the open
      # middle of the area leads to the Gym room
      if opts[:trial]
        cx, cy = map.width / 2, map.height / 2
        spot = (0..30).lazy.flat_map { |r| (-r..r).map { |d| [[cx + d, cy - r], [cx + d, cy + r], [cx - r, cy + d], [cx + r, cy + d]] }.flatten(1) }
                      .find { |x, y| passable_tile?(map, x, y) && passable_tile?(map, x, y + 1) && passable_tile?(map, x, y + 2) }
        spec[:towns][key] ||= { stage: opts[:trial], doors: [] }
        spec[:towns][key][:doors] << [:gym, spot[0], spot[1], opts[:trial_name], nil, :exact]
      end
      save_data(map, WG.map_path(mid))   # GeoRegion loads maps from disk
      spec[:maps][key] = mid
      spec[:names][key] = name
      spec[:stages][key] = opts[:stage_band] if opts[:stage_band]
    end
    # Forest gate and Victory Road: the tiles on the edge where their ports open
    edge = lambda do |key, side|
      m = WG.load_map(spec[:maps][key])
      px, py, pw, ph = port_cells(m.width, m.height, side, 0.5)
      tiles = case side
              when 'North' then (px...px + pw).map { |x| [x, 0] }
              when 'South' then (px...px + pw).map { |x| [x, m.height - 1] }
              when 'West'  then (py...py + ph).map { |y| [0, y] }
              when 'East'  then (py...py + ph).map { |y| [m.width - 1, y] }
              end
      dx, dy = side_vec(side)
      mid = tiles[tiles.length / 2]
      [tiles, [mid[0] - dx * 2, mid[1] - dy * 2]]
    end
    gate_tiles, arrival = st[:forest_gate] ? [st[:forest_gate], st[:arrival]] : edge.(st[:town], st[:gate_side])
    # Map connections line up the generated exits exactly (not by matching);
    # links with a real map are lined up on its open ground by GeoRegion
    spec[:offsets] = {}
    plan[:links].each do |a, side, b, frac|
      along = %w[North South].include?(side) ? 0 : 1
      ra = real.include?(a); rb = real.include?(b)
      if ra || rb
        next if !frac.is_a?(Hash)
        next spec[:offsets][[a, b]] = frac[:d] if frac[:d]
        if ra
          mb = WG.load_map(spec[:maps][b])
          spec[:offsets][[a, b]] = frac[:at] - port_center(mb.width, mb.height, Geo::OPPOSITE[side], fr.(frac))[along]
        else
          ma = WG.load_map(spec[:maps][a])
          spec[:offsets][[a, b]] = port_center(ma.width, ma.height, side, fr.(frac))[along] - frac[:at]
        end
        next
      end
      ma = WG.load_map(spec[:maps][a]); mb = WG.load_map(spec[:maps][b])
      ca = port_center(ma.width, ma.height, side, fr.(frac))
      cb = port_center(mb.width, mb.height, Geo::OPPOSITE[side], fr.(frac))
      spec[:offsets][[a, b]] = ca[along] - cb[along]
    end
    spec[:start] = { town: st[:town], forest_gate: gate_tiles, arrival: arrival, gate_dir: st[:gate_dir] || st[:gate_side],
                     arrival_dir: st[:arrival_dir] || { 'West' => 6, 'East' => 4, 'North' => 2, 'South' => 8 }[st[:gate_side]] }
    inward = { 'West' => 6, 'East' => 4, 'North' => 2, 'South' => 8 }
    spec[:gates] = (plan[:real_gates] || []).map do |rkey, rtiles, rarrive, gen, side|
      gtiles, garrive = edge.(gen, side)
      [rkey, rtiles, rarrive, gen, gtiles, garrive + [inward[side]]]
    end
    # :entrance in a warp is the middle of a side area's entrance port
    entrance = lambda do |key|
      side = plan[:nodes].find { |k, *| k == key }[3][:entrance]
      tiles, = edge.(key, side)
      dx, dy = side_vec(side)
      t = tiles[tiles.length / 2]
      [t[0] - dx, t[1] - dy]
    end
    spec[:warps] = (plan[:warps] || []).map do |a, pa, b, pb, o|
      [a, pa == :entrance ? entrance.(a) : pa, b, pb == :entrance ? entrance.(b) : pb, o]
    end
    vr_tiles, = edge.(vr[:from], vr[:side])
    spec[:victory_road] = { from: vr[:from], at: vr_tiles }
    spec
  end
end

def build_generated_region(region)
  # The map pack's own (often wrong) links for real maps used by the plan
  real = REGION_PLANS[region][:nodes].select { |_, k, _, _| k == :real }
  real_ids = real.map { |_, _, _, o| o[:map] }
  Geo.drop_pack_connections('PBS/map_connections.txt', real_ids) if !real_ids.empty?
  # Generated maps that real maps replace (and others no longer planned)
  (real.map(&:first) + (REGION_PLANS[region][:retired] || [])).each { |k| IDS.release("#{region}/#{k}") }
  # Trees planted over pockets of real maps that are walkable but closed in:
  # forest_fill: { key => [[x0, y0, x1, y1], ...] }, forest_tiles: [[even row
  # tiles by x parity], [odd row tiles]] (the tileset's dense forest)
  (REGION_PLANS[region][:forest_fill] || {}).each do |key, rects|
    mid = real.find { |k, *| k == key }[3][:map]
    m = WG.load_map(mid)
    pattern = REGION_PLANS[region][:forest_tiles]
    # In step with the map's own forest
    fx, fy = (0...m.height).lazy.flat_map { |y| (0...m.width).map { |x| [x, y] } }
                           .find { |x, y| pattern.flatten.include?(m.data[x, y, 1]) }
    r = pattern.index { |row| row.include?(m.data[fx, fy, 1]) }
    px = (fx - pattern[r].index(m.data[fx, fy, 1])) % 2; py = (fy - r) % 2
    rects.each do |x0, y0, x1, y1|
      (y0..y1).each { |y| (x0..x1).each { |x| m.data[x, y, 1] = pattern[(y - py) % 2][(x - px) % 2]; m.data[x, y, 2] = 0 } }
    end
    save_data(m, WG.map_path(mid))
  end
  GEO_SPEC[region] = Gen.build(region)
  build_geo_region(region)
  # Saved for the tests (t_geo.rb), which walk the region like a hand-made one
  File.write(File.join(__dir__, 'geo', "gen_#{region}.rb"),
             "# GENERATED by tools/headless/build_world.rb from plans/#{region}.rb - don't edit.\n" \
             "GEO_SPEC ||= {}\nGEO_SPEC[:#{region}] = #{ruby_lit(GEO_SPEC[region])}\n")
end
