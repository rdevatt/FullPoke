# Unova in the order of Pokémon Black and White. The map pack's hand-made maps
# (tileset 32) are used from Nuvema Town to Castelia City; the rest of the
# region is generated. Unova's route numbers are 301-323 in the map pack.
#
# Real maps join each other at the pack's own offsets. Route 3 and Nacrene meet
# at their gatehouses; Pinwheel Forest opens off Nacrene's east road and comes
# out on Castelia's Skyarrow Bridge pier; Route 4 starts at Castelia's north
# gate. Wellspring Cave is a side cave behind Route 3's cliff.
REGION_PLANS ||= {}
REGION_PLANS[:unova] = {
  nodes: [
    [:nuvema, :real, 'Nuvema Town', { map: 463, stage: 0,
                                       doors: [[:lab, 40, 8, "Professor Juniper's Lab"], [:house, 46, 19], [:home, 42, 28], [:house, 51, 28]] }],
    [:r301, :real, 'Route 1', { map: 490, stage_band: 1 }],
    [:accumula, :real, 'Accumula Town', { map: 464, stage: 1,
                                          doors: [[:house, 45, 10], [:house, 53, 10], [:house, 61, 9], [:pc, 64, 20], [:mart, 39, 30]] }],
    [:r302, :real, 'Route 2', { map: 494, stage_band: 1 }],
    [:striaton, :real, 'Striaton City', { map: 465, stage: 1,
                                          doors: [[:house, 38, 42], [:pc, 46, 42], [:gym, 52, 42], [:mart, 46, 49], [:house, 56, 49]] }],
    [:r303, :real, 'Route 3', { map: 495, stage_band: 2 }],
    [:wellspring, :cave, 'Wellspring Cave', { stage_band: 2, entrance: 'South' }],
    [:nacrene, :real, 'Nacrene City', { map: 466, stage: 2,
                                        doors: [[:house, 42, 16], [:house, 47, 16], [:house, 54, 19, 'Café Warehouse'], [:gym, 68, 15],
                                                [:house, 85, 19], [:house, 91, 19], [:house, 45, 31], [:house, 50, 31], [:pc, 62, 32],
                                                [:mart, 69, 29], [:house, 73, 29], [:house, 85, 31], [:house, 91, 31]] }],
    [:pinwheel, :forest, 'Pinwheel Forest', { stage_band: 3, extra_ports: [['West', 9.0 / 39]] }],   # 2nd opening: Nacrene's east glade
    [:castelia, :real, 'Castelia City', { map: 468, stage: 3,
                                          doors: [[:gym, 28, 64], [:pc, 78, 65], [:mart, 94, 65], [:house, 53, 65]] }],
    [:u4, :route, 'Route 4', { placeholder: 'Route 304', stage_band: 4, grass: 2 }],
    [:desert_resort, :route, 'Desert Resort', { stage_band: 4, grass: 6 }],
    [:nimbasa, :city, 'Nimbasa City', { gym: 4, stage: 4, houses: 4 }],
    [:u5, :route, 'Route 5', { placeholder: 'Route 305', stage_band: 5, shape: :ew }],
    [:driftveil, :city, 'Driftveil City', { gym: 5, stage: 5, houses: 4 }],
    [:u6, :route, 'Route 6', { placeholder: 'Route 306', stage_band: 6, water: true }],
    [:chargestone, :cave, 'Chargestone Cave', { stage_band: 6 }],
    [:mistralton, :town, 'Mistralton City', { gym: 6, stage: 6, houses: 3 }],
    [:u7, :route, 'Route 7', { placeholder: 'Route 307', stage_band: 7 }],
    [:twist_mountain, :cave, 'Twist Mountain', { placeholder: "Challenger's Cave", stage_band: 7 }],
    [:icirrus, :town, 'Icirrus City', { gym: 7, stage: 7, houses: 3 }],
    [:u8, :route, 'Route 8', { placeholder: 'Route 308', stage_band: 8, water: true }],
    [:u9, :route, 'Route 9', { placeholder: 'Route 309', stage_band: 8, shape: :ew }],
    [:opelucid, :city, 'Opelucid City', { gym: 8, stage: 8, houses: 4 }],
    [:u10, :route, 'Route 10', { placeholder: 'Route 310', stage_band: 9 }]
  ],
  # The generated maps the hand-made ones replaced
  retired: %i[u1 u2 u3],
  links: [
    [:nuvema, 'North', :r301, { d: 0 }], [:r301, 'North', :accumula, { d: -6 }], [:accumula, 'North', :r302, { d: 4 }],
    [:r302, 'North', :striaton, { d: 0 }], [:striaton, 'West', :r303, { d: -6 }], [:r303, 'West', :nacrene, { d: 24 }],
    # Pinwheel's port at its top corner so it stays clear of Route 3 on Nacrene's east side
    [:nacrene, 'East', :pinwheel, { at: 49, frac: 0 }],
    [:u4, 'North', :desert_resort], [:desert_resort, 'North', :nimbasa],
    [:nimbasa, 'West', :u5], [:u5, 'West', :driftveil], [:driftveil, 'North', :u6], [:u6, 'North', :chargestone],
    [:chargestone, 'North', :mistralton], [:mistralton, 'East', :u7], [:u7, 'East', :twist_mountain], [:twist_mountain, 'North', :icirrus],
    [:icirrus, 'East', :u8], [:u8, 'East', :u9], [:u9, 'East', :opelucid], [:opelucid, 'North', :u10]
  ],
  # [real map, its tiles, arrival on it, generated map, side of the generated map]
  real_gates: [
    [:castelia, [[141, 70], [141, 71], [141, 72], [141, 73]], [139, 71, 4], :pinwheel, 'East'],
    [:castelia, [[64, 5], [65, 5], [66, 5]], [65, 8, 2], :u4, 'South']
  ],
  warps: [
    [:r303, [7, 14], :wellspring, :entrance, { out_a: 6, out_b: 8 }],
    # Through Accumula's gatehouse, from the square to the road north to Route 2
    [:accumula, [34, 13], :accumula, [29, 13], { out_a: 6, out_b: 4 }],
    # Steps and trails to the clearings, hilltops and meadows the pack drew
    # with no way in (a pair of tiles in a cliff or tree line: each leads to
    # the open side of the other)
    [:nuvema, [16, 22], :nuvema, [17, 23], { out_a: 8, out_b: 2, quiet: true }],
    [:r301, [47, 55], :r301, [47, 56], { out_a: 4, out_b: 6, quiet: true }],
    [:accumula, [35, 32], :accumula, [36, 32], { out_a: 4, out_b: 6, quiet: true }],
    [:accumula, [13, 18], :accumula, [13, 19], { out_a: 6, out_b: 4, quiet: true }],
    [:accumula, [32, 33], :accumula, [33, 33], { out_a: 8, out_b: 2, quiet: true }],
    [:r302, [57, 7], :r302, [58, 7], { out_a: 4, out_b: 6, quiet: true }],
    [:striaton, [104, 18], :striaton, [97, 35], { out_a: 8, out_b: 2, quiet: true }],
    [:striaton, [20, 13], :striaton, [22, 13], { out_a: 4, out_b: 6, quiet: true }],
    [:striaton, [35, 12], :striaton, [35, 11], { out_a: 2, out_b: 8, quiet: true }],
    [:r303, [24, 63], :r303, [33, 63], { out_a: 4, out_b: 6, quiet: true }],
    [:nacrene, [18, 49], :nacrene, [34, 49], { out_a: 4, out_b: 6, quiet: true }]
  ],
  # Walled-in bits of the hand-made maps that lead nowhere are planted over
  forest_tiles: [[2172, 2173], [2164, 2165]],
  forest_fill: {
    r301: [[34, 38, 37, 41]],   # a lakeside clearing behind a rock wall
    nacrene: [[39, 66, 50, 66]],  # a gap under the trees south of the slope
    accumula: [[57, 1, 68, 1]]    # behind the trees past the apartment roofs
  },
  tile_fixes: { 32 => {
    # Tileset 32's stairs (over cliffs on Routes 1-3 and Nacrene's south
    # slope, Accumula's yard) are solid in the pack or look like building
    # walls to the building fix
    open: [9372, 9373, 9374, 9375, 9380, 9381, 9382, 9383, 9388, 9389, 9390, 9391,
           9396, 9397, 9398, 9399, 9404, 9405, 9406, 9407,
           9300, 9304, 9305, 9306, 9307, 9308, 9312, 9313, 9314, 9315, 9316,
           8984, 8985, 8986, 8987, 8988, 8992, 8993, 8994, 8995, 8996, 9000, 9001, 9002, 9003, 9004,
           9008, 9009, 9010, 9011, 9012, 9016, 9017, 9018, 9019, 9020, 9024, 9025, 9026, 9027, 9028,
           # the end of Castelia's Skyarrow pier, drawn over the waterfront railing
           9077, 9085, 9093, 9101],
    # The roofs of Accumula's apartment blocks and of the Pokémon Centers
    solid: [2312, 2313, 2314, 2315, 2316, 2317, 2318, 2320, 2321, 2322, 2323, 2324, 2325, 2326,
            2328, 2329, 2330, 2331, 2332, 2333, 2334,
            3340, 3341, 3344, 3345, 3346, 3347, 3348, 3349, 3352, 3353, 3354, 3355, 3356, 3357,
            3360, 3361, 3362, 3363, 3364, 3365, 3368, 3369, 3370, 3371, 3372, 3373]
  } },
  # The gatehouse on Nuvema's east edge leads to the Interregional Forest
  start: { town: :nuvema, forest_gate: [[56, 20], [56, 21], [56, 22]], arrival: [54, 21], gate_dir: 'East', arrival_dir: 4 },
  victory_road: { from: :u10, side: 'North' },
  requires: {
    r301: { starter: true }, r303: { badges: 1, extras: 1 }, pinwheel: 2, u4: 3, u5: 4, u6: 5, u7: 6, u8: 7, u10: { badges: 8, extras: 8 }
  },
  story: [
    { kind: :battle, key: :unova_rival2, at: [:striaton, [40, 52]], intro: "Cheren: You got the Trio Badge too? Then let's test what we've learned!" },
    { kind: :battle, key: :unova_ghetsis, at: [:opelucid, [27, 30]], requires: 7,
      intro: "Ghetsis: Team Plasma will rule Unova! Your interference ends here!",
      early: "A man in a strange robe watches the Dragonspiral Tower from afar." },
    { kind: :npc, name: 'Plasma Grunt', graphic: 'trainer_TEAMROCKET_M', at: [:accumula, [30, 22]],
      lines: ["Grunt: Liberate your Pokémon! Lord N says people and Pokémon should live apart..."] }
  ]
}
