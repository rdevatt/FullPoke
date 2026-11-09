# The map pack's own interior rooms, made the real insides of buildings.
#
# The pack drew its interiors as composite maps: many rooms on one big map
# (Pokémon Centers on 182, Marts and the Celadon Department Store on 181,
# houses on 179, Contest Halls on 22, gatehouses on 12, Hoenn's rooms on 10,
# 498, 501 and 503). Most towns get generated interiors instead (build_geo.rb),
# so most of these rooms were left with no way in. Here each room is given to
# a building:
#   - PackRooms::ASSIGN hands rooms to the doors of the geo and generated
#     regions (GeoRegion#build_rooms asks PackRooms.take for each door);
#   - pack_rooms_kanto wires Kanto's own leftover rooms with link();
#   - pack_rooms_finish walls off what was never a room (the void between
#     rooms, the outlines and labels the pack's author drew around groups of
#     rooms) and checks that every library room was handed out.
# Events added here are "FP: " events, replaced on every build. Pack warps on
# a room's exit tile are re-pointed in place.
# A room used by another region than its map's (Johto's Pokémon Centers on
# Kanto's 182) is recorded in World.room_regions, so FullPoke.region_at
# treats it as that region's ground.

module PackRooms
  module_function

  # Pokémon Center pair on map 182: [lower floor origin, upper floor origin].
  # The spare pairs are copies of the Kanto ones (Viridian's at 2,29 / 2,14):
  # door (7,9), stairs (1,6) on both floors. The nurse, the healing machine's
  # balls and the PCs are copied from Pewter's (23,29 / 23,14), like the
  # generated Pokémon Centers.
  def pc182(lower, upper)
    lx, ly = lower; ux, uy = upper
    { map: 182, kind: :pc, origin: [lx, ly], size: [15, 10], door: [lx + 7, ly + 9], arrive: [lx + 7, ly + 8],
      copy: [[182, 23, 29, 15, 10, lx, ly], [182, 23, 14, 15, 9, ux, uy]],
      check: [[182, 23, 29, 15, 10, lx, ly], [182, 23, 14, 15, 9, ux, uy]],
      stairs: [[[182, lx + 1, ly + 6], [182, ux + 1, uy + 6]]] }
  end

  # Kanto-style Mart on map 181 (11x9; door (4,8); the clerk behind the counter at (2,3))
  def mart181(x, y)
    { map: 181, kind: :mart, origin: [x, y], size: [11, 9], door: [x + 4, y + 8], arrive: [x + 4, y + 7],
      clerk: [x + 2, y + 3], clerk_dir: 6 }
  end

  # Kanto-style Mart on map 179 (13x11, the template generated Marts copy)
  def mart179(x, y)
    ex, ey = room_exit([179, x, y, 13, 11])
    { map: 179, kind: :mart, origin: [x, y], size: [13, 11], door: [x + ex, y + ey], arrive: [x + ex, y + ey - 1] }
  end

  # Contest Hall on map 22 (15x18; the door mat on the bottom row)
  def hall22(x, y, door, name)
    { map: 22, kind: :hall, origin: [x, y], size: [15, 18], door: door, arrive: [door[0], door[1] - 1],
      extra_npc: ['NPC 17', ["Welcome to the #{name}!", 'There are no shows today. Please come again!']] }
  end

  # Hoenn's Pokémon Center pair on map 501 (x0: its left wall): the nurse's
  # floor below (y 29-37, the door mat at x0+6), the escalator up to the
  # floor above (y 10-20). Copies of the first (x0 = 10).
  def pc501(x0)
    { map: 501, kind: :pc, origin: [x0, 29], size: [14, 9], door: [x0 + 6, 37], arrive: [x0 + 6, 36],
      nurse: [[x0 + 7, 31]], check: x0 == 10 ? [] : [[501, 10, 10, 14, 28, x0, 10]],
      warps: [[501, x0 + 1, 35, 501, x0 + 2, 16, 6, 'FP: Escalator'], [501, x0 + 1, 16, 501, x0 + 2, 35, 6, 'FP: Escalator']] }
  end

  # Hoenn's Mart on map 503 (x0: its left wall; the door mat at x0+3)
  def mart503(x0)
    { map: 503, kind: :mart, origin: [x0, 8], size: [11, 8], door: [x0 + 3, 15], arrive: [x0 + 3, 14],
      check: x0 == 5 ? [] : [[503, 5, 8, 11, 8, x0, 8]] }
  end

  # A house on map 10: box, door mat, and for two-storey houses the stairs
  # (each floor's stairs tile, landing on the tile below the other's)
  def house10(box, door, stairs = nil)
    r = { map: 10, kind: :house, origin: box[0, 2], size: box[2, 2], door: door, arrive: [door[0], door[1] - 1] }
    if stairs
      a, b = stairs
      r[:warps] = [[10, a[0], a[1], 10, b[0], b[1] + 1, 2, 'FP: Stairs'], [10, b[0], b[1], 10, a[0], a[1] + 1, 2, 'FP: Stairs']]
    end
    r
  end

  HALLS = [[12, 431, [16, 448]], [45, 431, [49, 448]], [78, 431, [82, 448]], [110, 431, [114, 448]],
           [225, 431, [229, 448]], [257, 431, [261, 448]], [143, 432, [147, 449]], [184, 432, [188, 449]],
           [296, 432, [300, 449]], [345, 432, [349, 449]]]

  def lib
    @lib ||= begin
      l = {}
      # Johto: the nine spare Pokémon Centers drawn under Kanto's
      [3, 24, 46, 69, 92, 114, 137, 160, 183].each_with_index { |x, i| l[:"pc_j#{i + 1}"] = pc182([x, 76], [x, 61]) }
      # four more further down the map
      [9, 45, 77, 111].each_with_index { |x, i| l[:"pc_s#{i + 1}"] = pc182([x, 125], [x, 108]) }
      # The L-shaped Pokémon Center with the Great Marsh exit (its nurse,
      # PCs and stairs are the pack's own)
      l[:pc_marsh] = { map: 182, kind: :pc, origin: [212, 29], size: [25, 18], door: [223, 46], arrive: [223, 45] }
      # Marts: two beside Kanto's, a row of ten and a row of four
      [161, 181].each_with_index { |x, i| l[:"mart_a#{i + 1}"] = mart181(x, 13) }
      [3, 21, 40, 59, 80, 99, 119, 139, 160, 180].each_with_index { |x, i| l[:"mart_b#{i + 1}"] = mart181(x, 90) }
      [7, 37, 68, 97].each_with_index { |x, i| l[:"mart_c#{i + 1}"] = mart181(x, 134) }
      HALLS.each_with_index { |(x, y, door), i| l[:"hall#{i + 1}"] = hall22(x, y, door, 'Contest Hall') }
      # The five Marts drawn in 179's Fuchsia group (their floor was solid)
      [[15, 8], [39, 8], [66, 18], [15, 28], [39, 28]].each_with_index { |(x, y), i| l[:"mart_k#{i + 1}"] = mart179(x, y) }
      # Hoenn (the pack drew them in the order of the towns: Oldale first)
      [10, 37, 66, 95, 122, 155, 182].each_with_index { |x, i| l[:"hpc#{i + 1}"] = pc501(x) }
      [5, 27, 51, 74, 100, 127, 150, 174].each_with_index { |x, i| l[:"hmart#{i + 1}"] = mart503(x) }
      l[:hlab] = { map: 498, kind: :lab, origin: [0, 0], size: [13, 13], door: [6, 12], arrive: [6, 11] }
      l[:h_brendan] = house10([5, 17, 11, 9], [13, 25], [[13, 19], [12, 1]])   # Littleroot: 1F, 2F
      l[:h_may] = house10([35, 17, 11, 9], [36, 25], [[37, 19], [37, 1]])
      l[:h_oldale1] = house10([75, 3, 10, 9], [78, 11])
      l[:h_oldale2] = house10([85, 22, 11, 8], [88, 29])
      l[:h_dew1] = house10([133, 1, 10, 8], [136, 8])
      l[:h_dew2] = house10([160, 2, 10, 9], [163, 10])
      l[:h_dewhall] = house10([134, 21, 18, 9], [139, 29])
      l
    end
  end

  # region => town => door kind => [room for the 1st door of that kind, 2nd, ...]
  ASSIGN = {
    johto: {
      cherrygrove: { pc: [:pc_j1], mart: [:mart_b1] },
      violet: { pc: [:pc_j2], mart: [:mart_b2] },
      azalea: { pc: [:pc_j3], mart: [:mart_b3] },
      goldenrod: { pc: [:pc_j4], mart: [:mart_b4] },
      ecruteak: { pc: [:pc_j5], mart: [:mart_b5], big: [:hall6] },   # the Dance Theater
      cianwood: { pc: [:pc_j6], mart: [:mart_b6] },
      olivine: { pc: [:pc_j7], mart: [:mart_b7] },
      mahogany: { pc: [:pc_j8], mart: [:mart_b8] },
      blackthorn: { pc: [:pc_j9], mart: [:mart_b9] }
    },
    sinnoh: {
      sandgem: { pc: [:pc_s1], mart: [:mart_a1] },
      jubilife: { pc: [:pc_s2], mart: [:mart_a2] },
      oreburgh: { pc: [:pc_s3], mart: [:mart_c1] },
      floaroma: { pc: [:pc_s4], mart: [:mart_c2] },
      eterna: { mart: [:mart_c3] },
      veilstone: { mart: [:mart_b10] },
      hearthome: { mart: [:mart_c4], big: [:hall5] },   # the Contest Hall
      pastoria: { pc: [:pc_marsh] },
      celestic: { mart: [:mart_k1] },
      snowpoint: { mart: [:mart_k2] },
      sunyshore: { mart: [:mart_k3] }
    },
    hoenn: {
      littleroot: { home: [:h_brendan], lab: [:hlab], house: [:h_may] },
      oldale: { pc: [:hpc1], mart: [:hmart1], house: [:h_oldale1, :h_oldale2] },
      petalburg: { pc: [:hpc2], mart: [:hmart2] },
      rustboro: { pc: [:hpc3], mart: [:hmart3] },
      dewford: { pc: [:hpc4], mart: [:hmart4], house: [:h_dewhall, :h_dew1] },
      slateport: { pc: [:hpc5], mart: [:hmart5], big: [:hall1] },
      mauville: { pc: [:hpc6], mart: [:hmart6] },
      verdanturf: { pc: [:hpc7], mart: [:hmart7], big: [:hall2] },
      lavaridge: { mart: [:hmart8], house: [nil, :h_dew2] },
      fallarbor: { big: [:hall3] }, lilycove: { big: [:hall4] },
      fortree: { mart: [:mart_k4] }, mossdeep: { mart: [:mart_k5] }
    },
    # Halls for the generated regions' big cities (their first house)
    unova: { nimbasa: { house: [:hall7] } },
    kalos: { lumiose: { house: [:hall8] } },
    alola: { hauoli: { house: [:hall9] } },
    galar: { hammerlocke: { house: [:hall10] } }
  }
  HALL_NAMES = { hall7: 'Pokémon Musical Theater', hall8: 'Lumiose Showcase Hall', hall9: "Hau'oli Hall", hall10: 'Hammerlocke Hall' }

  USED = {}

  # The pack room for the n-th door of this kind in a town, or nil
  def take(region, town, kind, n)
    rid = ASSIGN.dig(region, town, kind)&.[](n) or return nil
    raise "PackRooms: #{rid} handed out twice (#{USED[rid].inspect}, #{[region, town, kind].inspect})" if USED[rid]
    USED[rid] = [region, town, kind]
    room = lib.fetch(rid).dup
    room[:id] = rid
    if (nm = HALL_NAMES[rid])
      room[:extra_npc] = ['NPC 17', ["Welcome to the #{nm}!", 'There are no shows today. Please come again!']]
    end
    check_room(room)
    room
  end

  # The pack drew the spare rooms as copies of rooms already in use: a
  # different drawing would put the copied events in the wrong places (a few
  # tiles of decoration may differ).
  def check_room(room)
    (room[:check] || []).each do |sm, sx, sy, w, h, dx, dy|
      src = WG.src_map(sm); dst = kmap(room[:map])
      diff = 0
      h.times { |j| w.times { |i| 3.times { |z| diff += 1 if src.data[sx + i, sy + j, z] != dst.data[dx + i, dy + j, z] } } }
      raise "PackRooms: #{room[:id]} at #{dx},#{dy} isn't drawn like #{sx},#{sy} (#{diff} tiles differ)" if diff > 8
    end
    m = kmap(room[:map])
    raise "PackRooms: #{room[:id]} arrival #{room[:arrive].inspect} isn't walkable" if !passable_tile?(m, *room[:arrive])
  end

  # The exit warp of a room: the pack's warp on that tile re-pointed, or a new one
  def exit_warp(map_id, x, y, dest, dx, dy, name)
    if warp_event_at(map_id, x, y)
      retarget(map_id, x, y, dest, dx, dy, 2)
    else
      ev_warp(kmap(map_id), x, y, dest, dx, dy, 2, name: name)
    end
  end

  # Copies the events (not warps) in a box of a pack map onto another spot,
  # as "FP: " events (so the next build replaces them).
  def copy_events(sm, sx, sy, w, h, dest_id, dx, dy)
    src = WG.src_map(sm); dest = kmap(dest_id)
    src.events.values.sort_by(&:id).each do |ev|
      next unless ev.x >= sx && ev.y >= sy && ev.x < sx + w && ev.y < sy + h
      next if ev.name.start_with?('FP: ') || ev.pages.any? { |pg| pg.list.any? { |c| c.code == 201 } }
      nev = Marshal.load(Marshal.dump(ev))
      nev.id = (dest.events.keys.max || 0) + 1
      nev.x = ev.x - sx + dx
      nev.y = ev.y - sy + dy
      nev.name = "FP: #{ev.name.strip}"
      dest.events[nev.id] = nev
    end
  end

  def furnish_pc(room)
    (room[:copy] || []).each { |sm, sx, sy, w, h, dx, dy| copy_events(sm, sx, sy, w, h, room[:map], dx, dy) }
    (room[:stairs] || []).each { |a, b| link(a, b) }
    (room[:nurse] || []).each { |x, y| add_nurse(kmap(room[:map]), x, y) }
    (room[:pcs] || []).each { |x, y| new_event(kmap(room[:map]), 'FP: PC', x, y, [new_page(trigger: 0, list: EventList.build { script('pbPokeCenterPC') })]) }
  end

  # A nurse who heals, like Pewter's (copied: same text, healing and balls var)
  def add_nurse(m, x, y)
    src = WG.src_map(182).events.values.find { |e| e.x == 30 && e.y == 32 } or raise 'PackRooms: no nurse in Pewter'
    nev = Marshal.load(Marshal.dump(src))
    nev.id = (m.events.keys.max || 0) + 1
    nev.x = x; nev.y = y; nev.name = 'FP: Nurse'
    m.events[nev.id] = nev
  end

  def furnish_extra(room, _town, _label)
    (room[:links] || []).each { |a, b| link(a, b) }
    (room[:warps] || []).each { |fm, x, y, tm, tx, ty, dir, name| ev_warp(kmap(fm), x, y, tm, tx, ty, dir, name: name) }
    if (npc = room[:extra_npc])
      reach = reachable_from(kmap(room[:map]), *room[:arrive])
      x, y = free_spot(kmap(room[:map]), room[:arrive][0], room[:arrive][1] - 3,
                       box: [*room[:origin], *room[:size]], avoid: [room[:arrive]], reach: reach)
      ev_npc(kmap(room[:map]), x, y, 'FP: Attendant', npc[0], npc[1])
    end
  end

  def unused = lib.keys.reject { |k| USED[k] }

  # Tileset 2's Hoenn interiors (the tiles only maps 10, 498, 501 and 503
  # draw) were never set up: every floor was solid and the black filler
  # between the rooms walkable. Floors, door mats and stair landings open;
  # the filler and wall tiles that were walkable solid; the Pokémon Center
  # counter is a counter (the nurse is spoken to across it).
  HOENN_OPEN = [3376, 3377, 3414, 3438,                 # Littleroot houses: wood floor, stair landings
                3542, 3543, 3555, 3556,                 # Oldale-style houses: floor, mat
                3766, 3767, 3774, 3775, 3782, 3783, 3790, 3791,   # Dewford houses: tatami, entrance, mat
                3480, 3492, 3493,                       # Birch's lab: floor, mat
                3754, 3758, 3759]                       # Mart: floor edge, mat
  HOENN_SOLID = [3354, 3352, 3353, 3731, 3688]          # filler; wall tiles left walkable
  HOENN_COUNTER = (3680..3685).to_a
  # Kanto's rooms in 179 with floors left solid: the Mart floor (also the
  # floor of every generated Mart, copied from 179), Celadon Mansion's
  # carpets and roof, Vermilion's Fan Club floor, the Day Care's floor (also
  # in the generated houses copied from 179, and map 8) and their rug; the sky
  # drawn walkable around the rooftops (179, 181).
  KANTO_OPEN = [2641, 2948, 2956, 2973, 2917, 2887, 2860, 2861, 2862, 2868, 2869, 2870, 2876, 2877, 2878]
  KANTO_SOLID = [1180]
  def tile_fixes
    ts = TILESETS[2]
    KANTO_OPEN.each { |t| ts.passages[t] &= ~0x0f; KEPT_OPEN[[2, t]] = true }
    KANTO_SOLID.each { |t| ts.passages[t] |= 0x0f }
    HOENN_OPEN.each { |t| ts.passages[t] &= ~0x0f; KEPT_OPEN[[2, t]] = true }
    HOENN_SOLID.each { |t| ts.passages[t] |= 0x0f }
    HOENN_COUNTER.each { |t| ts.passages[t] |= 0x80 }
  end
