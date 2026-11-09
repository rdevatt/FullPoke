# Galar as separate maps in the order of Pokémon Sword and Shield: the Wild
# Area between Wedgehurst and Motostoke, the Gym Challenge from Turffield to
# Hammerlocke, and Wyndon's Champion Cup. Hammerlocke is the hub it is in the
# games: Routes 6, 7 and 10 leave from it.
REGION_PLANS ||= {}
REGION_PLANS[:galar] = {
  nodes: [
    [:postwick, :town, 'Postwick', { home: true, lab: "Professor Magnolia's House", houses: 2, mart: false }],
    [:g1, :route, 'Route 1', { placeholder: 'Route 601', stage_band: 1 }],
    [:wedgehurst, :town, 'Wedgehurst', { placeholder: 'Wedghurst', stage: 1, houses: 3 }],
    [:g2, :route, 'Route 2', { placeholder: 'Route 602', stage_band: 1, water: true }],
    [:rolling_fields, :route, 'Rolling Fields', { stage_band: 1, size: [60, 48], grass: 9, water: true }],
    [:motostoke, :city, 'Motostoke', { gym: 3, stage: 3, houses: 5 }],
    [:g3, :route, 'Route 3', { placeholder: 'Route 603', stage_band: 1 }],
    [:galar_mine, :cave, 'Galar Mine', { placeholder: 'West Galar Mine', stage_band: 1 }],
    [:g4, :route, 'Route 4', { placeholder: 'Route 604', stage_band: 1 }],
    [:turffield, :town, 'Turffield', { gym: 1, stage: 1, houses: 3 }],
    [:g5, :route, 'Route 5', { placeholder: 'Route 605', stage_band: 2, shape: :ew }],
    [:hulbury, :town, 'Hulbury', { gym: 2, stage: 2, houses: 3 }],
    [:galar_mine2, :cave, 'Galar Mine No. 2', { placeholder: 'East Galar Mine', stage_band: 3 }],
    [:dusty_bowl, :route, 'Dusty Bowl', { stage_band: 4, size: [60, 40], grass: 7 }],
    [:hammerlocke, :city, 'Hammerlocke', { gym: 8, stage: 8, houses: 5 }],
    [:g6, :route, 'Route 6', { placeholder: 'Route 606', stage_band: 4, shape: :ew }],
    [:stow, :town, 'Stow-on-Side', { gym: 4, stage: 4, houses: 3 }],
    [:glimwood, :forest, 'Glimwood Tangle', { stage_band: 5 }],
    [:ballonlea, :town, 'Ballonlea', { gym: 5, stage: 5, houses: 3 }],
    [:g7, :route, 'Route 7', { placeholder: 'Route 607', stage_band: 6 }],
    [:g8, :route, 'Route 8', { placeholder: 'Route 608', stage_band: 6 }],
    [:circhester, :city, 'Circhester', { gym: 6, stage: 6, houses: 4 }],
    [:g9, :route, 'Route 9', { placeholder: 'Route 609', stage_band: 7, shape: :ew, water: true }],
    [:spikemuth, :town, 'Spikemuth', { gym: 7, stage: 7, houses: 3 }],
    [:g10, :route, 'Route 10', { placeholder: 'Route 610', stage_band: 9, shape: :ew }],
    [:wyndon, :city, 'Wyndon', { stage: 9, houses: 4 }]
  ],
  links: [
    [:postwick, 'North', :g1], [:g1, 'North', :wedgehurst], [:wedgehurst, 'North', :g2], [:g2, 'North', :rolling_fields],
    [:rolling_fields, 'North', :motostoke], [:motostoke, 'North', :g3], [:g3, 'North', :galar_mine], [:galar_mine, 'North', :g4],
    [:g4, 'North', :turffield], [:turffield, 'East', :g5], [:g5, 'East', :hulbury], [:hulbury, 'South', :galar_mine2],
    [:galar_mine2, 'West', :motostoke], [:motostoke, 'West', :dusty_bowl], [:dusty_bowl, 'North', :hammerlocke],
    [:hammerlocke, 'West', :g6], [:g6, 'West', :stow], [:stow, 'North', :glimwood], [:glimwood, 'North', :ballonlea],
    [:hammerlocke, 'North', :g7], [:g7, 'North', :g8], [:g8, 'North', :circhester], [:circhester, 'East', :g9],
    [:g9, 'East', :spikemuth], [:hammerlocke, 'East', :g10], [:g10, 'East', :wyndon]
  ],
  start: { town: :postwick, gate_side: 'West' },
  victory_road: { from: :wyndon, side: 'North' },
  requires: {
    g1: { starter: true }, g5: 1, galar_mine2: 2, dusty_bowl: { badges: 3, extras: 3 }, glimwood: 4,
    g7: 5, g9: 6, g10: { badges: 8, extras: 8 }
  },
  story: [
    { kind: :battle, key: :galar_rival2, at: [:motostoke, [27, 26]], intro: "Hop: You beat Kabu? Brilliant! Now let's see you beat me!" },
    { kind: :battle, key: :galar_rose, at: [:hammerlocke, [27, 30]], requires: 7,
      intro: "Rose: The future of Galar can't wait for the Champion Cup. Let me show you why!",
      early: "Chairman Rose is busy at the Hammerlocke Energy Plant." },
    { kind: :npc, name: 'Wild Area guide', at: [:rolling_fields, [30, 26]],
      lines: ["This is the Wild Area! Pokémon roam everywhere here. Motostoke and the Gym Challenge are north."] }
  ]
}
