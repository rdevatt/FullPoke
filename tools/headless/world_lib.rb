# Map-generation helpers for build_world.rb (runs inside the headless harness, so the
# game's Compiler/push_* helpers and RPG classes are available).
#
# Outdoor maps are drawn with tileset 1 (the Kanto outdoor tileset) using Viridian
# Forest's tree pattern and building blocks copied from Pewter City / Pallet Town.
# Interiors are rooms copied from the map pack's Kanto interiors.
require 'json'
require_relative 'event_builder'

module WG
  OUT_TS   = 1
  GROUND   = 384
  GRASS    = 392            # tall grass (terrain tag 2), drawn on layer 1
  TREE_A   = [437, 438, 439]
  TREE_B   = [429, 430, 431]
  CAP_TOP  = [421, 422, 423]
  CAP_BOT1 = [445, 446, 447]
  CAP_BOT2 = [453, 454, 455]
  PATH     = 470            # dirt path centre tile

  # Building blocks: [source map, x, y, w, h, door x, door y] (door relative to block)
  STAMPS = {
    pc:     [25, 18, 31, 5, 5, 2, 4],
    gym:    [25, 15, 21, 7, 5, 3, 4],
    house:  [25, 11, 37, 5, 4, 1, 3],
    house2: [23, 12, 3, 5, 5, 1, 4]
  }
  # Rooms on the map pack's composite interior maps: [map, x, y, w, h]
  ROOMS = {
    pc:  [182, 23, 29, 16, 10],   # Pewter's Pokémon Center (door 30,38; nurse 30,32; PC 34,30)
    gym: [177, 32, 2, 13, 16],    # Pewter Gym (door 38,17; leader 38,7)
    lab: [175, 7, 6, 13, 14]      # Oak's Lab (door 13,19)
  }

  module_function

  def map_path(id) = format('Data/Map%03d.rxdata', id)
  def load_map(id) = load_data(map_path(id))

  @src_cache = {}
  def src_map(id) = (@src_cache[id] ||= load_map(id))

  def new_map(w, h, tileset)
    m = RPG::Map.new(w, h)
    m.tileset_id = tileset
    m.data = Table.new(w, h, 3)
    m.events = {}
    m
  end

  def set_bgm(map, name)
    map.autoplay_bgm = true
    map.bgm = RPG::AudioFile.new(name, 100, 100)
  end

  #-----------------------------------------------------------------------------
  # Map IDs: generated maps reuse the map pack's empty placeholder maps where one
  # exists for the place, otherwise the lowest free IDs (RPG Maker XP can't go
  # past 999). Assignments are kept in world_ids.json so rebuilding is stable.
  #-----------------------------------------------------------------------------
  class Ids
    attr_reader :infos
    def initialize(path)
      @path = path
      @assign = File.exist?(path) ? JSON.parse(File.read(path)) : {}
      @infos = load_data('Data/MapInfos.rxdata')
    end

    def save
      File.write(@path, JSON.pretty_generate(@assign.sort.to_h) + "\n")
      save_data(@infos, 'Data/MapInfos.rxdata')
    end

    def empty_placeholder?(id)
      return false if !@infos[id] || !File.exist?(WG.map_path(id))
      m = WG.load_map(id)
      return false if !m.events.empty?
      (0...m.height).each { |y| (0...m.width).each { |x| return false if (0..2).any? { |z| m.data[x, y, z].to_i > 0 } } }
      true
    end

    def placeholder_named(name, parent_root)
      cands = @infos.keys.sort.select { |id| @infos[id].name.strip.casecmp?(name) && under?(id, parent_root) }
      cands.find { |id| !@assign.value?(id) && empty_placeholder?(id) }
    end

    def under?(id, root)
      seen = {}
      while id && id > 0 && !seen[id]
        return true if id == root
        seen[id] = true
        id = @infos[id]&.parent_id
      end
      false
    end

    def free_id
      (1..999).find { |i| !@infos[i] && !@assign.value?(i) && !File.exist?(WG.map_path(i)) }
    end

    # key: stable name for this generated map. Returns the map id.
    def get(key, name:, parent:, placeholder: nil)
      id = @assign[key]
      if !id
        id = placeholder_named(placeholder, placeholder_root(parent)) if placeholder
        id ||= free_id
        raise "No map IDs left (RPG Maker XP allows 999)" if !id
        @assign[key] = id
      end
      # A reused placeholder keeps its place and name in the map tree
      if !@infos[id]
        info = RPG::MapInfo.new
        info.name = name
        info.parent_id = parent
        info.order = id
        @infos[id] = info
      end
      id
    end

    def placeholder_root(parent)
      id = parent
      id = @infos[id].parent_id while @infos[id] && @infos[id].parent_id > 0
      id
    end

    def [](key) = @assign[key]
  end

  #-----------------------------------------------------------------------------
  # Outdoor canvas: a tree mask in 3-tile-wide columns (the tree pattern repeats
  # every 3 tiles) plus layered tiles.
  #-----------------------------------------------------------------------------
  class Canvas
    attr_reader :w, :h, :map, :blocked

    def initialize(w, h)
      @w = w; @h = h
      @cols = (w + 2) / 3
      @tree = Array.new(@cols) { Array.new(h, true) }
      @map = WG.new_map(w, h, OUT_TS)
      @layer1 = {}
      @layer2 = {}
      @blocked = {}   # tiles covered by buildings etc.
    end

    def col_of(x) = x / 3

    # Opens (removes trees from) the rectangle, widened to whole 3-tile columns.
    def open(x, y, w, h)
      (col_of([x, 0].max)..col_of([x + w - 1, @w - 1].min)).each do |c|
        ([y, 0].max..[y + h - 1, @h - 1].min).each { |yy| @tree[c][yy] = false }
      end
    end

    def tree?(x, y)
      return true if x < 0 || y < 0 || x >= @w || y >= @h
      @tree[col_of(x)][y]
    end

    def open?(x, y) = !tree?(x, y) && !@blocked[[x, y]]

    def grass(x, y, w, h)
      (y...y + h).each { |yy| (x...x + w).each { |xx| @layer1[[xx, yy]] = GRASS if open?(xx, yy) } }
    end

    def tile1(x, y, t) = (@layer1[[x, y]] = t)

    def stamp(kind, x, y)
      sm, sx, sy, sw, sh, dx, dy = STAMPS[kind]
      src = WG.src_map(sm)
      sh.times do |j|
        sw.times do |i|
          l1 = src.data[sx + i, sy + j, 1]
          l2 = src.data[sx + i, sy + j, 2]
          @layer1[[x + i, y + j]] = l1 if l1 > 0
          @layer2[[x + i, y + j]] = l2 if l2 > 0
          @layer1.delete([x + i, y + j]) if l1 == 0 && @layer1[[x + i, y + j]] == GRASS
          @blocked[[x + i, y + j]] = true unless i == dx && j == dy
        end
      end
      [x + dx, y + dy]   # door
    end

    # Writes the tiles to the map.
    def render
      d = @map.data
      @h.times { |y| @w.times { |x| d[x, y, 0] = GROUND; d[x, y, 1] = 0; d[x, y, 2] = 0 } }
      @cols.times do |c|
        y = 0
        while y < @h
          if !@tree[c][y]
            y += 1
            next
          end
          y0 = y
          y += 1 while y < @h && @tree[c][y]
          y1 = y - 1
          draw_run(c, y0, y1)
        end
      end
      @layer1.each { |(x, y), t| d[x, y, 1] = t if x < @w && y < @h }
      @layer2.each { |(x, y), t| d[x, y, 2] = t if x < @w && y < @h }
      @map
    end

    def draw_run(c, y0, y1)
      bottom = y1 < @h - 1 && (y1 - y0) >= 2
      top = y0 > 0
      (y0..y1).each do |y|
        row = if top && y == y0 then CAP_TOP
              elsif bottom && y == y1 then CAP_BOT2
              elsif bottom && y == y1 - 1 then CAP_BOT1
              else
                ref = bottom ? y1 - 2 : y1
                ((ref - y).even?) ? TREE_A : TREE_B
              end
        3.times do |i|
          x = (c * 3) + i
          @map.data[x, y, 0] = row[i] if x < @w
        end
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Interiors
  #-----------------------------------------------------------------------------
  # Copies a room (all layers and the events inside it) into dest at (dx, dy).
  # Returns a hash old event id -> new event.
  def copy_room(dest, kind, dx, dy, copy_events: true)
    sm, sx, sy, sw, sh = ROOMS[kind]
    src = src_map(sm)
    sh.times { |j| sw.times { |i| 3.times { |z| dest.data[dx + i, dy + j, z] = src.data[sx + i, sy + j, z] } } }
    copied = {}
    return copied if !copy_events
    src.events.each_value do |ev|
      next unless ev.x >= sx && ev.y >= sy && ev.x < sx + sw && ev.y < sy + sh
      next if ev.pages.any? { |pg| pg.list.any? { |c| c.code == 201 } }   # warps are rebuilt
      nev = Marshal.load(Marshal.dump(ev))
      nev.id = (dest.events.keys.max || 0) + 1
      nev.x = ev.x - sx + dx
      nev.y = ev.y - sy + dy
      dest.events[nev.id] = nev
      copied[ev.id] = nev
    end
    copied
  end

  def fill_void(map, tile)
    map.height.times { |y| map.width.times { |x| map.data[x, y, 0] = tile } }
  end
