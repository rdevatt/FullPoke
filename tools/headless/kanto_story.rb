# Kanto after Brock, built into the map pack's own maps (called from
# build_world.rb's build_kanto). Three parts:
#
# 1. Repairs. The pack's Kanto came from an older version whose map IDs don't
#    match ours: many doors, gates, ladders and stairs pointed at Sinnoh or
#    Sevii maps, and some map connections were missing or wrong. Lavender Town,
#    Rock Tunnel, Routes 12-14, 17 and 20 and Victory Road were unreachable.
#    Pack warps are re-pointed in place (they keep their names); new ones are
#    "FP: " events like everything else generated.
# 2. The story (see Plugins/FullPoke Core/105_Kanto_Story.rb): S.S. Anne, Rocket
#    Hideout, Pokémon Tower, Snorlax, Saffron's gates, Silph Co., HMs, Victory
#    Road.
# 3. Gym trainers in Gyms 2-8.
#
# Every step checks on-foot reachability on the map it edits, so a layout
# change in the pack breaks the build instead of the game.

# A Kanto map to edit: the copy already being built, or a fresh one without its
# old generated events.
def kmap(id)
  return SAVED[id] if SAVED[id]
  m = WG.load_map(id)
  remove_fp_events(m)
  SAVED[id] = m
end

def warp_cmds(ev) = ev.pages.flat_map { |pg| pg.list.select { |c| c.code == 201 && c.parameters[0] == 0 } }

def warp_event_at(map_id, x, y)
  kmap(map_id).events.values.find { |e| e.x == x && e.y == y && !warp_cmds(e).empty? }
end

# A free walkable tile next to (x, y), preferring below, then above, the sides.
def beside(map_id, x, y, order = [[0, 1], [0, -1], [-1, 0], [1, 0]])
  m = kmap(map_id)
  order.each do |dx, dy|
    nx, ny = x + dx, y + dy
    return [nx, ny] if passable_tile?(m, nx, ny) && !event_at?(m, nx, ny)
  end
  free_spot(m, x, y + 1, avoid: [[x, y]])
end

# Points the pack's warp at (x, y) somewhere else.
def retarget(map_id, x, y, dest, dx, dy, dir = nil)
  ev = warp_event_at(map_id, x, y) or raise "Kanto: no warp at map #{map_id} (#{x},#{y})"
  warp_cmds(ev).each do |c|
    c.parameters[1] = dest; c.parameters[2] = dx; c.parameters[3] = dy
    c.parameters[4] = dir if dir
  end
end

# Two-way link between tiles a and b (each [map, x, y]): an existing pack warp
# on a tile is re-pointed, otherwise an "FP: " warp is added. Arrival is next
# to the other end.
def link(a, b, name: 'FP: Stairs', a_dir: nil, b_dir: nil)
  [[a, b, b_dir], [b, a, a_dir]].each do |(fm, fx, fy), (tm, tx, ty), dir|
    ax, ay = beside(tm, tx, ty)
    if warp_event_at(fm, fx, fy)
      retarget(fm, fx, fy, tm, ax, ay, dir)
    else
      ev_warp(kmap(fm), fx, fy, tm, ax, ay, dir || 2, name: name, se: name !~ /Ladder|Hole/)
    end
  end
end

# One-way warp (holes, ship gangways...).
def one_way(from, to, name:, dir: 2, cond: nil, fail_text: nil)
  fm, fx, fy = from
  tm, tx, ty = to
  ev_warp(kmap(fm), fx, fy, tm, tx, ty, dir, name: name, script_cond: cond, fail_text: fail_text)
end

def must_reach(map_id, from, to, what)
  r = reachable_from(kmap(map_id), *from)
  raise "Kanto: #{what} - (#{to.join(',')}) not reachable from (#{from.join(',')}) on map #{map_id}" if !r[to]
  r
end

