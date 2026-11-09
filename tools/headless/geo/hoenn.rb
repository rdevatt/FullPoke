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
    r124: 152, r126: 154
  },
  links: [
    [:littleroot, 'North', :r101], [:r101, 'North', :oldale], [:oldale, 'West', :r102], [:oldale, 'North', :r103],
    [:r102, 'West', :petalburg], [:petalburg, 'West', :r104], [:r104, 'North', :rustboro],
    [:dewford, 'North', :r106], [:slateport, 'North', :r110], [:r110, 'North', :mauville],
    [:r103, 'East', :r110], [:mauville, 'West', :r117], [:r117, 'West', :verdanturf], [:mauville, 'North', :r111],
    [:mauville, 'East', :r118], [:r111, 'West', :r112], [:r112, 'West', :lavaridge], [:r111, 'North', :r113],
    [:r113, 'West', :fallarbor], [:rustboro, 'East', :r116],
    [:r118, 'North', :r119], [:r119, 'East', :fortree], [:fortree, 'East', :r120], [:r120, 'South', :r121],
    [:r121, 'East', :lilycove], [:r121, 'South', :r122], [:lilycove, 'East', :r124],
    [:r124, 'East', :mossdeep], [:r124, 'South', :r126]
  ],
  offsets: { [:mauville, :r118] => 0 },
  # Route 120's bridge over the pond: nothing in the pack puts the player on
  # the bridge layer, so walking onto it is a crossing from end to end.
  gates: [
    [:r120, [[32, 77], [32, 78]], [33, 78, 6], :r120, [[23, 77], [23, 78]], [22, 78, 4]]
  ],
  # Petalburg Woods sits between Route 104's two halves
  warps: [
    [:r104, [40, 30], :woods, { near: [40, 8], pick: :top }, { out_a: 8 }],
    [:r104, [41, 30], :woods, { near: [40, 8], pick: :top }, { out_a: 8, one_way: true }],
    [:r104, [40, 39], :woods, { near: [24, 25], pick: :bottom }, { out_a: 2 }],
    [:r104, [41, 39], :woods, { near: [24, 25], pick: :bottom }, { out_a: 2, one_way: true }]
  ],
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
    { name: 'Weather Institute guide', graphic: 'NPC 11', at: [:fortree, [2, 20]], to: [:r119, [46, 114]], badges: 0, dest_name: 'the Weather Institute' }
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
    r111: 4, r112: 4, r113: 4, r118: 6, r119: 6, r120: 7, r121: 7, r122: 7, r124: 7, r126: 8
  },
  trainers: { r122: 1, r124: 2, r126: 2 },
  caves: [:rusturf],
  requires: {
    r101: { starter: true }, dewford: 1, r106: 1, slateport: 2, r110: 2, mauville: 2,
    r111: { badges: 3, extras: 3 }, r117: { badges: 3, extras: 3 }, verdanturf: 3, rusturf: 3, r112: 3, lavaridge: 3,
    r113: 3, fallarbor: 3,
    r118: { badges: 5, extras: 5 }, r119: 5, fortree: 5,
    r120: { badges: 6, extras: 6 }, r121: 6, lilycove: 6, r122: 6, r124: 6, mossdeep: 6,
    sootopolis: 7, r126: 7, ever_grande: 8
  },
  story: [
    { kind: :battle, key: :hoenn_rival2, at: [:r110, [20, 80]], intro: "May: Hi! Let's see how much you and your Pokémon have grown!" },
    { kind: :battle, key: :hoenn_maxie, at: [:r112, [20, 10]], intro: "Maxie: With the volcano's power, Team Magma will expand the land! Don't interfere!" },
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
