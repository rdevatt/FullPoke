# Alola as separate maps on its four islands, in the order of Pokémon Sun and
# Moon. Trials happen at the trial sites (a cave, a hill, a volcano, a jungle),
# grand trials in the kahunas' towns; ferries link the islands. Stage numbers
# follow the Alola data in 110_Data_Regions.rb.
REGION_PLANS ||= {}
REGION_PLANS[:alola] = {
  nodes: [
    # Melemele Island
    [:iki, :town, 'Iki Town', { home: true, lab: "Professor Kukui's Lab", houses: 2, mart: false, gym: 2, stage: 2 }],
    [:a1, :route, 'Route 1', { placeholder: 'Route 501', stage_band: 1 }],
    [:hauoli, :city, "Hau'oli City", { stage: 1, houses: 5 }],
    [:a2, :route, 'Route 2', { placeholder: 'Route 502', stage_band: 1, grass: 5 }],
    [:verdant_cavern, :cave, 'Verdant Cavern', { stage_band: 1, trial: 1, trial_name: "Ilima's trial" }],
    [:a3, :route, 'Route 3', { placeholder: 'Route 503', stage_band: 2 }],
    # Akala Island
    [:heahea, :city, 'Heahea City', { stage: 3, houses: 4 }],
    [:a4, :route, 'Route 4', { placeholder: 'Route 504', stage_band: 3 }],
    [:paniola, :town, 'Paniola Town', { stage: 3, houses: 3 }],
    [:a5, :route, 'Route 5', { placeholder: 'Route 505', stage_band: 3 }],
    [:brooklet_hill, :route, 'Brooklet Hill', { stage_band: 3, water: true, trial: 3, trial_name: "Lana's trial" }],
    [:a6, :route, 'Route 6', { placeholder: 'Route 506', stage_band: 4 }],
    [:royal_avenue, :town, 'Royal Avenue', { stage: 4, houses: 3 }],
    [:a7, :route, 'Route 7', { placeholder: 'Route 507', stage_band: 4, water: true }],
    [:wela_volcano, :cave, 'Wela Volcano Park', { stage_band: 4, trial: 4, trial_name: "Kiawe's trial" }],
    [:a8, :route, 'Route 8', { placeholder: 'Route 508', stage_band: 5 }],
    [:lush_jungle, :forest, 'Lush Jungle', { stage_band: 5, trial: 5, trial_name: "Mallow's trial" }],
    [:a9, :route, 'Route 9', { placeholder: 'Route 509', stage_band: 6 }],
    [:konikoni, :town, 'Konikoni City', { gym: 6, stage: 6, houses: 3 }],
    # Ula'ula Island
    [:malie, :city, 'Malie City', { placeholder: 'Maile City', gym: 8, stage: 8, houses: 4 }],
    [:a10, :route, 'Route 10', { placeholder: 'Route 510', stage_band: 7 }],
    [:hokulani, :route, 'Mount Hokulani', { stage_band: 7 }],
    [:a12, :route, 'Route 12', { placeholder: 'Route 512', stage_band: 7 }],
    [:tapu_village, :town, 'Tapu Village', { stage: 7, houses: 2 }],
    [:a14, :route, 'Route 14', { placeholder: 'Route 514', stage_band: 7, water: true }],
    [:thrifty, :town, 'Thrifty Megamart', { stage: 7, houses: 1, pc: false, trial: 7, trial_name: "Acerola's trial" }],
    [:a17, :route, 'Route 17', { placeholder: 'Route 517', stage_band: 8 }],
    [:po_town, :town, 'Po Town', { stage: 8, houses: 3, mart: false }],
    # Poni Island
    [:seafolk, :town, 'Seafolk Village', { stage: 8, houses: 3 }],
    [:poni_wilds, :route, 'Poni Wilds', { stage_band: 9, water: true }],
    [:poni_plains, :route, 'Poni Plains', { stage_band: 9, grass: 6 }],
    [:lanakila, :route, 'Mount Lanakila', { stage_band: 9 }]
  ],
  links: [
    [:iki, 'South', :a1], [:a1, 'South', :hauoli], [:hauoli, 'West', :a2], [:a2, 'North', :verdant_cavern],
    [:a2, 'West', :a3, 0.7],
    [:heahea, 'North', :a4], [:a4, 'North', :paniola], [:paniola, 'North', :a5], [:a5, 'North', :brooklet_hill],
    [:brooklet_hill, 'North', :a6], [:a6, 'North', :royal_avenue], [:royal_avenue, 'East', :a7], [:a7, 'East', :wela_volcano],
    [:wela_volcano, 'North', :a8], [:a8, 'North', :lush_jungle], [:lush_jungle, 'North', :a9], [:a9, 'North', :konikoni],
    [:malie, 'North', :a10], [:a10, 'North', :hokulani], [:hokulani, 'East', :a12], [:a12, 'East', :tapu_village],
    [:tapu_village, 'North', :a14], [:a14, 'North', :thrifty], [:thrifty, 'North', :a17], [:a17, 'North', :po_town],
    [:seafolk, 'North', :poni_wilds], [:poni_wilds, 'North', :poni_plains], [:poni_plains, 'North', :lanakila]
  ],
  start: { town: :iki, gate_side: 'West' },
  victory_road: { from: :lanakila, side: 'North' },
  requires: {
    a1: { starter: true }, a3: 1, heahea: { badges: 2, extras: 1 }, a5: 2, a6: 3, a8: 4, a9: 5,
    malie: 6, a17: 7, po_town: 7, seafolk: 8
  },
  story: [
    { kind: :battle, key: :alola_rival2, at: [:hauoli, [27, 24]], intro: "Hau: Hey! Done with Ilima's trial? Battle me before you head off!" },
    { kind: :battle, key: :alola_guzma, at: [:po_town, [21, 14]], requires: 7,
      intro: "Guzma: Team Skull's boss, Guzma, is here to destroy you!" },
    { kind: :ferry, at: [:hauoli, [21, 34]], to: :heahea, requires: 2 },
    { kind: :ferry, at: [:heahea, [27, 34]], to: :hauoli },
    { kind: :ferry, at: [:konikoni, [21, 26]], to: :malie, requires: 6 },
    { kind: :ferry, at: [:malie, [27, 34]], to: :konikoni },
    { kind: :ferry, at: [:malie, [33, 34]], to: :seafolk, requires: 8 },
    { kind: :ferry, at: [:seafolk, [21, 26]], to: :malie },
    { kind: :npc, name: 'Island guide', at: [:iki, [21, 20]],
      lines: ["Alola! Trials replace Gyms here. Clear a trial site's captain and Totem, then face the island's kahuna."] }
  ]
}