# The tile on the way from a to b whose blocking cuts b off (nearest to a,
# at least `skip` steps in), for Snorlax, Cut trees and other obstacles.
def chokepoint(map_id, a, b, skip: 2, from_end: false)
  m = kmap(map_id)
  prev = { a => nil }
  q = [a]
  until q.empty?
    c = q.shift
    break if c == b
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      n = [c[0] + dx, c[1] + dy]
      next if prev.key?(n) || !passable_tile?(m, *n)
      prev[n] = c
      q << n
    end
  end
  raise "Kanto: no path #{a} -> #{b} on map #{map_id}" if !prev.key?(b)
  path = []
  c = b
  (path.unshift(c); c = prev[c]) while c
  cands = path[skip...-2]
  cands = cands.reverse if from_end
  cands.each do |t|
    next if event_at?(m, *t)
    seen = { a => true, t => true }
    q = [a]
    until q.empty?
      c = q.shift
      [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
        n = [c[0] + dx, c[1] + dy]
        next if seen[n] || !passable_tile?(m, *n)
        seen[n] = true
        q << n
      end
    end
    return t if !seen[b]
  end
  raise "Kanto: no chokepoint between #{a} and #{b} on map #{map_id}"
end

# Whether blocking these tiles separates b from a. On composite interior maps,
# void_tile marks the empty space between rooms (as in reachable_from).
def cuts_off?(map_id, tiles, a, b, void_tile: nil)
  m = kmap(map_id)
  return false if !reachable_from(m, *a, void_tile: void_tile)[b]
  seen = { a => true }
  tiles.each { |t| seen[t] = true }
  q = [a]
  until q.empty?
    c = q.shift
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      n = [c[0] + dx, c[1] + dy]
      next if seen[n] || !passable_tile?(m, *n)
      next if void_tile && m.data[n[0], n[1], 0] == void_tile && m.data[n[0], n[1], 1] == 0 && m.data[n[0], n[1], 2] == 0
      seen[n] = true
      q << n
    end
  end
  return !seen[b]
end

# How many tiles are reachable from `from` with `tile` blocked.
def floor_size_without(map_id, from, tile)
  m = kmap(map_id)
  seen = { from => true, tile => true }
  q = [from]
  until q.empty?
    c = q.shift
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      n = [c[0] + dx, c[1] + dy]
      next if seen[n] || !passable_tile?(m, *n)
      seen[n] = true
      q << n
    end
  end
  seen.size - 1
end

# A free tile reachable from `from`, near (x, y).
def spot_near(map_id, x, y, from, avoid: [])
  free_spot(kmap(map_id), x, y, reach: reachable_from(kmap(map_id), *from), avoid: avoid)
end

# Like spot_near, for someone who stays put for good (trainers stand where
# they battled): never on a tile that would cut `from` off from any of `keep`,
# counting the solid events already placed.
def standing_spot(map_id, x, y, from, keep, void_tile: nil, whole: false)
  m = kmap(map_id)
  reach = reachable_from(m, *from, void_tile: void_tile)
  solid = m.events.values.select { |e| e.pages[0] && !e.pages[0].through &&
                                       (e.pages[0].graphic.character_name != '' || e.pages[0].graphic.tile_id > 0) }
                     .map { |e| [e.x, e.y] }
  # tiles reachable from `from` with these blocked
  size = lambda do |blocked|
    seen = blocked.to_h { |t| [t, true] }.merge(from => true); q = [from]; n = 1
    until q.empty?
      c = q.shift
      [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
        t = [c[0] + dx, c[1] + dy]
        next if seen[t] || !reach[t]
        seen[t] = true; q << t; n += 1
      end
    end
    n
  end
  all = size.(solid)
  (0..60).each do |r|
    (-r..r).flat_map { |dx| [[x + dx, y + r - dx.abs], [x + dx, y - r + dx.abs]] }.uniq.each do |p|
      next if !reach[p] || event_at?(m, *p) || p == from
      next if keep.any? { |k| cuts_off?(map_id, solid + [p], from, k, void_tile: void_tile) }
      next if whole && size.(solid + [p]) < all - 1   # whole: nor any other part of the floor
      return p
    end
  end
  raise "Kanto: no standing spot near #{x},#{y} on map #{map_id}"
end

# ev_trainer with a generated name ("FP: Trainer(n)" still reads as a trainer
# to Essentials), so rebuilding replaces it.
def fp_trainer(*args)
  ev = ev_trainer(*args)
  ev.name = "FP: #{ev.name}"
  ev
end

def k_trainer(map_id, x, y, key, sight: 3, dir: 2, intro: nil)
  defn = FullPoke::Teams.get(key) or raise "Kanto: no trainer #{key}"
  fp_trainer(kmap(map_id), x, y, sight, "trainer_#{defn[:tr_type]}", dir, defn[:tr_type],
             intro || 'You look like a Trainer! Let\'s battle!',
             "FullPoke::Circuit.extra_battle(:kanto, :#{key})", 'That was a good battle.')
end

# An NPC whose talk runs a KantoStory helper; once it returns true the NPC
# says `done` from then on (or disappears with gone: true).
def k_story_npc(map_id, x, y, name, graphic, call, done: nil, gone: false, dir: 2, then_list: nil)
  page1 = new_page(trigger: 0, graphic: graphic, direction: dir, list: EventList.build {
    if_script("FullPoke::KantoStory.#{call}") do
      instance_eval(&then_list) if then_list
      self_switch('A', true)
    end
  })
  page2 = gone ? new_page(self_switch: 'A', through: true) :
                 new_page(trigger: 0, graphic: graphic, direction: dir, self_switch: 'A', list: EventList.build { text(done || '...') })
  new_event(kmap(map_id), "FP: #{name}", x, y, [page1, page2])
end

def k_cut_tree(map_id, x, y)
  page1 = new_page(trigger: 0, graphic: 'Object tree 1', list: EventList.build {
    if_script('pbCut') { script('pbSmashEvent(get_self)') }
  })
  new_event(kmap(map_id), 'FP: CutTree', x, y, [page1])
end

# Invisible wall built from a tile graphic (blocks walking, never interacts).
def k_blocker(map_id, x, y, tile_from)
  m = kmap(map_id)
  pg = new_page(trigger: 0, list: EventList.build {})
  ts = TILESETS[m.tileset_id]
  tile = [2, 1, 0].map { |z| m.data[*tile_from, z] }.find { |t| t.to_i > 0 && ts.passages[t] & 0x0f == 0x0f }
  raise "Kanto: no solid tile at #{tile_from} on map #{map_id} to copy" if !tile
  pg.graphic.tile_id = tile
  new_event(m, 'FP: Blocker', x, y, [pg])
end

#-------------------------------------------------------------------------------
# 1. Connections
#-------------------------------------------------------------------------------
# Kanto's outdoor maps, edge to edge (format of PBS/map_connections.txt: the
# first map's tile at the given position lines up with the second map's).
KANTO_CONNECTIONS = [
  '23,North,19,34,South,20', '173,South,4,34,North,0', '173,North,0,35,South,2', '25,South,1,35,North,0',
  '173,West,0,55,East,0', '36,West,0,25,East,17', '37,South,0,36,North,57', '37,East,0,26,West,0',
  '26,North,0,57,South,4', '58,West,2,57,East,0', '37,North,108,57,South,0', '26,South,0,38,North,0',
  '31,North,0,38,South,0', '26,East,6,42,West,0', '43,West,11,42,East,0', '43,South,0,27,North,0',
  '41,East,5,27,West,0', '41,East,29,45,West,0', '31,East,5,41,West,0', '31,West,0,40,East,3',
  '40,West,0,29,East,0', '24,North,3,39,South,0', '24,East,1,44,West,0', '45,West,48,44,East,0',
  '45,North,0,27,South,0', '46,North,48,45,South,0', '47,East,0,46,West,0', '48,East,0,47,West,30',
  '48,West,0,30,East,0', '29,West,3,49,East,0', '50,North,0,49,South,22', '51,North,0,50,South,1',
  '30,West,10,51,East,0', '30,South,17,52,North,0', '53,East,0,52,West,3', '53,West,40,172,East,0',
  '54,South,0,172,North,19', '54,North,0,23,South,2'
]

#-------------------------------------------------------------------------------
# 2. Repairs
#-------------------------------------------------------------------------------
def kanto_repairs
  # Route gates (Route Entrances, map 12): each room's doors lead back to the
  # route the room belongs to; the pack had them pointing one or two maps off.
  [[[38, 25, 32], [12, 80, 7]], [[38, 25, 38], [12, 80, 16]],   # Route 5 -> Saffron
   [[45, 14, 12], [12, 142, 68]], [[45, 14, 17], [12, 142, 79]], # Route 12 (Lavender)
   [[40, 15, 23], [12, 187, 12]], [[40, 21, 23], [12, 199, 12]], # Route 7 -> Saffron
   [[41, 1, 15], [12, 254, 14]], [[41, 6, 15], [12, 266, 14]],   # Route 8 -> Saffron
   [[44, 59, 18], [12, 347, 29]], [[44, 64, 18], [12, 359, 29]], # Route 11 -> 12
   [[48, 12, 21], [12, 236, 71]], [[48, 17, 21], [12, 248, 71]], # Route 15 (Fuchsia)
   [[51, 46, 9], [12, 432, 90]], [[51, 51, 9], [12, 444, 90]]]  # Route 18 (Fuchsia)
    .each do |out, room|
    link(out, room)
  end
  [[38, 24, 32, 25], [38, 24, 38, 25]].each do |m, x, y, twin|   # second tile of the Route 5 doors
    ev = warp_event_at(m, twin, y)
    retarget(m, x, y, *warp_cmds(ev)[0].parameters[1, 3]) if warp_event_at(m, x, y)
  end
  # Route 6 -> Saffron: the gatehouse's north doors sit on the roof edge, so
  # Saffron's south edge gets doors into the room instead.
  link([31, 25, 39], [12, 135, 8])
  ev_warp(kmap(31), 24, 39, 12, *beside(12, 135, 8), 2, name: 'FP: Gate door')
  link([39, 27, 5], [12, 135, 17])
  retarget(39, 26, 5, *warp_cmds(warp_event_at(39, 27, 5))[0].parameters[1, 3])
  [[26, 0], [27, 0]].each { |x, y| retarget(39, x, y, 12, *beside(12, 135, 8)) }   # on the roof edge: unused
  # Route 16's gate: two passages, the lower one to Cycling Road (Route 17)
  [[[49, 48, 23], [12, 348, 91]], [[49, 53, 23], [12, 360, 91]]].each { |out, room| link(out, room) }
  retarget(12, 348, 82, 49, 47, 18); retarget(12, 360, 82, 49, 55, 18)
  # Upstairs rooms of the gates
  [[[12, 146, 77], [12, 144, 52]], [[12, 246, 75], [12, 244, 53]], [[12, 358, 95], [12, 356, 67]],
   [[12, 442, 94], [12, 443, 71]]].each { |a, b| link(a, b) }
  # Pokémon Centers: Route 10's, Cinnabar's, and every Center's upstairs
  link([43, 13, 25], [182, 285, 38])
  link([172, 44, 4], [182, 189, 38])
  link([172, 30, 17], [181, 124, 21])
  [46, 69, 92, 114, 137, 160, 183, 250, 279].each { |x| link([182, x, 35], [182, x, 20]) }
  # Houses: Route 12's fishing house, Bill's Sea Cottage on Route 25
  link([45, 14, 82], [179, 125, 386])
  link([58, 51, 8], [179, 132, 450])
  # Underground Path Route 5 <-> Route 6
  link([369, 9, 4], [369, 9, 21])
  link([369, 6, 78], [369, 9, 94])
  link([39, 33, 13], [369, 9, 99])
  # Rock Tunnel: 1F holes <-> B1F ladders (the north entrance's part of 1F only
  # reaches the south exit through B1F)
  link([338, 45, 2], [338, 95, 3], name: 'FP: Ladder')
  link([338, 45, 21], [338, 100, 28], name: 'FP: Ladder')
  link([338, 4, 2], [338, 64, 3], name: 'FP: Ladder')
  link([338, 20, 13], [338, 89, 12], name: 'FP: Ladder')
  retarget(43, 8, 24, 338, 17, 3)
  must_reach(338, [17, 3], [45, 3], 'Rock Tunnel north part')
  raise 'Kanto: Rock Tunnel can be crossed without B1F' if reachable_from(kmap(338), 17, 3)[[18, 37]]
  # Pokémon Tower: 1F..7F stairs. On 2F the graves wall the stairs up in;
  # two graves make way.
  tower = kmap(207)
  [[31, 13], [31, 14]].each { |x, y| tower.data[x, y, 1] = 0 }
  [[[207, 19, 9], [207, 46, 10]], [[207, 30, 10], [207, 57, 10]], [[207, 73, 10], [207, 100, 10]],
   [[207, 84, 10], [207, 112, 10]], [[207, 128, 10], [207, 156, 10]], [[207, 147, 16], [207, 176, 16]]]
    .each { |a, b| link(a, b) }
  # each floor: from the stairs up into it to the stairs up out of it
  [[[46, 10], [30, 10]], [[57, 10], [73, 10]], [[100, 10], [84, 10]], [[112, 10], [128, 10]], [[156, 10], [147, 16]]]
    .each { |from, to| must_reach(207, beside(207, *from), beside(207, *to), 'Pokémon Tower floor') }
end

#-------------------------------------------------------------------------------
# 3. Story
#-------------------------------------------------------------------------------
def kanto_victory_road
  vr = 335
  # Route 23 cave mouths: west = entrance (1F), east = exit (2F)
  link([56, 10, 28], [vr, 21, 21], name: 'FP: Cave')
  link([56, 23, 28], [vr, 92, 13], name: 'FP: Cave')
  # Ladders drawn on 2F (it has none of its own), using Rock Tunnel's ladder tiles
  m = kmap(vr)
  [[47, 3], [75, 3], [82, 10]].each { |x, y| m.data[x, y - 1, 2] = 8193; m.data[x, y, 2] = 8201 }
  link([vr, 13, 1], [vr, 47, 3], name: 'FP: Ladder')    # 1F -> 2F
  link([vr, 75, 3], [vr, 110, 2], name: 'FP: Ladder')   # 2F -> 3F
  link([vr, 139, 18], [vr, 82, 10], name: 'FP: Hole')   # 3F hole <-> 2F east passage
  must_reach(vr, [21, 20], [13, 2], 'Victory Road 1F')
  must_reach(vr, [47, 4], [75, 4], 'Victory Road 2F')
  must_reach(vr, beside(vr, 110, 2), [139, 17], 'Victory Road 3F')
  must_reach(vr, [82, 11], [92, 12], 'Victory Road 2F exit')
  k_trainer(vr, *standing_spot(vr, 60, 8, [47, 4], [[75, 4]]), :kanto_vroad_t1, sight: 4)
  k_trainer(vr, *standing_spot(vr, 125, 12, beside(vr, 110, 2), [[139, 17]]), :kanto_vroad_t2, sight: 4)
  # Route 23: past the water and the cave there is no way round Victory Road
  r23 = kmap(56)
  raise 'Kanto: Route 23 bypasses Victory Road' if reachable_from(r23, 13, 150)[[17, 5]]
  # The League's badge check is at the Route 22 -> 23 gate
  g = kmap(12)
  old = warp_event_at(12, 447, 16)
  g.events.delete(old.id) if old
  # The pack's placeholders here: a "TESTER" handing out the Boulder Badge and a
  # guard checking a "Rock Badge" variable that only the tester sets
  g.events.delete_if { |_, e| e.name == 'TESTER' || (e.name == 'Counter(1)' && e.x == 448 && e.y == 17) }
  ev_warp(g, 447, 16, 56, 13, 153, 8, name: 'FP: To Route 23', script_cond: 'FullPoke::KantoStory.league_gate?',
          fail_text: 'The guard blocks the way.')
  ev_npc(g, 448, 17, 'FP: League guard', 'NPC 27', ['Beyond here are Route 23 and Victory Road, the way to the Indigo Plateau.',
                                                     'Only Trainers with all eight Kanto Badges may pass.'], dir: 4)
end

def kanto_story
  # Bill (Sea Cottage, Route 25) -> S.S. Ticket
  bill_room = beside(179, 132, 450)
  k_story_npc(179, *spot_near(179, 133, 445, bill_room), 'Bill', 'NPC 05', 'bill', done: 'Have fun on the S.S. Anne!')
  # Vermilion Harbor -> S.S. Anne (1F corridor) -> 2F (rival) -> Captain
  harbor = beside(179, 45, 257)
  hr = reachable_from(kmap(179), *harbor)
  sailor = free_spot(kmap(179), 45, 260, reach: hr)   # at the end of the pier
  ship = 345
  ship1 = [85, 128]                 # 1F corridor, by the gangway
  deck2 = [90, 52]                  # 2F corridor
  new_event(kmap(179), 'FP: Harbor sailor', *sailor, [new_page(trigger: 0, graphic: 'trainer_KANTOSAILOR', list: EventList.build {
    if_script('FullPoke::KantoStory.board_ss_anne?') { play_se('Door exit'); transfer(ship, ship1[0], ship1[1], 8) }
  })])
  gang = free_spot(kmap(ship), ship1[0], ship1[1] + 1, avoid: [ship1])
  one_way([ship, *gang], [179, *harbor], name: 'FP: Gangway', cond: 'FullPoke::KantoStory.leave_ss_anne')
  # 1F's stairs (top right) <-> 2F's (bottom right); 2F's narrow passage ends at
  # the Captain's cabin door
  up1 = spot_near(ship, 101, 118, ship1)
  down2 = spot_near(ship, 97, 61, deck2)
  link([ship, *up1], [ship, *down2])
  link([ship, 90, 45], [ship, *spot_near(ship, 55, 37, [57, 36])], name: 'FP: Door')
  must_reach(ship, deck2, [90, 46], 'S.S. Anne 2F')
  k_trainer(ship, *standing_spot(ship, 78, 120, ship1, [up1, gang]), :kanto_ssanne_t1, sight: 3, dir: 6)
  k_trainer(ship, *standing_spot(ship, 94, 124, ship1, [up1, gang]), :kanto_ssanne_t2, sight: 3, dir: 4)
  k_trainer(ship, *standing_spot(ship, 78, 53, deck2, [[90, 46], down2]), :kanto_ssanne_t3, sight: 3, dir: 6)
  rival = FullPoke::Teams.get(:kanto_rival_ssanne)
  # beside the three-wide passage to the cabin, facing across it
  rx, ry = standing_spot(ship, 89, 48, deck2, [[90, 46]])
  fp_trainer(kmap(ship), rx, ry, 2, "trainer_#{rival[:tr_type]}", rx < 90 ? 6 : (rx > 90 ? 4 : 2), rival[:tr_type],
             "Bonjour! Fancy meeting you here. Let's see how your Pokémon are doing!",
             'FullPoke::Circuit.extra_battle(:kanto, :kanto_rival_ssanne)', 'Humph! At least you\'re raising your Pokémon!')
  k_story_npc(ship, *spot_near(ship, 57, 33, [57, 36]), 'Captain', 'NPC 01', 'captain', done: 'Fair winds to you!')
  # Cut trees: in front of Vermilion Gym and on Route 9 east of Cerulean
  k_cut_tree(24, *chokepoint(24, [19, 8], [19, 28], from_end: true))
  # Route 9 starts two tiles wide: two trees
  raise 'Kanto: Route 9 trees leave a way round' if !cuts_off?(42, [[4, 12], [4, 13]], [0, 12], [71, 13])
  [[4, 12], [4, 13]].each { |x, y| k_cut_tree(42, x, y) }
  # Rock Tunnel hikers
  k_trainer(338, *standing_spot(338, 30, 6, [17, 3], [[45, 3]]), :kanto_rocktunnel_t1, sight: 3)
  k_trainer(338, *standing_spot(338, 80, 20, [95, 4], [[100, 29]]), :kanto_rocktunnel_t2, sight: 3)
  # Celadon Game Corner -> Rocket Hideout B1F..B4F -> Giovanni (Silph Scope).
  # The pack fenced the Game Corner's door in: a gap in the fence, and the door
  # moves down onto the step.
  gc = 235
  celadon = kmap(29)
  celadon.data[37, 26, 1] = 0
  ev_warp(celadon, 37, 25, gc, 9, 13, 8, name: 'FP: Game Corner door')
  retarget(gc, 9, 14, 29, 37, 26, 2)
  must_reach(29, [37, 27], [37, 26], 'Game Corner door')
  hide = 375
  b1 = beside(hide, 11, 4)
  # the poster hangs on the back wall, above the floor tile nearest (16, 2)
  fx, fy = spot_near(gc, 16, 2, [9, 13])
  poster = [fx, fy - 1]
  raise 'Kanto: Game Corner poster spot is walkable' if passable_tile?(kmap(gc), *poster)
  new_event(kmap(gc), 'FP: Poster', *poster, [new_page(trigger: 0, list: EventList.build {
    if_script('FullPoke::KantoStory.poster') { play_se('Door exit'); transfer(hide, b1[0], b1[1], 2) }
  })])
  k_trainer(gc, *standing_spot(gc, fx - 1, fy + 1, [9, 13], [[fx, fy]]),
            :kanto_rocket_gamecorner, sight: 3, dir: 2, intro: "I'm guarding this poster! Get lost!")
  one_way([hide, 11, 4], [gc, 9, 13], name: 'FP: Stairs', dir: 2)
  # B2F is a maze of spin tiles (not supported here), so the way down skips it:
  # B1F -> B3F -> B4F, with B2F's two halves as side rooms.
  link([hide, 18, 4], [hide, 23, 46])     # B1F -> B3F
  link([hide, 25, 56], [hide, 59, 60])    # B3F -> B4F
  link([hide, 16, 32], [hide, 66, 8])     # B1F <-> B2F (east)
  link([hide, 60, 24], [hide, 30, 46])    # B2F (west) <-> B3F
  must_reach(hide, b1, [18, 5], 'Hideout B1F')
  must_reach(hide, [23, 47], [25, 57], 'Hideout B3F')
  b4 = beside(hide, 59, 60)
  k_trainer(hide, *standing_spot(hide, 8, 12, b1, [[18, 5], [16, 33]]), :kanto_rocket_hideout1, sight: 3)
  k_trainer(hide, *standing_spot(hide, 56, 15, [66, 9], []), :kanto_rocket_hideout2, sight: 3)
  k_trainer(hide, *standing_spot(hide, 15, 55, [23, 47], [[25, 57], [30, 47]]), :kanto_rocket_hideout3, sight: 3)
  gio = FullPoke::Teams.get(:kanto_giovanni_hideout)
  k_story_npc(hide, *spot_near(hide, 66, 46, b4), 'Giovanni', "trainer_#{gio[:tr_type]}", 'giovanni_hideout', gone: true)
  # Pokémon Tower: rival (2F), Channelers, the ghost (6F), Rockets and Mr. Fuji (7F)
  tower = 207
  rv = FullPoke::Teams.get(:kanto_rival_tower)
  f2 = beside(tower, 46, 10)
  fp_trainer(kmap(tower), *standing_spot(tower, 38, 10, f2, [beside(tower, 30, 10)]), 4, "trainer_#{rv[:tr_type]}", 6, rv[:tr_type],
             "Hey! What brings you here? Your Pokémon don't look dead! Let's see if they can still fight!",
             'FullPoke::Circuit.extra_battle(:kanto, :kanto_rival_tower)', 'What? You stinker! I took it easy on you, too!')
  [[65, 6, 57, 73], [92, 6, 100, 84], [120, 14, 112, 128]].each_with_index do |(x, y, from, to), i|
    k_trainer(tower, *standing_spot(tower, x, y, beside(tower, from, 10), [beside(tower, to, 10)]), :"kanto_tower_t#{i + 1}", sight: 3)
  end
  f6 = beside(tower, 156, 10)
  gpos = chokepoint(tower, f6, beside(tower, 147, 16), skip: 1, from_end: true)
  k_story_npc(tower, *gpos, 'Ghost', 'FP_GHOST', 'ghost_marowak', gone: true)
  f7 = beside(tower, 176, 16)
  fuji = spot_near(tower, 177, 3, f7)
  k_story_npc(tower, *fuji, 'Mr. Fuji', 'NPC 10', 'fuji', done: 'Please take good care of your Pokémon.')
  [[175, 7], [179, 9], [177, 12]].each_with_index do |(x, y), i|
    k_trainer(tower, *standing_spot(tower, x, y, f7, [beside(tower, *fuji)]), :"kanto_rocket_tower#{i + 1}", sight: 2,
              intro: 'This old guy came to complain about us harming Pokémon. Beat it, kid!')
  end
  # Snorlax: Route 12 (south of the gate) and Route 16 (west of Celadon)
  # Route 12: just south of where Route 11's gate comes in, so Lavender and
  # Vermilion are both cut off from Routes 13-15
  raise 'Kanto: Route 12 Snorlax leaves a way round' if !cuts_off?(45, [[14, 68], [15, 68]], [14, 19], [14, 115]) ||
                                                        !cuts_off?(45, [[14, 68], [15, 68]], [2, 66], [14, 115])
  k_story_npc(45, 14, 68, 'Snorlax', 'FP_SNORLAX', 'snorlax(:route12)', gone: true)
  k_blocker(45, 15, 68, [16, 68])
  raise 'Kanto: Route 16 Snorlax leaves a way round' if !cuts_off?(49, [[69, 22], [69, 23], [69, 24]], [71, 23], [53, 23])
  k_story_npc(49, 69, 23, 'Snorlax', 'FP_SNORLAX', 'snorlax(:route16)', gone: true)
  # The road is three tiles wide where Snorlax sleeps: wall off its sides
  [[69, 22], [69, 24]].each { |x, y| k_blocker(49, x, y, [69, 21]) }
  # Saffron's gates: the doors into the city check for 4 Badges
  [[12, 80, 16, 38, 25, 39], [12, 135, 8, 31, 25, 38], [12, 199, 12, 40, 22, 23], [12, 254, 14, 41, 0, 15]]
    .each do |m, x, y, *_|
    ev = warp_event_at(m, x, y)
    ev.pages.each do |pg|
      next if pg.list.any? { |c| c.code == 111 }
      body = pg.list[0...-1]
      pg.list = EventList.build do
        if_script('FullPoke::KantoStory.saffron_open?') { body.each { |c| cmd(c.code, c.parameters) } }
      end
    end
  end
  # Silph Co.: elevator between 1F, 7F and 11F
  silph = 258
  floors = { '1F' => [9, 19], '7F' => [90, 105], '11F' => [82, 175] }
  spots = floors.transform_values { |(x, y)| free_spot(kmap(silph), x, y) }
  spots.each do |fl, (x, y)|
    # stepping on the elevator opens its menu, so it mustn't stand in the way
    whole = reachable_from(kmap(silph), x, y)
    lift = whole.keys.reject { |p| p == [x, y] || event_at?(kmap(silph), *p) }
                .sort_by { |px, py| (px - x).abs + (py - y).abs }
                .find { |p| floor_size_without(silph, [x, y], p) == whole.size - 1 }
    others = floors.keys - [fl]
    new_event(kmap(silph), 'FP: Elevator', *lift, [new_page(trigger: 1, list: EventList.build {
      text('This is the Silph Co. elevator. Which floor?')
      choices(others + ['Stay here'], cancel: others.length + 1) do |i|
        if i < others.length
          dest = spots[others[i]]
          play_se('Door exit')
          transfer(silph, dest[0], dest[1], 2)
        end
      end
    })])
  end
  f7s = spots['7F']; f11 = spots['11F']
  emp = spot_near(silph, f7s[0] - 12, f7s[1] + 8, f7s)
  k_story_npc(silph, *emp, 'Silph employee', 'NPC 15', 'lapras', done: 'Lapras is a gentle Pokémon.')
  rs = FullPoke::Teams.get(:kanto_rival_silph)
  fp_trainer(kmap(silph), *standing_spot(silph, f7s[0] - 6, f7s[1] + 4, f7s, [beside(silph, *emp)]), 4,
             "trainer_#{rs[:tr_type]}", 2, rs[:tr_type],
             'What kept you? Team Rocket is here, but first let me show you how strong I\'ve become!',
             'FullPoke::Circuit.extra_battle(:kanto, :kanto_rival_silph)', 'Arrgh! You\'re still better than me!')
  pres = spot_near(silph, f11[0] - 6, f11[1] + 12, f11)
  k_story_npc(silph, *pres, 'President', 'NPC 18', 'president', done: 'Silph Co. will never forget your help.')
  gs = FullPoke::Teams.get(:kanto_giovanni_silph)
  gio11 = spot_near(silph, f11[0] - 2, f11[1] + 10, f11, avoid: [beside(silph, *pres)])
  k_story_npc(silph, *gio11, 'Giovanni', "trainer_#{gs[:tr_type]}", 'giovanni_silph', gone: true)
  must_reach(silph, f11, beside(silph, *gio11), 'Silph Co. 11F')
  # the grunts must leave a way to Giovanni (who then leaves the President free)
  k_trainer(silph, *standing_spot(silph, f11[0] - 4, f11[1] + 4, f11, [beside(silph, *gio11)], whole: true), :kanto_rocket_silph1, sight: 2)
  k_trainer(silph, *standing_spot(silph, f11[0] + 2, f11[1] + 6, f11, [beside(silph, *gio11)], whole: true), :kanto_rocket_silph2, sight: 2)
  # HMs: Flash (Oak's aide, Route 2 gate), Fly (Route 16), Surf and Strength (Safari Zone gate)
  aide = spot_near(12, 35, 10, beside(12, 37, 5))
  new_event(kmap(12), 'FP: Oak\'s aide', *aide, [new_page(trigger: 0, graphic: 'NPC 09', list: EventList.build {
    if_script('FullPoke::KantoStory.give_once(:got_hm05, :HM05, ["I\'m one of Professor Oak\'s aides. Take this HM - Flash lights up dark caves like Rock Tunnel."], "Flash needs the Boulder Badge.")') {}
  })])
  fly = spot_near(49, 38, 17, [60, 17])
  new_event(kmap(49), 'FP: Fly girl', *fly, [new_page(trigger: 0, graphic: 'NPC 06', list: EventList.build {
    if_script('FullPoke::KantoStory.give_once(:got_hm02, :HM02, ["Oh, you found my secret retreat! Please keep it a secret, and take this HM. It\'s Fly!"], "Fly needs the Thunder Badge.")') {}
  })])
  safari = spot_near(12, 81, 52, [83, 54])
  new_event(kmap(12), 'FP: Safari Warden', *safari, [new_page(trigger: 0, graphic: 'NPC 21', list: EventList.build {
    if_script('FullPoke::KantoStory.give_once(:got_hm03, :HM03, ["I\'m the Safari Zone Warden. A Trainer who\'s come this far deserves these.", "This HM is Surf. With the Soul Badge it carries you across water."], nil)') {}
    if_script('FullPoke::KantoStory.give_once(:got_hm04, :HM04, ["And this one is Strength. It moves boulders once you have the Rainbow Badge."], "Enjoy the Safari Zone!")') {}
  })])
end

#-------------------------------------------------------------------------------
# 4. Gym trainers (Gyms 2-8): between the Gym's entrance and its Leader
#-------------------------------------------------------------------------------
def kanto_gym_trainers(rooms, leaders)
  rooms.each do |n, (ax, ay)|
    lx, ly = leaders[n]
    keys = (1..3).map { |i| :"kanto_gym#{n}_t#{i}" }.select { |k| FullPoke::Teams.get(k) }
    front = beside(177, lx, ly)
    keys.each_with_index do |key, i|
      f = (i + 1.0) / (keys.length + 1)
      tx = (ax + (lx - ax) * f).round + (i.even? ? -2 : 2)
      ty = (ay + (ly - ay) * f).round
      spot = standing_spot(177, tx, ty, [ax, ay], [front], void_tile: 384)
      k_trainer(177, *spot, key, sight: 2, dir: i.even? ? 6 : 4, intro: 'Our Leader is waiting. You\'ll have to get past me first!')
    end
  end
end

#-------------------------------------------------------------------------------
# 5. Traversal: every room and area of Kanto within reach
#-------------------------------------------------------------------------------
# Walkable tiles, and with surf: true water tiles (any tile whose top layer is
# water, as Game_Map#playerPassable? treats it when surfing).
def k_open?(m, x, y, surf)
  return false if x < 0 || y < 0 || x >= m.width || y >= m.height
  return true if passable_tile?(m, x, y)
  return false if !surf
  ts = TILESETS[m.tileset_id]
  [2, 1, 0].each { |z| t = m.data[x, y, z]; return [5, 6, 7].include?(ts.terrain_tags[t]) if t > 0 }
  false
end

# The map's areas: tile => area index, and the tiles of each area.
def k_areas(m, surf: true)
  comp = {}; areas = []
  m.height.times do |y|
    m.width.times do |x|
      next if comp[[x, y]] || !k_open?(m, x, y, surf)
      i = areas.length; g = []; q = [[x, y]]; comp[[x, y]] = i
      until q.empty?
        c = q.shift; g << c
        [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
          n = [c[0] + dx, c[1] + dy]
          next if comp[n] || !k_open?(m, *n, surf)
          comp[n] = i; q << n
        end
      end
      areas << g
    end
  end
  [comp, areas]
end

# A tile of the area for a warp: a drawn ladder (`prefer`) if there is a free
# one, else a dry free tile away from events, as open as possible (so it never
# blocks a corridor), nearest to (x, y).
def k_warp_spot(m, tiles, x, y, prefer: [])
  ev = m.events.values.to_h { |e| [[e.x, e.y], true] }
  dist = ->((tx, ty)) { (tx - x).abs + (ty - y).abs }
  drawn = tiles.select { |tx, ty| !ev[[tx, ty]] && [1, 2].any? { |z| prefer.include?(m.data[tx, ty, z]) } }
  return [drawn.min_by(&dist), true] if !drawn.empty?
  cands = tiles.select do |tx, ty|
    passable_tile?(m, tx, ty) && !ev[[tx, ty]] && [[1, 0], [-1, 0], [0, 1], [0, -1]].none? { |dx, dy| ev[[tx + dx, ty + dy]] }
  end
  open = ->(tx, ty) { [-1, 0, 1].product([-1, 0, 1]).count { |dx, dy| passable_tile?(m, tx + dx, ty + dy) } }
  best = cands.map { |t| [open.(*t), t] }
  [9, 6, 4, 0].each do |need|
    pick = best.select { |o, _| o >= need }.min_by { |_, t| dist.(t) }
    return [pick[1], false] if pick
  end
  [nil, false]
end

# Links every area of a dungeon map (10+ tiles, inside box [x0, y0, x1, y1] if
# given) to the parts reachable from its entrances, nearest first: through its
# drawn ladders (`prefer`) where it has free ones, else through new ladders
# (gfx: [[dy, tile id], ...] drawn on layer 2). The entrances are the areas
# beside warps to other maps, plus `entries`. Returns the number of links.
def k_stitch(map_id, entries = [], min: 10, gfx: nil, prefer: [], name: 'FP: Ladder', box: nil, surf: true, skip: [])
  m = kmap(map_id)
  comp, areas = k_areas(m, surf: surf)
  touch = ->(i, x, y) { [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]].any? { |dx, dy| comp[[x + dx, y + dy]] == i } }
  inbox = ->(x, y) { !box || (x >= box[0] && y >= box[1] && x <= box[2] && y <= box[3]) }
  todo = entries.map { |x, y| comp[[x, y]] or raise "Kanto: stitch entry (#{x},#{y}) on map #{map_id} is not walkable" }
  m.events.each_value do |e|
    next if !inbox.(e.x, e.y)
    warp_cmds(e).each { |c| next if c.parameters[1] == map_id; todo.concat(areas.each_index.select { |i| touch.(i, e.x, e.y) }) }
  end
  reached = {}
  spread = lambda do
    until todo.empty?
      i = todo.shift
      next if reached[i]
      reached[i] = true
      m.events.each_value do |e|
        next if !touch.(i, e.x, e.y)
        warp_cmds(e).each { |c| j = comp[[c.parameters[2], c.parameters[3]]]; todo << j if c.parameters[1] == map_id && j }
      end
    end
  end
  spread.()
  raise "Kanto: stitch of map #{map_id} has no entrance" if reached.empty?
  skipped = skip.map { |x, y| comp[[x, y]] }
  links = 0
  loop do
    left = areas.each_index.select do |i|
      !reached[i] && !skipped.include?(i) && areas[i].length >= min && areas[i].any? { |x, y| inbox.(x, y) && passable_tile?(m, x, y) }
    end
    break if left.empty?
    want = left.to_h { |i| [i, true] }
    # the nearest unreached area: breadth-first over the whole map from the reached ones
    from = {}; q = []
    reached.each_key { |i| areas[i].each { |t| from[t] = t; q << t } }
    hit = nil
    until q.empty? || hit
      c = q.shift
      [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
        n = [c[0] + dx, c[1] + dy]
        next if from[n] || n[0] < 0 || n[1] < 0 || n[0] >= m.width || n[1] >= m.height
        from[n] = from[c]
        (hit = n; break) if want[comp[n]]
        q << n
      end
    end
    i = comp[hit]; src = from[hit]
    a, a_drawn = k_warp_spot(m, areas[comp[src]], *src, prefer: prefer)
    b, b_drawn = k_warp_spot(m, areas[i], *hit, prefer: prefer)
    raise "Kanto: no place for a ladder on map #{map_id} near #{hit.join(',')}" if !a || !b
    link([map_id, *a], [map_id, *b], name: name)
    [[a, a_drawn], [b, b_drawn]].each do |(x, y), drawn|
      (gfx || []).each { |dy, t| m.data[x, y + dy, 2] = t if !drawn && m.data[x, y + dy, 2] == 0 }
    end
    links += 1
    todo << i
    spread.()
  end
  links
end

# Two-way stairs between the areas around a and b ([map, x, y]), each end on a
# free open tile nearest to the given one.
def k_link_near(a, b, name: 'FP: Stairs')
  ends = [a, b].map do |mid, x, y|
    m = kmap(mid)
    spot, = k_warp_spot(m, reachable_from(m, x, y).keys, x, y)
    raise "Kanto: no free tile near (#{x},#{y}) on map #{mid}" if !spot
    [mid, *spot]
  end
  link(*ends, name: name)
end

def kanto_traversal
  tag_grass   # tileset fixes first: the areas below are worked out with them
  # Houses whose doors the pack left without warps (their rooms in map 179 led
  # to a town tile with no way back)
  [[[29, 21, 31], [179, 21, 140]],                                     # Celadon
   [[25, 36, 28], [179, 34, 409]], [[25, 11, 34], [179, 68, 409]],    # Pewter
   [[172, 33, 7], [179, 117, 226]], [[172, 35, 14], [179, 142, 226]], # Cinnabar
   [[172, 42, 16], [179, 171, 226]], [[172, 41, 24], [179, 118, 257]],
   [[172, 29, 27], [179, 142, 257]], [[172, 33, 27], [179, 168, 257]]].each { |out, room| link(out, room, name: 'FP: Door') }
  # Cinnabar Lab: the lobby's three doorways to its back rooms. The labs map
  # keeps its other FP events (Oak's Lab opening, built by
  # build_kanto_opening.rb), so only these doors are replaced.
  if !SAVED[175]
    SAVED[175] = WG.load_map(175)
    SAVED[175].events.delete_if { |_, e| e.name == 'FP: Door' }
  end
  [[42, 33], [48, 50], [54, 67]].each { |dx, my| link([175, dx, 10], [175, 41, my], name: 'FP: Door') }
  # Route gates: upstairs of Route 11's and Route 22's gates; the stairs of the
  # others are drawn walled in, so a twin warp beside them is walked into
  link([12, 357, 34], [12, 355, 13])
  k_link_near([12, 446, 24], [12, 462, 20])
  [[146, 77], [246, 75], [358, 95], [442, 94]].each { |x, y| k_touchable(12, x, y) }
  # S.S. Anne: the deck, from the stairs at the end of the lower corridor
  k_link_near([345, 58, 126], [349, 9, 9])
  # Underground Path Route 7 <-> Route 8: entrance houses, stairs, tunnel
  link([40, 7, 28], [369, 60, 52], name: 'FP: Door')
  link([41, 13, 9], [369, 181, 52], name: 'FP: Door')
  link([369, 60, 48], [369, 83, 48])
  link([369, 181, 48], [369, 157, 48])
  # Safari Zone: through the gate's north passage (no fee); the grass drawn
  # around it is out of bounds
  link([12, 83, 53], [249, 78, 82], name: 'FP: Safari Zone')   # the carpet is drawn solid: walk into it
  k_wall_off(249, 0, 0, size: 6726)
  # Seafoam Islands: the two cave mouths on Route 20
  link([53, 60, 43], [340, 6, 22], name: 'FP: Cave')
  link([53, 72, 49], [340, 32, 22], name: 'FP: Cave')
  # Cerulean Cave (for Champions): 1F ladders up to 2F (middle) and down to B1F
  [[[10, 2], [61, 4]], [[34, 2], [81, 4]], [[2, 4], [53, 6]], [[30, 10], [74, 9]], [[24, 11], [71, 10]],
   [[5, 15], [55, 14]], [[1, 7], [104, 7]]].each { |a, b| link([194, *a], [194, *b], name: 'FP: Ladder') }
  (WORLD[:map_rules] ||= {})[194] = { region: :kanto, completed: true }
  # Hall of Fame: the Champion's door leads into it, and out of it home
  hof = kmap(292).events.values.find { |e| e.name == 'FP: Hall of Fame' } or raise 'Kanto: no Hall of Fame door'
  hof.pages.each { |pg| pg.list.each { |c| (c.code = 201; c.parameters = [0, 297, 5, 11, 8, 1]) if c.code == 355 && c.parameters[0] =~ /go_home/ } }
  solidify_void(kmap(297))
  ev_script_touch(kmap(297), 5, 12, 'FP: Hall of Fame exit', 'FullPoke.go_home(:kanto)')
  must_reach(297, [5, 11], [5, 3], 'Hall of Fame')
  # Every other floor and room of the dungeons: their own ladders where drawn,
  # else new ones (a door mat inside buildings)
  cave = { gfx: [[-1, 8193], [0, 8201]], prefer: [8201, 8200] }
  k_stitch(340, prefer: [7421], gfx: [[0, 7421]])                          # Seafoam Islands
  [194, 332, 338, 329, 335].each { |id| k_stitch(id, **cave) }             # Cerulean Cave, Mt. Moon, Rock Tunnel, Diglett's Cave, Victory Road
  [207, 258, 280, 345, 375, 369].each { |id| k_stitch(id, gfx: [[0, 585]]) } # Tower, Silph Co., Mansion, S.S. Anne, Hideout, Underground Paths
  k_stitch(249, name: 'FP: Path')                                         # Safari Zone
  K_DECOR.each { |id, x, y, size| k_wall_off(id, x, y, size: size) }
end

# A warp drawn walled in on all four sides gets a twin on a wall tile beside
# it that can be walked into.
def k_touchable(map_id, x, y)
  m = kmap(map_id)
  ev = warp_event_at(map_id, x, y) or raise "Kanto: no warp at map #{map_id} (#{x},#{y})"
  side = [[1, 0], [-1, 0], [0, 1], [0, -1]]
  return if side.any? { |dx, dy| passable_tile?(m, x + dx, y + dy) }
  tx, ty = side.map { |dx, dy| [x + dx, y + dy] }.find do |nx, ny|
    !event_at?(m, nx, ny) && side.any? { |dx, dy| [nx + dx, ny + dy] != [x, y] && passable_tile?(m, nx + dx, ny + dy) }
  end
  raise "Kanto: warp at map #{map_id} (#{x},#{y}) can't be reached from any side" if !tx
  c = warp_cmds(ev)[0]
  ev_warp(m, tx, ty, *c.parameters[1, 4], name: 'FP: Stairs')
end

# An empty tile that blocks, per tileset, to wall off what can't be reached
# (26's is made solid in build_world.rb's SOLID_TILES; no map used it).
K_BLOCK_TILE = { 1 => 896, 2 => 764, 23 => 4710, 26 => 896 }

# Makes an area nobody can reach solid (land or water joined to (x, y)): the
# cliff tops, the sea outside the channels and the ground around the Safari Zone
# that the map pack drew walkable. `size` is the area's expected size, a check
# that the flood stays inside it.
def k_wall_off(map_id, x, y, size: nil)
  m = kmap(map_id)
  tile = K_BLOCK_TILE[m.tileset_id] or raise "Kanto: no blocking tile for tileset #{m.tileset_id}"
  return 0 if m.data[x, y, 2] == tile   # walled off by an earlier build (maps are rebuilt from the last one)
  raise "Kanto: (#{x},#{y}) on map #{map_id} isn't walkable" if !k_open?(m, x, y, true)
  r = { [x, y] => true }; q = [[x, y]]
  until q.empty?
    c = q.shift
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      n = [c[0] + dx, c[1] + dy]
      next if r[n] || !k_open?(m, *n, true)
      r[n] = true; q << n
    end
  end
  ev = m.events.values.find { |e| r[[e.x, e.y]] && !warp_cmds(e).empty? }
  raise "Kanto: area at (#{x},#{y}) on map #{map_id} has a warp (#{ev.name})" if ev
  raise "Kanto: area at (#{x},#{y}) on map #{map_id} is #{r.size} tiles, not about #{size}" if size && r.size > size * 1.25 + 5
  r.each_key do |tx, ty|
    if m.data[tx, ty, 2] != 0
      next if m.data[tx, ty, 1] != 0
      m.data[tx, ty, 1] = m.data[tx, ty, 2]
    end
    m.data[tx, ty, 2] = tile
  end
  r.size
end

# Areas no one can reach, as [map, x, y, size]: cliff tops and rock fill drawn
# walkable, the sea outside the routes' channels (behind rock lines and fences),
# tree tops and roof edges. Found with the whole-game audit (t_reach.rb AUDIT=).
K_DECOR = [
  [36, 2, 0, 292], [36, 17, 3, 12], [36, 0, 18, 11],                       # Route 3
  [37, 39, 0, 778], [37, 0, 0, 377], [37, 24, 0, 192],                     # Route 4
  [41, 5, 19, 925], [41, 5, 0, 445],                                       # Route 8
  [42, 67, 6, 21], [42, 7, 16, 12],                                        # Route 9
  [43, 1, 78, 33], [43, 2, 58, 20], [43, 2, 38, 13], [43, 14, 68, 10],     # Route 10
  [55, 0, 0, 669], [55, 55, 30, 256], [55, 4, 25, 94], [55, 13, 30, 25], [55, 51, 11, 10],   # Route 22
  [56, 9, 22, 125], [56, 0, 154, 42], [56, 20, 154, 39], [56, 24, 34, 25], [56, 22, 0, 12], [56, 0, 0, 11],  # Route 23
  [57, 0, 0, 764], [57, 36, 16, 50], [57, 17, 16, 14], [57, 34, 29, 78],   # Route 24
  [58, 39, 23, 510], [58, 0, 0, 407], [58, 99, 0, 128], [58, 104, 0, 60], [58, 121, 14, 42],  # Route 25
  [25, 0, 0, 475], [25, 46, 36, 70], [25, 11, 0, 52], [25, 44, 34, 22], [25, 3, 7, 16], [25, 16, 12, 10],  # Pewter
  [26, 0, 0, 22], [26, 30, 0, 72],                                         # Cerulean
  [52, 2, 0, 10], [52, 0, 6, 59],                                          # Route 19
  [30, 10, 27, 24], [30, 19, 37, 18], [30, 36, 39, 12],                    # Fuchsia
  [33, 20, 18, 14], [33, 18, 13, 12], [33, 0, 18, 12], [33, 0, 13, 10],    # Indigo Plateau
  [53, 0, 0, 4418], [46, 70, 0, 3384],                                     # Routes 20 and 13: open sea
  [45, 19, 1, 1394], [45, 0, 2, 161], [45, 0, 0, 10], [45, 6, 19, 10],     # Route 12
  [54, 0, 15, 549], [35, 59, 40, 38], [44, 0, 22, 30],                     # Routes 21, 2, 11
  [50, 9, 146, 40], [50, 23, 146, 28], [47, 18, 23, 128],                  # Routes 17, 14
  [48, 18, 26, 54], [48, 6, 17, 18], [48, 6, 24, 12],                      # Route 15
  [24, 0, 0, 293], [24, 52, 33, 72], [24, 31, 1, 22], [24, 47, 5, 12], [24, 51, 5, 12],  # Vermilion
  [172, 16, 0, 13],                                                        # Cinnabar
  [173, 2, 22, 57], [173, 0, 0, 44], [173, 26, 1, 34], [173, 5, 0, 16],    # Viridian
  [27, 0, 20, 40], [235, 7, 0, 11], [175, 11, 36, 28]                      # Lavender, Game Corner, Labs
]