end

#===============================================================================
# Event helpers
#===============================================================================
def ev_warp(map, x, y, dest_map, dx, dy, dir, name: 'Warp', script_cond: nil, fail_text: nil, se: true)
  list = EventList.build do
    if script_cond
      if_script(script_cond, otherwise: proc { text(fail_text || "You can't go this way yet.") }) do
        play_se('Door exit') if se
        transfer(dest_map, dx, dy, dir)
      end
    else
      play_se('Door exit') if se
      transfer(dest_map, dx, dy, dir)
    end
  end
  new_event(map, name, x, y, [new_page(trigger: 1, list: list)])
end

# A warp whose destination is computed by a script (FullPoke.forest_gate etc.).
def ev_script_touch(map, x, y, name, script, trigger: 1, graphic: '')
  list = EventList.build { script(script) }
  new_event(map, name, x, y, [new_page(trigger: trigger, list: list, graphic: graphic)])
end

def ev_npc(map, x, y, name, graphic, lines, dir: 2, move_type: 0)
  list = EventList.build { lines.each { |l| text(l) } }
  new_event(map, name, x, y, [new_page(trigger: 0, list: list, graphic: graphic, direction: dir, move_type: move_type)])
end

def ev_sign(map, x, y, name, lines)
  list = EventList.build { lines.each { |l| text(l) } }
  new_event(map, name, x, y, [new_page(trigger: 0, list: list)])
