# Builds the Kanto opening: intro fixes -> Oak stops the player in Pallet Town ->
# Oak's Lab (starter choice, rival battle) -> Oak's Parcel delivery (Pokédex).
# Idempotent: events it creates are named "FP: ..." and rebuilt on each run.
require_relative 'event_builder'

SW = {
  chose_bulbasaur: 40, chose_charmander: 41, chose_squirtle: 42,   # read by the Route 22 rival battle
  carrying_parcel: 38, parcel_errand: 44,                          # read by the Viridian Mart clerk
  oak_stops_player: 61, oak_in_pallet: 62, lab_scene: 63, choosing_starter: 64,
  has_starter: 65, rival_lab_done: 66, has_pokedex: 68
}
SW_NAMES = {
  38 => 'Kanto: Carrying Oak\'s Parcel', 40 => 'Kanto: Chose Bulbasaur', 41 => 'Kanto: Chose Charmander',
  42 => 'Kanto: Chose Squirtle', 44 => 'Kanto: Parcel errand (Mart clerk)', 61 => 'Kanto: Oak stops player',
  62 => 'Kanto: Oak walking in Pallet', 63 => 'Kanto: Oak\'s Lab scene', 64 => 'Kanto: Choosing starter',
  65 => 'Kanto: Has starter', 66 => 'Kanto: Rival lab battle done', 68 => 'Kanto: Has Pokédex'
}
RIVAL_VAR = 27
LAB = 175; PALLET = 23

def map_path(id) = sprintf("Data/Map%03d.rxdata", id)
def edit_map(id)
  m = load_data(map_path(id)); yield m; save_data(m, map_path(id))
end

#--- System: name the story switches -----------------------------------------
sys = load_data("Data/System.rxdata")
SW_NAMES.each { |id, name| sys.switches[id] = name }
sys.variables[RIVAL_VAR] = 'Kanto: Rival name'
save_data(sys, "Data/System.rxdata")

#--- Map 1: intro fixes ------------------------------------------------------
edit_map(1) do |m|
  ev = m.events.values.find { |e| e.name.start_with?('INTRO') }
  list = ev.pages[0].list
  branch = nil
  list.each do |c|
    case c.code
    when 402 then branch = c.parameters[1]
    when 241 then c.parameters[0].name = 'New Start' if c.parameters[0].name == 'begin'
    when 231
      c.parameters[1] = { 'Oak' => 'introOak', 'Pikachul' => 'introMarill' }.fetch(c.parameters[1], c.parameters[1])
    when 355
      # pbChangePlayer counts player characters from 1 in v21 (metadata [1] boy, [2] girl).
      if c.parameters[0] =~ /^pbChangePlayer\(\d\)$/
        c.parameters[0] = "pbChangePlayer(#{branch == 'GIRL' ? 2 : 1})"
      end
    end
  end
  # There's no rival portrait; drop that picture.
  list.reject! { |c| c.code == 231 && c.parameters[1] == 'Rival' }
  # pbGetPlayerGraphic returns a trainer sprite path, not a Pictures/ name: show the intro portraits.
  i = list.index { |c| c.code == 355 && c.parameters[0].start_with?('pbShowPicture(2,pbGetPlayerGraphic') }
  if i
    list.delete_at(i + 1) while list[i + 1]&.code == 655
    list[i].parameters[0] = 'pbShowPicture(2, ($player.character_ID == 2 ? "introGirl" : "introBoy"), 1, 230, 160)'
  end
  # Old tail flags (Switch 2 off / script switch 28 on) -> start the Kanto story.
  t = list.index { |c| c.code == 121 && c.parameters[0] == 2 }
  list[t].parameters.replace([SW[:oak_stops_player], SW[:oak_stops_player], 0]) if t
  list.reject! { |c| c.code == 121 && c.parameters[0] == 28 }
end

