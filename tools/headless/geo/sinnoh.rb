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
    r217: 244, r218: 245, r222: 250, r223: 251
  },
  names: { league_isle: 'Pokémon League', r211w: 'Route 211', r211e: 'Route 211' },
  links: [
    [:twinleaf, 'North', :r201], [:r201, 'East', :sandgem], [:sandgem, 'North', :r202], [:r202, 'North', :jubilife],
    [:jubilife, 'East', :r203], [:jubilife, 'North', :r204], [:r204, 'North', :floaroma],
    [:floaroma, 'East', :r205], [:r205, 'East', :eterna], [:eterna, 'South', :r206], [:r206, 'South', :r207],
    [:oreburgh, 'East', :r207], [:r208, 'East', :hearthome], [:solaceon, 'South', :r209],
    [:r210, 'South', :solaceon], [:r210, 'East', :r215], [:r215, 'East', :veilstone],
    [:r214, 'South', :r213], [:r213, 'West', :pastoria], [:pastoria, 'West', :r212],
    [:jubilife, 'West', :r218], [:r218, 'West', :canalave], [:r211e, 'East', :celestic], [:celestic, 'East', :r210],
    [:eterna, 'East', :r211w], [:r211w, 'East', :r211e], [:r216, 'East', :r217],
    [:r217, 'North', :snowpoint], [:r213, 'East', :r222], [:r222, 'East', :sunyshore], [:sunyshore, 'North', :r223],
    [:r223, 'North', :league_isle]
  ],
  offsets: { [:r216, :r217] => -152, [:r205, :eterna] => 5, [:r222, :sunyshore] => -1, [:r206, :r207] => 0 },
  gates: [
    # Hearthome's north gatehouse and Route 209's west exit
    [:hearthome, [[8, 8], [9, 8], [10, 8]], [9, 10, 2], :r209, [[0, 52], [0, 53], [0, 54], [0, 55], [0, 56]], [2, 54, 6]],
    # Hearthome's south stairs and Route 212's north gatehouse
    [:hearthome, [[7, 53], [8, 53], [9, 53], [10, 53]], [8, 51, 8], :r212, [[17, 3], [18, 3], [19, 3], [20, 3]], [18, 5, 2]],
    # Veilstone's south exit and Route 214's gatehouse
    # Oreburgh's east end and Route 207 (the map pack walls them apart)
    [:oreburgh, [[67, 18]], [66, 18, 4], :r207, [[2, 3], [2, 4], [2, 5]], [3, 4, 6]],
    # Eterna's south gatehouse and the top of the Cycling Road (Route 206)
    [:eterna, [[15, 56], [16, 56], [17, 56], [18, 56]], [16, 54, 8], :r206, [[15, 4], [16, 4], [17, 4], [18, 4]], [16, 6, 2]],
    # Route 213: the gatehouse between the hotel meadow and Valor Lakefront
    [:r213, [[57, 58]], [56, 58, 4], :r213, [[59, 58]], [60, 58, 6]],
    [:veilstone, [[34, 67], [35, 67], [36, 67], [37, 67], [38, 67], [39, 67]], [36, 64, 8], :r214, [[15, 3], [16, 3], [17, 3], [18, 3]], [16, 5, 2]]
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
                                [:house, 22, 29], [:house, 11, 26], [:house, 11, 36],
                                [:big, 25, 48, 'Galactic Eterna Building', ["Team Galactic's grunts have cleared out. Nobody's here."]]] },
    veilstone: { stage: 3, doors: [[:gym, 30, 50], [:pc, 42, 38], [:mart, 23, 31, 'Veilstone Department Store'], [:house, 37, 31],
                                   [:house, 12, 49], [:house, 18, 49], [:house, 22, 49],
                                   [:big, 7, 40, 'Game Corner', ["The Game Corner is closed for renovations."]],
                                   [:big, 43, 18, 'Galactic HQ', ["Team Galactic's headquarters. The doors are locked tight."]]] },
    pastoria: { stage: 4, doors: [[:gym, 12, 27], [:pc, 25, 17], [:house, 44, 28], [:house, 30, 26], [:house, 26, 42],
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
    r214: 4, r213: 4, r212: 5, r218: 6, r211w: 6, r211e: 6, r216: 7, r217: 7, r222: 8, r223: 9
  },
  trainers: { r218: 2, r223: 2 },
  requires: {
    r202: { starter: true }, r204: 1, floaroma: 1, r205: 1, eterna: 1,
    r206: 2, r207: 2, r208: 2, hearthome: 2, r209: 2, solaceon: 2, r210: 2, r215: 2, veilstone: 2,
    r214: 3, r213: 3, pastoria: 3, r212: { badges: 4, extras: 4 },
    r218: 5, canalave: 5, r211w: 5, r211e: 5, celestic: 5,
    r216: 6, r217: 6, snowpoint: 6,
    r222: { badges: 7, extras: 7 }, sunyshore: { badges: 7, extras: 7 }, r223: 8, league_isle: 8
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
  victory_road: { from: :league_isle, at: [[22, 66]] }
}
