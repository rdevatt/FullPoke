# Builds FullPoke's generated world: the Interregional Forest and the playable
# circuit of every region except Kanto (see Plugins/FullPoke Core/080_Circuits.rb).
#   tools/headless/run.sh build_world.rb
# then tools/headless/run.sh t_compile.rb (map metadata/connections changed).
#
# Re-runnable: generated maps are rebuilt in place (their IDs are kept in
# world_ids.json). Real map-pack maps it touches (Pallet Town and the Johto,
# Hoenn, Sinnoh and Unova start towns) only get events named "FP: …", which
# are replaced on each run.
require_relative 'world_lib'
require_relative 'build_geo'

PluginManager.runPlugins unless $plugins_ran
$plugins_ran = true
GameData.load_all rescue nil

IDS = WG::Ids.new(File.join(__dir__, 'world_ids.json'))
TILESETS = load_data('Data/Tilesets.rxdata')
WORLD = { roots: {}, regions: {}, forest_exits: {}, forest_maps: [], encounters: [] }
METADATA = {}      # map id => lines for map_metadata.txt
CONNECTIONS = []   # lines for map_connections.txt
SAVED = {}

# Maps are written only once the whole build has succeeded.
def save_map(id, map)
  SAVED[id] = map
end

def meta(id, name, outdoor: true, bgm: nil, battleback: nil, extra: [])
  lines = ["Name = #{name}"]
  lines << "Outdoor = true" << "ShowArea = true" if outdoor
  lines << "BattleBack = #{battleback}" if battleback
  lines.concat(extra)
  METADATA[id] = lines
end

#-------------------------------------------------------------------------------
# Passability on real (non-generated) maps, for placing events.
#-------------------------------------------------------------------------------
def passable_tile?(map, x, y)
  return false if x < 0 || y < 0 || x >= map.width || y >= map.height
  ts = TILESETS[map.tileset_id]
  [2, 1, 0].each do |z|
    t = map.data[x, y, z]
    next if t.nil? || t == 0
    return false if ts.passages[t] & 0x0f == 0x0f
    return false if ts.terrain_tags[t] == 5 || ts.terrain_tags[t] == 7   # water / deep water
    return true if ts.priorities[t] == 0
  end
  map.data[x, y, 0].to_i > 0
end

def event_at?(map, x, y) = map.events.values.any? { |e| e.x == x && e.y == y }

# Tiles reachable on foot from (x, y) (ignoring one-way ledges). On composite
# interior maps, void_tile marks the empty space between rooms.
def reachable_from(map, x, y, void_tile: nil)
  seen = { [x, y] => true }
  queue = [[x, y]]
  until queue.empty?
    cx, cy = queue.shift
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      n = [cx + dx, cy + dy]
      next if seen[n] || !passable_tile?(map, *n)
      next if void_tile && map.data[n[0], n[1], 0] == void_tile && map.data[n[0], n[1], 1] == 0 && map.data[n[0], n[1], 2] == 0
      seen[n] = true
      queue << n
    end
  end
  seen
end

# Nearest free passable tile to (x, y) (Manhattan rings), optionally inside a box
# and/or within a set of reachable tiles.
def free_spot(map, x, y, box: nil, avoid: [], reach: nil)
  (0..60).each do |r|
    cands = []
    (-r..r).each do |dx|
      dy = r - dx.abs
      [[x + dx, y + dy], [x + dx, y - dy]].uniq.each { |p| cands << p }
    end
    cands.each do |px, py|
      next if box && !(px >= box[0] && py >= box[1] && px < box[0] + box[2] && py < box[1] + box[3])
      next if avoid.include?([px, py])
      next if reach && !reach[[px, py]]
      next unless passable_tile?(map, px, py) && !event_at?(map, px, py)
      return [px, py]
    end
  end
  raise "no free tile near #{x},#{y}"
end

def remove_fp_events(map)
  map.events.delete_if { |_, e| e.name.start_with?('FP: ') }
end

#-------------------------------------------------------------------------------
# Interregional Forest: 3x3 maps joined by map connections. Eight outer maps
# hold the region gates (two in the south map); the centre is a clearing with a
# Ranger who heals and a PC.
#-------------------------------------------------------------------------------
FW = 48; FH = 42
FOREST_LAYOUT = {
  nw: [0, 0], n: [1, 0], ne: [2, 0], w: [0, 1], c: [1, 1], e: [2, 1], sw: [0, 2], s: [1, 2], se: [2, 2]
}
FOREST_GATES = {   # region => [forest map, side, along (tile)]
  kanto: [:nw, :left, 18], johto: [:n, :top, 22], hoenn: [:ne, :right, 18], sinnoh: [:e, :right, 22],
  unova: [:se, :right, 22], kalos: [:s, :bottom, 12], paldea: [:s, :bottom, 33], alola: [:sw, :left, 22],
  galar: [:w, :left, 18]
}
FOREST_NAMES = {
  nw: 'Interregional Forest - Kanto Path', n: 'Interregional Forest - Johto Path',
  ne: 'Interregional Forest - Hoenn Path', e: 'Interregional Forest - Sinnoh Path',
  se: 'Interregional Forest - Unova Path', s: 'Interregional Forest - Southern Paths',
  sw: 'Interregional Forest - Alola Path', w: 'Interregional Forest - Galar Path',
  c: 'Interregional Forest - Heart Clearing'
}
LANDMARKS = {
  nw: 'The Elder Oak', n: 'Whispering Hollow', ne: 'Mossy Stone Ring', e: 'Old Ranger Hut ruins',
  se: 'Twin Stumps', s: 'Sunlit Glade', sw: 'Fern Maze', w: 'Hollow Log Path', c: 'The Heart Clearing'
}
FOREST_ITEMS = %i[POTION SUPERPOTION REVIVE ETHER RARECANDY FULLHEAL HYPERPOTION MAXREVIVE PPUP
                  NUGGET BIGMUSHROOM TINYMUSHROOM MIRACLESEED SILVERPOWDER LEAFSTONE MAXPOTION]
FOREST_TRAINER_SPECIES = %i[BUTTERFREE BEEDRILL PARASECT VENOMOTH LEDIAN ARIADOS YANMA HERACROSS
  BEAUTIFLY DUSTOX MASQUERAIN NINJASK KRICKETUNE VESPIQUEN LEAVANNY SCOLIPEDE GALVANTULA VIVILLON
  RIBOMBEE ORBEETLE BRELOOM SHIFTRY TANGROWTH LUDICOLO VILEPLUME BELLOSSOM SUNFLORA JUMPLUFF]

