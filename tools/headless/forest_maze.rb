# The Interregional Forest: every forest in the game combined into one and
# shuffled. A 4x4 grid of large maps holds a 16x16 maze of forest "rooms";
# each room is a piece cut from one of the game's forests (the map pack's
# Viridian Forest, Ilex Forest and Petalburg Woods, and the generated
# Santalune Forest, Pinwheel Forest, Lush Jungle and Glimwood Tangle), placed
# at random. Rooms are joined by corridors through thick tree walls along a
# random spanning tree with extra loops. The nine region gates are on the
# outer edge; the Heart Clearing (healing, PC) is in the middle.
#
# Every walkable tile is reachable: inside each pasted piece, water and ledges
# are flattened, and any pocket the piece's own trees cut off gets a path
# carved to the rest of the room.
module ForestMaze
  COLS = 4; ROWS = 4             # maps
  RW = 24; RH = 21               # room size
  ROOMS_X = 4; ROOMS_Y = 4       # rooms per map
  W = RW * ROOMS_X; H = RH * ROOMS_Y
  GX = COLS * ROOMS_X; GY = ROWS * ROOMS_Y   # global room grid (16 x 16)
  # Forests the rooms are cut from: [map id, name]
  SOURCES = [[326, 'Viridian Forest'], [196, 'Ilex Forest'], [566, 'Petalburg Woods'], [923, 'Santalune Forest'],
             [908, 'Pinwheel Forest'], [927, 'Lush Jungle'], [735, 'Glimwood Tangle']]
  # region => [global room x, global room y, side]
  GATES = {
    kanto: [0, 3, :left], galar: [0, 9, :left], alola: [0, 14, :left],
    johto: [5, 0, :top], hoenn: [11, 0, :top],
    sinnoh: [15, 4, :right], unova: [15, 11, :right],
    kalos: [4, 15, :bottom], paldea: [11, 15, :bottom]
  }
  HEART = [7, 7]
  AREA_NAMES = [
    ['Elder Oak Wilds', 'Whispering Hollow', 'Mossy Stone Ring', 'Old Ranger Hut'],
    ['Twin Stumps', 'Fern Maze', 'Heart Clearing', 'Hollow Log Path'],
    ['Sunlit Glade', 'Bramble Tangle', 'Misty Thicket', 'Lantern Grove'],
    ['Deepwood', 'Root Cellar Woods', 'Petal Path', 'Far Pines']
  ]

  module_function

  def interior(rx, ry) = [rx * RW + 3, ry * RH + 2, 18, 17]   # local room interior box
  def door_y(ry) = ry * RH + 10
  def door_x(rx) = rx * RW + 10

  # Random spanning tree over the global room grid plus ~12% extra links.
  # Returns { [[x, y], [x2, y2]] => :path | :cut }
  def maze(rng)
    links = {}
    seen = { [0, 0] => true }
    stack = [[0, 0]]
    until stack.empty?
      cur = stack.last
      nbrs = [[1, 0], [-1, 0], [0, 1], [0, -1]].map { |dx, dy| [cur[0] + dx, cur[1] + dy] }
                                                .select { |x, y| x.between?(0, GX - 1) && y.between?(0, GY - 1) && !seen[[x, y]] }
      if nbrs.empty?
        stack.pop
        next
      end
      nxt = nbrs[rng.rand(nbrs.length)]
      seen[nxt] = true
      links[[cur, nxt].sort] = :path
      stack << nxt
    end
    (GX * GY * 12 / 100).times do
      x = rng.rand(GX); y = rng.rand(GY)
      dx, dy = [[1, 0], [0, 1]][rng.rand(2)]
      next if x + dx >= GX || y + dy >= GY
      key = [[x, y], [x + dx, y + dy]].sort
      links[key] ||= (rng.rand < 0.35 ? :cut : :path)
    end
    links
  end

  def sanitize_piece(map, box)
    ts = TILESETS[map.tileset_id]
    x0, y0, w, h = box
    (y0...y0 + h).each do |y|
      (x0...x0 + w).each do |x|
        # Empty cells are walkable in the game; make them ground so they count
        map.data[x, y, 0] = WG::GROUND if map.data[x, y, 0].to_i == 0
        [0, 1, 2].each do |z|
          t = map.data[x, y, z]
          next if t.nil? || t == 0
          tag = ts.terrain_tags[t]
          if [5, 6, 7, 1, 8, 9, 15].include?(tag)   # water, ledges, waterfalls, bridges
            map.data[x, y, z] = (z == 0 ? WG::GROUND : 0)
          end
        end
      end
    end
  end

  # Clears a tile to plain ground.
  def clear(map, x, y)
    map.data[x, y, 0] = WG::GROUND
    map.data[x, y, 1] = 0
    map.data[x, y, 2] = 0
  end

  # Walkable components inside a box. Returns { tile => component index }
  def components(map, box)
    x0, y0, w, h = box
    comp = {}
    n = 0
    (y0...y0 + h).each do |y|
      (x0...x0 + w).each do |x|
        next if comp[[x, y]] || !passable_tile?(map, x, y)
        q = [[x, y]]; comp[[x, y]] = n
        until q.empty?
          cx, cy = q.shift
          [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
            nx, ny = cx + dx, cy + dy
            next if nx < x0 || ny < y0 || nx >= x0 + w || ny >= y0 + h || comp[[nx, ny]] || !passable_tile?(map, nx, ny)
            comp[[nx, ny]] = n
            q << [nx, ny]
          end
        end
        n += 1
      end
    end
    comp
  end

  # Joins everything walkable in the box into one area around `anchor`:
  # first every door, then each other pocket - small gaps between trees are
  # planted over with trees, larger pockets get an L-shaped path carved to the
  # nearest tile of the main area.
  def connect_box(map, box, anchor, doors)
    carve_to = lambda do |from, main_tiles|
      tx, ty = main_tiles.min_by { |x, y| (x - from[0]).abs + (y - from[1]).abs }
      x, y = from
      until x == tx && y == ty
        clear(map, x, y)
        if x != tx then x += (tx <=> x) else y += (ty <=> y) end   # one axis per step: no diagonal gaps
      end
    end
    doors.each do |door|
      comp = components(map, box)
      main = comp[anchor]
      next if comp[door] == main
      carve_to.(door, comp.select { |_, c| c == main }.keys)
    end
    300.times do
      comp = components(map, box)
      main = comp[anchor]
      groups = comp.reject { |_, c| c == main }.group_by { |_, c| c }
      return if groups.empty?
      _, tiles = groups.first
      tiles = tiles.map(&:first)
      if tiles.length <= 6
        tiles.each { |x, y| map.data[x, y, 0] = WG::TREE_A[x % 3]; map.data[x, y, 1] = 0; map.data[x, y, 2] = 0 }
      else
        carve_to.(tiles.first, comp.select { |_, c| c == main }.keys)
      end
    end
  end
end

def build_forest_maze
  fm = ForestMaze
  folder = IDS.get('forest/folder', name: 'Interregional Forest', parent: 0)
  save_map(folder, WG.new_map(20, 15, WG::OUT_TS))
  WORLD[:roots][folder] = :forest
  %w[nw n ne w c e sw s se].each { |k| IDS.release("forest/#{k}") }   # the old 3x3 forest
  ids = {}
  fm::ROWS.times { |gy| fm::COLS.times { |gx| ids[[gx, gy]] = IDS.get("forest/m#{gx}_#{gy}", name: "Interregional Forest - #{fm::AREA_NAMES[gy][gx]}", parent: folder) } }
  rng = Random.new(Zlib.crc32('forest/maze'))
  links = fm.maze(rng)
  sources = fm::SOURCES.map { |id, name| [WG.load_map(id), name] }.select { |m, _| m.tileset_id == WG::OUT_TS && m.width >= 24 }
  trainer_no = 0
  fm::ROWS.times do |gy|
    fm::COLS.times do |gx|
      mid = ids[[gx, gy]]
      mrng = Random.new(Zlib.crc32("forest/map/#{gx}/#{gy}"))
      cv = WG::Canvas.new(fm::W, fm::H)
      local = ->(rx, ry) { [rx - gx * fm::ROOMS_X, ry - gy * fm::ROOMS_Y] }
      mine = ->(rx, ry) { rx / fm::ROOMS_X == gx && ry / fm::ROOMS_Y == gy }
      # Room interiors
      fm::ROOMS_Y.times { |ly| fm::ROOMS_X.times { |lx| x, y, w, h = fm.interior(lx, ly); cv.open(x, y, w, h) } }
      # Corridors (links touching a room of this map)
      links.each do |(a, b), _kind|
        next unless mine.(*a) || mine.(*b)
        if a[1] == b[1]   # horizontal: from a's interior right to b's interior left
          ry = a[1]
          y = fm.door_y(ry - gy * fm::ROOMS_Y) - 1
          ax = (a[0] - gx * fm::ROOMS_X) * fm::RW + 18
          bx = (b[0] - gx * fm::ROOMS_X) * fm::RW + 6
          x0 = [ax, 0].max; x1 = [bx, fm::W].min
          cv.open(x0, y, x1 - x0, 3) if x1 > x0
        else              # vertical
          rx = a[0]
          x = fm.door_x(rx - gx * fm::ROOMS_X) - 1
          ay = (a[1] - gy * fm::ROOMS_Y) * fm::RH + 16
          by = (b[1] - gy * fm::ROOMS_Y) * fm::RH + 4
          y0 = [ay, 0].max; y1 = [by, fm::H].min
          cv.open(x, y0, 3, y1 - y0) if y1 > y0
        end
      end
      # Region gates on the outer edge
      gates_here = fm::GATES.select { |_, (rx, ry, _)| mine.(rx, ry) }
      gates_here.each do |_, (rx, ry, side)|
        lx, ly = local.(rx, ry)
        case side
        when :left   then cv.open(0, fm.door_y(ly) - 1, lx * fm::RW + 6, 3)
        when :right  then cv.open(lx * fm::RW + 18, fm.door_y(ly) - 1, fm::W - (lx * fm::RW + 18), 3)
        when :top    then cv.open(fm.door_x(lx) - 1, 0, 3, ly * fm::RH + 4)
        when :bottom then cv.open(fm.door_x(lx) - 1, ly * fm::RH + 16, 3, fm::H - (ly * fm::RH + 16))
        end
      end
      map = cv.render
      WG.set_bgm(map, 'Natural Park')
      # Paste a piece of a real forest into each room, then make it all reachable
      room_names = {}
      fm::ROOMS_Y.times do |ly|
        fm::ROOMS_X.times do |lx|
          rx, ry = gx * fm::ROOMS_X + lx, gy * fm::ROOMS_Y + ly
          box = fm.interior(lx, ly)
          if [rx, ry] == fm::HEART
            (box[1]...box[1] + box[3]).each { |y| (box[0]...box[0] + box[2]).each { |x| fm.clear(map, x, y) } }
            room_names[[lx, ly]] = 'Heart Clearing'
            next
          end
          src, name = sources[mrng.rand(sources.length)]
          sx = mrng.rand(src.width - box[2] + 1); sy = mrng.rand(src.height - box[3] + 1)
          box[3].times { |j| box[2].times { |i| 3.times { |z| map.data[box[0] + i, box[1] + j, z] = src.data[sx + i, sy + j, z] } } }
          fm.sanitize_piece(map, box)
          room_names[[lx, ly]] = name
        end
      end
      # Reachability, room by room: the corridor openings and everything inside
      fm::ROOMS_Y.times do |ly|
        fm::ROOMS_X.times do |lx|
          x, y, w, h = fm.interior(lx, ly)
          # Doors: where corridors enter this interior
          doors = [[x, fm.door_y(ly)], [x + w - 1, fm.door_y(ly)], [fm.door_x(lx), y], [fm.door_x(lx), y + h - 1]]
          doors.select! { |dx, dy| [[dx - 1, dy], [dx + 1, dy], [dx, dy - 1], [dx, dy + 1]].any? { |px, py| !(px.between?(x, x + w - 1) && py.between?(y, y + h - 1)) && passable_tile?(map, px, py) } }
          anchor = doors.first || [x + w / 2, y + h / 2]
          doors.each { |dx, dy| fm.clear(map, dx, dy) }
          fm.clear(map, *anchor)
          fm.connect_box(map, [x, y, w, h], anchor, doors)
        end
      end
      # Events: Heart Clearing, gates, landmark signs, trainers, items, Cut trees
      if mine.(*fm::HEART)
        lx, ly = local.(*fm::HEART)
        x, y, = fm.interior(lx, ly)
        new_event(map, 'FP: Ranger', x + 8, y + 6, [new_page(trigger: 0, graphic: 'NPC 22', list: EventList.build {
          text('Welcome to the Heart Clearing, the middle of the Interregional Forest.')
          text('Let me look after your Pokémon.')
          script('pbSetPokemonCenter')
          recover_all
          play_me('Pkmn healing')
          wait(20)
          text('Every forest in the world grows somewhere in these woods. Each path out leads to the first town of a region.')
        })])
        ev_script_touch(map, x + 11, y + 6, 'FP: PC', 'pbPokeCenterPC', trigger: 0)
        ev_sign(map, x + 5, y + 10, 'FP: Sign', ['Heart Clearing', "Rare Pokémon from every region you have completed gather in this forest's tall grass."])
        map.data[x + 2, y + 13, 1] = WG::GRASS
        cv_grass = [[x + 2, y + 12], [x + 13, y + 3]]
        cv_grass.each { |gx_, gy_| 4.times { |i| 2.times { |j| map.data[gx_ + i, gy_ + j, 1] = WG::GRASS } } }
      end
      gates_here.each do |region, (rx, ry, side)|
        lx, ly = local.(rx, ry)
        reg = FullPoke.region(region)
        case side
        when :left   then tiles = (-1..1).map { |d| [0, fm.door_y(ly) + d] }; inner = [2, fm.door_y(ly)]; dir = 6
        when :right  then tiles = (-1..1).map { |d| [fm::W - 1, fm.door_y(ly) + d] }; inner = [fm::W - 3, fm.door_y(ly)]; dir = 4
        when :top    then tiles = (-1..1).map { |d| [fm.door_x(lx) + d, 0] }; inner = [fm.door_x(lx), 2]; dir = 2
        when :bottom then tiles = (-1..1).map { |d| [fm.door_x(lx) + d, fm::H - 1] }; inner = [fm.door_x(lx), fm::H - 3]; dir = 8
        end
        tiles.each { |ex, ey| ev_script_touch(map, ex, ey, "FP: Gate #{region}", "FullPoke.forest_gate(:#{region})") }
        sx, sy = free_spot(map, inner[0] + (dir == 6 ? 2 : dir == 4 ? -2 : 2), inner[1] + (dir == 2 ? 2 : dir == 8 ? -2 : 2))
        ev_sign(map, sx, sy, "FP: Gate sign #{region}", ["#{reg.name} path", "This way to #{reg.start_town}, the first town of the #{reg.name} region."])
        WORLD[:forest_exits][region] = [mid, inner[0], inner[1], dir]
      end
      # A sign in each room naming the forest it grew from
      room_names.each do |(lx, ly), name|
        next if name == 'Heart Clearing'
        next if mrng.rand(3) != 0
        x, y, w, h = fm.interior(lx, ly)
        sx, sy = free_spot(map, x + w / 2, y + 2, box: [x, y, w, h]) rescue next
        ev_sign(map, sx, sy, 'FP: Landmark', ["Trees from #{name} grow here."])
      end
      # Walkable tiles of the whole map (rooms may only join through other maps)
      reach_all = {}
      fm::ROOMS_Y.times do |ly|
        fm::ROOMS_X.times do |lx|
          x, y, w, h = fm.interior(lx, ly)
          start = (y...y + h).to_a.product((x...x + w).to_a).map(&:reverse).find { |px, py| passable_tile?(map, px, py) }
          next if !start || reach_all[start]
          reach_all.merge!(reachable_from(map, *start))
        end
      end
      spots = reach_all.keys.select do |x, y|
        x > 2 && y > 2 && x < fm::W - 3 && y < fm::H - 3 && !event_at?(map, x, y) &&
          [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, -1], [1, -1], [-1, 1]].all? { |dx, dy| reach_all[[x + dx, y + dy]] }
      end.sort
      spots = spots.shuffle(random: mrng)
      2.times do
        x, y = spots.pop || break
        trainer_no += 1
        species = FOREST_TRAINER_SPECIES.shuffle(random: mrng).first(2 + mrng.rand(2))
        lvl = 26 + mrng.rand(10)
        key2 = :"forest_trainer_#{trainer_no}"
        FOREST_TRAINERS << [key2, species.map { |s| "#{s}:#{lvl}" }.join(' ')]
        gfx = %w[trainer_BUGCATCHER trainer_CAMPER trainer_PICNICKER trainer_POKEMONRANGER_M trainer_POKEMONRANGER_F][mrng.rand(5)]
        ev_trainer(map, x, y, 3, gfx, [2, 4, 6, 8][mrng.rand(4)], gfx.sub('trainer_', '').to_sym, "The forest trains us all. Let's battle!",
                   "FullPoke.trainer_battle(:#{key2})", "Every region's rare Pokémon pass through here.", name_prefix: 'FP: ')
      end
      5.times do |i|
        x, y = spots.pop || break
        item = FOREST_ITEMS[mrng.rand(FOREST_ITEMS.length)]
        i.even? ? ev_item_ball(map, x, y, item, name_prefix: 'FP: ') : ev_hidden_item(map, x, y, item, name_prefix: 'FP: ')
      end
      # Cut trees only on the extra loops, so they never cut anything off
      links.each do |(a, b), kind|
        next if kind != :cut || !mine.(*a) || !mine.(*b)
        lx, ly = local.(*a)
        cx, cy = a[1] == b[1] ? [lx * fm::RW + 22, fm.door_y(ly)] : [fm.door_x(lx), ly * fm::RH + 19]
        next if event_at?(map, cx, cy) || !passable_tile?(map, cx, cy)
        new_event(map, 'FP: CutTree', cx, cy, [new_page(trigger: 0, graphic: 'Object tree 1', list: EventList.build {
          if_script('pbCut') { script('pbEraseThisEvent') }
        })])
      end
      save_map(mid, map)
      meta(mid, "Interregional Forest - #{fm::AREA_NAMES[gy][gx]}", battleback: 'forest')
      WORLD[:forest_maps] << mid
      WORLD[:encounters] << { map: mid, forest: true }
    end
  end
  # Seamless connections between neighbouring forest maps
  ids.each do |(gx, gy), mid|
    CONNECTIONS << "#{mid},East,0,#{ids[[gx + 1, gy]]},West,0" if ids[[gx + 1, gy]]
    CONNECTIONS << "#{mid},South,0,#{ids[[gx, gy + 1]]},North,0" if ids[[gx, gy + 1]]
  end
end
