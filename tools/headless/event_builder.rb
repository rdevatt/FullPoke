# Small DSL over the v21 Compiler's push_* helpers for writing event command lists
# with correct RMXP indentation (runs inside the headless harness).
class EventList
  attr_reader :list
  def initialize; @list = []; @i = 0; end
  def self.build(&b) = new.tap { |e| e.instance_eval(&b) }.finish
  def finish; Compiler.push_end(@list); @list; end
  def text(t) = Compiler.push_text(@list, t, @i)
  def script(s) = Compiler.push_script(@list, s, @i)
  def wait(n) = Compiler.push_wait(@list, n, @i)
  def comment(c) = Compiler.push_comment(@list, c, @i)
  def cmd(code, params) = Compiler.push_event(@list, code, params, @i)
  def switch(id, on) = cmd(121, [id, id, on ? 0 : 1])
  def self_switch(ch, on) = Compiler.push_self_switch(@list, ch, on, @i)
  def exit_event = Compiler.push_exit(@list, @i)
  def erase = cmd(116, [])
  def tone(r, g, b, gray, frames) = cmd(223, [Tone.new(r, g, b, gray), frames])
  def fade_out(frames = 10) = (tone(-255, -255, -255, 0, frames); wait(frames))
  def fade_in(frames = 10) = (tone(0, 0, 0, 0, frames); wait(frames))
  def play_me(name) = cmd(249, [RPG::AudioFile.new(name, 100, 100)])
  def play_se(name) = cmd(250, [RPG::AudioFile.new(name, 80, 100)])
  def transfer(map, x, y, dir, fade = 1) = cmd(201, [0, map, x, y, dir, fade])
  def recover_all = cmd(314, [0])
  # character: -1 player, 0 this event, n event id
  def move(character, route, wait_for: true)
    if wait_for then Compiler.push_move_route_and_wait(@list, character, route, @i)
    else Compiler.push_move_route(@list, character, route, @i) end
  end
  def wait_moves = cmd(210, [])
  # if_script("cond") { then } .else { otherwise }
  # The condition is made strictly true/false: RPG Maker's script branches skip
  # both the "then" and the "else" part when the script returns nil.
  def if_script(cond, otherwise: nil, &then_block)
    cond = "(#{cond}) ? true : false" unless cond.end_with?('? true : false')
    Compiler.push_branch(@list, cond, @i)
    @i += 1
    instance_eval(&then_block)
    if otherwise
      Compiler.push_else(@list, @i)
      instance_eval(&otherwise)
    end
    Compiler.push_branch_end(@list, @i)
    @i -= 1
  end
  # choices(["Yes","No"], cancel: 2) { |idx| ...per-choice block... }
  def choices(opts, cancel: 0, &blk)
    Compiler.push_choices(@list, opts, cancel, @i)
    @i += 1
    opts.each_with_index do |o, idx|
      Compiler.push_choice(@list, idx, o, @i)
      instance_exec(idx, &blk)
    end
    Compiler.push_choices_end(@list, @i)
    @i -= 1
  end
end

# Pages without commands default to Player Touch: an empty Action Button page under
# the player still counts as "triggered" in v21 and would swallow the Use button.
def new_page(trigger: nil, graphic: '', direction: 2, switch1: nil, switch2: nil, self_switch: nil, through: false,
             move_type: 0, step_anime: false, direction_fix: false, list: nil)
  pg = RPG::Event::Page.new
  pg.trigger = trigger || (list ? 0 : 1)
  pg.graphic.character_name = graphic
  pg.graphic.direction = direction
  pg.through = through
  pg.move_type = move_type
  pg.step_anime = step_anime
  pg.direction_fix = direction_fix
  if switch1 then pg.condition.switch1_valid = true; pg.condition.switch1_id = switch1 end
  if switch2 then pg.condition.switch2_valid = true; pg.condition.switch2_id = switch2 end
  if self_switch then pg.condition.self_switch_valid = true; pg.condition.self_switch_ch = self_switch end
  pg.list = list || EventList.build {}
  pg
end

def new_event(map, name, x, y, pages)
  id = (map.events.keys.max || 0) + 1
  ev = RPG::Event.new(x, y)
  ev.id = id; ev.name = name; ev.pages = pages
  map.events[id] = ev
  ev
end
