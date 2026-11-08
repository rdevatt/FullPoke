#===============================================================================
# Kanto: Gym Leaders, Elite Four, Champion, rival and Team Rocket.
# Traditional teams follow FireRed/LeafGreen. Brock and the early rival battles
# are PBS trainers (PBS/trainers.txt); their entries here only describe how
# they're enhanced in continuous mode.
#===============================================================================
module FullPoke
  module Data
    def self.kanto
      t = FullPoke::Teams
      # PBS trainers (enhancement rules only)
      t.register(key: :kanto_brock_pbs, region: :kanto, role: :gym, tr_type: :KANTOLEADER_Brock,
                 types: [:ROCK], signature: [:ONIX, :GEODUDE], tier: 1)
      t.register(key: :kanto_rival_pbs, region: :kanto, role: :rival, tr_type: :KANTORIVAL1,
                 rival_starter: true, signature: [:PIDGEY], tier: 1, size: 4)
      # Gyms
      t.register(key: :kanto_misty, region: :kanto, role: :gym, tr_type: :KANTOLEADER_Misty, name: "Misty",
                 party: "STARYU:18 STARMIE:21:SITRUSBERRY", types: [:WATER], signature: [:STARMIE, :PSYDUCK], tier: 2,
                 lose_text: "Wow! You're too much! All right! You can have the Cascade Badge to show you beat me!")
      t.register(key: :kanto_surge, region: :kanto, role: :gym, tr_type: :KANTOLEADER_Surge, name: "Lt. Surge",
                 party: "VOLTORB:21 PIKACHU:18 RAICHU:24:SITRUSBERRY", types: [:ELECTRIC], signature: [:RAICHU, :ELECTABUZZ], tier: 3,
                 lose_text: "Whoa! You're the real deal, kid! Fine then, take the Thunder Badge!")
      t.register(key: :kanto_erika, region: :kanto, role: :gym, tr_type: :KANTOLEADER_Erika, name: "Erika",
                 party: "VICTREEBEL:29 TANGELA:24 VILEPLUME:29:SITRUSBERRY", types: [:GRASS], signature: [:VILEPLUME, :VICTREEBEL], tier: 4,
                 lose_text: "Oh! I concede defeat. You are remarkably strong. I must confer on you the Rainbow Badge.")
      t.register(key: :kanto_koga, region: :kanto, role: :gym, tr_type: :KANTOLEADER_Koga, name: "Koga",
                 party: "KOFFING:37 MUK:39 KOFFING:37 WEEZING:43:SITRUSBERRY", types: [:POISON], signature: [:WEEZING, :MUK], tier: 5,
                 lose_text: "Humph! You have proven your worth! Here! Take the Soul Badge!")
      t.register(key: :kanto_sabrina, region: :kanto, role: :gym, tr_type: :KANTOLEADER_Sabrina, name: "Sabrina",
                 party: "KADABRA:38 MRMIME:37 VENOMOTH:38 ALAKAZAM:43:SITRUSBERRY", types: [:PSYCHIC], signature: [:ALAKAZAM, :MRMIME], tier: 6,
                 lose_text: "This loss shocks me! But a loss is a loss. I admit I didn't work hard enough to win. You earned the Marsh Badge.")
      t.register(key: :kanto_blaine, region: :kanto, role: :gym, tr_type: :KANTOLEADER_Blaine, name: "Blaine",
                 party: "GROWLITHE:42 PONYTA:40 RAPIDASH:42 ARCANINE:47:SITRUSBERRY", types: [:FIRE], signature: [:ARCANINE, :RAPIDASH], tier: 7,
                 lose_text: "I have burned down to nothing! Not even ashes remain! You have earned the Volcano Badge.")
      t.register(key: :kanto_giovanni, region: :kanto, role: :gym, tr_type: :LEADER_Giovanni, name: "Giovanni",
                 party: "RHYHORN:45 DUGTRIO:42 NIDOQUEEN:44 NIDOKING:45 RHYDON:50:SITRUSBERRY", types: [:GROUND], signature: [:RHYDON, :NIDOKING], tier: 8,
                 lose_text: "Ha! That was a truly intense fight. You have won! As proof, here is the Earth Badge!")
      # Team Rocket
      t.register(key: :kanto_giovanni_hideout, region: :kanto, role: :boss, tr_type: :ROCKETBOSS, name: "Giovanni",
                 party: "ONIX:25 RHYHORN:24 KANGASKHAN:29", types: [:GROUND, :NORMAL], signature: [:KANGASKHAN, :RHYDON], tier: 4,
                 lose_text: "What? This can't be! I see that you raise Pokémon with utmost care.")
      t.register(key: :kanto_giovanni_silph, region: :kanto, role: :boss, tr_type: :ROCKETBOSS, name: "Giovanni",
                 party: "NIDORINO:37 KANGASKHAN:35 RHYHORN:37 NIDOQUEEN:41", types: [:GROUND, :NORMAL], signature: [:NIDOQUEEN, :KANGASKHAN], tier: 6,
                 lose_text: "Arrgh! I lost again!? Blast it all! You ruined our plans for Silph!")
      # Rival
      t.register(key: :kanto_rival_cerulean, region: :kanto, role: :rival, tr_type: :KANTORIVAL1,
                 party: "PIDGEOTTO:17 ABRA:16 RATTATA:15 STARTER:18", rival_starter: true, signature: [:PIDGEOT], tier: 2, size: 4,
                 lose_text: "Hey! Take it easy! You won already!")
      t.register(key: :kanto_rival_ssanne, region: :kanto, role: :rival, tr_type: :KANTORIVAL1,
                 party: "PIDGEOTTO:19 RATICATE:16 KADABRA:18 STARTER:20", rival_starter: true, signature: [:PIDGEOT], tier: 3, size: 4,
                 lose_text: "Humph! At least you're raising your Pokémon!")
      t.register(key: :kanto_rival_tower, region: :kanto, role: :rival, tr_type: :KANTORIVAL1,
                 party: "PIDGEOTTO:25 GROWLITHE:23 EXEGGCUTE:22 KADABRA:20 STARTER:25", rival_starter: true, signature: [:PIDGEOT], tier: 4, size: 5,
                 lose_text: "What? You stinker! I took it easy on you, too!")
      t.register(key: :kanto_rival_silph, region: :kanto, role: :rival, tr_type: :KANTORIVAL2,
                 party: "PIDGEOT:37 GROWLITHE:38 EXEGGCUTE:35 ALAKAZAM:35 STARTER:40", rival_starter: true, signature: [:PIDGEOT], tier: 6, size: 5,
                 lose_text: "Arrgh! You're still better than me!")
      t.register(key: :kanto_rival_route22, region: :kanto, role: :rival, tr_type: :KANTORIVAL2,
                 party: "PIDGEOT:47 RHYHORN:45 GROWLITHE:45 EXEGGCUTE:45 ALAKAZAM:47 STARTER:53", rival_starter: true, signature: [:PIDGEOT], tier: 8, size: 6,
                 lose_text: "What!? I was just careless!")
      # Elite Four and Champion
      t.register(key: :kanto_lorelei, region: :kanto, role: :e4, tr_type: :KANTOELITEFOUR_Lorelei, name: "Lorelei",
                 party: "DEWGONG:52 CLOYSTER:51 SLOWBRO:52 JYNX:54 LAPRAS:54:SITRUSBERRY", types: [:ICE], signature: [:LAPRAS, :CLOYSTER], tier: 9,
                 lose_text: "You're better than I thought!")
      t.register(key: :kanto_bruno, region: :kanto, role: :e4, tr_type: :KANTOELITEFOUR_Bruno, name: "Bruno",
                 party: "ONIX:51 HITMONCHAN:53 HITMONLEE:53 ONIX:54 MACHAMP:56:SITRUSBERRY", types: [:FIGHTING], signature: [:MACHAMP, :HITMONLEE], tier: 9,
                 lose_text: "Why? How could I lose?")
      t.register(key: :kanto_agatha, region: :kanto, role: :e4, tr_type: :KANTOELITEFOUR_Agatha, name: "Agatha",
                 party: "GENGAR:54 GOLBAT:54 HAUNTER:53 ARBOK:56 GENGAR:58:SITRUSBERRY", types: [:GHOST], signature: [:GENGAR], tier: 9,
                 lose_text: "Oh, my! You're something special, child!")
      t.register(key: :kanto_lance, region: :kanto, role: :e4, tr_type: :ELITEFOUR_Lance, name: "Lance",
                 party: "GYARADOS:56 DRAGONAIR:54 DRAGONAIR:54 AERODACTYL:58 DRAGONITE:60:SITRUSBERRY", types: [:DRAGON], signature: [:DRAGONITE, :GYARADOS], tier: 9,
                 lose_text: "That's it! I hate to admit it, but you are a Pokémon master!")
      t.register(key: :kanto_champion, region: :kanto, role: :champion, tr_type: :KANTORIVAL2,
                 party: "PIDGEOT:59 ALAKAZAM:57 RHYDON:59 GYARADOS:59 EXEGGUTOR:61 STARTER:63:SITRUSBERRY", rival_starter: true,
                 signature: [:PIDGEOT, :ALAKAZAM], tier: 10,
                 lose_text: "NO! That can't be! You beat my best!")
      FullPoke::Circuit.define(:kanto, {
        stages: [
          { town: "Pewter City", leader: :kanto_brock_pbs, badge: "Boulder Badge" },
          { town: "Cerulean City", leader: :kanto_misty, badge: "Cascade Badge" },
          { town: "Vermilion City", leader: :kanto_surge, badge: "Thunder Badge" },
          { town: "Celadon City", leader: :kanto_erika, badge: "Rainbow Badge" },
          { town: "Fuchsia City", leader: :kanto_koga, badge: "Soul Badge" },
          { town: "Saffron City", leader: :kanto_sabrina, badge: "Marsh Badge" },
          { town: "Cinnabar Island", leader: :kanto_blaine, badge: "Volcano Badge" },
          { town: "Viridian City", leader: :kanto_giovanni, badge: "Earth Badge" }
        ],
        rivals: {},
        league: [:kanto_lorelei, :kanto_bruno, :kanto_agatha, :kanto_lance],
        champion: :kanto_champion,
        legendary: [:MEWTWO, 70]
      })
    end
  end
end

FullPoke::Data.kanto

# Players who start elsewhere and walk into Pallet Town from the forest still
# get the Kanto opening: Oak stops them at the tall grass and takes them to his
# lab (switch 61, normally set by the intro).
EventHandlers.add(:on_fullpoke_region_begun, :kanto_opening,
  proc { |region_id, _mode|
    next if region_id != :kanto || !$game_switches
    $game_switches[61] = true if !$game_switches[65]
  }
)

# Oak's starter is recorded as the Kanto starter (the rival's ace depends on it).
EventHandlers.add(:on_end_battle, :kanto_starter_record,
  proc { |_outcome, _can_lose|
    next if !$fullpoke || FullPoke.state(:kanto).starter || !$game_switches[65]
    sp = [[40, :BULBASAUR], [41, :CHARMANDER], [42, :SQUIRTLE]].find { |sw, _| $game_switches[sw] }
    FullPoke.state(:kanto).starter = sp[1] if sp
  }
)