end

# A shop clerk on a pack map
def pack_clerk(map_id, x, y, items, dir: 2, greeting: 'Welcome! How may I help you?')
  items = items.select { |i| GameData::Item.exists?(i) }
  new_event(kmap(map_id), 'FP: Clerk', x, y, [new_page(trigger: 0, graphic: 'NPC 19', direction: dir, list: EventList.build {
    text(greeting)
    script("pbPokemonMart(#{items.inspect})")
  })])
end

# Kanto's leftover rooms (after kanto_traversal; uses its link()/kmap())
def pack_rooms_kanto
  PackRooms.tile_fixes
  # Celadon Department Store (181, the floors at y 53): the two front doors
  # led to a Sinnoh route. 1F-5F each have the elevator door at the top; the
  # elevator (27,58) goes to the floor picked on its panel (variable 51).
  link([29, 14, 17], [181, 6, 68], name: 'FP: Door')
  link([29, 18, 17], [181, 13, 68], name: 'FP: Door')
  floors = { 1 => [9, 54], 2 => [49, 54], 3 => [76, 54], 4 => [108, 54], 5 => [138, 54] }
  floors.each_value { |x, y| retarget(181, x, y, 181, 29, 63, 8) }
  lift = warp_event_at(181, 29, 64) or raise 'PackRooms: no elevator exit'
  n = 0
  lift.pages.each do |pg|
    pg.list.each do |c|
      next if c.code != 201
      fl = floors[n += 1] or raise 'PackRooms: elevator has more than five floors'
      fx, fy = fl
      c.parameters[1] = 181; c.parameters[2] = fx; c.parameters[3] = fy + 1; c.parameters[4] = 2
    end
  end
  # 5F's stairs up to the roof; the roof is only its fenced floor
  spot5, = k_warp_spot(kmap(181), reachable_from(kmap(181), 135, 56).keys, 135, 56)
  link([181, *spot5], [181, 174, 59])
  pack_clerk(181, *free_spot(kmap(181), 46, 57), %i[POKEBALL GREATBALL ULTRABALL POTION SUPERPOTION HYPERPOTION FULLHEAL REVIVE ESCAPEROPE REPEL SUPERREPEL MAXREPEL])
  pack_clerk(181, *free_spot(kmap(181), 73, 58), %i[XATTACK XDEFENSE XSPATK XSPDEF XSPEED XACCURACY DIREHIT GUARDSPEC])
  pack_clerk(181, *free_spot(kmap(181), 105, 59), %i[FIRESTONE WATERSTONE THUNDERSTONE LEAFSTONE MOONSTONE])
  pack_clerk(181, *free_spot(kmap(181), 135, 59), %i[HPUP PROTEIN IRON CALCIUM ZINC CARBOS])
  pack_clerk(181, *free_spot(kmap(181), 170, 58), %i[FRESHWATER SODAPOP LEMONADE], greeting: 'Thirsty? Fresh drinks!')
  ev_npc(kmap(181), *free_spot(kmap(181), 9, 60), 'FP: Receptionist', 'NPC 17',
         ['Welcome to the Celadon Department Store!', 'Take the elevator to visit every floor.'])
  # Celadon Mansion (179): 1F (17,153; the doors from Celadon), 2F, 3F, the
  # roof and the room on the roof
  k_link_near([179, 30, 161], [179, 56, 161])
  k_link_near([179, 47, 161], [179, 76, 161])
  k_link_near([179, 85, 161], [179, 113, 157])
  link([179, 107, 164], [179, 140, 165], name: 'FP: Door')
  # ... and the stair landings at the top of 2F and 3F, from 1F's (where
  # the back door comes in)
  k_link_near([179, 21, 153], [179, 46, 154])
  k_link_near([179, 47, 154], [179, 75, 154])
  # Pewter: the house on the ledge west of the Pokémon Center. Its stairs
  # end on the roof of the house below; they lead down beside that house.
  ev_warp(kmap(25), 14, 37, 25, 16, 37, 6, name: 'FP: Stairs')
  ev_warp(kmap(25), 15, 37, 25, 14, 36, 8, name: 'FP: Stairs')
  # Saffron: Copycat's house, its stairs to the room upstairs
  link([179, 114, 311], [179, 114, 296])
  # Route houses whose doors led to other regions' maps: Route 2's (trade
  # house) and Route 5's (the Day Care); Route 16's house had no door
  link([35, 31, 22], [179, 225, 387], name: 'FP: Door')
  link([38, 23, 25], [179, 221, 430], name: 'FP: Door')
  link([49, 39, 15], [179, 128, 416], name: 'FP: Door')
  # The League reception gate's west wing (map 12, 20,91): its north door
  # opens off the main hall's west door; the south door (to Johto's Route 26
  # in the pack) leads back into the hall, Johto being reached from the forest
  link([12, 428, 21], [12, 24, 92], name: 'FP: Door')
  retarget(12, 24, 101, 12, 429, 22, 6)
  ev_npc(kmap(12), *free_spot(kmap(12), 23, 97), 'FP: Guard', 'NPC 11',
         ['This wing leads to Route 26 and Johto.', 'The road is closed. Travel to Johto through the Interregional Forest!'])