def forest_maze(rng, openings)
  # 8 x 7 cells of 6x6 tiles; spanning tree + extra links (loops).
  cw, ch = 8, 7
  links = {}
  seen = { [rng.rand(cw), rng.rand(ch)] => true }
  frontier = []
  add = lambda do |c|
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      n = [c[0] + dx, c[1] + dy]
      next if n[0] < 0 || n[1] < 0 || n[0] >= cw || n[1] >= ch || seen[n]
      frontier << [c, n]
    end
  end
  add.call(seen.keys.first)
  until frontier.empty?
    a, b = frontier.delete_at(rng.rand(frontier.length))
    next if seen[b]
    seen[b] = true
    links[[a, b].sort] = :path
    add.call(b)
  end
  # Extra links: loops; some become Cut-tree shortcuts.
  (cw * ch / 3).times do
    a = [rng.rand(cw), rng.rand(ch)]
    dx, dy = [[1, 0], [0, 1]][rng.rand(2)]
    b = [a[0] + dx, a[1] + dy]
    next if b[0] >= cw || b[1] >= ch || links[[a, b].sort]
    links[[a, b].sort] = (rng.rand(3) == 0) ? :cut : :path
  end
  links
end

def build_forest
  folder = IDS.get('forest/folder', name: 'Interregional Forest', parent: 0)
  m = WG.new_map(20, 15, WG::OUT_TS)
  save_map(folder, m)
  WORLD[:roots][folder] = :forest
  ids = {}
  FOREST_LAYOUT.each_key { |k| ids[k] = IDS.get("forest/#{k}", name: FOREST_NAMES[k], parent: folder) }
  # Shared openings between neighbours (tile coordinate along the edge)
  h_open = [9, 30]   # along vertical edges (y)
  v_open = [12, 33]  # along horizontal edges (x)
  trainer_no = 0
  FOREST_LAYOUT.each do |key, (gx, gy)|
    rng = Random.new(Zlib.crc32("forest/#{key}"))
    cv = WG::Canvas.new(FW, FH)
    links = forest_maze(rng, nil)
    cell_box = ->(cx, cy) { [cx * 6, (cy * 6), 3, 3] }
    # Rooms and links
    (0...8).each { |cx| (0...7).each { |cy| x, y, = cell_box.call(cx, cy); cv.open(x, y, 3, 3) } }
    cut_spots = []
    links.each do |(a, b), kind|
      ax, ay, = cell_box.call(*a)
      if a[1] == b[1]   # horizontal
        cv.open(ax + 3, ay, 3, 3)
        cut_spots << [ax + 4, ay + 1] if kind == :cut
      else
        cv.open(ax, ay + 3, 3, 3)
        cut_spots << [ax + 1, ay + 4] if kind == :cut
      end
    end
    # Edge openings to neighbours (and gates)
    neighbours = { left: [gx - 1, gy], right: [gx + 1, gy], top: [gx, gy - 1], bottom: [gx, gy + 1] }
    neighbours.each do |side, (nx, ny)|
      next if nx < 0 || ny < 0 || nx > 2 || ny > 2
      openings = (side == :left || side == :right) ? h_open : v_open
      openings.each { |along| carve_edge(cv, side, along) }
    end
    gates = FOREST_GATES.select { |_, g| g[0] == key }
    gates.each { |_, (_, side, along)| carve_edge(cv, side, along) }
    # Clearings with tall grass, and the central clearing
    if key == :c
      cv.open(15, 12, 18, 18)
      cv.grass(15, 26, 6, 3)
      cv.grass(27, 12, 6, 3)
    else
      2.times do
        cx = 3 + rng.rand(5) * 6; cy = 3 + rng.rand(4) * 6
        cv.open(cx, cy, 9, 6)
      end
    end
    # Tall grass in some corridors
    (FH * FW / 60).times do
      x = rng.rand(FW - 6); y = rng.rand(FH - 3)
      cv.grass(x, y, 3 + rng.rand(4), 2 + rng.rand(2))
    end
    cv.stamp(:house2, 22, 13) if key == :c   # Ranger station
    map = cv.render
    WG.set_bgm(map, 'Natural Park')
    # Events
    if key == :c
      new_event(map, 'FP: Ranger', 21, 19, [new_page(trigger: 0, graphic: 'NPC 22', list: EventList.build {
        text('Welcome to the Heart Clearing, the middle of the Interregional Forest.')
        text('Let me look after your Pokémon.')
        script('pbSetPokemonCenter')
        recover_all
        play_me('Pkmn healing')
        wait(20)
        text('There! Every path out of this forest leads to the first town of a region. Good luck!')
      })])
      ev_script_touch(map, 26, 19, 'FP: PC', 'pbPokeCenterPC', trigger: 0)
      ev_sign(map, 18, 24, 'FP: Sign', ['Heart Clearing', 'Rare Pokémon from every region you have completed gather in this forest\'s tall grass.'])
    end
    ev_sign(map, *free_spot(map, FW / 2, FH / 2), 'FP: Landmark', [LANDMARKS[key]])
    gates.each do |region, (_, side, along)|
      gx_, gy_, inner, dir = gate_coords(side, along)
      reg = FullPoke.region(region)
      3.times do |i|
        ex, ey = (side == :left || side == :right) ? [gx_, gy_ + i - 1] : [gx_ + i - 1, gy_]
        ev_script_touch(map, ex, ey, "FP: Gate #{region}", "FullPoke.forest_gate(:#{region})")
      end
      sx, sy = free_spot(map, inner[0], inner[1] + ((side == :top || side == :bottom) ? 0 : 2))
      ev_sign(map, sx, sy, "FP: Gate sign #{region}", ["#{reg.name} path", "This way to #{reg.start_town}, the first town of the #{reg.name} region."])
      WORLD[:forest_exits][region] = [ids[key], inner[0], inner[1], dir]
    end
    # Trainers, items, Cut-tree shortcuts
    2.times do
      x, y = free_spot(map, 6 + rng.rand(FW - 12), 6 + rng.rand(FH - 12))
      trainer_no += 1
      idx = trainer_no
      species = FOREST_TRAINER_SPECIES.shuffle(random: rng).first(2 + rng.rand(2))
      lvl = 26 + rng.rand(10)
      key2 = :"forest_trainer_#{idx}"
      FOREST_TRAINERS << [key2, species.map { |s| "#{s}:#{lvl}" }.join(' ')]
      gfx = %w[trainer_BUGCATCHER trainer_CAMPER trainer_PICNICKER trainer_POKEMONRANGER_M trainer_POKEMONRANGER_F][rng.rand(5)]
      tr_type = gfx.sub('trainer_', '').to_sym
      ev_trainer(map, x, y, 3, gfx, [2, 4, 6, 8][rng.rand(4)], tr_type, "The forest trains us all. Let's battle!",
                 "FullPoke.trainer_battle(:#{key2})", "Every region's rare Pokémon pass through here.")
    end
    4.times do |i|
      x, y = free_spot(map, 3 + rng.rand(FW - 6), 3 + rng.rand(FH - 6))
      item = FOREST_ITEMS[rng.rand(FOREST_ITEMS.length)]
      i.even? ? ev_item_ball(map, x, y, item) : ev_hidden_item(map, x, y, item)
    end
    cut_spots.first(3).each do |x, y|
      next if event_at?(map, x, y)
      new_event(map, 'FP: CutTree', x, y, [new_page(trigger: 0, graphic: 'Object tree 1', list: EventList.build {
        if_script('pbCut') { script('pbEraseThisEvent') }
      })])
    end
    save_map(ids[key], map)
    meta(ids[key], FOREST_NAMES[key], battleback: 'forest')
    WORLD[:forest_maps] << ids[key]
    WORLD[:encounters] << { map: ids[key], forest: true }
  end
  # Seamless connections between neighbouring forest maps
  FOREST_LAYOUT.each do |k, (gx, gy)|
    FOREST_LAYOUT.each do |k2, (gx2, gy2)|
      if gx2 == gx + 1 && gy2 == gy
        CONNECTIONS << "#{ids[k]},East,0,#{ids[k2]},West,0"
      elsif gy2 == gy + 1 && gx2 == gx
        CONNECTIONS << "#{ids[k]},South,0,#{ids[k2]},North,0"
      end
    end
  end
