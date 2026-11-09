# Sinnoh from the map pack's Diamond/Pearl/Platinum-style maps (tileset 31).
# Coordinates were read off renders (tools/headless/render.sh) and passability
# grids (pass_grid.rb); doors are snapped to the nearest building front.
# Mt. Coronet's caves aren't in the pack, so its passes are short warps or
# direct links between the routes on either side.
GEO_SPEC ||= {}
GEO_SPEC[:sinnoh] = {
  maps: {
    twinleaf: 209, sandgem: 210, jubilife: 211, oreburgh: 212, floaroma: 213, eterna: 214, hearthome: 215,
    solaceon: 216, veilstone: 217, pastoria: 218, celestic: 219, canalave: 220, snowpoint: 221, sunyshore: 222,
    league_isle: 223, r201: 227, r202: 228, r203: 229, r204: 230, r205: 231, r206: 232, r207: 233, r208: 234,
    r209: 236, r210: 237, r211w: 238, r211e: 900, r212: 239, r213: 240, r214: 241, r215: 242, r216: 243,
    r217: 244, r218: 245, r222: 250, r223: 251,
    r219: 246, r220: 247, r221: 248, wilds: 892, alamos: 888, fuego: 899, r224: 252,
    # The Battle Zone (postgame, by ferry from Snowpoint)
    fight_area: 224, frontier: 906, r225: 253, survival: 225, r226: 254, r227: 255, r228: 256,
    r229: 257, resort: 226, r230: 259
  },
  names: { league_isle: 'Pokémon League', r211w: 'Route 211', r211e: 'Route 211', wilds: 'Mt. Coronet' },
  links: [
    [:twinleaf, 'North', :r201], [:r201, 'East', :sandgem], [:sandgem, 'North', :r202], [:r202, 'North', :jubilife],
    [:jubilife, 'East', :r203], [:jubilife, 'North', :r204], [:r204, 'North', :floaroma],
    [:floaroma, 'East', :r205], [:r205, 'East', :eterna], [:eterna, 'South', :r206], [:r206, 'South', :r207],
    [:oreburgh, 'East', :r207], [:r208, 'East', :hearthome], [:solaceon, 'South', :r209],
    [:r210, 'South', :solaceon], [:r210, 'East', :r215], [:r215, 'East', :veilstone],
    [:r214, 'South', :r213], [:r213, 'West', :pastoria], [:pastoria, 'West', :r212],
    [:jubilife, 'West', :r218], [:r218, 'West', :canalave], [:r211e, 'East', :celestic], [:celestic, 'East', :r210],
    [:eterna, 'East', :r211w], [:r216, 'East', :r217],
    [:r217, 'North', :snowpoint], [:r213, 'East', :r222], [:r222, 'East', :sunyshore], [:sunyshore, 'North', :r223],
    [:r223, 'North', :league_isle],
    # Mt. Coronet's slopes (the pack's Wilds map) between the routes around it
    [:r216, 'South', :wilds], [:wilds, 'East', :r211e], [:wilds, 'West', :r207], [:r208, 'West', :wilds],
    [:wilds, 'East', :alamos], [:r205, 'West', :fuego], [:floaroma, 'North', :fuego],
    [:sandgem, 'South', :r219], [:r219, 'South', :r220], [:r220, 'East', :r221], [:league_isle, 'East', :r224],
    [:fight_area, 'East', :r230], [:r225, 'East', :survival],
    [:survival, 'East', :r226], [:r226, 'North', :r227], [:r226, 'East', :r228], [:r226, 'South', :r230],
    [:r228, 'South', :r229], [:r229, 'South', :resort], [:r229, 'West', :r230]
  ],
  # (b's coordinate along the edge = a's - offset; these follow the map pack's own connections)
  offsets: { [:r216, :r217] => -152, [:r205, :eterna] => 5, [:r222, :sunyshore] => -1, [:r206, :r207] => 0,
             [:r216, :wilds] => 101, [:wilds, :r211e] => 54, [:wilds, :r207] => 242, [:r208, :wilds] => -245,
             [:wilds, :alamos] => 104, [:r205, :fuego] => 70, [:floaroma, :fuego] => 0, [:r219, :r220] => -11,
             [:r220, :r221] => -3, [:league_isle, :r224] => -220, [:fight_area, :r230] => -8, [:r225, :survival] => 0,
             [:r226, :r227] => 60, [:r226, :r228] => 0, [:r226, :r230] => 0, [:r228, :r229] => 0, [:r229, :resort] => 22,
             [:r229, :r230] => -8, [:sandgem, :r219] => 0, [:survival, :r226] => 0,
             # The rest as best_offset found them before walls changed which edge tiles are open
             [:twinleaf, :r201] => -4, [:r201, :sandgem] => 0, [:sandgem, :r202] => -28, [:r202, :jubilife] => -6,
             [:jubilife, :r203] => -3, [:jubilife, :r204] => 26, [:r204, :floaroma] => -7, [:floaroma, :r205] => -114,
             [:eterna, :r206] => 0, [:oreburgh, :r207] => 0, [:r208, :hearthome] => -23, [:solaceon, :r209] => -30,
             [:r210, :solaceon] => 63, [:r210, :r215] => -2, [:r215, :veilstone] => 66, [:r214, :r213] => -62,
             [:r213, :pastoria] => 54, [:pastoria, :r212] => -38, [:jubilife, :r218] => -31, [:r218, :canalave] => 1,
             [:r211e, :celestic] => 0, [:celestic, :r210] => -14, [:eterna, :r211w] => 0, [:r217, :snowpoint] => 0,
             [:r213, :r222] => 0, [:sunyshore, :r223] => 11, [:r223, :league_isle] => 5 },
  gates: [
    # Hearthome's north gatehouse and Route 209's west exit
    [:hearthome, [[8, 8], [9, 8], [10, 8]], [9, 10, 2], :r209, [[0, 52], [0, 53], [0, 54], [0, 55], [0, 56]], [2, 54, 6]],
    # Hearthome's south stairs and Route 212's north gatehouse
    [:hearthome, [[7, 53], [8, 53], [9, 53], [10, 53]], [8, 51, 8], :r212, [[17, 3], [18, 3], [19, 3], [20, 3]], [18, 5, 2]],
    # Veilstone's south exit and Route 214's gatehouse
    # Oreburgh's east end and Route 207 (the map pack walls them apart)
    [:oreburgh, [[61, 13], [61, 14]], [60, 14, 4], :r207, [[2, 3], [2, 4], [2, 5]], [3, 4, 6]],
    # Eterna's south gatehouse and the top of the Cycling Road (Route 206)
    [:eterna, [[15, 56], [16, 56], [17, 56], [18, 56]], [16, 54, 8], :r206, [[15, 4], [16, 4], [17, 4], [18, 4]], [16, 6, 2]],
    # Route 213: the gatehouse between the hotel meadow and Valor Lakefront
    [:r213, [[57, 58]], [56, 58, 4], :r213, [[59, 58]], [60, 58, 6]],
    [:veilstone, [[34, 67], [35, 67], [36, 67], [37, 67], [38, 67], [39, 67]], [36, 64, 8], :r214, [[15, 3], [16, 3], [17, 3], [18, 3]], [16, 5, 2]],
    # Route 211's bridge into Mt. Coronet (a bridge across a map edge loses its BridgeOn)
    [:r211w, [[19, 20], [19, 21], [19, 22]], [9, 21, 4], :wilds, [[3, 77], [3, 78], [3, 79], [3, 80]], [5, 78, 6]],
    # The Fight Area's north gatehouse and the south gate of Route 225
    [:fight_area, [[22, 2], [23, 2]], [22, 4, 2], :r225, [[29, 101], [30, 101], [31, 101], [32, 101]], [30, 99, 8]],
    # The Fight Area's north stairs (drawn solid) and the Battle Frontier's south road
    [:fight_area, [[46, 5], [47, 5]], [46, 6, 2], :frontier, (38..64).map { |x| [x, 99] }, [51, 96, 8]],
    # Route 224 starts beside the League courtyard (the pack's edge doesn't line up)
    [:league_isle, [[29, 49], [29, 50], [29, 51]], [27, 50, 4], :r224, [[22, 229], [22, 230], [22, 231]], [20, 230, 4]]
  ],
  # Mt. Coronet: Route 207's cave mouth comes out below Route 208's cliffs
  warps: [
    # Oreburgh Gate: Route 203's cave mouth and Oreburgh's west tunnel
    [:r203, [49, 11], :oreburgh, [8, 12], { out_a: 2, out_b: 6 }],
    [:r207, [58, 7], :r208, [8, 12], { out_a: 4, out_b: 2 }],
    # Mt. Coronet's northern passage: Route 211's cave to the snowfields of Route 216
    [:r211e, [2, 9], :r216, [150, 30], { out_a: 2, out_b: 2 }]
  ],
  # The League island's dock: surf up to its south shore to land (one way; the
  # Grove Compass or the Hall of Fame takes you back)
  docks: [[:league_isle, (15..30).map { |x| [x, 77] }, [22, 68, 8]]],
  ferries: [
    { name: 'Sailor', at: [:snowpoint, [10, 56]], to: [:fight_area, [9, 18]], completed: true, dest_name: 'the Battle Zone' },
    { name: 'Sailor', at: [:fight_area, [9, 18]], to: [:snowpoint, [10, 56]], badges: 0, dest_name: 'Snowpoint City' }
  ],
  start: { town: :twinleaf, forest_gate: [[27, 26], [28, 26], [29, 26]], arrival: [28, 25], gate_dir: 'South' },
  towns: {
    twinleaf: { stage: 0, doors: [[:home, 30, 9], [:house, 40, 9], [:house, 30, 18], [:house, 40, 18]] },
    sandgem: { stage: 0, doors: [[:lab, 8, 9, "Professor Rowan's Lab"], [:pc, 17, 9], [:mart, 27, 9], [:house, 22, 18], [:house, 27, 18],
                                  [:house, 8, 22], [:house, 16, 22]] },
    jubilife: { stage: 1, doors: [[:house, 19, 15, "Trainers' School", ["Welcome to the Trainers' School! Type matchups are the key to winning."]],
                                  [:house, 39, 15, 'Pokétch Company', ["Pokétch: the Pokémon Watch. Every Trainer in Sinnoh wants one!"]],
                                  [:pc, 55, 36], [:mart, 55, 29], [:house, 28, 16], [:house, 41, 37], [:house, 16, 49], [:house, 57, 54]] },
    oreburgh: { stage: 1, doors: [[:gym, 31, 17], [:pc, 55, 18], [:mart, 37, 9], [:house, 22, 7], [:house, 30, 7], [:house, 39, 17],
                                  [:big, 56, 12, 'Oreburgh Mining Museum', ["The Oreburgh Mine has given us coal for a hundred years — and fossils!"]]] },
    floaroma: { stage: 2, doors: [[:pc, 30, 47], [:mart, 38, 40], [:house, 27, 12, 'Pick a Peck of Colors', ["Floaroma's flowers bloom thanks to the sweet Honey we sell."]],
                                  [:house, 28, 30], [:house, 25, 38], [:house, 34, 47]] },
    eterna: { stage: 2, doors: [[:gym, 40, 27], [:pc, 17, 21], [:mart, 22, 37], [:house, 29, 12], [:house, 50, 12], [:house, 24, 21],
                                [:house, 22, 29], [:house, 11, 36],
                                [:big, 25, 48, 'Galactic Eterna Building', ["Team Galactic's grunts have cleared out. Nobody's here."]]] },
    veilstone: { stage: 3, doors: [[:gym, 30, 50], [:pc, 42, 38], [:mart, 23, 31, 'Veilstone Department Store'], [:house, 37, 31],
                                   [:house, 12, 49], [:house, 18, 49], [:house, 22, 49],
                                   [:big, 7, 40, 'Game Corner', ["The Game Corner is closed for renovations."]],
                                   [:big, 43, 18, 'Galactic HQ', ["Team Galactic's headquarters. The doors are locked tight."]]] },
    pastoria: { stage: 4, doors: [[:gym, 12, 27], [:pc, 25, 17], [:house, 44, 28], [:house, 26, 42],
                                  [:closed, 34, 4, 'Great Marsh', ["The Great Marsh Safari Game is closed today."]]] },
    hearthome: { stage: 5, doors: [[:gym, 51, 20], [:pc, 16, 20], [:mart, 22, 20], [:house, 37, 20],
                                   [:house, 10, 32, 'Poffin House', ["Cooking Poffins makes Pokémon happy!"]], [:house, 23, 33],
                                   [:house, 40, 33], [:house, 45, 33], [:big, 32, 11, 'Contest Hall', ["Super Contests are held here. Not today, though!"]]] },
    canalave: { stage: 6, doors: [[:gym, 16, 26], [:pc, 34, 18], [:house, 27, 27, 'Canalave Library', ["The library holds old myths about the Pokémon of Sinnoh's lakes."]],
                                  [:house, 16, 37], [:house, 30, 37], [:house, 16, 45], [:house, 30, 45]] },
    celestic: { stage: 6, doors: [[:pc, 25, 35], [:mart, 10, 34], [:house, 16, 23, "Elder's House", ["Elder: The ruins here tell of the time and space Pokémon. Cyrus was asking about them..."]],
                                  [:house, 4, 7], [:house, 17, 7], [:house, 24, 7]] },
    snowpoint: { stage: 7, doors: [[:gym, 17, 31], [:pc, 30, 43], [:mart, 5, 43], [:house, 5, 19], [:house, 28, 19],
                                   [:closed, 17, 10, 'Snowpoint Temple', ["Only those the Pokémon League recognizes may enter the temple."]]] },
    sunyshore: { stage: 8, doors: [[:gym, 16, 23], [:pc, 29, 45], [:mart, 22, 30], [:house, 45, 7], [:house, 53, 7],
                                   [:big, 57, 48, 'Vista Lighthouse', ["From the top of the lighthouse you can see the Pokémon League across the sea."]]] }
  },
  stages: {
    r201: 1, r202: 1, r203: 1, r204: 2, r205: 2, r206: 3, r207: 3, r208: 3, r209: 3, r210: 3, r215: 3,
    r214: 4, r213: 4, r212: 5, r218: 6, r211w: 6, r211e: 6, r216: 7, r217: 7, r222: 8, r223: 9,
    fuego: 2, r219: 6, r220: 6, r221: 6, wilds: 6, r224: 9, r225: 9, r226: 9, r227: 9, r228: 9, r229: 9, r230: 9
  },
  trainers: { r218: 2, r223: 2 },
  requires: {
    r202: { starter: true }, r204: 1, floaroma: 1, r205: 1, eterna: 1,
    r206: 2, r207: 2, r208: 2, hearthome: 2, r209: 2, solaceon: 2, r210: 2, r215: 2, veilstone: 2,
    r214: 3, r213: 3, pastoria: 3, r212: { badges: 4, extras: 4 },
    r218: 5, canalave: 5, r211w: 5, r211e: 5, celestic: 5,
    r216: 6, r217: 6, snowpoint: 6,
    r222: { badges: 7, extras: 7 }, sunyshore: { badges: 7, extras: 7 }, r223: 8, league_isle: 8,
    fuego: 1, r219: 5, r220: 5, r221: 5, wilds: 5, alamos: 5,
    **%i[r224 fight_area frontier r225 survival r226 r227 r228 r229 resort r230].to_h { |k| [k, { completed: true }] }
  },
  story: [
    { kind: :battle, key: :sinnoh_rival2, at: [:pastoria, [30, 30]], intro: "Barry: There you are! I'm gonna be the one who beats Crasher Wake first! Let's battle!" },
    { kind: :battle, key: :sinnoh_cyrus, at: [:snowpoint, [18, 14]], intro: "Cyrus: A new world without spirit... You would stand in its way? Then I'll crush you here." },
    { kind: :npc, name: 'Galactic Grunt', graphic: 'trainer_TEAMROCKET_M', at: [:eterna, [27, 47]],
      lines: ["Grunt: Team Galactic will make a new world! ...Our boss is up north at Snowpoint now."] },
    { kind: :npc, name: 'Rowan aide', at: [:sandgem, [12, 12]],
      lines: ["Professor Rowan studies how Pokémon evolve. The Gyms of Sinnoh start at Oreburgh City, east of Jubilife."] },
    { kind: :wild, species: [:DRIFLOON, 22], flag: :valley_drifloon, at: [:r205, [55, 145]], name: 'Valley Windworks Drifloon',
      graphic: '', intro: "A Drifloon floats over from the Valley Windworks!" }
  ],
  victory_road: { from: :league_isle, at: [[22, 66]] },
  # The Cycling Road's south BridgeOn switches are four rows short of the deck
  bridge_switches: { r206: { on: (10..20).map { |x| [x, 105] } } },
  # Tile 520 is blank; walls (mountain tops drawn with walkable rock) use it
  tile_fixes: { 31 => { solid: [520] } },
  wall_tile: 520,
  # Rock plateaus, mountain tops and sea beyond lines of rocks, where no path
  # leads (from SURF=1 AUDIT=@sinnoh_ids.txt AUDIT_AREAS=1 t_reach.rb: areas of
  # rock or water ground)
  walls: {
    oreburgh: [[67, 4], [10, 26], [0, 0], [54, 0], [7, 17], [15, 26], [41, 52]],
    eterna: [[61, 28]],
    solaceon: [[62, 9], [66, 15]],
    sunyshore: [[64, 37], [7, 59], [57, 54]],
    league_isle: [[31, 55], [12, 58], [24, 60]],
    r203: [[48, 0], [44, 0]],
    # Water under railed bridges that no shore reaches (boxed to the strip)
    r212: [[37, 107, 28, 107, 71, 123]],
    r205: [[64, 146], [22, 165], [28, 165], [26, 68], [9, 131], [94, 136], [5, 91], [62, 63], [74, 145], [10, 82], [10, 120], [45, 162], [78, 13], [30, 142], [59, 145], [78, 158], [59, 163], [31, 136]],
    r206: [[28, 37], [31, 96], [52, 0], [22, 0], [47, 0], [30, 113], [82, 21], [0, 36], [0, 96], [56, 114], [0, 18], [68, 124], [74, 18], [39, 122], [80, 0]],
    r207: [[67, 0], [25, 21], [18, 25], [63, 23], [2, 23], [0, 0], [64, 0]],
    r208: [[0, 32]],
    r209: [[58, 29], [58, 58], [8, 0]],
    r210: [[61, 31], [58, 33], [63, 30], [3, 0], [26, 0], [64, 0], [0, 114], [90, 0], [56, 0], [43, 0], [66, 51], [88, 0], [21, 0], [66, 39], [69, 95], [74, 9], [51, 0], [2, 14], [68, 86]],
    r211w: [[1, 26], [15, 27], [2, 0], [17, 0], [18, 23, 18, 23, 19, 59]],
    r211e: [[31, 0], [5, 31], [3, 14], [32, 30]],
    r213: [[60, 25], [54, 106], [15, 86], [16, 90]],
    r214: [[0, 29], [0, 68], [0, 16], [21, 9]],
    r215: [[41, 92], [59, 100], [21, 100]],
    r216: [[37, 0], [94, 31], [102, 29], [30, 30], [33, 31], [36, 32], [34, 0], [124, 34], [28, 15]],
    r217: [[34, 11], [39, 190], [52, 29], [12, 33], [64, 17], [18, 15], [36, 189]],
    r218: [[14, 0], [24, 58]],
    r223: [[25, 41], [22, 76], [17, 92], [24, 35], [14, 35], [36, 42], [18, 53]],
    r219: [[22, 15], [0, 15]],
    r220: [[0, 0], [34, 0]],
    r221: [[20, 30], [0, 4]],
    wilds: [[95, 249], [0, 4], [6, 87], [35, 225], [104, 89], [0, 241], [38, 114], [123, 108], [48, 170], [73, 170], [37, 120], [14, 69], [124, 277], [81, 228], [44, 205], [87, 158], [21, 150], [71, 205], [91, 217], [105, 218], [35, 76], [101, 88], [14, 164], [48, 60], [37, 220], [3, 57], [103, 255], [120, 276], [96, 60], [78, 154], [114, 58], [25, 246], [111, 164], [8, 57], [63, 78], [39, 152], [106, 58], [69, 165], [86, 58], [72, 77], [20, 183]],
    alamos: [[42, 26]],
    fuego: [[0, 28]],
    r224: [[6, 246], [13, 258], [54, 200]],
    r225: [[0, 0], [0, 7], [31, 10]],
    survival: [[0, 0]],
    r226: [[96, 23], [30, 0], [0, 0]],
    r227: [[0, 0], [17, 14], [11, 64], [32, 67]],
    r228: [[30, 46], [0, 27], [27, 83], [1, 65], [2, 58], [28, 30]],
    r230: [[14, 31], [86, 0]]
  },
  # Areas the pack cut off from every path get ladders (link_areas) from tiles
  # players reach (from the audit: the reached tile nearest each such area)
  link_areas: {
    jubilife: [[10, 11]],
    oreburgh: [[62, 43], [32, 11], [31, 25]],
    floaroma: [[31, 3], [15, 4]],
    hearthome: [[6, 13], [55, 13], [22, 6], [6, 10], [55, 6], [38, 11]],
    solaceon: [[8, 6], [61, 16]],
    sunyshore: [[45, 49], [43, 12], [46, 23], [17, 12]],
    league_isle: [[8, 45], [37, 21], [15, 68], [37, 20], [8, 53], [30, 68]],
    r204: [[18, 2], [11, 7], [16, 26]],
    r205: [[12, 99], [96, 11], [58, 34]],
    r206: [[24, 118]],
    r207: [[57, 11], [47, 5], [49, 18]],
    r210: [[66, 27]],
    r212: [[105, 40], [68, 72], [21, 14], [18, 72], [17, 32], [14, 38]],
    r211w: [[15, 20]],
    r213: [[49, 64], [52, 44], [75, 53], [82, 62]],
    r216: [[49, 13]],
    r219: [[6, 10]],
    r221: [[81, 17], [74, 20], [67, 20], [83, 18]],
    wilds: [[53, 153], [11, 64]],
    alamos: [[14, 15], [36, 12]],
    fuego: [[30, 36], [22, 15]],
    fight_area: [[44, 8]],
    frontier: [[64, 85], [24, 70], [86, 65], [32, 81], [78, 78]],
    r225: [[25, 47], [10, 24], [13, 91], [22, 15], [10, 86]],
    survival: [[29, 32], [12, 38], [21, 38], [12, 24], [20, 24], [20, 38]],
    r226: [[36, 29], [60, 19], [8, 16], [11, 23], [49, 30], [35, 31]],
    r227: [[12, 38], [24, 13]],
    r228: [[4, 73], [8, 54], [12, 30], [19, 97]],
    r230: [[49, 17]],
    r224: [[20, 230]]
  }
}
