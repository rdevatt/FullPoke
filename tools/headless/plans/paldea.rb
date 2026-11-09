# Paldea as separate maps around Mesagoza, after Pokémon Scarlet and Violet.
# All three stories are here: the Victory Road Gyms in their towns, the Path
# of Legends Titans in the wild (beating one counts as its Titan battle before
# the matching Gym, as in FullPoke's Paldea data), and the Starfall Street Team
# Star bases. The League waits north of Mesagoza; Nemona's final battle needs
# all three stories finished. Paldea stays locked until the Generation 9 data
# is installed.
REGION_PLANS ||= {}
REGION_PLANS[:paldea] = {
  nodes: [
    [:cabo_poco, :town, 'Cabo Poco', { home: true, lab: "Director Clavell's Office", houses: 2, mart: false }],
    [:poco_path, :route, 'Poco Path', { stage_band: 1 }],
    [:los_platos, :town, 'Los Platos', { stage: 1, houses: 2 }],
    [:south1, :route, 'South Province (Area One)', { stage_band: 1, size: [60, 48], grass: 8, water: true }],
    [:mesagoza, :city, 'Mesagoza', { stage: 1, houses: 6 }],
    [:south3, :route, 'South Province (Area Three)', { stage_band: 1, size: [60, 40], grass: 7 }],
    [:cortondo, :town, 'Cortondo', { gym: 1, stage: 1, houses: 3 }],
    [:south2, :route, 'South Province (Area Two)', { stage_band: 2, size: [60, 40], grass: 7 }],
    [:artazon, :town, 'Artazon', { gym: 2, stage: 2, houses: 3 }],
    [:east1, :route, 'East Province (Area One)', { stage_band: 3, size: [60, 40], grass: 7 }],
    [:levincia, :city, 'Levincia', { gym: 3, stage: 3, houses: 4 }],
    [:asado_desert, :route, 'Asado Desert', { stage_band: 4, size: [60, 44], grass: 4 }],
    [:cascarrafa, :city, 'Cascarrafa', { gym: 4, stage: 4, houses: 4 }],
    [:west1, :route, 'West Province (Area One)', { stage_band: 5, size: [60, 40], grass: 7 }],
    [:medali, :town, 'Medali', { gym: 5, stage: 5, houses: 3 }],
    [:east3, :route, 'East Province (Area Three)', { stage_band: 6, size: [60, 40], grass: 6 }],
    [:montenevera, :town, 'Montenevera', { gym: 6, stage: 6, houses: 3 }],
    [:north1, :route, 'North Province (Area One)', { stage_band: 7, size: [60, 40], grass: 6 }],
    [:alfornada, :town, 'Alfornada', { gym: 7, stage: 7, houses: 3 }],
    [:glaseado, :route, 'Glaseado Mountain', { stage_band: 8, size: [60, 48], grass: 6, trial: 8, trial_name: "Grusha's Gym" }],
    [:league_road, :route, 'Path to the Pokémon League', { stage_band: 9 }]
  ],
  links: [
    [:cabo_poco, 'North', :poco_path], [:poco_path, 'North', :los_platos], [:los_platos, 'North', :south1],
    [:south1, 'North', :mesagoza], [:mesagoza, 'West', :south3, 0.3], [:south3, 'West', :cortondo],
    [:mesagoza, 'South', :south2, 0.8], [:south2, 'East', :artazon], [:mesagoza, 'East', :east1],
    [:east1, 'East', :levincia], [:mesagoza, 'West', :asado_desert, 0.7], [:asado_desert, 'West', :cascarrafa],
    [:cascarrafa, 'North', :west1], [:west1, 'North', :medali], [:levincia, 'North', :east3],
    [:east3, 'North', :montenevera], [:mesagoza, 'North', :north1], [:north1, 'West', :alfornada],
    [:north1, 'North', :glaseado], [:glaseado, 'East', :league_road]
  ],
  start: { town: :cabo_poco, gate_side: 'West' },
  victory_road: { from: :league_road, side: 'North' },
  requires: {
    poco_path: { starter: true }, south2: 1, east1: 2, asado_desert: 3, west1: 4, east3: 5, north1: 6,
    glaseado: 7, league_road: 8
  },
  story: [
    # Path of Legends: Titans in the wild
    { kind: :wild, species: [:KLAWF, 16], flag: :totem1, at: [:south3, [30, 20]], name: 'Titan Klawf', graphic: '',
      intro: 'A huge Klawf drops from the cliffs! It\'s the Stony Cliff Titan!' },
    { kind: :wild, species: [:BOMBIRDIER, 20], flag: :totem3, at: [:east1, [30, 20]], name: 'Titan Bombirdier', graphic: '',
      intro: 'Bombirdier swoops down! It\'s the Open Sky Titan!' },
    { kind: :wild, species: [:ORTHWORM, 29], flag: :totem4, at: [:asado_desert, [30, 22]], name: 'Titan Orthworm', graphic: '',
      intro: 'The sand bursts open! It\'s the Lurking Steel Titan, Orthworm!' },
    { kind: :wild, species: [:GREATTUSK, 45], flag: :totem6, at: [:east3, [30, 20]], name: 'Titan Great Tusk', graphic: '',
      intro: 'The ground shakes... It\'s the Quaking Earth Titan!' },
    { kind: :wild, species: [:DONDOZO, 56], flag: :totem8, at: [:glaseado, [20, 30]], name: 'Titan Dondozo', graphic: '',
      intro: 'A gigantic Dondozo rises from the lake! It\'s the False Dragon Titan!' },
    # Starfall Street: Team Star bases
    { kind: :battle, key: :paldea_giacomo, at: [:south2, [40, 18]], intro: 'Giacomo: Segin Squad\'s base is off limits! Starfall Street begins here!' },
    { kind: :battle, key: :paldea_mela, at: [:east1, [40, 18]], intro: 'Mela: Schedar Squad doesn\'t back down from anyone!' },
    { kind: :battle, key: :paldea_rival2, at: [:levincia, [27, 26]], intro: 'Nemona: Three badges already? Let\'s battle!' },
    { kind: :battle, key: :paldea_atticus, at: [:west1, [40, 18]], intro: 'Atticus: Navi Squad\'s poison verse awaits thee!' },
    { kind: :battle, key: :paldea_ortega, at: [:east3, [40, 18]], intro: 'Ortega: Ruchbah Squad will make you sorry you came!' },
    { kind: :battle, key: :paldea_eri, at: [:north1, [40, 18]], intro: 'Eri: Caph Squad stands firm. Show me your strength!' },
    { kind: :npc, name: 'Academy student', at: [:mesagoza, [27, 24]],
      lines: ['Welcome to Mesagoza! The Treasure Hunt has three paths: the Gyms, the Titans and Team Star. You\'ll need all three before Nemona will face you at the League.'] }
  ]
}