end

# Never rooms: the void between the rooms, outlines and labels drawn around
# groups of rooms, the pillars' sides in gatehouses and a hall drawn over
# with stray tiles. [map, x, y, size] (k_wall_off), found with the
# whole-game audit (t_reach.rb AUDIT_AREAS=1).
PACK_DECOR = [
  [182, 100, 94, 10356], [181, 0, 75, 8338],                                   # void below the rooms
  [22, 20, 10, 68], [22, 367, 387, 36], [22, 356, 391, 21], [22, 366, 401, 12],   # broken hall; "SI" label
  # 179: outlines around each town's rooms, route-number labels
  [179, 7, 1, 622], [179, 104, 202, 354], [179, 97, 286, 351], [179, 5, 374, 241], [179, 5, 284, 111],
  [179, 80, 286, 82], [179, 82, 361, 64], [179, 4, 318, 59], [179, 22, 119, 55], [179, 13, 432, 50],
  [179, 57, 57, 47], [179, 87, 75, 45], [179, 40, 441, 33], [179, 26, 56, 31], [179, 8, 78, 29],
  [179, 83, 273, 28], [179, 9, 57, 26], [179, 190, 420, 23], [179, 6, 455, 23], [179, 105, 441, 21],
  [179, 105, 407, 18], [179, 11, 474, 18], [179, 18, 272, 17], [179, 38, 278, 16], [179, 96, 440, 15],
  [179, 97, 406, 14], [179, 33, 433, 14], [179, 7, 107, 13], [179, 7, 66, 12], [179, 10, 118, 12],
  [179, 32, 472, 11], [179, 187, 431, 10],
  # 12: route outlines and numbers, "Plum Isle"
  [12, 119, 0, 93], [12, 409, 110, 91], [12, 135, 142, 57], [12, 179, 32, 55], [12, 235, 92, 53],
  [12, 1, 30, 47], [12, 294, 46, 39], [12, 4, 53, 33], [12, 69, 62, 33], [12, 214, 87, 33],
  [12, 423, 47, 32], [12, 22, 77, 29], [12, 189, 127, 22], [12, 313, 43, 20], [12, 486, 67, 18],
  [12, 213, 116, 18], [12, 165, 123, 18], [12, 62, 8, 17], [12, 279, 58, 17], [12, 467, 61, 16],
  [12, 313, 62, 16], [12, 46, 29, 15], [12, 486, 45, 14], [12, 459, 49, 14], [12, 166, 106, 14],
  [12, 63, 33, 12], [12, 192, 141, 11], [12, 231, 0, 10], [12, 484, 59, 10], [12, 196, 110, 10],
  [12, 199, 111, 10], [12, 185, 124, 10], [12, 114, 136, 10],
  # 12: the aisles behind the gatehouses' long counters
  [12, 76, 8, 13], [12, 83, 8, 13], [12, 131, 9, 13], [12, 138, 9, 13], [12, 20, 93, 13], [12, 27, 93, 13],
  [12, 137, 69, 17], [12, 349, 81, 33],
  [12, 348, 33, 12], [12, 443, 38, 12], [12, 237, 75, 12], [12, 433, 94, 12], [12, 349, 95, 12],
  [179, 114, 133, 16],                                                         # Celadon restaurant: behind the counter
  # 10: outlines and the "L", "OL", "Dew" labels around Hoenn's town groups
  [10, 65, 31, 120], [10, 130, 39, 51], [10, 190, 24, 43], [10, 60, 0, 22], [10, 187, 0, 18],
  [10, 121, 18, 17], [10, 173, 25, 16], [10, 106, 8, 14], [10, 178, 27, 12], [10, 120, 35, 11]
]