end
FOREST_TRAINERS = []

# Opens a 3-wide way from the edge into the maze.
def carve_edge(cv, side, along)
  case side
  when :left   then cv.open(0, along - 1, 6, 3)
  when :right  then cv.open(FW - 6, along - 1, 6, 3)
  when :top    then cv.open(along - 1, 0, 3, 6)
  when :bottom then cv.open(along - 1, FH - 6, 3, 6)
  end
end

# [gate x, gate y, inner arrival tile, facing direction]
def gate_coords(side, along)
  case side
  when :left   then [0, along, [2, along], 6]
  when :right  then [FW - 1, along, [FW - 3, along], 4]
  when :top    then [along, 0, [along, 2], 2]
  when :bottom then [along, FH - 1, [along, FH - 3], 8]
  end
end

#-------------------------------------------------------------------------------
# Region circuits
#-------------------------------------------------------------------------------
REAL_START = { johto: 7, hoenn: 122, sinnoh: 209, unova: 463, kanto: 23 }
REGION_ROOT = { johto: 3, hoenn: 4, sinnoh: 408, unova: 32, kalos: 396, alola: 583, galar: 584 }
REGION_BGM = {
  johto: ['Route 2', 'Cedolan City'], hoenn: ['Route 3', 'Lerucean Town'], sinnoh: ['Route 1', 'Lappet Town'],
  unova: ['Route 2', 'Cedolan City'], kalos: ['Route 3', 'Lerucean Town'], alola: ['Islands', 'Lappet Town'],
  galar: ['Route 1', 'Cedolan City'], paldea: ['Route 3', 'Lerucean Town']
}
SW_, SH_ = 42, 60

def region_root(region)
  return REGION_ROOT[region] if REGION_ROOT[region]
  id = IDS.get("#{region}/folder", name: "#{FullPoke.region(region).name} Region", parent: 0)
  save_map(id, WG.new_map(20, 15, WG::OUT_TS)) unless SAVED[id]
  WORLD[:roots][id] = region
  id
end

# Interiors (tileset 2): a Pokémon Center per town (0 = start town, 9 = League) and the lab.
def build_interiors(region, root)
  name = "#{FullPoke.region(region).name} PokeCenters"
  id = IDS.get("#{region}/interiors", name: name, parent: root, placeholder: name)
  _, sx, sy, rw, rh = WG::ROOMS[:pc]
  cols = 4
  map = WG.new_map(cols * 18, 3 * 16, 2)
  WG.fill_void(map, 384)
  rooms = {}
  (0..9).each do |n|
    ox = (n % cols) * 18 + 1; oy = (n / cols) * 16 + 2
    WG.copy_room(map, :pc, ox, oy)
    rooms[n] = { origin: [ox, oy], door: [ox + 7, oy + 9], arrive: [ox + 7, oy + 8] }
  end
  lx, ly = 3 * 18 + 1, 2 * 16 + 1
  WG.copy_room(map, :lab, lx, ly, copy_events: false)
  rooms[:lab] = { origin: [lx, ly], door: [lx + 6, ly + 13], arrive: [lx + 6, ly + 12] }
  [map, id, rooms]
end

def mart_items(n)
  base = %i[POKEBALL POTION ANTIDOTE PARALYZEHEAL AWAKENING ESCAPEROPE REPEL]
  base += %i[GREATBALL SUPERPOTION BURNHEAL ICEHEAL SUPERREPEL] if n >= 3
  base += %i[ULTRABALL HYPERPOTION REVIVE FULLHEAL MAXREPEL] if n >= 5
  base += %i[MAXPOTION FULLRESTORE] if n >= 7
  base.select { |i| GameData::Item.exists?(i) }
end

# Gyms and League (tileset 7): eight Gym rooms on the left, a copy of the Kanto
# League's rooms on the right.
def build_gyms(region, root)
  name = "#{FullPoke.region(region).name} Gyms"
  id = IDS.get("#{region}/gyms", name: name, parent: root, placeholder: name)
  league_src = WG.load_map(292)
  map = WG.new_map(4 * 15 + 4 + league_src.width, [2 * 18 + 2, league_src.height].max, 7)
  WG.fill_void(map, 48)   # the "Black" autotile: impassable, unlike tile 384 in this tileset
  gyms = {}
  (1..8).each do |n|
    ox = ((n - 1) % 4) * 15 + 1; oy = ((n - 1) / 4) * 18 + 1
    WG.copy_room(map, :gym, ox, oy, copy_events: false)
    gyms[n] = { origin: [ox, oy], door: [ox + 6, oy + 15], arrive: [ox + 6, oy + 14], leader: [ox + 6, oy + 5] }
  end
  # League: copy map 292 and find its rooms (connected non-void areas)
  lox = 4 * 15 + 4
  league_src.height.times do |y|
    league_src.width.times do |x|
      3.times { |z| map.data[lox + x, y, z] = league_src.data[x, y, z] }
    end
  end
  solidify_void(map)
  rooms = league_rooms(league_src).map { |b| [b[0] + lox, b[1], b[2], b[3]] }
  [map, id, gyms, rooms]
end

# The League map's empty space is tile 48 (solid) or 384 (black but walkable in
# this tileset). Makes all of it solid so nobody can wander off a room.
def solidify_void(map)
  map.height.times do |y|
    map.width.times do |x|
      next if map.data[x, y, 1] != 0 || map.data[x, y, 2] != 0
      map.data[x, y, 0] = 48 if map.data[x, y, 0] == 384
    end
  end