end

def ev_item_ball(map, x, y, item)
  page1 = new_page(trigger: 0, graphic: 'Object ball', list: EventList.build {
    if_script("pbItemBall(:#{item})") { self_switch('A', true) }
  })
  page2 = new_page(self_switch: 'A')
  new_event(map, 'Item', x, y, [page1, page2])
end

def ev_hidden_item(map, x, y, item)
  page1 = new_page(trigger: 0, list: EventList.build {
    if_script("pbItemBall(:#{item})") { self_switch('A', true) }
  })
  page2 = new_page(self_switch: 'A')
  new_event(map, 'HiddenItem', x, y, [page1, page2])
end

# A trainer that walks up when it sees the player. battle_script must return true
# when the player wins (e.g. "FullPoke.route_trainer_battle(:johto, 1, 0)").
# Mirrors the events Essentials' compiler makes from "Battle:" comments.
def ev_trainer(map, x, y, sight, graphic, dir, tr_type, intro, battle_script, after)
  page1 = new_page(trigger: 2, graphic: graphic, direction: dir, list: EventList.build {
    script("pbTrainerIntro(:#{tr_type})")
    script('pbNoticePlayer(get_self)')
    text(intro)
    if_script(battle_script) { self_switch('A', true) }
    script('pbTrainerEnd')
  })
  page2 = new_page(trigger: 0, graphic: graphic, direction: dir, self_switch: 'A', list: EventList.build { text(after) })
  new_event(map, "Trainer(#{sight})", x, y, [page1, page2])
end
