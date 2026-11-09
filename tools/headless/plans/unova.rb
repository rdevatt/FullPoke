# Unova as separate maps in the order of Pokémon Black and White. The map pack
# has hand-made maps for Nuvema to Castelia (tileset 32) whose exits are
# gatehouses; until those are wired up by hand like Johto's, the whole region
# is generated (the hand-made maps are kept untouched). Unova's route numbers
# are 301-323 in the map pack.
REGION_PLANS ||= {}
REGION_PLANS[:unova] = {
  nodes: [
    [:nuvema, :town, 'Nuvema Town', { placeholder: 'Nuvema Town (generated)', home: true, lab: "Professor Juniper's Lab", houses: 2, mart: false }],
    [:u1, :route, 'Route 1', { placeholder: 'Route 1 (Unova)', stage_band: 1, water: true }],
    [:accumula, :town, 'Accumula Town', { placeholder: 'Accumula Town (generated)', stage: 1, houses: 3 }],
    [:u2, :route, 'Route 2', { placeholder: 'Route 2 (Unova)', stage_band: 1 }],
    [:striaton, :town, 'Striaton City', { placeholder: 'Striaton City (generated)', gym: 1, stage: 1, houses: 3 }],
    [:u3, :route, 'Route 3', { placeholder: 'Route 3 (Unova)', stage_band: 2, water: true }],
    [:wellspring, :cave, 'Wellspring Cave', { stage_band: 2 }],
    [:nacrene, :town, 'Nacrene City', { placeholder: 'Nacrene City (generated)', gym: 2, stage: 2, houses: 3 }],
    [:pinwheel, :forest, 'Pinwheel Forest', { stage_band: 3 }],
    [:castelia, :city, 'Castelia City', { placeholder: 'Castelia City (generated)', gym: 3, stage: 3, houses: 6 }],
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
  links: [
    [:nuvema, 'North', :u1], [:u1, 'North', :accumula], [:accumula, 'East', :u2], [:u2, 'East', :striaton],
    [:striaton, 'North', :u3], [:u3, 'North', :wellspring], [:wellspring, 'North', :nacrene], [:nacrene, 'East', :pinwheel],
    [:pinwheel, 'East', :castelia], [:castelia, 'North', :u4], [:u4, 'North', :desert_resort], [:desert_resort, 'North', :nimbasa],
    [:nimbasa, 'West', :u5], [:u5, 'West', :driftveil], [:driftveil, 'North', :u6], [:u6, 'North', :chargestone],
    [:chargestone, 'North', :mistralton], [:mistralton, 'East', :u7], [:u7, 'East', :twist_mountain], [:twist_mountain, 'North', :icirrus],
    [:icirrus, 'East', :u8], [:u8, 'East', :u9], [:u9, 'East', :opelucid], [:opelucid, 'North', :u10]
  ],
  start: { town: :nuvema, gate_side: 'West' },
  victory_road: { from: :u10, side: 'North' },
  requires: {
    u1: { starter: true }, u3: { badges: 1, extras: 1 }, pinwheel: 2, u4: 3, u5: 4, u6: 5, u7: 6, u8: 7, u10: { badges: 8, extras: 8 }
  },
  story: [
    { kind: :battle, key: :unova_rival2, at: [:striaton, [21, 22]], intro: "Cheren: You got the Trio Badge too? Then let's test what we've learned!" },
    { kind: :battle, key: :unova_ghetsis, at: [:opelucid, [27, 30]], requires: 7,
      intro: "Ghetsis: Team Plasma will rule Unova! Your interference ends here!",
      early: "A man in a strange robe watches the Dragonspiral Tower from afar." },
    { kind: :npc, name: 'Plasma Grunt', graphic: 'trainer_TEAMROCKET_M', at: [:accumula, [21, 24]],
      lines: ["Grunt: Liberate your Pokémon! Lord N says people and Pokémon should live apart..."] }
  ]
}
