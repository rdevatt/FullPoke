# Loads every map the way the game does and reports anything that would crash or
# misbehave: missing graphics, bad transfers, undefined trainers/items/species.
GameData.load_all
problems = Hash.new { |h, k| h[k] = [] }
infos = pbLoadMapInfos
sizes = {}
infos.keys.each { |id| m = load_data(sprintf("Data/Map%03d.rxdata", id)); sizes[id] = [m.width, m.height] }
$game_system   = Game_System.new
$PokemonSystem = PokemonSystem.new
$game_temp     = Game_Temp.new
$game_switches = Game_Switches.new
$game_variables = Game_Variables.new
$game_self_switches = Game_SelfSwitches.new
$game_screen = Game_Screen.new
$PokemonGlobal = PokemonGlobalMetadata.new
$player = Player.new("Tester", GameData::TrainerType.keys.first)
$data_tilesets = load_data("Data/Tilesets.rxdata")
$data_common_events = load_data("Data/CommonEvents.rxdata")
$data_system = load_data("Data/System.rxdata")
$game_player = Game_Player.new
check_script = lambda do |where, s|
  s.scan(/TrainerBattle\.start\(\s*:(\w+)\s*,\s*"([^"]*)"\s*(?:,\s*(\d+))?/) do |t, n, v|
    problems["undefined trainer #{t},#{n},#{v.to_i}"] << where unless GameData::Trainer.exists?(t.to_sym, n, v.to_i)
  end
  s.scan(/(?:pbReceiveItem|pbItemBall|\$bag\.add|\$bag\.has\?|\$bag\.remove)\(\s*:(\w+)/) do |(it)|
    problems["undefined item #{it}"] << where unless GameData::Item.exists?(it.to_sym)
  end
  s.scan(/pbPokemonMart\(\s*\[(.*?)\]/m) do |(list)|
    list.scan(/:(\w+)/) { |(it)| problems["undefined mart item #{it}"] << where unless GameData::Item.exists?(it.to_sym) }
  end
  s.scan(/(?:pbAddPokemon|pbAddToParty|WildBattle\.start)\(\s*:(\w+)/) do |(sp)|
    problems["undefined species #{sp}"] << where unless GameData::Species.exists?(sp.to_sym)
  end
  problems["v18 syntax: #{$&}"] << where if s =~ /PB(Items|Species|Trainers|Moves)::|\$Trainer\b|\$PokemonBag|Kernel\./
  begin
    RubyVM::InstructionSequence.compile(s)
  rescue SyntaxError => e
    problems["script syntax error: #{s.inspect[0, 60]}"] << where
  end
end
infos.keys.sort.each do |id|
  begin
    $game_map = Game_Map.new
    $game_map.setup(id)
    rawmap = load_data(sprintf("Data/Map%03d.rxdata", id))
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    rawmap.events.each_value do |ev|
      ev.pages.each_with_index do |pg, pi|
        where = "map #{id} ev #{ev.id} '#{ev.name}' p#{pi + 1}"
        cn = pg.graphic.character_name
        if !cn.empty? && !pbResolveBitmap("Graphics/Characters/" + cn)
          problems["missing charset Graphics/Characters/#{cn}"] << where
        end
        buf = nil
        flush = lambda { check_script.call(where, buf.join("\n")) if buf; buf = nil }
        pg.list.each do |cmd|
          case cmd.code
          when 355 then flush.call; buf = [cmd.parameters[0].to_s]
          when 655 then buf << cmd.parameters[0].to_s if buf
          else
            flush.call
            case cmd.code
            when 111 then check_script.call(where, cmd.parameters[1].to_s) if cmd.parameters[0] == 12
            when 201
              if cmd.parameters[0] == 0
                tm, tx, ty = cmd.parameters[1], cmd.parameters[2], cmd.parameters[3]
                if !sizes[tm] then problems["transfer to missing map #{tm}"] << where
                elsif tx >= sizes[tm][0] || ty >= sizes[tm][1] then problems["transfer out of bounds map #{tm} (#{tx},#{ty})"] << where
                end
              end
            when 231 then problems["missing picture #{cmd.parameters[1]}"] << where if !pbResolveBitmap("Graphics/Pictures/" + cmd.parameters[1].to_s)
            when 241, 249, 132, 133
              a = cmd.parameters[0]
              dir = cmd.code == 249 || cmd.code == 133 ? "ME" : "BGM"
              problems["missing audio #{dir}/#{a.name}"] << where if a && !a.name.empty? && !FileTest.audio_exist?("Audio/#{dir}/#{a.name}")
            end
          end
        end
        flush.call
      end
    end
    # Build every event sprite as Spriteset_Map would (loads charsets via RPG::Cache).
    $game_map.events.each_value do |ev|
      begin
        Sprite_Character.new(viewport, ev).dispose
      rescue Exception => e
        problems["sprite error: #{e.message[0, 90]}"] << "map #{id} ev #{ev.id}"
      end
    end
    # Tileset graphics as the tilemap renderer would request them.
    ts = $data_tilesets[rawmap.tileset_id]
    problems["missing tileset #{ts.tileset_name}"] << "map #{id}" if !pbResolveBitmap("Graphics/Tilesets/" + ts.tileset_name)
    ts.autotile_names.each { |a| problems["missing autotile #{a}"] << "map #{id}" if !a.empty? && !pbResolveBitmap("Graphics/Autotiles/" + a) }
    bgm = rawmap.bgm
    problems["missing map BGM #{bgm.name}"] << "map #{id}" if rawmap.autoplay_bgm && !bgm.name.empty? && !FileTest.audio_exist?("Audio/BGM/" + bgm.name)
  rescue Exception => e
    problems["MAP LOAD ERROR #{e.class}: #{e.message[0, 100]}"] << "map #{id} #{e.backtrace.first(2).join(' | ')}"
  end
end
# Map connections and metadata consistency
MapFactoryHelper.getMapConnections rescue nil
conns = load_data("Data/map_connections.dat")
conns.each do |c|
  [c[0], c[3]].each { |m| problems["connection references missing map #{m}"] << c.inspect if !sizes[m] }
end
GameData::MapMetadata.each do |mm|
  problems["map_metadata for missing map #{mm.id}"] << mm.real_name.to_s if !sizes[mm.id]
  if mm.teleport_destination
    hm, hx, hy = mm.teleport_destination
    problems["HealingSpot to missing map #{hm}"] << "map #{mm.id}" if !sizes[hm]
  end
end
GameData::Encounter.each { |e| problems["encounters for missing map #{e.map}"] << "" if !sizes[e.map] }
problems.sort_by { |k, v| [k.start_with?('missing map BGM') ? 1 : 0, k] }.each do |k, v|
  puts "#{k}  [#{v.size}x] #{v.uniq.first(4).join('; ')}"
end
puts "TOTAL distinct problems: #{problems.size}"