end

def league_rooms(src)
  void = ->(x, y) { [48, 384].include?(src.data[x, y, 0]) && src.data[x, y, 1] == 0 && src.data[x, y, 2] == 0 }
  seen = {}
  rooms = []
  src.height.times do |y|
    src.width.times do |x|
      next if seen[[x, y]] || void.call(x, y)
      stack = [[x, y]]; minx = maxx = x; miny = maxy = y; count = 0
      until stack.empty?
        px, py = stack.pop
        next if px < 0 || py < 0 || px >= src.width || py >= src.height || seen[[px, py]] || void.call(px, py)
        seen[[px, py]] = true; count += 1
        minx = [minx, px].min; maxx = [maxx, px].max; miny = [miny, py].min; maxy = [maxy, py].max
        [[1, 0], [-1, 0], [0, 1], [0, -1]].each { |dx, dy| stack << [px + dx, py + dy] }
      end
      rooms << [minx, miny, maxx - minx + 1, maxy - miny + 1] if count > 60
    end
  end
  rooms.sort_by { |r| -r[1] }   # bottom room first: the order you walk through them
end

# A stage: route (south half) and town (north half).
def build_stage(region, n, root, data, interiors, gyms, prev_exit)
  reg = FullPoke.region(region)
  st = data[:stages][n - 1]
  town = st[:town]
  id = IDS.get("#{region}/stage#{n}", name: town, parent: root, placeholder: town)
  rng = Random.new(Zlib.crc32("#{region}/stage/#{n}"))
  cv = WG::Canvas.new(SW_, SH_)
  # Route: three switchback bands
  cv.open(18, 54, 3, 6)            # entry from the south
  cv.open(6, 50, 30, 5)            # band A
  cv.open(30, 42, 6, 9)            # A -> B (right)
  cv.open(6, 40, 30, 5)            # band B
  cv.open(6, 32, 6, 9)             # B -> C (left)
  cv.open(6, 30, 30, 5)            # band C
  cv.open(18, 24, 6, 7)            # C -> town
  cv.open(3, 4, 36, 21)            # town
  cv.open(18, 0, 3, 5)             # exit north
  cv.grass(21, 51, 12, 3)
  cv.grass(9, 41, 12, 3)
  cv.grass(21, 31, 12, 3)
  pc_door = cv.stamp(:pc, 6, 14)
  gym_door = cv.stamp(:gym, 27, 5)
  house_door = cv.stamp(:house, 30, 16)
  map = cv.render
  WG.set_bgm(map, REGION_BGM[region][1])
  # Warps: south back to the previous map, north to the next (badge-gated)
  3.times do |i|
    ev_warp(map, 18 + i, 59, prev_exit[0], prev_exit[1], prev_exit[2], 2, name: 'FP: South exit', se: false)
  end
  pc = interiors[:rooms][n]
  ev_warp(map, pc_door[0], pc_door[1], interiors[:id], pc[:arrive][0], pc[:arrive][1], 8, name: 'FP: PC door')
  ev_warp(interiors[:map], pc[:door][0], pc[:door][1], id, pc_door[0], pc_door[1] + 1, 2, name: 'FP: PC exit')
  ev_npc(interiors[:map], *free_spot(interiors[:map], pc[:origin][0] + 3, pc[:origin][1] + 6), 'FP: Clerk', 'NPC 19', [])
    .pages[0].list = EventList.build { text('Welcome! How may I help you?'); script("pbPokemonMart(#{mart_items(n).inspect})") }
  g = gyms[:rooms][n]
  ev_warp(map, gym_door[0], gym_door[1], gyms[:id], g[:arrive][0], g[:arrive][1], 8, name: 'FP: Gym door')
  ev_warp(gyms[:map], g[:door][0], g[:door][1], id, gym_door[0], gym_door[1] + 1, 2, name: 'FP: Gym exit')
  populate_gym(region, n, gyms)
  leader = FullPoke::Teams.get(st[:leader])
  # Route trainers, items
  [[8, 52, 6], [33, 42, 4], [8, 32, 6]].each_with_index do |(x, y, dir), i|
    tr_type, gfx, = FullPoke::Circuit.route_trainer_class(region, n, i)
    ev_trainer(map, x, y, 4, gfx, dir, tr_type, 'Hey! You look like a Trainer!',
               "FullPoke.route_trainer_battle(:#{region}, #{n}, #{i})", 'Good luck at the Gym!')
  end
  ev_item_ball(map, 6, 54, %i[POTION POKEBALL SUPERPOTION GREATBALL HYPERPOTION ULTRABALL REVIVE FULLRESTORE][n - 1])
  ev_hidden_item(map, 34, 44, %i[ETHER RARECANDY PPUP NUGGET RARECANDY MAXETHER PPMAX RARECANDY][n - 1])
  ev_npc(map, house_door[0], house_door[1], 'FP: House door', '', ['The door is locked. Nobody seems to be home.'])
  ev_sign(map, 16, 24, 'FP: Town sign', ["#{town}", "#{reg.name} region. Gym Leader: #{leader[:name]}."])
  # Story battles in town
  (st[:extras] || []).each_with_index do |key, i|
    defn = FullPoke::Teams.get(key)
    ex, ey = [[14, 6], [24, 6], [12, 10]][i]
    nm = defn[:name] || reg.rival_name
    new_event(map, "FP: #{nm}", ex, ey, [
      new_page(trigger: 0, graphic: "trainer_#{defn[:tr_type]}", list: EventList.build {
        text("#{nm}: You won't get past me that easily!")
        if_script("FullPoke::Circuit.extra_battle(:#{region}, :#{key})") { self_switch('A', true) }
      }),
      new_page(trigger: 0, graphic: "trainer_#{defn[:tr_type]}", self_switch: 'A', list: EventList.build { text("#{nm}: Next time will be different.") })
    ])
  end
  ev_npc(map, 12, 22, 'FP: Local', 'NPC 07', ["#{leader[:name]} is the Leader of the #{town} Gym.",
                                              (leader[:types] ? "I hear they use #{leader[:types].map { |t| GameData::Type.get(t).name }.join('/')}-type Pokémon." : "They're tough!")])
  WORLD[:encounters] << { map: id, circuit: [region, n] }
  meta(id, town, battleback: 'field')
  [id, map]
end