#--- Map 23: Pallet Town -- Oak stops the player ------------------------------
edit_map(PALLET) do |m|
  oak = m.events.values.find { |e| e.name == 'Intro Oak' }
  oak.pages[1].condition.switch1_id = SW[:oak_in_pallet]
  oak.pages[1].through = true
  [m.events.values.find { |e| e.name == 'First Oak Meet (1)' }, m.events.values.find { |e| e.name == 'First Oak Meet (2)' }].each do |stop|
    col = stop.x                          # 19 or 20
    pg = stop.pages[0]
    pg.condition.switch1_id = SW[:oak_stops_player]
    pg.trigger = 1                        # player touch
    pg.list = EventList.build do
      wait 5
      text "\\bWait! Don't go out!"
      switch SW[:oak_in_pallet], true
      wait 5
      # Oak walks from in front of his lab up to the player (through-mode so he can't get stuck).
      move oak.id, [PBMoveRoute::THROUGH_ON, PBMoveRoute::LEFT, PBMoveRoute::UP, PBMoveRoute::UP, PBMoveRoute::UP,
                    PBMoveRoute::UP, PBMoveRoute::RIGHT] + (col == 20 ? [PBMoveRoute::RIGHT] : []) +
                   [PBMoveRoute::UP, PBMoveRoute::UP, PBMoveRoute::UP, PBMoveRoute::UP, PBMoveRoute::THROUGH_OFF]
      move(-1, [PBMoveRoute::TURN_DOWN])
      text "\\bOAK: It's unsafe! Wild Pokémon live in tall grass!"
      text "\\bYou need your own Pokémon for your protection."
      text "\\bI know! Come with me to my Lab!"
      fade_out 20
      switch SW[:oak_in_pallet], false
      switch SW[:lab_scene], true
      transfer LAB, 16, 12, 8, 1
      fade_in 20
    end
  end
end

