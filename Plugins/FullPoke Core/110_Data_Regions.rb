#===============================================================================
# Johto, Hoenn, Sinnoh, Unova, Kalos, Alola, Galar and Paldea: the important
# trainers of each region and its circuit (see 080_Circuits.rb).
#
# Traditional teams follow each region's main-series game (HeartGold/SoulSilver,
# Omega Ruby/Alpha Sapphire, Platinum, Black/White, X/Y, Sun/Moon, Sword/Shield,
# Scarlet/Violet), trimmed where a game's team depends on choices.
# "STARTER" in a rival's party is the starter strong against the player's.
#
# Trainer types FP_* are generic classes (Gym Leader, Elite Four, …) shared by
# every region; the characters are told apart by name.
#===============================================================================
module FullPoke
  module Data
    # One line per trainer: key, role, trainer type, name, team, types, signature, tier
    def self.t(region, key, role, type, name, party, types = nil, sig = nil, tier = 1, extra = {})
      FullPoke::Teams.register({ key: key, region: region, role: role, tr_type: type, name: name,
                                 party: party, types: types, signature: sig || [], tier: tier,
                                 lose_text: extra[:lose] || "Well done. You've earned it." }.merge(extra))
    end

    def self.gym(region, n, key, type, name, party, types, sig, badge, town, extra = {})
      t(region, key, :gym, type, name, party, types, sig, n, extra)
      { town: town, leader: key, badge: badge, totem: extra[:totem], extras: extra[:extras] }
    end

    def self.regions
      #--- Johto -----------------------------------------------------------------
      r = :johto
      t(r, :johto_rival1, :rival, :FP_RIVAL_M, nil, "STARTER:5", nil, [:SNEASEL], 1, rival_starter: true, size: 4)
      t(r, :johto_rival2, :rival, :FP_RIVAL_M, nil, "GASTLY:12 ZUBAT:14 STARTER:16", nil, [:SNEASEL], 2, rival_starter: true, size: 4)
      t(r, :johto_rival3, :rival, :FP_RIVAL_M, nil, "HAUNTER:20 MAGNEMITE:18 ZUBAT:20 STARTER:22", nil, [:SNEASEL, :CROBAT], 5, rival_starter: true, size: 5)
      t(r, :johto_rival4, :rival, :FP_RIVAL_M, nil, "SNEASEL:34 GOLBAT:36 MAGNETON:35 GENGAR:35 ALAKAZAM:35 STARTER:38", nil, [:WEAVILE, :CROBAT], 8, rival_starter: true)
      t(r, :johto_archer, :boss, :FP_BOSS_M, "Archer", "HOUNDOUR:38 KOFFING:38 HOUNDOOM:40", [:DARK, :POISON], [:HOUNDOOM], 7,
        lose: "Team Rocket... disbanded again...")
      Circuit.define(r, {
        stages: [
          gym(r, 1, :johto_falkner, :FP_LEADER_M, "Falkner", "PIDGEY:9 PIDGEOTTO:13", [:FLYING], [:PIDGEOT], "Zephyr Badge", "Violet City"),
          gym(r, 2, :johto_bugsy, :FP_LEADER_M, "Bugsy", "METAPOD:15 KAKUNA:15 SCYTHER:17", [:BUG], [:SCIZOR, :SCYTHER], "Hive Badge", "Azalea Town", extras: [:johto_rival2]),
          gym(r, 3, :johto_whitney, :FP_LEADER_F, "Whitney", "CLEFAIRY:17 MILTANK:19", [:NORMAL], [:MILTANK], "Plain Badge", "Goldenrod City"),
          gym(r, 4, :johto_morty, :FP_LEADER_M, "Morty", "GASTLY:21 HAUNTER:21 HAUNTER:23 GENGAR:25", [:GHOST], [:GENGAR], "Fog Badge", "Ecruteak City", extras: [:johto_rival3]),
          gym(r, 5, :johto_chuck, :FP_LEADER_M, "Chuck", "PRIMEAPE:27 POLIWRATH:30", [:FIGHTING], [:POLIWRATH], "Storm Badge", "Cianwood City"),
          gym(r, 6, :johto_jasmine, :FP_LEADER_F, "Jasmine", "MAGNEMITE:30 MAGNEMITE:30 STEELIX:35", [:STEEL], [:STEELIX], "Mineral Badge", "Olivine City"),
          gym(r, 7, :johto_pryce, :FP_LEADER_M, "Pryce", "SEEL:30 DEWGONG:32 PILOSWINE:34", [:ICE], [:MAMOSWINE], "Glacier Badge", "Mahogany Town", extras: [:johto_archer]),
          gym(r, 8, :johto_clair, :FP_LEADER_F, "Clair", "DRAGONAIR:37 DRAGONAIR:37 DRAGONAIR:37 KINGDRA:40", [:DRAGON], [:KINGDRA], "Rising Badge", "Blackthorn City")
        ],
        rivals: { 0 => :johto_rival1, 9 => :johto_rival4 },
        league: [
          t(r, :johto_will, :e4, :FP_ELITE_M, "Will", "XATU:40 JYNX:41 EXEGGUTOR:41 SLOWBRO:41 XATU:42", [:PSYCHIC], [:XATU], 9)[:key],
          t(r, :johto_koga, :e4, :FP_ELITE_M, "Koga", "ARIADOS:40 VENOMOTH:41 FORRETRESS:43 MUK:42 CROBAT:44", [:POISON], [:CROBAT], 9)[:key],
          t(r, :johto_bruno, :e4, :FP_ELITE_M, "Bruno", "HITMONTOP:42 HITMONLEE:42 HITMONCHAN:42 ONIX:43 MACHAMP:46", [:FIGHTING], [:MACHAMP], 9)[:key],
          t(r, :johto_karen, :e4, :FP_ELITE_F, "Karen", "UMBREON:42 VILEPLUME:42 MURKROW:44 GENGAR:45 HOUNDOOM:47", [:DARK], [:HOUNDOOM, :UMBREON], 9)[:key]
        ],
        champion: t(r, :johto_lance, :champion, :FP_CHAMPION_M, "Lance", "GYARADOS:44 DRAGONITE:47 DRAGONITE:47 AERODACTYL:46 CHARIZARD:46 DRAGONITE:50", nil, [:DRAGONITE, :GYARADOS], 10)[:key],
        legendary: [:HOOH, 70]
      })

      #--- Hoenn -----------------------------------------------------------------
      r = :hoenn
      t(r, :hoenn_rival1, :rival, :FP_RIVAL_F, nil, "STARTER:5", nil, [:SWELLOW], 1, rival_starter: true, size: 4)
      t(r, :hoenn_rival2, :rival, :FP_RIVAL_F, nil, "WINGULL:18 SHROOMISH:18 STARTER:20", nil, [:PELIPPER], 3, rival_starter: true, size: 4)
      t(r, :hoenn_rival3, :rival, :FP_RIVAL_F, nil, "PELIPPER:31 LOMBRE:32 STARTER:34", nil, [:PELIPPER], 6, rival_starter: true, size: 5)
      t(r, :hoenn_maxie, :boss, :FP_BOSS_M, "Maxie", "MIGHTYENA:24 ZUBAT:24 CAMERUPT:25", [:FIRE, :GROUND, :DARK], [:CAMERUPT], 5,
        lose: "Team Magma's plans... thwarted.")
      Circuit.define(r, {
        stages: [
          gym(r, 1, :hoenn_roxanne, :FP_LEADER_F, "Roxanne", "GEODUDE:12 GEODUDE:12 NOSEPASS:14", [:ROCK], [:PROBOPASS, :NOSEPASS], "Stone Badge", "Rustboro City"),
          gym(r, 2, :hoenn_brawly, :FP_LEADER_M, "Brawly", "MACHOP:14 MEDITITE:14 MAKUHITA:16", [:FIGHTING], [:HARIYAMA], "Knuckle Badge", "Dewford Town"),
          gym(r, 3, :hoenn_wattson, :FP_LEADER_M, "Wattson", "MAGNEMITE:19 VOLTORB:19 MAGNETON:21 MANECTRIC:24", [:ELECTRIC], [:MANECTRIC], "Dynamo Badge", "Mauville City", extras: [:hoenn_rival2]),
          gym(r, 4, :hoenn_flannery, :FP_LEADER_F, "Flannery", "SLUGMA:26 NUMEL:26 TORKOAL:29", [:FIRE], [:TORKOAL], "Heat Badge", "Lavaridge Town"),
          gym(r, 5, :hoenn_norman, :FP_LEADER_M, "Norman", "SLAKING:28 VIGOROTH:30 LINOONE:29 SLAKING:31", [:NORMAL], [:SLAKING], "Balance Badge", "Petalburg City", extras: [:hoenn_maxie]),
          gym(r, 6, :hoenn_winona, :FP_LEADER_F, "Winona", "SWABLU:31 TROPIUS:31 PELIPPER:30 SKARMORY:32 ALTARIA:33", [:FLYING], [:ALTARIA], "Feather Badge", "Fortree City", extras: [:hoenn_rival3]),
          gym(r, 7, :hoenn_tate, :FP_LEADER_M, "Tate", "SOLROCK:42 LUNATONE:42", [:PSYCHIC], [:SOLROCK, :LUNATONE], "Mind Badge", "Mossdeep City"),
          gym(r, 8, :hoenn_juan, :FP_LEADER_M, "Juan", "LUVDISC:41 WHISCASH:41 SEALEO:43 CRAWDAUNT:43 KINGDRA:46", [:WATER], [:KINGDRA, :MILOTIC], "Rain Badge", "Sootopolis City")
        ],
        rivals: { 0 => :hoenn_rival1 },
        league: [
          t(r, :hoenn_sidney, :e4, :FP_ELITE_M, "Sidney", "MIGHTYENA:46 SHIFTRY:48 CACTURNE:46 CRAWDAUNT:48 ABSOL:49", [:DARK], [:ABSOL], 9)[:key],
          t(r, :hoenn_phoebe, :e4, :FP_ELITE_F, "Phoebe", "DUSCLOPS:48 BANETTE:49 SABLEYE:50 BANETTE:49 DUSCLOPS:51", [:GHOST], [:DUSKNOIR], 9)[:key],
          t(r, :hoenn_glacia, :e4, :FP_ELITE_F, "Glacia", "GLALIE:50 SEALEO:50 SEALEO:52 GLALIE:52 WALREIN:53", [:ICE], [:WALREIN], 9)[:key],
          t(r, :hoenn_drake, :e4, :FP_ELITE_M, "Drake", "SHELGON:52 ALTARIA:54 FLYGON:53 FLYGON:53 SALAMENCE:55", [:DRAGON], [:SALAMENCE], 9)[:key]
        ],
        champion: t(r, :hoenn_steven, :champion, :FP_CHAMPION_M, "Steven", "SKARMORY:57 CLAYDOL:55 AGGRON:56 CRADILY:56 ARMALDO:56 METAGROSS:58", nil, [:METAGROSS, :AGGRON], 10)[:key],
        legendary: [:RAYQUAZA, 70]
      })

      #--- Sinnoh ----------------------------------------------------------------
      r = :sinnoh
      t(r, :sinnoh_rival1, :rival, :FP_RIVAL_M, nil, "STARTER:5", nil, [:STARAPTOR], 1, rival_starter: true, size: 4)
      t(r, :sinnoh_rival2, :rival, :FP_RIVAL_M, nil, "STARAVIA:25 ROSELIA:23 PONYTA:23 STARTER:27", nil, [:STARAPTOR], 4, rival_starter: true, size: 5)
      t(r, :sinnoh_rival3, :rival, :FP_RIVAL_M, nil, "STARAPTOR:48 HERACROSS:48 FLOATZEL:49 ROSERADE:49 SNORLAX:51 STARTER:53", nil, [:STARAPTOR, :SNORLAX], 8, rival_starter: true)
      t(r, :sinnoh_cyrus, :boss, :FP_BOSS_M, "Cyrus", "HOUNDOOM:45 HONCHKROW:47 CROBAT:46 GYARADOS:46 WEAVILE:48", [:DARK], [:WEAVILE, :HONCHKROW], 7,
        lose: "I see... So this is how it ends.")
      Circuit.define(r, {
        stages: [
          gym(r, 1, :sinnoh_roark, :FP_LEADER_M, "Roark", "GEODUDE:12 ONIX:12 CRANIDOS:14", [:ROCK], [:RAMPARDOS], "Coal Badge", "Oreburgh City"),
          gym(r, 2, :sinnoh_gardenia, :FP_LEADER_F, "Gardenia", "CHERUBI:19 TURTWIG:19 ROSERADE:22", [:GRASS], [:ROSERADE], "Forest Badge", "Eterna City"),
          gym(r, 3, :sinnoh_maylene, :FP_LEADER_F, "Maylene", "MEDITITE:27 MACHOKE:27 LUCARIO:30", [:FIGHTING], [:LUCARIO], "Cobble Badge", "Veilstone City"),
          gym(r, 4, :sinnoh_wake, :FP_LEADER_M, "Crasher Wake", "GYARADOS:27 QUAGSIRE:27 FLOATZEL:30", [:WATER], [:FLOATZEL], "Fen Badge", "Pastoria City", extras: [:sinnoh_rival2]),
          gym(r, 5, :sinnoh_fantina, :FP_LEADER_F, "Fantina", "DUSKULL:32 HAUNTER:34 MISMAGIUS:36", [:GHOST], [:MISMAGIUS], "Relic Badge", "Hearthome City"),
          gym(r, 6, :sinnoh_byron, :FP_LEADER_M, "Byron", "MAGNETON:37 STEELIX:38 BASTIODON:41", [:STEEL], [:BASTIODON], "Mine Badge", "Canalave City"),
          gym(r, 7, :sinnoh_candice, :FP_LEADER_F, "Candice", "SNEASEL:40 PILOSWINE:40 ABOMASNOW:42 FROSLASS:44", [:ICE], [:FROSLASS, :ABOMASNOW], "Icicle Badge", "Snowpoint City", extras: [:sinnoh_cyrus]),
          gym(r, 8, :sinnoh_volkner, :FP_LEADER_M, "Volkner", "JOLTEON:46 RAICHU:46 LUXRAY:48 ELECTIVIRE:50", [:ELECTRIC], [:ELECTIVIRE, :LUXRAY], "Beacon Badge", "Sunyshore City")
        ],
        rivals: { 0 => :sinnoh_rival1, 9 => :sinnoh_rival3 },
        league: [
          t(r, :sinnoh_aaron, :e4, :FP_ELITE_M, "Aaron", "DUSTOX:49 BEAUTIFLY:49 VESPIQUEN:50 HERACROSS:51 DRAPION:53", [:BUG], [:DRAPION, :VESPIQUEN], 9)[:key],
          t(r, :sinnoh_bertha, :e4, :FP_ELITE_F, "Bertha", "WHISCASH:50 GLISCOR:53 HIPPOWDON:52 GOLEM:52 RHYPERIOR:55", [:GROUND], [:HIPPOWDON], 9)[:key],
          t(r, :sinnoh_flint, :e4, :FP_ELITE_M, "Flint", "HOUNDOOM:52 FLAREON:55 RAPIDASH:53 INFERNAPE:55 MAGMORTAR:57", [:FIRE], [:INFERNAPE], 9)[:key],
          t(r, :sinnoh_lucian, :e4, :FP_ELITE_M, "Lucian", "MRMIME:53 ESPEON:55 BRONZONG:54 ALAKAZAM:56 GALLADE:59", [:PSYCHIC], [:GALLADE, :BRONZONG], 9)[:key]
        ],
        champion: t(r, :sinnoh_cynthia, :champion, :FP_CHAMPION_F, "Cynthia", "SPIRITOMB:58 ROSERADE:58 TOGEKISS:60 LUCARIO:60 MILOTIC:58 GARCHOMP:62", nil, [:GARCHOMP, :LUCARIO], 10)[:key],
        legendary: [:GIRATINA, 70]
      })

      #--- Unova -----------------------------------------------------------------
      r = :unova
      t(r, :unova_rival1, :rival, :FP_RIVAL_M, nil, "STARTER:5", nil, [:LIEPARD], 1, rival_starter: true, size: 4)
      t(r, :unova_rival2, :rival, :FP_RIVAL_M, nil, "PATRAT:12 PURRLOIN:12 STARTER:14", nil, [:LIEPARD], 2, rival_starter: true, size: 4)
      t(r, :unova_rival3, :rival, :FP_RIVAL_M, nil, "UNFEZANT:46 LIEPARD:46 SIMIPOUR:46 STARTER:48", nil, [:UNFEZANT, :LIEPARD], 8, rival_starter: true)
      t(r, :unova_ghetsis, :boss, :FP_BOSS_M, "Ghetsis", "COFAGRIGUS:52 BOUFFALANT:52 SEISMITOAD:52 BISHARP:52 EELEKTROSS:52 HYDREIGON:54", nil, [:HYDREIGON], 8,
        lose: "Impossible! I am the perfect ruler of a perfect new world!")
      Circuit.define(r, {
        stages: [
          gym(r, 1, :unova_cilan, :FP_LEADER_M, "Cilan", "LILLIPUP:12 PANSAGE:14", [:GRASS], [:SIMISAGE], "Trio Badge", "Striaton City", extras: [:unova_rival2]),
          gym(r, 2, :unova_lenora, :FP_LEADER_F, "Lenora", "HERDIER:18 WATCHOG:20", [:NORMAL], [:WATCHOG, :STOUTLAND], "Basic Badge", "Nacrene City"),
          gym(r, 3, :unova_burgh, :FP_LEADER_M, "Burgh", "WHIRLIPEDE:21 DWEBBLE:21 LEAVANNY:23", [:BUG], [:LEAVANNY], "Insect Badge", "Castelia City"),
          gym(r, 4, :unova_elesa, :FP_LEADER_F, "Elesa", "EMOLGA:25 EMOLGA:25 ZEBSTRIKA:27", [:ELECTRIC], [:ZEBSTRIKA], "Bolt Badge", "Nimbasa City"),
          gym(r, 5, :unova_clay, :FP_LEADER_M, "Clay", "KROKOROK:29 PALPITOAD:29 EXCADRILL:31", [:GROUND], [:EXCADRILL], "Quake Badge", "Driftveil City"),
          gym(r, 6, :unova_skyla, :FP_LEADER_F, "Skyla", "SWOOBAT:33 UNFEZANT:33 SWANNA:35", [:FLYING], [:SWANNA], "Jet Badge", "Mistralton City"),
          gym(r, 7, :unova_brycen, :FP_LEADER_M, "Brycen", "VANILLISH:37 CRYOGONAL:37 BEARTIC:39", [:ICE], [:BEARTIC], "Freeze Badge", "Icirrus City"),
          gym(r, 8, :unova_drayden, :FP_LEADER_M, "Drayden", "FRAXURE:41 DRUDDIGON:41 HAXORUS:43", [:DRAGON], [:HAXORUS], "Legend Badge", "Opelucid City", extras: [:unova_ghetsis])
        ],
        rivals: { 0 => :unova_rival1, 9 => :unova_rival3 },
        league: [
          t(r, :unova_shauntal, :e4, :FP_ELITE_F, "Shauntal", "COFAGRIGUS:48 JELLICENT:48 GOLURK:48 CHANDELURE:50", [:GHOST], [:CHANDELURE], 9)[:key],
          t(r, :unova_grimsley, :e4, :FP_ELITE_M, "Grimsley", "SCRAFTY:48 LIEPARD:48 KROOKODILE:48 BISHARP:50", [:DARK], [:BISHARP], 9)[:key],
          t(r, :unova_caitlin, :e4, :FP_ELITE_F, "Caitlin", "REUNICLUS:48 MUSHARNA:48 SIGILYPH:48 GOTHITELLE:50", [:PSYCHIC], [:GOTHITELLE], 9)[:key],
          t(r, :unova_marshal, :e4, :FP_ELITE_M, "Marshal", "THROH:48 SAWK:48 MIENSHAO:48 CONKELDURR:50", [:FIGHTING], [:CONKELDURR], 9)[:key]
        ],
        champion: t(r, :unova_iris, :champion, :FP_CHAMPION_F, "Iris", "HYDREIGON:57 DRUDDIGON:57 LAPRAS:57 AGGRON:57 ARCHEOPS:57 HAXORUS:59", nil, [:HAXORUS, :HYDREIGON], 10)[:key],
        legendary: [:RESHIRAM, 70]
      })

      #--- Kalos -----------------------------------------------------------------
      r = :kalos
      t(r, :kalos_rival1, :rival, :FP_RIVAL_F, nil, "STARTER:5", nil, [:MEOWSTIC], 1, rival_starter: true, size: 4)
      t(r, :kalos_rival2, :rival, :FP_RIVAL_F, nil, "FLETCHLING:12 STARTER:14", nil, [:TALONFLAME], 2, rival_starter: true, size: 4)
      t(r, :kalos_rival3, :rival, :FP_RIVAL_F, nil, "MEOWSTIC:57 ABSOL:57 JOLTEON:57 STARTER:59", nil, [:MEOWSTIC, :ABSOL], 8, rival_starter: true)
      t(r, :kalos_lysandre, :boss, :FP_BOSS_M, "Lysandre", "MIENSHAO:49 HONCHKROW:49 PYROAR:51 GYARADOS:53", [:FIRE, :DARK], [:PYROAR, :GYARADOS], 7,
        lose: "The future I wanted... is gone.")
      Circuit.define(r, {
        stages: [
          gym(r, 1, :kalos_viola, :FP_LEADER_F, "Viola", "SURSKIT:10 VIVILLON:12", [:BUG], [:VIVILLON], "Bug Badge", "Santalune City", extras: [:kalos_rival2]),
          gym(r, 2, :kalos_grant, :FP_LEADER_M, "Grant", "AMAURA:25 TYRUNT:25", [:ROCK], [:TYRANTRUM, :AURORUS], "Cliff Badge", "Cyllage City"),
          gym(r, 3, :kalos_korrina, :FP_LEADER_F, "Korrina", "MIENFOO:29 MACHOKE:28 HAWLUCHA:32", [:FIGHTING], [:LUCARIO, :HAWLUCHA], "Rumble Badge", "Shalour City"),
          gym(r, 4, :kalos_ramos, :FP_LEADER_M, "Ramos", "JUMPLUFF:30 WEEPINBELL:31 GOGOAT:34", [:GRASS], [:GOGOAT], "Plant Badge", "Coumarine City"),
          gym(r, 5, :kalos_clemont, :FP_LEADER_M, "Clemont", "EMOLGA:35 MAGNETON:35 HELIOLISK:37", [:ELECTRIC], [:HELIOLISK], "Voltage Badge", "Lumiose City"),
          gym(r, 6, :kalos_valerie, :FP_LEADER_F, "Valerie", "MAWILE:38 MRMIME:39 SYLVEON:42", [:FAIRY], [:SYLVEON], "Fairy Badge", "Laverre City"),
          gym(r, 7, :kalos_olympia, :FP_LEADER_F, "Olympia", "SIGILYPH:44 SLOWKING:45 MEOWSTIC:48", [:PSYCHIC], [:MEOWSTIC], "Psychic Badge", "Anistar City", extras: [:kalos_lysandre]),
          gym(r, 8, :kalos_wulfric, :FP_LEADER_M, "Wulfric", "ABOMASNOW:56 CRYOGONAL:55 AVALUGG:59", [:ICE], [:AVALUGG], "Iceberg Badge", "Snowbelle City")
        ],
        rivals: { 0 => :kalos_rival1, 9 => :kalos_rival3 },
        league: [
          t(r, :kalos_malva, :e4, :FP_ELITE_F, "Malva", "PYROAR:63 TORKOAL:63 CHANDELURE:63 TALONFLAME:65", [:FIRE], [:TALONFLAME], 9)[:key],
          t(r, :kalos_siebold, :e4, :FP_ELITE_M, "Siebold", "CLAWITZER:63 GYARADOS:63 STARMIE:63 BARBARACLE:65", [:WATER], [:BARBARACLE], 9)[:key],
          t(r, :kalos_wikstrom, :e4, :FP_ELITE_M, "Wikstrom", "KLEFKI:63 PROBOPASS:63 SCIZOR:63 AEGISLASH:65", [:STEEL], [:AEGISLASH], 9)[:key],
          t(r, :kalos_drasna, :e4, :FP_ELITE_F, "Drasna", "DRAGALGE:63 DRUDDIGON:63 ALTARIA:63 NOIVERN:65", [:DRAGON], [:NOIVERN], 9)[:key]
        ],
        champion: t(r, :kalos_diantha, :champion, :FP_CHAMPION_F, "Diantha", "HAWLUCHA:64 TYRANTRUM:65 AURORUS:65 GOURGEIST:65 GOODRA:66 GARDEVOIR:68", nil, [:GARDEVOIR, :GOODRA], 10)[:key],
        legendary: [:XERNEAS, 70]
      })

      #--- Alola: island trials (Totem Pokémon, then the captain) and Kahunas' grand trials
      r = :alola
      t(r, :alola_rival1, :rival, :FP_RIVAL_M, nil, "STARTER:5", nil, [:RAICHU], 1, rival_starter: true, size: 4)
      t(r, :alola_rival2, :rival, :FP_RIVAL_M, nil, "PICHU:7 STARTER:9", nil, [:RAICHU], 2, rival_starter: true, size: 4)
      t(r, :alola_rival3, :rival, :FP_RIVAL_M, nil, "NOIBAT:33 FLAREON:34 RAICHU:34 STARTER:36", nil, [:RAICHU, :NOIVERN], 7, rival_starter: true)
      t(r, :alola_guzma, :boss, :FP_BOSS_M, "Guzma", "ARIADOS:41 MASQUERAIN:41 GOLISOPOD:43", [:BUG], [:GOLISOPOD], 7,
        lose: "Guzma... What is wrong with you?!")
      Circuit.define(r, {
        stages: [
          gym(r, 1, :alola_ilima, :FP_CAPTAIN_M, "Ilima", "YUNGOOS:10 SMEARGLE:11", [:NORMAL], [:GUMSHOOS], "Normalium Z", "Hau'oli City", totem: [:GUMSHOOS, 12], extras: [:alola_rival2]),
          gym(r, 2, :alola_hala, :FP_KAHUNA_M, "Hala", "MANKEY:15 MAKUHITA:15 CRABRAWLER:16", [:FIGHTING], [:HARIYAMA, :CRABOMINABLE], "Fightinium Z", "Heahea City"),
          gym(r, 3, :alola_lana, :FP_CAPTAIN_F, "Lana", "CHINCHOU:18 SHELLDER:18 WISHIWASHI:20", [:WATER], [:WISHIWASHI], "Waterium Z", "Paniola Town", totem: [:WISHIWASHI, 20]),
          gym(r, 4, :alola_kiawe, :FP_CAPTAIN_M, "Kiawe", "GROWLITHE:22 FLETCHINDER:22 SALANDIT:23", [:FIRE], [:ARCANINE], "Firium Z", "Royal Avenue", totem: [:SALAZZLE, 22]),
          gym(r, 5, :alola_mallow, :FP_CAPTAIN_F, "Mallow", "FOMANTIS:24 STEENEE:25", [:GRASS], [:TSAREENA, :LURANTIS], "Grassium Z", "Maile City", totem: [:LURANTIS, 24]),
          gym(r, 6, :alola_olivia, :FP_KAHUNA_F, "Olivia", "NOSEPASS:26 BOLDORE:26 LYCANROC:27", [:ROCK], [:LYCANROC, :PROBOPASS], "Rockium Z", "Konikoni City"),
          gym(r, 7, :alola_acerola, :FP_CAPTAIN_F, "Acerola", "SABLEYE:33 DRIFBLIM:34 MIMIKYU:35", [:GHOST], [:MIMIKYU, :PALOSSAND], "Ghostium Z", "Tapu Village", totem: [:MIMIKYU, 33], extras: [:alola_guzma]),
          gym(r, 8, :alola_nanu, :FP_KAHUNA_M, "Nanu", "SABLEYE:38 KROKOROK:38 PERSIAN:39", [:DARK], [:PERSIAN, :KROOKODILE], "Darkinium Z", "Po Town")
        ],
        rivals: { 0 => :alola_rival1, 9 => :alola_rival3 },
        league: [
          t(r, :alola_e4_hala, :e4, :FP_KAHUNA_M, "Hala", "HARIYAMA:54 PRIMEAPE:54 BEWEAR:54 POLIWRATH:54 CRABOMINABLE:55", [:FIGHTING], [:CRABOMINABLE], 9)[:key],
          t(r, :alola_e4_olivia, :e4, :FP_KAHUNA_F, "Olivia", "RELICANTH:54 CARBINK:54 GOLEM:54 PROBOPASS:54 LYCANROC:55", [:ROCK], [:LYCANROC], 9)[:key],
          t(r, :alola_e4_acerola, :e4, :FP_ELITE_F, "Acerola", "SABLEYE:54 DRIFBLIM:54 DHELMISE:54 FROSLASS:54 PALOSSAND:55", [:GHOST], [:PALOSSAND], 9)[:key],
          t(r, :alola_kahili, :e4, :FP_ELITE_F, "Kahili", "SKARMORY:54 CROBAT:54 ORICORIO:54 MANDIBUZZ:54 TOUCANNON:55", [:FLYING], [:TOUCANNON], 9)[:key]
        ],
        champion: t(r, :alola_kukui, :champion, :FP_CHAMPION_M, "Kukui", "LYCANROC:57 NINETALES:56 BRAVIARY:56 MAGNEZONE:56 SNORLAX:56 STARTER:58", nil, [:LYCANROC], 10, rival_starter: true)[:key],
        legendary: [:SOLGALEO, 70]
      })

      #--- Galar: Gym Challenge, then the Champion Cup ---------------------------
      r = :galar
      t(r, :galar_rival1, :rival, :FP_RIVAL_M, nil, "WOOLOO:6 STARTER:5", nil, [:DUBWOOL], 1, rival_starter: true, size: 4)
      t(r, :galar_rival2, :rival, :FP_RIVAL_M, nil, "WOOLOO:14 ROOKIDEE:14 STARTER:16", nil, [:DUBWOOL, :CORVIKNIGHT], 3, rival_starter: true, size: 4)
      t(r, :galar_rose, :boss, :FP_BOSS_M, "Rose", "COPPERAJAH:61 FERROTHORN:61 ESCAVALIER:61 PERRSERKER:62 KLINKLANG:63", [:STEEL], [:COPPERAJAH], 8,
        lose: "I see. Then the future of Galar is in your hands.")
      Circuit.define(r, {
        stages: [
          gym(r, 1, :galar_milo, :FP_LEADER_M, "Milo", "GOSSIFLEUR:19 ELDEGOSS:20", [:GRASS], [:ELDEGOSS], "Grass Badge", "Turffield"),
          gym(r, 2, :galar_nessa, :FP_LEADER_F, "Nessa", "GOLDEEN:22 ARROKUDA:23 DREDNAW:24", [:WATER], [:DREDNAW], "Water Badge", "Hulbury"),
          gym(r, 3, :galar_kabu, :FP_LEADER_M, "Kabu", "NINETALES:25 ARCANINE:25 CENTISKORCH:27", [:FIRE], [:CENTISKORCH], "Fire Badge", "Motostoke", extras: [:galar_rival2]),
          gym(r, 4, :galar_bea, :FP_LEADER_F, "Bea", "HITMONTOP:34 PANGORO:34 SIRFETCHD:35 MACHAMP:36", [:FIGHTING], [:MACHAMP, :SIRFETCHD], "Fighting Badge", "Stow-on-Side"),
          gym(r, 5, :galar_opal, :FP_LEADER_F, "Opal", "MAWILE:36 TOGEKISS:37 ALCREMIE:38", [:FAIRY], [:ALCREMIE], "Fairy Badge", "Ballonlea"),
          gym(r, 6, :galar_gordie, :FP_LEADER_M, "Gordie", "BARBARACLE:40 SHUCKLE:40 STONJOURNER:41 COALOSSAL:42", [:ROCK], [:COALOSSAL], "Rock Badge", "Circhester"),
          gym(r, 7, :galar_piers, :FP_LEADER_M, "Piers", "SCRAFTY:44 MALAMAR:45 SKUNTANK:45 OBSTAGOON:46", [:DARK], [:OBSTAGOON], "Dark Badge", "Spikemuth"),
          gym(r, 8, :galar_raihan, :FP_LEADER_M, "Raihan", "GIGALITH:46 FLYGON:47 SANDACONDA:46 DURALUDON:48", [:DRAGON], [:DURALUDON, :FLYGON], "Dragon Badge", "Hammerlocke", extras: [:galar_rose])
        ],
        rivals: { 0 => :galar_rival1 },
        league: [
          t(r, :galar_marnie, :e4, :FP_RIVAL_F, "Marnie", "LIEPARD:47 TOXICROAK:47 SCRAFTY:47 MORPEKO:48 GRIMMSNARL:49", [:DARK], [:GRIMMSNARL], 9)[:key],
          t(r, :galar_bede, :e4, :FP_RIVAL_M, "Bede", "MAWILE:51 GARDEVOIR:53 RAPIDASH:52 HATTERENE:53", [:FAIRY, :PSYCHIC], [:HATTERENE], 9)[:key],
          t(r, :galar_rival3, :rival, :FP_RIVAL_M, nil, "DUBWOOL:59 CORVIKNIGHT:60 PINCURCHIN:59 SNORLAX:59 STARTER:62", nil, [:DUBWOOL, :CORVIKNIGHT], 9, rival_starter: true)[:key],
          t(r, :galar_raihan_final, :e4, :FP_LEADER_M, "Raihan", "FLYGON:53 GIGALITH:53 SANDACONDA:53 GOODRA:54 DURALUDON:55", [:DRAGON], [:DURALUDON], 9)[:key]
        ],
        champion: t(r, :galar_leon, :champion, :FP_CHAMPION_M, "Leon", "AEGISLASH:62 DRAGAPULT:62 HAXORUS:63 SEISMITOAD:64 RHYPERIOR:64 CHARIZARD:65", nil, [:CHARIZARD, :DRAGAPULT], 10)[:key],
        legendary: [:ZACIAN, 70]
      })

      #--- Paldea: Victory Road (Gyms), Path of Legends (Titans), Starfall Street
      # (Team Star) and the final battle with Nemona. Needs the Gen 9 data.
      r = :paldea
      t(r, :paldea_rival1, :rival, :FP_RIVAL_F, nil, "STARTER:5", nil, [:PAWMOT], 1, rival_starter: true, size: 4)
      t(r, :paldea_rival2, :rival, :FP_RIVAL_F, nil, "PAWMI:20 ROCKRUFF:20 STARTER:22", nil, [:PAWMOT, :LYCANROC], 3, rival_starter: true, size: 5)
      star = [
        [:paldea_giacomo, "Giacomo", "PAWNIARD:21 REVAVROOM:20", [:DARK], [:KINGAMBIT], 2],
        [:paldea_mela, "Mela", "TORKOAL:27 REVAVROOM:28", [:FIRE], [:TORKOAL], 3],
        [:paldea_atticus, "Atticus", "SKUNTANK:32 MUK:32 REVAVROOM:33", [:POISON], [:SKUNTANK], 5],
        [:paldea_ortega, "Ortega", "AZUMARILL:50 WIGGLYTUFF:50 DACHSBUN:50 REVAVROOM:51", [:FAIRY], [:DACHSBUN], 6],
        [:paldea_eri, "Eri", "TOXICROAK:55 PASSIMIAN:55 LUCARIO:55 ANNIHILAPE:56 REVAVROOM:56", [:FIGHTING], [:ANNIHILAPE], 7]
      ]
      star.each { |k, n, p, ty, sg, tier| t(r, k, :boss, :FP_STARBOSS, n, p, ty, sg, tier, lose: "Star Squad is never giving up!") }
      Circuit.define(r, {
        stages: [
          gym(r, 1, :paldea_katy, :FP_LEADER_F, "Katy", "NYMBLE:14 TAROUNTULA:14 TEDDIURSA:15", [:BUG], [:LOKIX], "Bug Badge", "Cortondo", totem: [:KLAWF, 16]),
          gym(r, 2, :paldea_brassius, :FP_LEADER_M, "Brassius", "PETILIL:16 SMOLIV:16 SUDOWOODO:17", [:GRASS], [:ARBOLIVA], "Grass Badge", "Artazon", extras: [:paldea_giacomo]),
          gym(r, 3, :paldea_iono, :FP_LEADER_F, "Iono", "WATTREL:23 BELLIBOLT:23 LUXIO:23 MISMAGIUS:24", [:ELECTRIC], [:BELLIBOLT, :KILOWATTREL], "Electric Badge", "Levincia", totem: [:BOMBIRDIER, 20], extras: [:paldea_mela, :paldea_rival2]),
          gym(r, 4, :paldea_kofu, :FP_LEADER_M, "Kofu", "VELUZA:29 WUGTRIO:29 CRABOMINABLE:30", [:WATER], [:VELUZA], "Water Badge", "Cascarrafa", totem: [:ORTHWORM, 29]),
          gym(r, 5, :paldea_larry, :FP_LEADER_M, "Larry", "KOMALA:35 DUDUNSPARCE:35 STARAPTOR:36", [:NORMAL], [:DUDUNSPARCE], "Normal Badge", "Medali", extras: [:paldea_atticus]),
          gym(r, 6, :paldea_ryme, :FP_LEADER_F, "Ryme", "BANETTE:41 MIMIKYU:41 HOUNDSTONE:41 TOXTRICITY:42", [:GHOST], [:HOUNDSTONE], "Ghost Badge", "Montenevera", totem: [:GREATTUSK, 45], extras: [:paldea_ortega]),
          gym(r, 7, :paldea_tulip, :FP_LEADER_F, "Tulip", "FARIGIRAF:44 GARDEVOIR:44 ESPATHRA:44 FLORGES:45", [:PSYCHIC], [:ESPATHRA, :FARIGIRAF], "Psychic Badge", "Alfornada", extras: [:paldea_eri]),
          gym(r, 8, :paldea_grusha, :FP_LEADER_M, "Grusha", "FROSMOTH:47 BEARTIC:47 CETITAN:47 ALTARIA:48", [:ICE], [:CETITAN], "Ice Badge", "Glaseado Mountain", totem: [:DONDOZO, 56])
        ],
        rivals: { 0 => :paldea_rival1 },
        league: [
          t(r, :paldea_rika, :e4, :FP_ELITE_F, "Rika", "WHISCASH:57 CAMERUPT:57 DONPHAN:57 DUGTRIO:57 CLODSIRE:58", [:GROUND], [:CLODSIRE], 9)[:key],
          t(r, :paldea_poppy, :e4, :FP_ELITE_F, "Poppy", "COPPERAJAH:58 MAGNEZONE:58 BRONZONG:58 CORVIKNIGHT:58 TINKATON:59", [:STEEL], [:TINKATON], 9)[:key],
          t(r, :paldea_larry_e4, :e4, :FP_ELITE_M, "Larry", "TROPIUS:59 ORICORIO:59 ALTARIA:59 STARAPTOR:59 FLAMIGO:60", [:FLYING], [:FLAMIGO], 9)[:key],
          t(r, :paldea_hassel, :e4, :FP_ELITE_M, "Hassel", "NOIVERN:60 HAXORUS:60 DRAGALGE:60 FLAPPLE:60 BAXCALIBUR:61", [:DRAGON], [:BAXCALIBUR], 9)[:key]
        ],
        champion: t(r, :paldea_geeta, :champion, :FP_CHAMPION_F, "Geeta", "ESPATHRA:61 GOGOAT:61 VELUZA:61 AVALUGG:61 KINGAMBIT:61 GLIMMORA:62", nil, [:GLIMMORA, :KINGAMBIT], 10)[:key],
        final: t(r, :paldea_nemona, :champion, :FP_RIVAL_F, nil, "LYCANROC:65 GOODRA:65 DUDUNSPARCE:65 ORTHWORM:65 PAWMOT:65 STARTER:66", nil, [:PAWMOT], 11, rival_starter: true)[:key],
        require_extras: true,
        legendary: [:KORAIDON, 70]
      })
    end
  end
end

FullPoke::Data.regions