# Victory Road: one more route, then the League.
def build_victory_road(region, root, data, prev_exit, league_entry)
  name = 'Victory Road'
  id = IDS.get("#{region}/victoryroad", name: "#{FullPoke.region(region).name} Victory Road", parent: root, placeholder: name)
  cv = WG::Canvas.new(SW_, 40)
  cv.open(18, 34, 3, 6); cv.open(6, 28, 30, 6); cv.open(30, 16, 6, 13); cv.open(6, 12, 30, 6); cv.open(6, 4, 6, 9)
  cv.open(6, 2, 30, 4); cv.open(18, 0, 3, 3)
  cv.grass(9, 29, 18, 3); cv.grass(15, 13, 15, 3)
  map = cv.render
  WG.set_bgm(map, 'Cave')
  3.times { |i| ev_warp(map, 18 + i, 39, prev_exit[0], prev_exit[1], prev_exit[2], 2, name: 'FP: South exit', se: false) }
  3.times do |i|
    ev_warp(map, 18 + i, 0, league_entry[0], league_entry[1], league_entry[2], 8, name: 'FP: League entrance')
  end
  [[10, 30, 6], [33, 20, 4], [10, 14, 6]].each_with_index do |(x, y, dir), i|
    tr_type, gfx, = FullPoke::Circuit.route_trainer_class(region, 9, i)
    ev_trainer(map, x, y, 4, gfx, dir, tr_type, 'Only the best reach the League!',
               "FullPoke.route_trainer_battle(:#{region}, 9, #{i})", 'Go on. The League is just ahead.')
  end
  if (rk = data[:rivals][9])
    defn = FullPoke::Teams.get(rk)
    nm = FullPoke.region(region).rival_name
    new_event(map, "FP: #{nm}", 24, 4, [
      new_page(trigger: 0, graphic: "trainer_#{defn[:tr_type]}", list: EventList.build {
        text("#{nm}: One last battle before the League!")
        if_script("FullPoke::Circuit.extra_battle(:#{region}, :#{rk})") { self_switch('A', true) }
      }),
      new_page(trigger: 0, graphic: "trainer_#{defn[:tr_type]}", self_switch: 'A', list: EventList.build { text("#{nm}: Go win it all!") })
    ])
  end
  # The region's legendary waits here once the region is completed
  new_event(map, 'FP: Legendary', 30, 3, [new_page(trigger: 0, graphic: 'Object ball', list: EventList.build {
    script("FullPoke::Circuit.legendary(:#{region})")
  })])
  ev_item_ball(map, 7, 3, :MAXREVIVE)
  WORLD[:encounters] << { map: id, circuit: [region, 9] }
  meta(id, "#{FullPoke.region(region).name} Victory Road", battleback: 'field')
  [id, map]
end

