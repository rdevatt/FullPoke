#===============================================================================
# Kanto's story after Brock, following FireRed/LeafGreen in a compact form.
# The events (built by tools/headless/kanto_story.rb) call these helpers; each
# returns true once its step is done so the event can switch itself off.
#
#   Bill (Route 25)              S.S. Ticket
#   S.S. Anne (Vermilion)        rival, Captain -> HM01 Cut; the ship then sails
#   Rocket Hideout (Celadon)     Giovanni -> Silph Scope
#   Pokémon Tower (Lavender)     rival, the ghost Marowak (needs the Silph Scope),
#                                Rockets, Mr. Fuji -> Poké Flute
#   Snorlax (Routes 12 and 16)   wake it with the Poké Flute
#   Saffron's gates              open once the player has 4 Kanto Badges
#   Silph Co. (Saffron)          rival, Lapras, Giovanni -> Master Ball; Sabrina's
#                                Gym opens afterwards
#   Viridian Gym                 opens with 7 Badges
#   HMs                          Cut (Captain), Flash (Oak's aide, Route 2),
#                                Fly (Route 16), Surf and Strength (Safari Zone)
# Story progress is kept as Kanto's FullPoke flags.
#===============================================================================
module FullPoke
  module KantoStory
    module_function

    def flag?(f) = FullPoke.flag?(:kanto, f)
    def set(f) = FullPoke.set_flag(:kanto, f)
    def badges = FullPoke.region_badge_count(:kanto)

    # Gives an item once, with a few lines of dialogue first.
    def give_once(flag, item, lines, after = nil)
      if flag?(flag)
        pbMessage(_INTL(after)) if after
        return true
      end
      lines.each { |l| pbMessage(_INTL(l)) }
      pbReceiveItem(item)
      set(flag)
      return true
    end

    def bill
      give_once(:got_ssticket, :SSTICKET,
                ["Hiya! I'm Bill, the Pokémon Maniac. Thanks for dropping by!",
                 "The S.S. Anne is in Vermilion City. Its passengers are all Trainers. Here, take my ticket and go to the party!"],
                "Have fun on the S.S. Anne!")
    end

    # Harbor sailor: true lets the player board.
    def board_ss_anne?
      if flag?(:ss_anne_sailed)
        pbMessage(_INTL("The S.S. Anne has set sail. She'll be back in Vermilion next year."))
        return false
      end
      if !$bag.has?(:SSTICKET)
        pbMessage(_INTL("Welcome to Vermilion Harbor. You need an S.S. Ticket to board the S.S. Anne."))
        return false
      end
      pbMessage(_INTL("Welcome aboard the S.S. Anne! May I see your ticket? ...Thank you!"))
      return true
    end

    def captain
      return give_once(:got_hm01, :HM01,
                       ["Ooargh... I feel hideous... Urrp! Seasick...",
                        "...Whew! Thank you for rubbing my back! As thanks, take this Hidden Machine.",
                        "It teaches Cut. With the Cascade Badge your Pokémon can use it outside of battle to cut down small trees."],
                       "I must thank you again. Fair winds to you!")
    end

    # Leaving the ship after the Captain: it sails away.
    def leave_ss_anne
      set(:ss_anne_sailed) if flag?(:got_hm01)
      return true
    end

    # The poster in the Game Corner hides the switch to the Rocket Hideout.
    def poster
      if !FullPoke.flag?(:kanto, :beat_kanto_rocket_gamecorner)
        pbMessage(_INTL("Hey! Get away from that poster!"))
        return false
      end
      pbMessage(_INTL("Behind the poster is a switch! A hidden staircase opened!")) if !flag?(:poster_found)
      set(:poster_found)
      return true
    end

    def giovanni_hideout
      return true if flag?(:hideout_done)
      return false if !FullPoke::Circuit.extra_battle(:kanto, :kanto_giovanni_hideout)
      pbMessage(_INTL("Giovanni: I see you raise Pokémon with utmost care. A child like you would never understand what I hope to achieve."))
      pbMessage(_INTL("I shall step aside this time. Take this - it is no use to me now."))
      pbReceiveItem(:SILPHSCOPE)
      set(:hideout_done)
      return true
    end

    # The ghost blocking the top of the Pokémon Tower.
    def ghost_marowak
      return true if flag?(:ghost_calmed)
      if !$bag.has?(:SILPHSCOPE)
        pbMessage(_INTL("Be gone... Intruders..."))
        pbMessage(_INTL("A ghost blocks the way! It can't be identified without a Silph Scope."))
        return false
      end
      pbMessage(_INTL("The Silph Scope unveiled the ghost's identity! It's the restless spirit of a Marowak!"))
      setBattleRule("cannotRun")
      setBattleRule("disablePokeBalls")
      return false if !WildBattle.start(:MAROWAK, 30)
      pbMessage(_INTL("The ghost was the restless soul of Cubone's mother. Its spirit was calmed and departed to the afterlife."))
      set(:ghost_calmed)
      return true
    end

    def fuji
      if !(1..3).all? { |i| FullPoke.flag?(:kanto, :"beat_kanto_rocket_tower#{i}") }
        pbMessage(_INTL("Mr. Fuji: Please... help me. Team Rocket won't let me go."))
        return false
      end
      return give_once(:got_pokeflute, :POKEFLUTE,
                       ["Mr. Fuji: Heh? You came to save me? Thank you. The Rockets came to kill Pokémon for their bones.",
                        "Please take this Poké Flute. Its tune awakens sleeping Pokémon - even the Snorlax blocking the roads."],
                       "Mr. Fuji: Please take good care of your Pokémon.")
    end

    # A sleeping Snorlax: true once it's gone.
    def snorlax(where)
      flag = :"snorlax_#{where}"
      return true if flag?(flag)
      pbMessage(_INTL("A sleeping Pokémon blocks the way!"))
      if !$bag.has?(:POKEFLUTE)
        pbMessage(_INTL("It's fast asleep. Maybe a special tune would wake it..."))
        return false
      end
      return false if !pbConfirmMessage(_INTL("Would you like to use the Poké Flute?"))
      pbMessage(_INTL("\\PN played the Poké Flute. Snorlax woke up! It attacked in a grumpy rage!"))
      return false if !WildBattle.start(:SNORLAX, 30)
      pbMessage(_INTL("Snorlax calmed down. With a big yawn, it returned to the mountains!"))
      set(flag)
      return true
    end

    def saffron_open?
      return true if badges >= 4
      pbMessage(_INTL("Guard: I'm on guard duty. Saffron City is closed to Trainers without four Kanto Badges."))
      return false
    end

    def lapras
      if flag?(:got_lapras)
        pbMessage(_INTL("Lapras is a gentle Pokémon. Take care of it!"))
        return true
      end
      if !FullPoke.flag?(:kanto, :beat_kanto_rival_silph)
        pbMessage(_INTL("Silph employee: Team Rocket took over the building! Please, help us!"))
        return false
      end
      pbMessage(_INTL("Silph employee: Thank you for chasing them off! Please take this Pokémon as thanks."))
      return false if !pbAddPokemon(:LAPRAS, FullPoke.scale_level(25, :kanto))
      set(:got_lapras)
      return true
    end

    def giovanni_silph
      return true if flag?(:silph_done)
      return false if !FullPoke::Circuit.extra_battle(:kanto, :kanto_giovanni_silph)
      pbMessage(_INTL("Giovanni: Arrgh! I lost again!? Blast it all! You ruined our plans for Silph!"))
      pbMessage(_INTL("But Team Rocket will never fall! ... I'm leaving."))
      set(:silph_done)
      return true
    end

    def president
      if !flag?(:silph_done)
        pbMessage(_INTL("President: Team Rocket is after our Master Ball... Please, stop Giovanni!"))
        return false
      end
      return give_once(:got_masterball, :MASTERBALL,
                       ["President: Thank you for saving Silph. Please accept this Master Ball. It catches any Pokémon without fail."],
                       "President: Silph Co. will never forget your help.")
    end

    # Gym requirements beyond walking in.
    def gym_open?(n)
      case n
      when 6
        return true if flag?(:silph_done)
        pbMessage(_INTL("Sabrina: Team Rocket has taken over Silph Co. I can't accept challenges until the city is free."))
        return false
      when 8
        return true if badges >= 7
        pbMessage(_INTL("The Viridian Gym Leader is away. Come back with seven Kanto Badges."))
        return false
      end
      return true
    end

    # Route 22 -> 23 gate: the League checks all eight Badges.
    def league_gate?
      return true if badges >= 8
      pbMessage(_INTL("Only Trainers with all eight Kanto Badges may pass to Victory Road and the Pokémon League."))
      return false
    end
  end
end