def pack_rooms_finish
  left = PackRooms.unused
  raise "PackRooms: rooms never handed to a door: #{left.join(', ')}" if !left.empty?
  PACK_DECOR.each { |id, x, y, size| k_wall_off(id, x, y, size: size) }
  # The Department Store roof's fence top and the sky above it
  pack_block_rect(181, 164, 53, 183, 55)
  pack_room_regions
end

# Makes every tile of a rectangle solid (like k_wall_off, for decoration that
# touches a floor)
def pack_block_rect(map_id, x0, y0, x1, y1)
  m = kmap(map_id)
  tile = K_BLOCK_TILE[m.tileset_id]
  (y0..y1).each do |y|
    (x0..x1).each do |x|
      next if m.data[x, y, 2] == tile
      raise "PackRooms: #{map_id} (#{x},#{y}) has an event" if event_at?(m, x, y)
      if m.data[x, y, 2] != 0
        next if m.data[x, y, 1] != 0
        m.data[x, y, 1] = m.data[x, y, 2]
      end
      m.data[x, y, 2] = tile
    end
  end
end

# Rooms on another region's composite map (Johto's Pokémon Centers on Kanto's
# map 182...) are that other region's ground: the game asks
# FullPoke.region_at, which reads these boxes (every floor of the room, found
# from its door through its stairs).
def pack_room_regions
  out = Hash.new { |h, k| h[k] = [] }
  PackRooms::USED.sort_by { |rid, _| rid.to_s }.each do |rid, (region, _town, _kind)|
    room = PackRooms.lib[rid]
    next if FullPoke.region_of_map(room[:map]) == region
    pack_room_floors(room[:map], room[:arrive]).each { |x0, y0, x1, y1| out[room[:map]] << [x0, y0, x1, y1, region] }
  end
  WORLD[:room_regions] = out.to_h
end

# Bounding boxes of the floors joined to (x, y) by walking and by the map's
# own stairs.
def pack_room_floors(map_id, start)
  m = kmap(map_id)
  warps = m.events.values.flat_map { |e| warp_cmds(e).select { |c| c.parameters[1] == map_id }.map { |c| [e.x, e.y, c.parameters[2], c.parameters[3]] } }
  seen = {}
  boxes = []
  todo = [start]
  until todo.empty?
    s = todo.shift
    next if seen[s]
    tiles = reachable_from(m, *s).keys
    tiles.each { |t| seen[t] = true }
    xs = tiles.map(&:first); ys = tiles.map(&:last)
    boxes << [xs.min, ys.min, xs.max, ys.max]
    near = tiles.flat_map { |x, y| [[x, y], [x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]] }.to_h { |t| [t, true] }
    warps.each { |wx, wy, dx, dy| todo << [dx, dy] if near[[wx, wy]] && !seen[[dx, dy]] }
  end
  boxes
end