def place_league(region, data, gyms_id, gmap, rooms, vroad_id, back: nil)
  rooms = rooms.first(5)   # bottom -> top: 4 Elite Four rooms, then the Champion's
  keys = data[:league] + [data[:champion]]
  entry = nil
  rooms.each_with_index do |(rx, ry, rw, rh), i|
    cx = rx + rw / 2
    bottom = free_spot(gmap, cx, ry + rh - 2, box: [rx, ry, rw, rh])
    # Work from what is actually walkable from the entrance
    inside = ->(p) { p[0] >= rx && p[1] >= ry && p[0] < rx + rw && p[1] < ry + rh }
    reach = reachable_from(gmap, *bottom).select { |p, _| inside.call(p) }
    top = reach.keys.reject { |p| event_at?(gmap, *p) }.min_by { |x, y| [y, (x - cx).abs] }
    target_y = ry + (rh / 2) - 1
    mid = reach.keys.reject { |p| p == bottom || p == top || event_at?(gmap, *p) }
               .sort_by { |x, y| (x - cx).abs + (y - target_y).abs }
               .find do |p|
                 # The member mustn't block the way from the entrance to the next door
                 seen = { bottom => true }
                 q = [bottom]
                 until q.empty?
                   c = q.shift
                   [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
                     n = [c[0] + dx, c[1] + dy]
                     next if seen[n] || n == p || !reach[n]
                     seen[n] = true
                     q << n
                   end
                 end
                 seen[top]
               end
    entry ||= [gyms_id, bottom[0], bottom[1]]
    if i == 0
      back_to = back || [vroad_id, 19, 1]
      new_event(gmap, 'FP: League exit', bottom[0], bottom[1] + 1, [new_page(trigger: 1, list: EventList.build {
        transfer(back_to[0], back_to[1], back_to[2], 2)
      })]) if passable_tile?(gmap, bottom[0], bottom[1] + 1)
    end
    defn = FullPoke::Teams.get(keys[i])
    nm = defn[:name] || FullPoke.region(region).rival_name || 'Champion'
    new_event(gmap, "FP: League battle #{nm}", mid[0], mid[1], [new_page(trigger: 0, graphic: "trainer_#{defn[:tr_type]}", direction: 2, list: EventList.build {
      text("#{nm}: Welcome to the #{FullPoke.region(region).name} League. Let's begin!")
      script("FullPoke::Circuit.league_battle(:#{region}, #{i})")
    })])
    if i == 4 && data[:final]
      fdefn = FullPoke::Teams.get(data[:final])
      fnm = fdefn[:name] || FullPoke.region(region).rival_name
      fx, fy = free_spot(gmap, mid[0] + 2, mid[1], box: [rx, ry, rw, rh], avoid: [bottom, top])
      new_event(gmap, "FP: Final #{fnm}", fx, fy, [new_page(trigger: 0, graphic: "trainer_#{fdefn[:tr_type]}", list: EventList.build {
        if_script("FullPoke::Circuit.league_cleared?(:#{region}, 4)", otherwise: proc { text("#{fnm}: Beat the Champion first. Then it's our turn!") }) do
          text("#{fnm}: This is it. Our final battle!")
          script("FullPoke::Circuit.league_battle(:#{region}, 5)")
        end
      })])
    end
    # Door to the next room (or the Hall of Fame message for the last)
    nxt = rooms[i + 1]
    if nxt
      nb = free_spot(gmap, nxt[0] + nxt[2] / 2, nxt[1] + nxt[3] - 2, box: nxt)
      new_event(gmap, 'FP: League door', top[0], top[1], [new_page(trigger: 1, list: EventList.build {
        if_script("FullPoke::Circuit.league_cleared?(:#{region}, #{i})", otherwise: proc { text('The door is sealed. Win the battle in this room first.') }) do
          transfer(gyms_id, nb[0], nb[1], 8)
        end
      })])
      new_event(gmap, 'FP: League back', nb[0], nb[1] + 1, [new_page(trigger: 1, list: EventList.build {
        transfer(gyms_id, top[0], top[1] + 1, 2)
      })]) if passable_tile?(gmap, nb[0], nb[1] + 1)
    else
      last = keys.length - 1 + (data[:final] ? 1 : 0)
      new_event(gmap, 'FP: Hall of Fame', top[0], top[1], [new_page(trigger: 1, list: EventList.build {
        if_script("FullPoke.completed?(:#{region})", otherwise: proc { text('The way to the Hall of Fame opens for the Champion.') }) do
          text('Your names and your Pokémon are recorded in the Hall of Fame.')
          script("FullPoke.go_home(:#{region})")
        end
      })])
    end
  end
  entry
end

def build_start_town(region, root, data, interiors, stage1)
  reg = FullPoke.region(region)
  real = REAL_START[region]
  if real
    id = real
    map = WG.load_map(id)
    remove_fp_events(map)
    cx, cy = map.width / 2, map.height / 2
    # Use the largest walkable area of the town
    best = nil
    (0...map.height).step(3) do |yy|
      (0...map.width).step(3) do |xx|
        next if !passable_tile?(map, xx, yy) || (best && best[[xx, yy]])
        r = reachable_from(map, xx, yy)
        best = r if !best || r.size > best.size
      end
    end
    arrive = free_spot(map, 3, cy, reach: best)
    taken = [arrive]
    gate = free_spot(map, arrive[0] - 1, arrive[1], avoid: taken, reach: best); taken << gate
    home = free_spot(map, cx - 3, cy + 2, avoid: taken, reach: best); taken << home
    prof = free_spot(map, cx, cy, avoid: taken, reach: best); taken << prof
    exitp = free_spot(map, cx, 1, avoid: taken, reach: best); taken << exitp
    pcp = free_spot(map, cx + 3, cy + 2, avoid: taken, reach: best)
  else
    id = IDS.get("#{region}/start", name: reg.start_town, parent: root, placeholder: reg.start_town)
    cv = WG::Canvas.new(SW_, 34)
    cv.open(3, 4, 36, 26); cv.open(0, 14, 3, 3); cv.open(18, 0, 3, 5)
    cv.grass(27, 24, 9, 3)
    house = cv.stamp(:house, 8, 7)
    lab = cv.stamp(:house2, 27, 7)
    pcd = cv.stamp(:pc, 8, 19)
    map = cv.render
    arrive = [2, 15]; gate = [0, 15]
    home = [house[0], house[1] + 1]
    prof = nil
    exitp = [19, 0]
    pcp = pcd
    ev_npc(map, house[0], house[1], 'FP: Home door', '', ['Mom: Be careful out there! Come home whenever you need a rest.'])
    lr = interiors[:rooms][:lab]
    ev_warp(map, lab[0], lab[1], interiors[:id], lr[:arrive][0], lr[:arrive][1], 8, name: 'FP: Lab door')
    ev_warp(interiors[:map], lr[:door][0], lr[:door][1], id, lab[0], lab[1] + 1, 2, name: 'FP: Lab exit')
    prof_map = interiors[:map]
    prof = free_spot(prof_map, lr[:origin][0] + 6, lr[:origin][1] + 4)
  end
  WG.set_bgm(map, REGION_BGM[region][1]) if !real
  # Forest gate (3 tiles where possible) and arrival
  ev_script_touch(map, gate[0], gate[1], 'FP: Forest gate', "FullPoke.gate_to_forest(:#{region})")
  ev_sign(map, *free_spot(map, arrive[0], arrive[1] - 1, avoid: [arrive]), 'FP: Forest sign',
          ['West: Interregional Forest', "Paths to every region's first town."])
  # Professor: starter, then the first rival battle
  prof_map ||= map
  rival = data[:rivals][0]
  new_event(prof_map, "FP: #{reg.professor}", prof[0], prof[1], [new_page(trigger: 0, graphic: 'trainer_PROFESSOR', list: EventList.build {
    if_script("FullPoke.state(:#{region}).starter", otherwise: proc {
      text("#{reg.professor}: Welcome to the #{reg.name} region! You'll need a partner for your journey.")
      script("FullPoke.give_starter(:#{region})")
      if rival
        text("#{reg.rival_name}: Hey! I got my Pokémon too. Let's see whose is stronger!")
        script("setBattleRule(\"canLose\")")
        script("FullPoke::Circuit.extra_battle(:#{region}, :#{rival}) || FullPoke.set_flag(:#{region}, :beat_#{rival})")
        text("#{reg.rival_name}: See you on the road!")
      end
      script('$player.heal_party')
    }) do
      text("#{reg.professor}: The Gyms of #{reg.name} are waiting. Use the Grove Compass to return to the forest any time.")
    end
  })])
  # PC (start town)
  pc = interiors[:rooms][0]
  if real
    new_event(map, 'FP: Nurse', pcp[0], pcp[1], [new_page(trigger: 0, graphic: 'NPC 16', list: EventList.build {
      text('Let me heal your Pokémon.')
      script('pbSetPokemonCenter')
      recover_all
      play_me('Pkmn healing')
      text('Your Pokémon are fighting fit!')
    })])
  else
    ev_warp(map, pcp[0], pcp[1], interiors[:id], pc[:arrive][0], pc[:arrive][1], 8, name: 'FP: PC door')
    ev_warp(interiors[:map], pc[:door][0], pc[:door][1], id, pcp[0], pcp[1] + 1, 2, name: 'FP: PC exit')
  end
  # North exit to stage 1, once the player has a starter
  (real ? [exitp] : [[18, 0], [19, 0], [20, 0]]).each do |ex, ey|
    ev_warp(map, ex, ey, stage1, 19, SH_ - 2, 8, name: 'FP: Exit to route',
            script_cond: "FullPoke.state(:#{region}).starter", fail_text: "#{reg.professor} wants to see you before you leave town.")
  end
  meta(id, reg.start_town, battleback: 'field') if !real
  dest_from_stage = real ? [id, exitp[0], exitp[1] + 1] : [id, 19, 1]
  WORLD[:regions][region] = { arrival: [id, arrive[0], arrive[1], 6], home: [id, home[0], home[1], 2], start_map: id }
  [id, map, dest_from_stage]
end

GYM_TRAINERS = []

def build_region(region)
  data = FullPoke::Circuit.get(region)
  root = region_root(region)
  imap, iid, irooms = build_interiors(region, root)
  interiors = { map: imap, id: iid, rooms: irooms }
  gmap, gid, grooms, lrooms = build_gyms(region, root)
  gyms = { map: gmap, id: gid, rooms: grooms }
  # Reserve IDs first so maps can point at each other
  stage_ids = (1..8).map { |n| IDS.get("#{region}/stage#{n}", name: data[:stages][n - 1][:town], parent: root, placeholder: data[:stages][n - 1][:town]) }
  vr_id = IDS.get("#{region}/victoryroad", name: "#{FullPoke.region(region).name} Victory Road", parent: root, placeholder: 'Victory Road')
  start_id, start_map, start_back = build_start_town(region, root, data, interiors, stage_ids[0])
  maps = {}
  prev = start_back
  (1..8).each do |n|
    nxt = n < 8 ? [stage_ids[n], 19, SH_ - 2] : [vr_id, 19, 38]
    sid, smap = build_stage(region, n, root, data, interiors, gyms, prev)
    # North exit: gated by the badge (and this town's story battles)
    3.times do |i|
      ev_warp(smap, 18 + i, 0, nxt[0], nxt[1], nxt[2], 8, name: 'FP: North exit', se: false,
              script_cond: "FullPoke.badge?(:#{region}, #{n - 1}) && FullPoke::Circuit.stage_extras_done?(:#{region}, #{n})",
              fail_text: "You need the #{data[:stages][n - 1][:badge]} (and to settle things in town) before going on.")
    end
    maps[sid] = smap
    prev = [sid, 19, 1]
  end
  league_entry = place_league(region, data, gid, gmap, lrooms, vr_id)
  vid, vmap = build_victory_road(region, root, data, prev, league_entry)
  # Pokémon Center 9: inside the League entrance? Keep it simple: heal at the
  # Victory Road gate with a nurse.
  new_event(vmap, 'FP: Nurse', 22, 38, [new_page(trigger: 0, graphic: 'NPC 16', list: EventList.build {
    text('The League is ahead. Let me heal your Pokémon.')
    script('pbSetPokemonCenter')
    recover_all
    play_me('Pkmn healing')
  })])
  maps.each { |sid, smap| save_map(sid, smap) }
  save_map(vid, vmap)
  save_map(start_id, start_map)
  save_map(iid, imap); meta(iid, "#{FullPoke.region(region).name} Pokémon Center", outdoor: false)
  save_map(gid, gmap); meta(gid, "#{FullPoke.region(region).name} Gyms and League", outdoor: false, battleback: 'indoor1')
  WORLD[:regions][region][:league] = league_entry
end

#-------------------------------------------------------------------------------
# Kanto: a forest gate in Pallet Town (the Kanto opening itself is unchanged).
#-------------------------------------------------------------------------------
def build_kanto_gate
  map = WG.load_map(23)
  remove_fp_events(map)
  arrive = free_spot(map, 2, 10)
  gate = free_spot(map, arrive[0] - 1, arrive[1], avoid: [arrive])
  ev_script_touch(map, gate[0], gate[1], 'FP: Forest gate', 'FullPoke.gate_to_forest(:kanto)')
  ev_sign(map, *free_spot(map, arrive[0], arrive[1] + 1, avoid: [arrive, gate]), 'FP: Forest sign',
          ['West: Interregional Forest', "Paths to every region's first town."])
  save_map(23, map)
  WORLD[:regions][:kanto] = { arrival: [23, arrive[0], arrive[1], 6], home: nil, start_map: 23 }
end


#-------------------------------------------------------------------------------
# Kanto (the map pack's own maps): Gym Leaders 2-8 in the existing Gym rooms,
# Route 23 -> Indigo Plateau -> the existing Kanto League map, story battles and
# Mewtwo. Brock and the opening are untouched (built by build_kanto_opening.rb).
#-------------------------------------------------------------------------------
KANTO_GYM_ROOMS = {   # stage => arrival tile in map 177 (from the town doors)
  2 => [64, 20], 3 => [93, 21], 4 => [125, 20], 5 => [156, 23], 6 => [75, 94], 7 => [29, 60], 8 => [18, 24]
}
KANTO_EXTRAS = [   # [map, near x, near y, trainer key, line]
  [26, 24, 6, :kanto_rival_cerulean, "Hey! Let's see how your Pokémon are doing!"],
  [24, 26, 38, :kanto_rival_ssanne, "Bonjour! Fancy meeting you here. Let's battle!"],
  [29, 34, 22, :kanto_giovanni_hideout, "So you've come this far. I am Giovanni, leader of Team Rocket."],
  [31, 24, 18, :kanto_rival_silph, "What kept you? Let me show you how strong I've become!"],
  [55, 30, 20, :kanto_rival_route22, "I'm heading to the Pokémon League. Not before I beat you, though!"]
]

def build_kanto
  data = FullPoke::Circuit.get(:kanto)
  gm = WG.load_map(177)
  remove_fp_events(gm)
  gm.events.delete_if { |_, e| e.name.strip == 'Misty' }   # map-pack placeholder
  KANTO_GYM_ROOMS.each do |n, (ax, ay)|
    reach = reachable_from(gm, ax, ay, void_tile: 384)
    spot = reach.keys.reject { |p| event_at?(gm, *p) }.min_by { |x, y| [y, (x - ax).abs] }
    leader = FullPoke::Teams.get(data[:stages][n - 1][:leader])
    new_event(gm, "FP: Leader #{leader[:name]}", spot[0], spot[1], [new_page(trigger: 0, graphic: "trainer_#{leader[:tr_type]}", list: EventList.build {
      text("I'm #{leader[:name]}, the Gym Leader. Let's see what you can do!")
      if_script("FullPoke::Circuit.challenge(:kanto, #{n})") { text('You battled splendidly.') }
    })])
  end
  save_map(177, gm)
  # Indigo Plateau and the League
  league = WG.load_map(292)
  remove_fp_events(league)
  solidify_void(league)
  rooms = league_rooms(league)
  indigo = WG.load_map(33)
  remove_fp_events(indigo)
  entry = place_league(:kanto, data, 292, league, rooms, nil, back: [33, 11, 7])
  door = indigo.events.values.find { |e| e.pages[0].list.any? { |c| c.code == 201 } }
  if door
    door.pages.each { |pg| pg.list.each { |c| c.parameters[1, 3] = entry[0, 3] if c.code == 201 } }
  end
  arrive = free_spot(indigo, 11, indigo.height - 3)
  new_event(indigo, 'FP: Nurse', *free_spot(indigo, 14, 9, avoid: [arrive]), [new_page(trigger: 0, graphic: 'NPC 16', list: EventList.build {
    text('Welcome to the Indigo Plateau. Let me heal your Pokémon.')
    script('pbSetPokemonCenter')
    recover_all
    play_me('Pkmn healing')
  })])
  save_map(33, indigo)
  save_map(292, league)
  meta(292, 'Pokémon League', outdoor: false, battleback: 'indoor1') if false
  r23 = WG.load_map(56)
  remove_fp_events(r23)
  gx, gy = free_spot(r23, 17, 1)
  new_event(r23, 'FP: To Indigo Plateau', gx, gy, [new_page(trigger: 1, list: EventList.build {
    if_script('FullPoke.region_badge_count(:kanto) >= 8', otherwise: proc { text('Only Trainers with all eight Kanto Badges may pass to the Indigo Plateau.') }) do
      play_se('Door exit')
      transfer(33, arrive[0], arrive[1], 8)
    end
  })])
  ev_sign(r23, *free_spot(r23, gx + 2, gy + 1), 'FP: Sign', ['Route 23', 'North: Indigo Plateau. Eight Badges required.'])
  save_map(56, r23)
  # Story battles (optional in Kanto) and Mewtwo
  KANTO_EXTRAS.each do |map_id, nx, ny, key, line|
    m = SAVED[map_id] || WG.load_map(map_id)
    remove_fp_events(m) if !SAVED[map_id]
    defn = FullPoke::Teams.get(key)
    nm = defn[:name] || 'Rival'
    x, y = free_spot(m, nx, ny)
    new_event(m, "FP: #{nm} (#{key})", x, y, [
      new_page(trigger: 0, graphic: "trainer_#{defn[:tr_type]}", list: EventList.build {
        text(line)
        if_script("FullPoke::Circuit.extra_battle(:kanto, :#{key})") { self_switch('A', true) }
      }),
      new_page(trigger: 0, graphic: "trainer_#{defn[:tr_type]}", self_switch: 'A', list: EventList.build { text('...') })
    ])
    save_map(map_id, m)
  end
  cer = SAVED[26] || WG.load_map(26)
  new_event(cer, 'FP: Legendary', *free_spot(cer, 3, 13), [new_page(trigger: 0, graphic: 'Object ball', list: EventList.build {
    script('FullPoke::Circuit.legendary(:kanto)')
  })])
  save_map(26, cer)
  WORLD[:regions][:kanto][:league] = entry
end


#-------------------------------------------------------------------------------
# New game: after naming, choose the starting region and mode. Kanto continues
# with the existing opening (Oak stops the player in Pallet Town); any other
# region sends the player to its first town.
#-------------------------------------------------------------------------------
def patch_intro
  map = SAVED[1] || WG.load_map(1)
  ev = map.events.values.find { |e| e.pages[0].list.any? { |c| c.code == 355 && c.parameters[0].to_s.include?('pbTrainerName') } }
  return if !ev
  list = ev.pages[0].list
  return if list.any? { |c| [111, 355].include?(c.code) && c.parameters.to_s.include?('intro_choose_region') }
  i = list.index { |c| c.code == 121 && c.indent == 0 && c.parameters[0] == 61 }
  return if !i || list[i + 1]&.code != 201
  kanto_switch = list[i]
  kanto_transfer = list[i + 1]
  branch = EventList.build do
    if_script('FullPoke.intro_choose_region == :kanto', otherwise: proc { script('FullPoke.intro_go_to_start_region') }) do
      cmd(121, kanto_switch.parameters)
      cmd(201, kanto_transfer.parameters)
    end
  end
  branch.pop   # drop the list terminator
  list[i, 2] = branch
  save_map(1, map)
end

# Oak's starters get the continuous offset like every other Pokémon in Kanto.
def patch_kanto_starters
  map = SAVED[175] || WG.load_map(175)
  changed = false
  map.events.each_value do |ev|
    ev.pages.each do |pg|
      pg.list.each do |c|
        next if c.code != 111 || c.parameters[0] != 12
        if c.parameters[1] =~ /\ApbAddPokemon\(:(\w+), 5\)\z/
          c.parameters[1] = "pbAddPokemon(:#{$1}, FullPoke.scale_level(5, :kanto))"
          changed = true
        end
      end
    end
  end
  save_map(175, map) if changed
end

# Tall grass that the map pack's tilesets never tagged, so wild Pokémon can appear in it.
GRASS_TAGS = { 23 => [390, 391] }
def tag_grass
  GRASS_TAGS.each { |ts, tiles| tiles.each { |t| TILESETS[ts].terrain_tags[t] = 2 } }
end

#-------------------------------------------------------------------------------
build_forest
build_kanto_gate
patch_intro
patch_kanto_starters
build_kanto
tag_grass
FullPoke::Circuit.region_ids.each do |r|
  next if r == :kanto
  if GEO_SPEC[r]
    Geo.drop_pack_connections('PBS/map_connections.txt', GEO_SPEC[r][:maps].values)
    (1..8).each { |n| IDS.release("#{r}/stage#{n}") }
    IDS.release("#{r}/start")
    build_geo_region(r)
  else
    build_region(r)
  end
end
save_data(TILESETS, 'Data/Tilesets.rxdata')
SAVED.each { |id, map| save_data(map, WG.map_path(id)) }
IDS.save

# Data file read by the plugin
def ruby_lit(v)
  case v
  when Hash then "{ " + v.map { |k, x| "#{ruby_lit(k)} => #{ruby_lit(x)}" }.join(", ") + " }"
  when Array then "[" + v.map { |x| ruby_lit(x) }.join(", ") + "]"
  when Symbol then ":#{v}"
  when String then v.inspect
  when nil then "nil"
  else v.to_s
  end
end
trainers = FOREST_TRAINERS.map { |k, party| "  FullPoke::Teams.register(key: :#{k}, region: :forest, role: :trainer, tr_type: :BUGCATCHER, name: \"Forest Trainer\", party: #{party.inspect}, lose_text: \"The forest has much to teach.\")" }
gym_tr = GYM_TRAINERS.map { |k, r, party, i| "  FullPoke::Teams.register(key: :#{k}, region: :#{r}, role: :trainer, tr_type: :#{i == 0 ? 'COOLTRAINER_M' : 'COOLTRAINER_F'}, name: \"#{i == 0 ? 'Gym Trainer' : 'Gym Trainer'}\", party: #{party.inspect}, lose_text: \"Our Leader is stronger than me!\")" }
File.write('Plugins/FullPoke Core/091_World_Generated.rb', <<~RUBY)
  #===============================================================================
  # GENERATED by tools/headless/build_world.rb - don't edit by hand; edit the
  # builder or the region data and rebuild.
  #===============================================================================
  module FullPoke
    WORLD_DATA = #{ruby_lit(WORLD)}
  end

  #{trainers.join("\n")}
  #{gym_tr.join("\n")}
RUBY

# PBS: map metadata and connections for generated maps (between markers)
def replace_block(path, lines)
  text = File.read(path, encoding: 'bom|utf-8')
  b = "# >>> FullPoke generated (tools/headless/build_world.rb) >>>"
  e = "# <<< FullPoke generated <<<"
  text = text.sub(/\n?#{Regexp.escape(b)}.*#{Regexp.escape(e)}\n?/m, "\n")
  text = text.rstrip + "\n" + b + "\n" + lines.join("\n") + "\n" + e + "\n"
  File.write(path, text)
end
meta_lines = METADATA.sort.map { |id, lines| "#-------------------------------\n[#{format('%03d', id)}]\n#{lines.join("\n")}" }
replace_block('PBS/map_metadata.txt', meta_lines)
replace_block('PBS/map_connections.txt', CONNECTIONS)
GEO_WARNINGS.each { |w| puts "WARNING: #{w}" }
puts "World built: #{SAVED.size} maps saved, #{WORLD[:encounters].size} encounter tables, IDs in world_ids.json"
