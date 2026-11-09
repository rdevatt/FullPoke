# Kalos as separate maps in the order of Pokémon X and Y. The map pack's empty
# Kalos placeholders are used where they exist (its routes are numbered 401-422
# for Kalos Routes 1-22). stage_band = the Gym the area leads to (wild levels).
REGION_PLANS ||= {}
REGION_PLANS[:kalos] = {
  nodes: [
    [:vaniville, :town, 'Vaniville Town', { home: true, lab: "Professor Sycamore's Lab", houses: 2, mart: false }],
    [:k1, :route, 'Route 1', { placeholder: 'Route 401', stage_band: 1, size: [36, 30], grass: 1 }],
    [:aquacorde, :town, 'Aquacorde Town', { houses: 2, gym: false, stage: 1 }],
    [:k2, :route, 'Route 2', { placeholder: 'Route 402', stage_band: 1 }],
    [:santalune_forest, :forest, 'Santalune Forest', { stage_band: 1 }],
    [:k3, :route, 'Route 3', { placeholder: 'Route 403', stage_band: 1, water: true }],
    [:santalune, :town, 'Santalune City', { gym: 1, stage: 1, houses: 3 }],
    [:k4, :route, 'Route 4', { placeholder: 'Route 404', stage_band: 2, grass: 2 }],
    [:lumiose, :city, 'Lumiose City', { gym: 5, stage: 5, houses: 6 }],
    [:k5, :route, 'Route 5', { placeholder: 'Route 405', stage_band: 2, shape: :ew }],
    [:camphrier, :town, 'Camphrier Town', { stage: 2, houses: 3 }],
    [:k7, :route, 'Route 7', { placeholder: 'Route 407', stage_band: 2, water: true }],
    [:connecting_cave, :cave, 'Connecting Cave', { stage_band: 2 }],
    [:k8, :route, 'Route 8', { placeholder: 'Route 408', stage_band: 2, shape: :ew, water: true }],
    [:ambrette, :town, 'Ambrette Town', { stage: 2, houses: 2 }],
    [:k9, :route, 'Route 9', { placeholder: 'Route 409', stage_band: 2 }],
    [:glittering_cave, :cave, 'Glittering Cave', { stage_band: 2 }],
    [:cyllage, :town, 'Cyllage City', { gym: 2, stage: 2, houses: 3 }],
    [:k10, :route, 'Route 10', { placeholder: 'Route 410', stage_band: 3 }],
    [:geosenge, :town, 'Geosenge Town', { stage: 3, houses: 2 }],
    [:k11, :route, 'Route 11', { placeholder: 'Route 411', stage_band: 3 }],
    [:reflection_cave, :cave, 'Reflection Cave', { stage_band: 3 }],
    [:shalour, :town, 'Shalour City', { gym: 3, stage: 3, houses: 3 }],
    [:k12, :route, 'Route 12', { placeholder: 'Route 412', stage_band: 4, shape: :ew, water: true }],
    [:coumarine, :town, 'Coumarine City', { gym: 4, stage: 4, houses: 3 }],
    [:k13, :route, 'Route 13', { placeholder: 'Route 413', stage_band: 5, grass: 6 }],
    [:k14, :route, 'Route 14', { placeholder: 'Route 414', stage_band: 6, water: true }],
    [:laverre, :town, 'Laverre City', { gym: 6, stage: 6, houses: 3 }],
    [:k15, :route, 'Route 15', { placeholder: 'Route 415', stage_band: 7 }],
    [:dendemille, :town, 'Dendemille Town', { stage: 7, houses: 2 }],
    [:k17, :route, 'Route 17', { placeholder: 'Route 417', stage_band: 7 }],
    [:anistar, :town, 'Anistar City', { gym: 7, stage: 7, houses: 3 }],
    [:k18, :route, 'Route 18', { placeholder: 'Route 418', stage_band: 8, shape: :ew }],
    [:couriway, :town, 'Couriway Town', { stage: 8, houses: 2 }],
    [:k19, :route, 'Route 19', { placeholder: 'Route 419', stage_band: 8, water: true }],
    [:snowbelle, :town, 'Snowbelle City', { gym: 8, stage: 8, houses: 3 }],
    [:k21, :route, 'Route 21', { placeholder: 'Route 421', stage_band: 9 }]
  ],
  # [map, side the next one is on, next map, position along the side 0..1]
  links: [
    [:vaniville, 'North', :k1], [:k1, 'North', :aquacorde], [:aquacorde, 'North', :k2], [:k2, 'North', :santalune_forest],
    [:santalune_forest, 'North', :k3], [:k3, 'North', :santalune], [:santalune, 'North', :k4], [:k4, 'North', :lumiose],
    [:lumiose, 'West', :k5], [:k5, 'West', :camphrier], [:camphrier, 'North', :k7], [:k7, 'North', :connecting_cave],
    [:connecting_cave, 'North', :k8], [:k8, 'West', :ambrette], [:ambrette, 'North', :k9], [:k9, 'North', :glittering_cave],
    [:glittering_cave, 'North', :cyllage], [:cyllage, 'North', :k10], [:k10, 'North', :geosenge], [:geosenge, 'North', :k11],
    [:k11, 'North', :reflection_cave], [:reflection_cave, 'North', :shalour], [:shalour, 'East', :k12], [:k12, 'East', :coumarine],
    [:coumarine, 'South', :k13], [:k13, 'West', :lumiose], [:lumiose, 'North', :k14], [:k14, 'North', :laverre],
    [:laverre, 'North', :k15], [:k15, 'North', :dendemille], [:dendemille, 'North', :k17], [:k17, 'North', :anistar],
    [:anistar, 'East', :k18], [:k18, 'East', :couriway], [:couriway, 'North', :k19], [:k19, 'North', :snowbelle],
    [:snowbelle, 'North', :k21]
  ],
  start: { town: :vaniville, gate_side: 'West' },
  victory_road: { from: :k21, side: 'North' },
  requires: {
    k1: { starter: true }, k4: { badges: 1, extras: 1 }, k10: 2, k12: 3, k13: 4, k14: 5, k15: 6,
    k18: { badges: 7, extras: 7 }, k21: 8
  },
  story: [
    { kind: :battle, key: :kalos_rival2, at: [:santalune, [21, 20]], intro: "Shauna: Hey! Did you just get the Bug Badge? Let's see how strong we've both gotten!" },
    { kind: :battle, key: :kalos_lysandre, at: [:lumiose, [27, 24]], requires: 6,
      intro: "Lysandre: You've seen too much of Team Flare's plans. The world must be made beautiful... starting with you!",
      early: "A man in a red suit stands outside Lysandre Café. He ignores you for now." },
    { kind: :npc, name: 'Lumiose guide', at: [:lumiose, [20, 30]],
      lines: ["Welcome to Lumiose City, the City of Light! Prism Tower's Gym is for Trainers with four badges."] }
  ]
}
