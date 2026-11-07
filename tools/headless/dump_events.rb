# Prints a readable listing of event commands for the given map IDs.
require_relative 'rpg_classes'
def load_rx(p) = File.open(p, 'rb') { |f| Marshal.load(f) }
dir = ARGV.shift
NAMES = { 101 => 'Text', 401 => '  +', 102 => 'Choices', 402 => 'When', 403 => 'WhenCancel', 404 => 'EndChoice',
  103 => 'InputNum', 104 => 'TextOpts', 105 => 'ButtonInput', 106 => 'Wait', 108 => 'Comment', 408 => '  #',
  111 => 'If', 411 => 'Else', 412 => 'EndIf', 112 => 'Loop', 413 => 'EndLoop', 113 => 'Break', 115 => 'Exit',
  116 => 'Erase', 117 => 'CallCommon', 118 => 'Label', 119 => 'Jump', 121 => 'Switch', 122 => 'Var', 123 => 'SelfSw',
  124 => 'Timer', 125 => 'Gold', 126 => 'Items', 129 => 'Party', 132 => 'BattleBGM', 133 => 'BattleME', 134 => 'SaveAccess',
  201 => 'Transfer', 202 => 'SetEventLoc', 203 => 'Scroll', 204 => 'MapSettings', 205 => 'Fog', 206 => 'FogOp',
  207 => 'Anim', 208 => 'Transparent', 209 => 'MoveRoute', 509 => '  route', 210 => 'WaitMove', 221 => 'PrepTrans',
  222 => 'ExecTrans', 223 => 'Tone', 224 => 'Flash', 225 => 'Shake', 231 => 'ShowPic', 232 => 'MovePic', 235 => 'ErasePic',
  241 => 'PlayBGM', 242 => 'FadeBGM', 245 => 'PlayBGS', 249 => 'PlayME', 250 => 'PlaySE', 251 => 'StopSE', 301 => 'Battle',
  302 => 'Shop', 303 => 'NameInput', 314 => 'RecoverAll', 340 => 'Abort', 351 => 'Menu', 353 => 'GameOver', 354 => 'Title',
  355 => 'Script', 655 => '  >', 0 => 'End' }
dir_names = { 2 => 'D', 4 => 'L', 6 => 'R', 8 => 'U' }
ARGV.map(&:to_i).each do |mid|
  m = load_rx(format('%s/Map%03d.rxdata', dir, mid))
  puts "=== Map #{mid} (#{m.width}x#{m.height}, tileset #{m.tileset_id}) ==="
  m.events.keys.sort.each do |eid|
    ev = m.events[eid]
    puts "-- Event #{eid} '#{ev.name}' @(#{ev.x},#{ev.y})"
    ev.pages.each_with_index do |pg, pi|
      c = pg.condition
      conds = []
      conds << "sw#{c.switch1_id}" if c.switch1_valid
      conds << "sw#{c.switch2_id}" if c.switch2_valid
      conds << "var#{c.variable_id}>=#{c.variable_value}" if c.variable_valid
      conds << "self#{c.self_switch_ch}" if c.self_switch_valid
      puts "  Page #{pi + 1} trig=#{pg.trigger} gfx='#{pg.graphic.character_name}' tile=#{pg.graphic.tile_id} dir=#{pg.graphic.direction} cond=[#{conds.join(',')}] through=#{pg.through}"
      pg.list.each do |cmd|
        next if cmd.code == 0 && cmd.indent == 0
        nm = NAMES[cmd.code] || cmd.code.to_s
        params = cmd.parameters.map { |x| x.is_a?(RPG::MoveRoute) ? "route[#{x.list.map(&:code).join(',')}]" : x.is_a?(RPG::AudioFile) ? "audio(#{x.name})" : x.inspect }
        puts "    #{'  ' * cmd.indent}#{nm} #{params.join(', ')}"
      end
    end
  end
end
