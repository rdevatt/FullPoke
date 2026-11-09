# Johto from the map pack's HeartGold/SoulSilver-style maps. Coordinates were
# read off renders of each map (tools/headless/render.sh); doors and gate faces
# are snapped to the nearest building front by the builder.
GEO_SPEC ||= {}
GEO_SPEC[:johto] = {
  maps: {
    new_bark: 7, r29: 93, cherrygrove: 17, r30: 891, r31: 97, violet: 21, r32: 98, r33: 99, azalea: 18,
    ilex: 196, r34: 100, goldenrod: 85, r35: 101, park: 192, r36: 102, r37: 103, ecruteak: 90, r38: 104,
    r39: 105, olivine: 88, r40: 106, r41: 107, cianwood: 28, r42: 108, mahogany: 89, r43: 109, rage: 201,
    r44: 110, blackthorn: 92, r45: 111, r46: 112, r27: 60, r26: 59, r47: 178, r48: 180,
    union_cave: 397, ice_path: 187,
    sprout: 199, slowpoke_well: 188, lighthouse: 200, bell_tower: 197, dark_cave: 185, dragons_den: 186,
    park: 192, ruins: 193, ruins_caves: 195, cliffedge: 184, cliff_caves: 893, tohjo: 204, r28: 94,
    mt_silver: 171, alto_mare: 96, r49: 277,
    # The map pack's own Johto interiors (a gatehouse, two house rooms)
    gate_rooms: 14, town_rooms: 9
  },
  # Mt. Silver is only an empty placeholder in the map pack: generated as a cave
  generate: { mt_silver: { size: [64, 52], ports: [['South', 0.5], ['North', 0.4], ['West', 0.3], ['East', 0.7]], rocks: 10 } },
  # Seamless map connections (offsets found automatically from the open ground)
  links: [
    [:new_bark, 'West', :r29], [:r29, 'West', :cherrygrove], [:cherrygrove, 'North', :r30],
    [:r30, 'North', :r31], [:violet, 'South', :r32], [:r33, 'West', :azalea], [:r34, 'North', :goldenrod],
    [:goldenrod, 'North', :r35], [:r35, 'North', :r36], [:r36, 'North', :r37], [:r37, 'North', :ecruteak],
    [:r38, 'West', :r39], [:r39, 'South', :olivine], [:olivine, 'West', :r40], [:r40, 'South', :r41],
    [:r41, 'West', :cianwood], [:cianwood, 'North', :r47], [:r47, 'North', :r48], [:r42, 'East', :mahogany],
    [:mahogany, 'North', :r43], [:r43, 'North', :rage], [:mahogany, 'East', :r44], [:blackthorn, 'South', :r45],
    [:r46, 'South', :r29], [:new_bark, 'East', :r27], [:r27, 'East', :r26],
    [:alto_mare, 'North', :r49]
  ],
  # Gatehouses: [map, tiles that lead through, [x, y, facing] where you come
  # out on that map, other map, its tiles, its arrival]
  gates: [
    [:violet, [[37, 37], [37, 38], [37, 39]], [36, 38, 4], :r31, [[2, 37], [2, 38], [2, 39]], [3, 38, 6]],
    [:violet, [[2, 22], [2, 23], [2, 24]], [3, 23, 6], :r36, [[75, 9], [75, 10]], [74, 9, 4]],
    [:ecruteak, [[2, 33], [2, 34], [2, 35], [2, 36]], [3, 35, 6], :r38, [[28, 18], [28, 19], [28, 20]], [27, 19, 4]],
    [:ecruteak, [[37, 40], [37, 41], [37, 42]], [36, 41, 4], :r42, [[4, 60], [4, 61], [3, 62]], [5, 61, 6]],
    [:azalea, [[2, 45], [2, 46], [2, 47]], [3, 46, 6], :ilex, [[11, 74], [11, 75], [11, 76]], [10, 75, 4]],
    [:ilex, [[6, 11], [7, 11]], [6, 12, 2], :r34, [[70, 43], [71, 43], [72, 43], [70, 42], [71, 42], [72, 42]], [74, 38, 8]],
    [:goldenrod, [[68, 2], [69, 2]], [69, 4, 2], :r35, [[67, 25]], [68, 24, 8]],
    [:mahogany, [[10, 3], [11, 3]], [10, 4, 2], :r43, [[13, 53]], [13, 51, 8]]
  ],
  offsets: { [:goldenrod, :r35] => 0, [:mahogany, :r43] => 0, [:r37, :ecruteak] => 30, [:new_bark, :r27] => -85, [:r27, :r26] => 0, [:r33, :azalea] => -39, [:alto_mare, :r49] => 14 },
  # Cave mouths: [map, entrance, map, entrance]. { near:, pick: } picks the
  # top- or bottom-most tile of the walkable area around `near` (cave floors).
  warps: [
    [:r32, [13, 79], :union_cave, { near: [5, 10], pick: :top }, { out_a: 8 }],
    [:r33, [21, 9], :union_cave, { near: [5, 10], pick: :bottom }, { out_a: 2 }],
    [:r44, [56, 62], :ice_path, { near: [10, 70], pick: :bottom }, { out_a: 2 }],
    [:blackthorn, [43, 16], :ice_path, { near: [10, 70], pick: :top }, { out_a: 2 }],
    [:azalea, [27, 43], :slowpoke_well, { near: [119, 6], pick: :top }, { out_a: 2 }],
    [:r31, [34, 36], :dark_cave, { near: [52, 83], pick: :bottom }, { out_a: 2 }],
    [:blackthorn, [25, 14], :dragons_den, { near: [5, 4], pick: :bottom }, { out_a: 2 }],
    # National Park: the gatehouse where Routes 35 and 36 meet, and through the
    # park's own east gatehouse
    [:r36, { door: [20, 21] }, :park, [99, 44], { out_b: 4 }],
    [:park, [70, 44], :park, [75, 44], { out_a: 4, out_b: 6 }],
    # Ruins of Alph: the gates on Routes 36 (north) and 32 (east), and the chambers
    [:r36, { door: [33, 11] }, :ruins, [26, 0], { out_b: 2 }],
    [:r32, { door: [4, 3] }, :ruins, [59, 48], { out_b: 4 }],
    [:ruins, { door: [37, 8] }, :ruins_caves, { near: [49, 22], pick: :top }],
    # Cianwood's cliff: Cliff Edge Gate up to Route 47, and Route 47's Cliff Cave
    [:cianwood, [3, 23], :cliffedge, { near: [9, 1], pick: :top }, { out_a: 6 }],
    [:cliffedge, { near: [11, 33], pick: :bottom }, :r47, [16, 57], { out_b: 8 }],
    [:r47, [88, 44], :cliff_caves, { near: [4, 15], pick: :bottom }, { out_a: 2 }],
    # Champions only: Route 28 past the League gate, and Mt. Silver beyond it
    [:r26, [5, 6], :gate_rooms, [6, 12], { out_a: 6 }],
    [:gate_rooms, [6, 3], :r28, [46, 9], { out_b: 4 }],
    [:gate_rooms, [1, 4], :town_rooms, { near: [13, 13], pick: :bottom }, { out_a: 6 }],
    [:r28, [3, 2], :mt_silver, { near: [33, 27], pick: :bottom }, { out_a: 2 }],
    # Tohjo Falls: in the woods north of Route 27's clearing
    [:r27, [28, 90], :tohjo, [40, 89], { out_a: 2 }]
  ],
  start: { town: :new_bark, forest_gate: [[10, 26], [11, 26], [12, 26]], arrival: [11, 25], gate_dir: 'South' },
  towns: {
    new_bark: { stage: 0, doors: [[:home, 4, 11], [:lab, 13, 12, "Professor Elm's Lab"], [:house, 5, 21], [:house, 13, 23]] },
    cherrygrove: { stage: 1, doors: [[:mart, 48, 8], [:pc, 57, 8], [:house, 41, 14], [:house, 49, 17],
                                     [:house, 58, 18, 'Guide Gent', ["I've lived in Cherrygrove all my life.", "Violet City is north, past Routes 30 and 31. Its Gym Leader, Falkner, uses Flying-type Pokémon."]]] },
    violet: { stage: 1, doors: [[:big, 8, 20, 'Elder', ["The Sprout Tower was built around a swaying pillar.", "Falkner's Gym is at the south end of town."]],
                                [:mart, 16, 24], [:house, 21, 30, "Earl's Pokémon Academy", ["Earl: Welcome, welcome! Status problems? Cure them with items or at a Pokémon Center!"]],
                                [:pc, 35, 30], [:house, 7, 31], [:house, 12, 31], [:house, 8, 40], [:gym, 26, 40],
                                [:dungeon, 30, 15, [:sprout, 11, 28]]] },
    azalea: { stage: 2, doors: [[:house, 5, 42, "Kurt's House", ["Kurt: I make Poké Balls from Apricorns. The Slowpoke here are in danger. Team Rocket's been seen at the well!"]],
                                [:house, 9, 42, 'Charcoal Kiln'], [:pc, 17, 43], [:mart, 22, 43], [:gym, 33, 44],
                                [:house, 12, 47]] },
    goldenrod: { stage: 3, doors: [[:big, 33, 13, 'Radio Tower', ["Welcome to the Goldenrod Radio Tower! Today's program: Professor Oak's Pokémon Talk."]],
                                   [:mart, 53, 12, 'Department Store'], [:house, 61, 12, 'Magnet Train Station', ["The Magnet Train to Saffron City isn't running today."]],
                                   [:house, 74, 5, 'Bike Shop', ["We sell the fastest bikes in Johto!"]], [:pc, 55, 25], [:gym, 79, 24],
                                   [:big, 62, 19, 'Game Corner', ["The Game Corner is closed for renovations."]],
                                   [:house, 75, 12], [:house, 57, 19], [:house, 73, 24], [:house, 61, 24]] },
    ecruteak: { stage: 4, doors: [[:big, 18, 33, 'Dance Theater', ["The Kimono Girls dance here every evening."]], [:house, 14, 33], [:house, 10, 35],
                                  [:mart, 30, 36], [:house, 27, 36], [:gym, 12, 41], [:house, 20, 41], [:house, 12, 47], [:pc, 21, 47],
                                  [:house, 28, 46], [:house, 31, 46],
                                  [:closed, 7, 27, 'Burned Tower', ["The Burned Tower: it burned down long ago. It isn't safe to go in."]],
                                  [:dungeon, 31, 24, [:bell_tower, { near: [49, 30], pick: :bottom }]]] },
    cianwood: { stage: 5, doors: [[:gym, 8, 15], [:house, 6, 33], [:mart, 16, 37], [:house, 6, 42],
                                  [:house, 11, 42, 'Pharmacy', ["Our secret medicine works on any sick Pokémon, even the one at the lighthouse!"]],
                                  [:house, 6, 50], [:pc, 18, 50]] },
    olivine: { stage: 6, doors: [[:gym, 28, 7], [:house, 10, 9], [:mart, 21, 11], [:house, 6, 17], [:house, 10, 17], [:house, 14, 17],
                                 [:pc, 10, 24], [:house, 15, 24],
                                 [:dungeon, 33, 20, [:lighthouse, { near: [8, 12], pick: :bottom }]]] },
    mahogany: { stage: 7, doors: [[:pc, 6, 7], [:mart, 5, 13], [:gym, 14, 14], [:house, 14, 8],
                                  [:house, 18, 8, 'Souvenir Shop', ["Rage Candy Bars! Get your Rage Candy Bars!"]]] },
    blackthorn: { stage: 8, doors: [[:gym, 16, 28], [:house, 22, 24, 'Dragon Clan Elder', ["Only those who have proven themselves may face the dragon masters."]],
                                    [:house, 29, 26], [:pc, 28, 32], [:mart, 24, 35], [:house, 11, 34], [:house, 16, 34], [:house, 35, 32]] }
  },
  # Level band (stage) of each area: wild Pokémon and trainers
  stages: {
    r29: 1, r30: 1, r31: 1, r32: 2, union_cave: 2, r33: 2, ilex: 3, r34: 3, r35: 4, r36: 4, r37: 4,
    r38: 5, r39: 5, r40: 5, r41: 5, r47: 6, r48: 6, r42: 7, r43: 7, rage: 7, r44: 8, ice_path: 8,
    r45: 9, r46: 9, r27: 9, r26: 9,
    sprout: 1, dark_cave: 2, slowpoke_well: 2, park: 4, ruins: 4, ruins_caves: 4, lighthouse: 5, cliffedge: 5,
    cliff_caves: 6, bell_tower: 8, dragons_den: 9, tohjo: 9, r28: 9, mt_silver: 9, alto_mare: 9, r49: 9
  },
  trainers: { r40: 2, r41: 2, rage: 2 },
  caves: [:union_cave, :ice_path, :sprout, :bell_tower, :lighthouse, :slowpoke_well, :dark_cave, :dragons_den,
          :ruins_caves, :cliffedge, :cliff_caves, :tohjo, :mt_silver],
  # Maps drawn as several separate floors or levels: ladders join every part
  # to the ones reached from the way in (see GeoRegion#link_areas)
  link_areas: {
    sprout: [11, 27], bell_tower: [49, 29], lighthouse: [8, 11], slowpoke_well: [119, 7], union_cave: [5, 10],
    ice_path: [32, 22], dark_cave: [52, 82], ruins_caves: [49, 23], cliff_caves: [4, 10], ruins: [[26, 1], [58, 48]],
    tohjo: [40, 88], r28: [18, 2], r48: [60, 18], gate_rooms: [6, 11], town_rooms: [13, 13],
    # Outdoors: cliff tops, ledges and shores the paths don't reach (the points
    # are on the paths, and on the sea where Surf reaches)
    new_bark: [1, 13], cherrygrove: [5, 1], violet: [37, 31], cianwood: [[13, 13], [1, 1], [14, 1]],
    goldenrod: [[1, 1], [9, 31]], olivine: [19, 1], blackthorn: [25, 16], r26: [[27, 25], [8, 7]],
    r27: [[8, 107], [22, 92]], r30: [[21, 2], [5, 39]], r31: [30, 34], r32: [9, 4], r33: [8, 1],
    r34: [[1, 1], [44, 1], [62, 1]], r35: [[44, 8], [97, 18]], park: [[36, 22], [77, 44]], r37: [[46, 1], [1, 16]],
    r38: [25, 19], r39: [35, 12], r40: [[1, 24], [48, 16]], r41: [28, 3], r42: [[6, 61], [58, 64]], r43: [3, 13],
    rage: [48, 8], r45: [26, 1], r46: [27, 20], r47: [[93, 52], [1, 39]], r49: [[1, 1], [138, 3]]
  },
  # Badges needed to enter (and the town's story battles from `extras`)
  requires: {
    r29: { starter: true }, r32: 1, union_cave: 1, r33: 1, azalea: 1,
    ilex: { badges: 2, extras: 2 }, r34: { badges: 2, extras: 2 }, goldenrod: 2,
    r35: 3, r36: 3, r37: 3, ecruteak: 3,
    r38: { badges: 4, extras: 4 }, r39: 4, olivine: 4, r40: 4, r41: 4, cianwood: 4, r47: 5, r48: 5,
    r42: 6, mahogany: 6, r43: 6, rage: 6,
    r44: { badges: 7, extras: 7 }, ice_path: 7, blackthorn: 7,
    r45: 8, r46: 8, r27: 8, r26: 8,
    slowpoke_well: 1, park: 3, ruins: 3, ruins_caves: 3, lighthouse: 4, cliffedge: 4, cliff_caves: 5,
    bell_tower: 7, dragons_den: 8, tohjo: 8,
    r28: { completed: true }, mt_silver: { completed: true }, alto_mare: { completed: true }, r49: { completed: true }
  },
  story: [
    { kind: :battle, key: :johto_rival2, at: [:azalea, [6, 45]], intro: "Silver: You again? I'll show you what real power is!" },
    { kind: :battle, key: :johto_rival3, at: [:ecruteak, [7, 29]], intro: "Silver: The legendary Pokémon of the Burned Tower... I'll be the one to catch it. Out of my way!" },
    { kind: :battle, key: :johto_archer, interior: [:mahogany, 18, 8], intro: "Archer: Team Rocket's base is right under this shop. You won't leave here in one piece!" },
    { kind: :wild, species: [:GYARADOS, 30], flag: :red_gyarados, at: [:rage, [40, 22]], name: 'Red Gyarados',
      graphic: '', intro: "The water churns... An enraged Gyarados surfaces!" },
    { kind: :wild, species: [:SUDOWOODO, 20], flag: :sudowoodo, at: [:r36, [40, 12]], name: 'Odd tree',
      graphic: '', intro: "It's an odd tree... It's moving! The tree attacked!" },
    { kind: :npc, name: 'Team Rocket Grunt', graphic: 'trainer_TEAMROCKET_M', at: [:azalea, [26, 45]],
      lines: ["Grunt: Slowpoke Tails sell for a fortune! Not that it's any of your business, kid."] },
    { kind: :npc, name: 'Lighthouse sailor', at: [:olivine, [30, 22]],
      lines: ["Jasmine stays by the sick Ampharos at the lighthouse. Cianwood's pharmacy across the sea has medicine that might help."] },
    # After the League: the boat to Alto Mare and back
    { kind: :ferry, at: [:olivine, [15, 30]], to: :alto_mare, requires: 8,
      early: "Sailor: The boat to Alto Mare only takes Champions of the Johto League." },
    { kind: :ferry, at: [:alto_mare, [79, 64]], to: :olivine }
  ],
  victory_road: { from: :r26, at: [[8, 5]] }
}
