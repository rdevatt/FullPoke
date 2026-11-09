# Hoenn from the map pack's Ruby/Sapphire/Emerald-style maps. Coordinates were
# read off renders (tools/headless/render.sh) and passability grids
# (pass_grid.rb); doors are snapped to the nearest building front.
#
# Sea crossings the original games make by boat or Dive use boatmen here:
# Mr. Briney sails Route 104 <-> Dewford <-> Slateport (as in the games), and
# sailors at Mossdeep and Sootopolis stand in for diving into Sootopolis and
# for the long surf to Ever Grande.
GEO_SPEC ||= {}
GEO_SPEC[:hoenn] = {
  maps: {
    littleroot: 122, oldale: 123, petalburg: 113, slateport: 114, mauville: 115, rustboro: 116, fortree: 117,
    lilycove: 118, mossdeep: 119, sootopolis: 120, ever_grande: 121, lavaridge: 125, fallarbor: 126,
    verdanturf: 127, dewford: 124,
    r101: 129, r102: 130, r103: 131, r104: 132, woods: 566, r106: 134, r110: 138, r111: 139, r112: 140,
    r113: 141, r116: 144, rusturf: 515, r117: 145, r118: 146, r119: 147, r120: 148, r121: 149, r122: 150,
    r124: 152, r126: 154,
    r105: 133, r107: 135, r108: 136, r109: 137, r114: 142, r115: 143, r123: 151, r125: 153, r127: 155,
    r128: 156, r129: 157, r130: 158, r131: 159, r132: 160, r133: 161, r134: 162, pacifidlog: 128,
    granite: 562, meteor: 493, jagged: 568, fiery: 569, underpass: 382, mirage: 164, shoal: 20,
    southern_island: 612, pyre: 576, pyre_inside: 570, frontier: 11, larousse: 895, r135: 894,
    legendary_caves: 582, underwater: 886, small_caves: 517
  },
  links: [
    [:littleroot, 'North', :r101], [:r101, 'North', :oldale], [:oldale, 'West', :r102], [:oldale, 'North', :r103],
    [:r102, 'West', :petalburg], [:petalburg, 'West', :r104], [:r104, 'North', :rustboro],
    [:dewford, 'North', :r106], [:slateport, 'North', :r110], [:r110, 'North', :mauville],
    [:r103, 'East', :r110], [:mauville, 'West', :r117], [:r117, 'West', :verdanturf], [:mauville, 'North', :r111],
    [:mauville, 'East', :r118], [:r111, 'West', :r112], [:r112, 'West', :lavaridge], [:r111, 'West', :r113],
    [:r113, 'West', :fallarbor], [:rustboro, 'East', :r116],
    [:r118, 'North', :r119], [:r119, 'East', :fortree], [:fortree, 'East', :r120], [:r120, 'South', :r121],
    [:r121, 'East', :lilycove], [:r121, 'South', :r122], [:lilycove, 'East', :r124],
    [:r124, 'East', :mossdeep], [:r124, 'South', :r126],
    # The southern seas: Route 104's coast to Dewford, Dewford to Slateport, and
    # Slateport's waters east to Pacifidlog and Ever Grande
    [:r104, 'South', :r105], [:r105, 'South', :r106], [:dewford, 'East', :r107], [:r107, 'East', :r108],
    [:r108, 'East', :r109], [:r109, 'North', :slateport], [:r109, 'East', :r134], [:r134, 'East', :r133],
    [:r133, 'East', :r132], [:r132, 'East', :pacifidlog], [:pacifidlog, 'East', :r131], [:r131, 'East', :r130],
    [:r130, 'East', :r129], [:r129, 'East', :r128], [:r128, 'East', :ever_grande], [:r128, 'North', :r127],
    [:r127, 'North', :mossdeep], [:r126, 'East', :r127], [:mossdeep, 'North', :r125],
    # Routes 114 and 115 around Meteor Falls, and Route 123 from Route 118 to Mt. Pyre's sea
    [:fallarbor, 'West', :r114], [:rustboro, 'North', :r115], [:r118, 'East', :r123], [:r122, 'South', :r123],
    # Larousse City and the long Route 135 beside it (reached by ship)
    [:larousse, 'East', :r135]
  ],
  # Route 113 runs west from the top of Route 111 (above Route 112)
  offsets: { [:mauville, :r118] => 0, [:r111, :r113] => -21 },
  # Route 120's bridge over the pond: nothing in the pack puts the player on
  # the bridge layer, so walking onto it is a crossing from end to end.
  gates: [
    [:r120, [[32, 77], [32, 78]], [33, 78, 6], :r120, [[23, 77], [23, 78]], [22, 78, 4]],
    # Larousse City's gatehouse up to the hills east of town
    [:larousse, [[47, 43]], [47, 44, 2], :larousse, [[44, 36]], [44, 34, 8]],
    # Sootopolis (an unfinished map in the pack): the crater's inner town to
    # the houses on its outer rim
    [:sootopolis, [[32, 19]], [33, 19, 6], :sootopolis, [[32, 18]], [31, 19, 4]]
  ],
  # Petalburg Woods sits between Route 104's two halves
  warps: [
    [:r104, [40, 30], :woods, { near: [40, 8], pick: :top }, { out_a: 8 }],
    [:r104, [41, 30], :woods, { near: [40, 8], pick: :top }, { out_a: 8, one_way: true }],
    [:r104, [40, 39], :woods, { near: [24, 25], pick: :bottom }, { out_a: 2 }],
    [:r104, [41, 39], :woods, { near: [24, 25], pick: :bottom }, { out_a: 2, one_way: true }],
    # Granite Cave: the mouth at Route 106's east end opens on the big lower
    # floor; ladders join it to the floor above (laid out 35 rows higher on the
    # map), which climbs to the top floor; the back passage leads to the small
    # chamber at the bottom of the map
    [:r106, [48, 16], :granite, [10, 81], { out_a: 2, out_b: 8 }],
    [:granite, [29, 26], :granite, [29, 61]], [:granite, [12, 27], :granite, [12, 62]],
    [:granite, [8, 29], :granite, [8, 64]], [:granite, [29, 37], :granite, [29, 72]],
    [:granite, [28, 45], :granite, [28, 80]], [:granite, [4, 45], :granite, [17, 11]],
    [:granite, [25, 37], :granite, [35, 3]],
    [:granite, [21, 102], :granite, { near: [20, 6], pick: :top }, { out_a: 2 }],
    # Desert Underpass: the cave by Route 114's lake (the pack's own warp)
    [:r114, [8, 23], :underpass, [11, 19], { out_a: 2, out_b: 8 }],
    # Meteor Falls between Route 114 and Route 115: the south door and the east
    # cave mouth of 1F; ladders down to B1F and the upper chambers
    [:r114, [5, 21], :meteor, [6, 40], { out_a: 2, out_b: 8 }],
    [:r115, [44, 33], :meteor, [26, 28], { out_a: 2, out_b: 2 }],
    [:meteor, [10, 3], :meteor, { near: [60, 30], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:meteor, [5, 4], :meteor, [102, 8]], [:meteor, [49, 18], :meteor, [100, 25]],
    [:meteor, [52, 24], :meteor, [115, 17]], [:meteor, [66, 27], :meteor, { near: [157, 28], pick: :bottom }],
    # Rusturf Tunnel from Route 116's east end to the top of Verdanturf
    [:r116, [65, 20], :rusturf, { near: [5, 20], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:verdanturf, [88, 1], :rusturf, { near: [30, 22], pick: :bottom }, { out_a: 2, out_b: 8 }],
    # The Battle Frontier's little caves
    [:frontier, { near: [35, 98], pick: :left }, :small_caves, { near: [7, 50], pick: :bottom }, { out_b: 8 }],
    # Mirage Tower in Route 111's desert, its four floors side by side on the map
    [:r111, [20, 56], :mirage, { near: [10, 15], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:mirage, [16, 5], :mirage, [47, 5]], [:mirage, [35, 16], :mirage, [66, 16]], [:mirage, [78, 5], :mirage, [97, 5]],
    # Route 112: Fiery Path runs from the cable car's ledge to the mouth on the
    # north side; Jagged Pass climbs from the western ledge to Mt. Chimney
    [:r112, [23, 20], :fiery, [26, 5], { out_a: 2, out_b: 8 }],
    [:r112, [22, 10], :fiery, [26, 37], { out_a: 2, out_b: 8 }],
    [:r112, [5, 34], :jagged, { near: [21, 98], pick: :bottom }, { out_a: 2, out_b: 8 }],
    # Mt. Pyre's door on its island in Route 122; Shoal Cave's mouth on Route
    # 125 (the low-tide chambers; their inner passages reach the high-tide ones)
    [:r122, [76, 29], :pyre, [13, 79], { out_a: 2, out_b: 2 }],
    [:r125, [22, 29], :shoal, { near: [18, 30], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:shoal, [26, 2], :shoal, [26, 52]], [:shoal, [5, 2], :shoal, [5, 52]],
    # The legendary caves (one pack map): Cave of Origin below Sootopolis down to
    # Kyogre's pool; Magma Hideout from Jagged Pass up to Groudon's lava; the
    # Regi chambers of the Desert Ruins (Route 111), Island Cave (Route 105)
    # and Ancient Tomb (Route 120)
    [:jagged, [29, 17], :legendary_caves, [87, 67], { out_a: 2, out_b: 2 }],
    [:legendary_caves, { near: [80, 70], pick: :top }, :legendary_caves, { near: [86, 32], pick: :bottom }, { out_b: 8 }],
    [:legendary_caves, [7, 32], :legendary_caves, { near: [10, 70], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:legendary_caves, [10, 62], :legendary_caves, { near: [20, 95], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:legendary_caves, [21, 84], :legendary_caves, { near: [10, 4], pick: :top }, { out_a: 2 }],
    [:r111, [29, 84], :legendary_caves, { near: [122, 26], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:legendary_caves, [122, 20], :legendary_caves, { near: [122, 8], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:r105, [19, 18], :legendary_caves, { near: [122, 68], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:legendary_caves, [122, 62], :legendary_caves, { near: [122, 50], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:r120, [7, 63], :legendary_caves, { near: [156, 68], pick: :bottom }, { out_a: 2, out_b: 8 }],
    [:legendary_caves, [156, 62], :legendary_caves, { near: [156, 50], pick: :bottom }, { out_a: 2, out_b: 8 }]
  ],
  # Dive spots off Mossdeep and Sootopolis (Route 124 and 126) into the sea floor
  dives: [
    [:r124, [20, 30], :underwater, [20, 30], 7],
    [:r126, [10, 62], :underwater, [100, 100], 7]
  ],
  # The pack's unfinished sketch of Hoenn's special interiors (labels drawn
  # on a black floor) and its empty Gym placeholder (one floor tile everywhere)
  blank: [206, 509],
  # Cave tileset (Cavetiles Extended1): the Hoenn caves' walls, rocks, ledges
  # of rock plateaus, lava, signs and the cable car station were never given
  # passability (the plateau tops share the floor tile, which stays open)
  tile_fixes: {
    27 => {
      solid: [2197, 2198, 2199, 2205, 2207, 2213, 2214, 2215,              # brown rock plateau rims
              2237, 2238, 2239, 2245, 2247, 2253, 2254, 2255,              # red rock plateau rims
              2296, 2297, 2298, 2304, 2306, 2312, 2313, 2314,              # large red plateau rims
              2376, 2377, 2378, 2384, 2386, 2392, 2393, 2394,              # grey plateau rims
              2192, 2193, 2194, 2195, 2196, 2200, 2201, 2202, 2208, 2209, 2210,   # cave walls and mouths
              2216, 2217, 2218, 2224, 2225, 2226, 2400, 2401, 2402, 2408, 2409, 2410,
              2236, 2244, 2344, 2345, 2346, 2352, 2353, 2354, 2355, 2360, 2361, 2362, 2363,  # red cliffs
              2368, 2369, 2379, 2380,
              2168, 2176, 2203, 2204, 2211, 2212, 2227, 2325, 2333, 2339, 2340, 2406, 2414, 2415,  # rocks
              2329, 2330, 2235, 2243,                                      # lava, black
              *(2258..2263), *(2266..2271), *(2274..2279), *(2282..2287), *(2290..2295),  # cable car station
              *(2300..2303), *(2308..2311), *(2316..2319), 2321, 2336,  # fences, signs
              2331, 2342, 2343, 2358, 2359, 2382, 2383,                    # tree trunks
              2016, 2017, 2020, 2028, 2029, 2035, 2036, 2037, 2043, 2045, 2046, 2047,  # Meteor Falls walls
              2051, 2052, 2053, 2054, 2055, 2066, 2072, 2073, 2074, 2080, 2081, 2082,
              428],                                                        # blocker (see blockers)
      above: [2323, 2326, 2327, 2334, 2335, 2350, 2351, 2366, 2367, 2374, 2375],  # treetops
      # Cave sea ("Sea deep" autotile): its edges were solid and none of it was
      # water, so Meteor Falls' pools couldn't be surfed
      open: [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67,
             72, 73, 74, 75, 76, 77, 78, 79, 80, 86, 87, 88, 89, 92],
      tags: { 2381 => 7, 2389 => 7, **(48..95).to_h { |t| [t, 7] } }      # cave pools and sea
    }
  },
  # Invisible solid tiles (fully transparent, unused anywhere): 428 is made
  # solid above; 896 already is in tilesets 1 and 28
  blocker_tiles: { 27 => 428, 1 => 896, 28 => 896 },
  blockers: {
    granite: [[0, 0], [6, 40], [16, 40], [19, 47], [15, 1], [8, 39]],
    underpass: [[16, 0], [88, 29], [2, 22], [0, 0], [62, 33]],
    fiery: [2305],                                 # Fiery Path's rock between its tunnels
    legendary_caves: [2206, 2385, [50, 0]],        # the bare rock around its chambers
    pyre: [[2, 2]],                                # the sea drawn behind Mt. Pyre's summit
    meteor: [[35, 0]],                             # the rock around Meteor Falls' chambers
    sootopolis: [[1, 2], [2, 4], [0, 91], [0, 95], [0, 99]],  # frame lines around the unfinished map
    # The tops of Sootopolis' crater (Route 126) and of the Sky Pillar's rock
    # (Route 131), and rocks in the sea: drawn as walkable ground, but rock
    r126: [[43, 31], [40, 41], [38, 37], [52, 18], [41, 43], [10, 0], [33, 45], [29, 43], [59, 43], [55, 51],
           [3, 50], [35, 56], [50, 40], [20, 69]],
    r131: [[30, 11], [35, 5], [30, 5]]
  },
  # Areas the paths, doors and boats don't reach (cliff tops, ledges, islets,
  # chambers of the caves) get ladders from the reached parts (see
  # GeoRegion#link_areas); the points are on the reached parts
  link_areas: {
    littleroot: [17, 11], petalburg: [13, 74], slateport: [24, 38], mauville: [26, 8],
    rustboro: [[52, 36], [18, 15], [28, 29], [45, 0]], fortree: [35, 27], lilycove: [38, 51],
    mossdeep: [[31, 16], [70, 38], [4, 38]], sootopolis: [85, 37], ever_grande: [[20, 82], [17, 60]],
    lavaridge: [[4, 54], [43, 49], [48, 45]], fallarbor: [10, 34], dewford: [[26, 7], [58, 12], [78, 6]],
    r101: [62, 10], r103: [[23, 34], [37, 52]], r104: [[20, 58], [53, 23], [66, 73]],
    r110: [[8, 56], [37, 11], [0, 53]], r111: [12, 75], r112: [[13, 47], [35, 7]], r113: [55, 23],
    r116: [38, 20], r117: [36, 17], r118: [[10, 32], [72, 35]], r119: [[62, 98], [58, 145]],
    r121: [[69, 26], [58, 5], [105, 9], [35, 0]], r122: [[56, 26], [101, 25]], r126: [10, 67],
    r105: [[34, 62], [70, 37], [65, 0], [40, 4]], r107: [[44, 2], [22, 46]], r123: [80, 5], r125: [51, 18],
    r131: [34, 52], r132: [[31, 20], [9, 48], [33, 6], [73, 49]], r135: [52, 10],
    granite: [10, 80], meteor: [[19, 22], [65, 21], [112, 22], [156, 23]], jagged: [[22, 92], [26, 38]],
    underpass: [34, 14], mirage: [[15, 6], [78, 6], [34, 15], [103, 6]], shoal: [26, 15],
    southern_island: [43, 13], pyre: [24, 50], frontier: [73, 66], larousse: [[22, 56], [43, 33]],
    legendary_caves: [[86, 68], [120, 27], [120, 69], [154, 69]], underwater: [48, 114],
    rusturf: [[5, 20], [30, 22]], small_caves: [7, 50]
  },
  # Boatmen: walk up to one to sail (if you have the badges)
  ferries: [
    { name: 'Mr. Briney', at: [:r104, [44, 66]], to: [:dewford, [58, 22]], badges: 1, dest_name: 'Dewford Town' },
    { name: 'Mr. Briney', at: [:dewford, [58, 22]], to: [:r104, [44, 66]], badges: 0, dest_name: 'Route 104' },
    { name: 'Mr. Briney', at: [:dewford, [62, 22]], to: [:slateport, [28, 46]], badges: 2, dest_name: 'Slateport City' },
    { name: 'Mr. Briney', at: [:slateport, [28, 46]], to: [:dewford, [62, 22]], badges: 0, dest_name: 'Dewford Town' },
    { name: 'Sailor', at: [:mossdeep, [24, 26]], to: [:sootopolis, [27, 53]], badges: 7, dest_name: 'Sootopolis City' },
    { name: 'Sailor', at: [:sootopolis, [27, 53]], to: [:mossdeep, [24, 26]], badges: 0, dest_name: 'Mossdeep City' },
    { name: 'Sailor', at: [:sootopolis, [30, 53]], to: [:ever_grande, [22, 47]], badges: 8, dest_name: 'Ever Grande City' },
    { name: 'Sailor', at: [:ever_grande, [22, 47]], to: [:sootopolis, [30, 53]], badges: 0, dest_name: 'Sootopolis City' },
    # The pack's Route 119 north of the Weather Institute can't be crossed (its
    # river and bridges block every way), so a guide leads you along the trail
    { name: 'Weather Institute guide', graphic: 'NPC 11', at: [:r119, [46, 114]], to: [:fortree, [3, 19]], badges: 5, dest_name: 'Fortree City' },
    { name: 'Weather Institute guide', graphic: 'NPC 11', at: [:fortree, [2, 20]], to: [:r119, [46, 114]], badges: 0, dest_name: 'the Weather Institute' },
    # After the League: the ships out of Slateport's harbor
    { name: 'Sailor', at: [:slateport, [23, 46]], to: [:southern_island, [20, 18]], badges: 8, dest_name: 'Southern Island' },
    { name: 'Sailor', at: [:southern_island, [20, 18]], to: [:slateport, [23, 46]], badges: 0, dest_name: 'Slateport City' },
    { name: 'Sailor', at: [:slateport, [33, 46]], to: [:frontier, [30, 98]], badges: 8, dest_name: 'the Battle Frontier' },
    { name: 'Sailor', at: [:frontier, [30, 98]], to: [:slateport, [33, 46]], badges: 0, dest_name: 'Slateport City' },
    { name: 'Sailor', at: [:slateport, [18, 46]], to: [:larousse, [19, 40]], badges: 8, dest_name: 'Larousse City' },
    { name: 'Sailor', at: [:larousse, [19, 40]], to: [:slateport, [18, 46]], badges: 0, dest_name: 'Slateport City' },
    # Route 112's cable car up to Mt. Chimney (the top of the Jagged Pass map)
    { name: 'Cable Car attendant', graphic: 'NPC 11', at: [:r112, [27, 30]], to: [:jagged, [17, 39]], badges: 3, dest_name: 'Mt. Chimney' },
    { name: 'Cable Car attendant', graphic: 'NPC 11', at: [:jagged, [17, 39]], to: [:r112, [27, 30]], badges: 0, dest_name: 'Route 112' }
  ],
  start: { town: :littleroot, forest_gate: [[13, 18], [14, 18]], arrival: [14, 17], gate_dir: 'South' },
  towns: {
    littleroot: { stage: 0, doors: [[:home, 16, 8], [:lab, 18, 15, "Professor Birch's Lab"],
                                    [:house, 27, 8, "May's House", ["May's mom: May went out to study Pokémon. She'd love a rival like you!"]]] },
    oldale: { stage: 1, doors: [[:pc, 7, 16], [:mart, 15, 6], [:house, 5, 7], [:house, 16, 16]] },
    petalburg: { stage: 5, doors: [[:gym, 22, 63], [:pc, 21, 71], [:mart, 26, 68],
                                   [:house, 7, 63, "Wally's House", ["Wally's mother: Wally is staying in Verdanturf for his health. The clean air there helps."]],
                                   [:house, 15, 63], [:house, 11, 74]] },
    rustboro: { stage: 1, doors: [[:big, 42, 15, 'Devon Corporation', ["Welcome to Devon Corporation! We make Poké Navs, Running Shoes... and Repeat Balls!"]],
                                  [:gym, 61, 28], [:pc, 47, 38], [:mart, 47, 45], [:house, 43, 30],
                                  [:house, 39, 38, 'Pokémon Trainer School', ["Today's lesson: status conditions! Paralysis halves your Pokémon's Speed."]],
                                  [:house, 57, 34], [:house, 57, 46]] },
    dewford: { stage: 2, doors: [[:pc, 63, 10], [:gym, 58, 17], [:house, 68, 17, 'Dewford Hall'], [:mart, 56, 23], [:house, 63, 4]] },
    slateport: { stage: 3, doors: [[:big, 10, 12, 'Contest Hall', ["The Contest Hall is preparing for its next show."]], [:mart, 14, 19], [:pc, 20, 19],
                                   [:big, 28, 12, "Stern's Shipyard", ["Captain Stern: My submarine will reach the Seafloor Cavern someday!"]], [:house, 6, 19],
                                   [:big, 30, 27, 'Oceanic Museum', ["The Oceanic Museum: exhibits about the sea and the Pokémon that live in it."]],
                                   [:house, 22, 43], [:house, 26, 43]] },
    mauville: { stage: 3, doors: [[:house, 8, 5, "Rydel's Cycles", ["Rydel: Bikes make the long roads of Hoenn a breeze!"]], [:pc, 23, 5], [:gym, 28, 7], [:house, 36, 5],
                                  [:big, 8, 13, 'Game Corner', ["The Game Corner is closed today."]], [:house, 20, 14], [:mart, 24, 14], [:house, 33, 14]] },
    verdanturf: { stage: 3, doors: [[:pc, 97, 3], [:mart, 93, 3], [:big, 83, 7, 'Contest Hall'], [:house, 82, 14, "Wally's Uncle's House"], [:house, 90, 14]] },
    lavaridge: { stage: 4, doors: [[:gym, 45, 48], [:pc, 50, 48], [:mart, 56, 47], [:house, 45, 57, 'Herb Shop'], [:house, 53, 57]] },
    fallarbor: { stage: 4, doors: [[:pc, 17, 30], [:house, 16, 23], [:big, 9, 30, 'Contest Hall'], [:mart, 16, 36], [:house, 7, 37, "Professor Cozmo's House"]] },
    fortree: { stage: 6, doors: [[:pc, 6, 16], [:mart, 5, 24], [:gym, 22, 21], [:house, 10, 13], [:house, 17, 13],
                                 [:house, 24, 13], [:house, 12, 24], [:house, 37, 24, 'Tree House', ["Living up in the trees is wonderful. The wind sings through the branches!"]]] },
    lilycove: { stage: 7, doors: [[:mart, 27, 15, 'Department Store'], [:big, 12, 16, 'Contest Hall'], [:pc, 25, 24], [:house, 13, 24], [:house, 37, 16],
                                  [:house, 40, 24], [:big, 23, 34, 'Lilycove Museum'], [:house, 12, 42, 'Cove Lily Motel']] },
    mossdeep: { stage: 7, doors: [[:house, 19, 9], [:house, 29, 9], [:house, 37, 9, "Steven's House", ["A note: \"I'm off on a journey. Steven.\""]],
                                  [:pc, 29, 16], [:mart, 38, 18], [:house, 38, 23], [:gym, 64, 31],
                                  [:big, 64, 16, 'Space Center', ["The Mossdeep Space Center: rocket launches every few months!"]]] },
    sootopolis: { stage: 8, doors: [[:gym, 41, 59], [:pc, 27, 51], [:mart, 56, 51]] },
    ever_grande: { stage: 9, doors: [[:pc, 28, 49]] }
  },
  stages: {
    r101: 1, r102: 1, r103: 1, r104: 1, woods: 1, r116: 2, rusturf: 3, r106: 2, r110: 3, r117: 3,
    r111: 4, r112: 4, r113: 4, r118: 6, r119: 6, r120: 7, r121: 7, r122: 7, r124: 7, r126: 8,
    r105: 5, r107: 5, r108: 5, r109: 3, granite: 2, r114: 4, r115: 2, meteor: 4, jagged: 5, fiery: 4, mirage: 5,
    r123: 6, r125: 8, r127: 8, r128: 8, r129: 7, r130: 7, r131: 7, r132: 7, r133: 7, r134: 7,
    underpass: 9, shoal: 8, pyre: 7, legendary_caves: 9, underwater: 8, r135: 9
  },
  trainers: { r122: 1, r124: 2, r126: 2, r125: 1, r127: 1, r128: 1, r129: 1, r130: 1, r131: 1, r132: 1, r133: 1, r134: 1,
              r105: 1, r107: 1, r108: 1, granite: 1, meteor: 1, underpass: 1, legendary_caves: 1, underwater: 1, mirage: 1 },
  caves: [:rusturf, :mirage],
  requires: {
    r101: { starter: true }, dewford: 1, r106: 1, slateport: 2, r110: 2, mauville: 2,
    r111: { badges: 3, extras: 3 }, r117: { badges: 3, extras: 3 }, verdanturf: 3, rusturf: 3, r112: 3, lavaridge: 3,
    r113: 3, fallarbor: 3,
    r118: { badges: 5, extras: 5 }, r119: 5, fortree: 5,
    r120: { badges: 6, extras: 6 }, r121: 6, lilycove: 6, r122: 6, r124: 6, mossdeep: 6,
    sootopolis: 7, r126: 7, ever_grande: 8,
    granite: 1, r105: 4, r107: 4, r108: 4, r109: 2, r114: 3, r115: 1, meteor: 3, underpass: 8, mirage: 4,
    r123: 5, r125: 7, r127: 7, r128: 7, r129: 6, r130: 6, r131: 6, r132: 6, r133: 6, r134: 6, pacifidlog: 6,
    jagged: 4, fiery: 3, pyre: 6, shoal: 7, underwater: 7,
    southern_island: { completed: true }, frontier: { completed: true }, small_caves: { completed: true },
    larousse: { completed: true }, r135: { completed: true }, legendary_caves: { completed: true }
  },
  story: [
    { kind: :battle, key: :hoenn_rival2, at: [:r110, [20, 80]], intro: "May: Hi! Let's see how much you and your Pokémon have grown!" },
    { kind: :battle, key: :hoenn_maxie, at: [:jagged, [20, 20]], intro: "Maxie: With the volcano's power, Team Magma will expand the land! Don't interfere!" },
    { kind: :battle, key: :hoenn_rival3, at: [:r119, [40, 120]], intro: "May: The Weather Institute is just ahead. But first, a battle!" },
    { kind: :npc, name: 'Team Aqua Grunt', graphic: 'NPC 21', at: [:slateport, [24, 30]],
      lines: ["Grunt: The Oceanic Museum has the Devon Goods we want. Team Aqua will expand the seas!"] },
    { kind: :npc, name: 'Team Magma Grunt', graphic: 'NPC 22', at: [:lavaridge, [50, 52]],
      lines: ["Grunt: Our leader Maxie is up on the mountain above Route 112. Keep away!"] },
    { kind: :npc, name: 'Wally', graphic: 'NPC 02', at: [:verdanturf, [86, 18]],
      lines: ["Wally: I'm getting stronger every day here. Someday I'll battle you!"] }
  ],
  victory_road: { from: :ever_grande, at: [[18, 41]] }
}