#--- Map 175: Oak's Lab ------------------------------------------------------
BALLS = [
  [:BULBASAUR,  'Grass',  15, SW[:chose_bulbasaur],  :CHARMANDER, 2, 16],
  [:CHARMANDER, 'Fire',   16, SW[:chose_charmander], :SQUIRTLE,   3, 17],
  [:SQUIRTLE,   'Water',  17, SW[:chose_squirtle],   :BULBASAUR,  1, 15]
]
edit_map(LAB) do |m|
  m.events.delete_if { |_, e| e.name.start_with?('FP:') }
  oak = new_event(m, 'FP: Prof. Oak', 16, 9, [])
  rival = new_event(m, 'FP: Rival', 14, 10, [])
  balls = BALLS.map { |sp, _, x, *| new_event(m, "FP: #{sp.to_s.capitalize} ball", x, 10, []) }
  ball_ids = balls.map(&:id)
  scene = new_event(m, 'FP: Lab scene', 8, 17, [])

  # Oak: absent until the lab scene, then guides the player through the opening.
  oak.pages = [
    new_page,
    new_page(graphic: 'trainer_PROFESSOR', switch1: SW[:choosing_starter], list: EventList.build {
      text "\\bOAK: Go on, \\PN. Choose one of the three Pokémon on the table!"
    }),
    new_page(graphic: 'trainer_PROFESSOR', switch1: SW[:has_starter], list: EventList.build {
      if_script("$bag.has?(:OAKSPACKAGE)", otherwise: proc {
        if_script("$player.has_pokedex", otherwise: proc {
          text "\\bOAK: The Poké Mart in Viridian City should have a parcel for me."
          text "\\bCould you pick it up on your way? Viridian is north of here, past Route 1."
        }) do
          text "\\bOAK: How is your Pokédex coming along? Try to meet every kind of Pokémon!"
        end
      }) do
        text "\\bOAK: Oh, \\PN! That's my custom Poké Ball order from the Viridian Mart. Thank you!"
        script "$bag.remove(:OAKSPACKAGE)"
        switch SW[:carrying_parcel], false
        switch SW[:parcel_errand], false
        text "\\bOAK: In return, take this. It's the Pokédex, a high-tech encyclopedia!"
        script "$player.has_pokedex = true"
        play_me 'Key item get'
        text "\\PN received the Pokédex!\\wtnp[30]"
        switch SW[:has_pokedex], true
        text "\\bOAK: You can't record Pokémon without catching them, so take these too."
        script "pbReceiveItem(:POKEBALL, 5)"
        text "\\bOAK: Completing the Pokédex is my dream. Go out and see the world, \\PN!"
      end
    })
  ]
  # Rival: waits in the lab while the player chooses, leaves after the battle.
  rival.pages = [
    new_page,
    new_page(graphic: 'trainer_KANTORIVAL1', switch1: SW[:choosing_starter], list: EventList.build {
      text "\\v[#{RIVAL_VAR}]: Hurry up and choose, \\PN! Gramps said I get to pick after you."
    }),
    new_page(switch1: SW[:rival_lab_done])
  ]
  # Starter balls.
  balls.each_with_index do |ball, i|
    sp, type, _x, chose_sw, rival_sp, rival_ver, _rx = BALLS[i]
    rival_ball = ball_ids[BALLS.index { |b| b[0] == rival_sp }]
    name = GameData::Species.get(sp).name
    rival_name = GameData::Species.get(rival_sp).name
    ball.pages = [
      new_page(graphic: 'Object ball', list: EventList.build {
        text "It's a Poké Ball. There's a Pokémon inside."
      }),
      new_page(graphic: 'Object ball', switch1: SW[:choosing_starter], list: EventList.build {
        script "pbShowPicture(1, \"Picture_#{sp}\", 1, 256, 140) rescue nil" if false
        text "\\bOAK: So you want #{name}, the #{type}-type Pokémon?"
        choices(['Yes', 'No'], cancel: 2) do |idx|
          if idx == 0
            if_script("pbAddPokemon(:#{sp}, 5)") do
              self_switch 'A', true
              switch chose_sw, true
              switch SW[:choosing_starter], false
              switch SW[:has_starter], true
              switch SW[:oak_stops_player], false
              text "\\v[#{RIVAL_VAR}]: Then I'll take this one!"
              script "pbSetSelfSwitch(#{rival_ball}, \"A\", true)"
              text "\\v[#{RIVAL_VAR}] received #{rival_name}!"
              text "\\v[#{RIVAL_VAR}]: Wait, \\PN! Let's check out our Pokémon! Come on, I'll take you on!"
              script "setBattleRule(\"canLose\")"
              if_script("TrainerBattle.start(:KANTORIVAL1, \"RIVAL\", #{rival_ver})", otherwise: proc {
                text "\\v[#{RIVAL_VAR}]: Yeah! Am I great or what?"
              }) do
                text "\\v[#{RIVAL_VAR}]: What? Unbelievable! I picked the wrong Pokémon!"
              end
              recover_all
              text "\\v[#{RIVAL_VAR}]: Okay! I'll make my Pokémon fight to toughen it up!"
              text "\\v[#{RIVAL_VAR}]: \\PN! Gramps! Smell ya later!"
              fade_out 10
              switch SW[:rival_lab_done], true
              switch SW[:parcel_errand], true
              fade_in 10
              text "\\bOAK: \\PN, raise your Pokémon well. Viridian City is just north of Route 1."
            end
          end
        end
      }),
      new_page(self_switch: 'A')
    ]
  end
  # The scene that plays when Oak brings the player in.
  scene.pages = [
    new_page,
    new_page(trigger: 3, switch1: SW[:lab_scene], list: EventList.build {
      text "\\v[#{RIVAL_VAR}]: Gramps! I'm fed up with waiting!"
      text "\\bOAK: \\v[#{RIVAL_VAR}]? Let me think... Oh, that's right, I told you to come! Just wait!"
      text "\\bOAK: Here, \\PN. There are three Pokémon here. Haha!"
      text "\\bThey are inside the Poké Balls. When I was young, I was a serious Pokémon Trainer."
      text "\\bIn my old age, I have only three left, but you can have one. Choose!"
      text "\\v[#{RIVAL_VAR}]: Hey! Gramps! What about me?"
      text "\\bOAK: Be patient! \\v[#{RIVAL_VAR}], you can have one, too!"
      switch SW[:lab_scene], false
      switch SW[:choosing_starter], true
    })
  ]
end
puts "Kanto opening built."
