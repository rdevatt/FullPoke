# Builds a region from the map pack's own hand-made maps (see geo/<region>.rb):
# map connections and gatehouse/cave warps between the real towns, routes and
# dungeons; doors into generated interiors (Poké Centers, Marts, houses, the
# lab and home); Gyms with Leaders and Gym trainers; route trainers, items and
# wild Pokémon; story battles; badge requirements per area; Victory Road and the
# League. Loaded by build_world.rb, which calls build_geo_region for regions in
# GEO_SPEC instead of generating a compact circuit.
require_relative 'geo_lib'
# (geo/gen_*.rb are written by the build for the tests and aren't loaded here)
Dir[File.join(__dir__, 'geo', '*.rb')].sort.reject { |f| File.basename(f).start_with?('gen_') }.each { |f| require f }

# Room templates on Kanto's composite interior map 179 (tileset 2): [map, x, y, w, h]
ROOM_TPL = {
  mart:  [[179, 15, 8, 13, 11]],
  house: [[179, 17, 68, 11, 9], [179, 43, 68, 11, 9], [179, 99, 78, 11, 9], [179, 121, 78, 11, 9],
          [179, 100, 103, 11, 9], [179, 122, 103, 11, 9], [179, 144, 102, 11, 9], [179, 164, 103, 11, 9],
          [179, 183, 102, 11, 9], [179, 22, 217, 11, 9], [179, 52, 217, 11, 9], [179, 16, 84, 12, 9]],
  big:   [[179, 169, 77, 13, 12], [179, 133, 50, 20, 11]]
}
CELL_W, CELL_H = 22, 16
GEO_WARNINGS = []
HOUSE_LINES = [
  ["I love the view from my window. You can see the whole town!"],
  ["My Pokémon and I take a walk on the route every morning."],
  ["Have you been to the Pokémon Center? They heal Pokémon for free!"],
  ["My grandpa says the Gym Leader here was once a Trainer just like you."],
  ["Wild Pokémon hide in tall grass. Walk through it and they'll jump out!"],
  ["If your Pokémon are tired, rest them before you head out again."],
  ["A Trainer came through here yesterday with a really rare Pokémon."],
  ["Some routes can only be crossed with a Pokémon's help. Collect badges and you'll see!"]
]

# Copies a box of tiles (all layers) from a source map.
def copy_box(dest, src_id, sx, sy, w, h, dx, dy)
  src = WG.src_map(src_id)
  h.times { |j| w.times { |i| 3.times { |z| dest.data[dx + i, dy + j, z] = src.data[sx + i, sy + j, z] } } }
end

# Exit tile of a template room: its warp event if it has one, otherwise the
# walkable bottom-row tile nearest the middle.
def room_exit(tpl)
  sm, sx, sy, w, h = tpl
  src = WG.src_map(sm)
  ev = src.events.values.find do |e|
    e.x >= sx && e.x < sx + w && e.y >= sy && e.y < sy + h && e.pages.any? { |p| p.list.any? { |c| c.code == 201 } }
  end
  return [ev.x - sx, ev.y - sy] if ev
  ys = (sy...sy + h).to_a.reverse
  ys.each do |y|
    xs = (sx...sx + w).select { |x| passable_tile?(src, x, y) && passable_tile?(src, x, y - 1) }
    return [xs.min_by { |x| (x - (sx + w / 2)).abs } - sx, y - sy] if !xs.empty?
  end
  raise "no exit in room #{tpl.inspect}"
end

class GeoRegion
  attr_reader :region, :spec, :maps

  def initialize(region)
    @region = region
    @spec = GEO_SPEC[region]
    @data = FullPoke::Circuit.get(region)
    @reg = FullPoke.region(region)
    @maps = {}
    @rng = Random.new(Zlib.crc32("geo/#{region}"))
  end

  def id(key)
    raise "#{@region}: unknown map #{key}" if !@spec[:maps][key]
    @spec[:maps][key]
  end

  def map(key)
    mid = id(key)
    @maps[mid] ||= begin
      m = WG.load_map(mid)
      remove_fp_events(m)
      m.events.delete_if { |_, e| e.pages.any? { |pg| pg.list.any? { |c| c.code == 201 } } }   # the pack's broken warps
      # Walls from the last build come off (build_walls puts back the current ones)
      if (wt = @spec[:wall_tile])
        m.height.times { |y| m.width.times { |x| m.data[x, y, 2] = 0 if m.data[x, y, 2] == wt } }
      end
      m
    end
  end

  def build
    root = region_root(@region)
    @root = root
    generate_maps
    build_rooms
    gmap, gid, grooms, lrooms = build_gyms(@region, root)
    @gyms = { map: gmap, id: gid, rooms: grooms }
    build_walls
    build_bridge_switches
    connect_maps
    build_gates
    build_warps
    build_docks
    build_ferries
    build_towns
    link_areas
    build_start
    build_routes
    build_story
    build_league(gmap, gid, lrooms)
    map_rules
    @maps.each { |mid, m| save_map(mid, m) }
    save_map(@interiors_id, @interiors); meta(@interiors_id, "#{@reg.name} Interiors", outdoor: false)
    save_map(gid, gmap); meta(gid, "#{@reg.name} Gyms and League", outdoor: false, battleback: 'indoor1')
    @spec[:maps].each do |key, mid|
      next if METADATA[mid]
      town = @spec[:towns]&.key?(key)
      cave = WG.load_map(mid).tileset_id == 27 || (@spec[:caves] || []).include?(key)
      meta(mid, @spec.dig(:names, key) || INFO_NAME.call(mid), outdoor: !cave, battleback: cave ? 'cave1' : 'field',
           extra: cave ? ["DarkMap = false"] : [])
    end
  end

  # Places the map pack has only as empty placeholder maps, generated as caves
  # like the generated regions' (its ports are winding branches, sealed at the
  # map edge): `generate: { key => { size: [w, h], ports: [[side, frac], ...] } }`
  def generate_maps
    (@spec[:generate] || {}).each do |key, g|
      rng = Random.new(Zlib.crc32("geo/#{@region}/#{key}"))
      m = Gen.cave({ size: g[:size], rocks: g[:rocks] }, g[:ports], rng)
      m.height.times do |y|
        m.width.times do |x|
          next if x > 0 && y > 0 && x < m.width - 1 && y < m.height - 1
          m.data[x, y, 0] = Gen::CAVE_VOID
          m.data[x, y, 1] = 0
        end
      end
      WG.set_bgm(m, g[:bgm] || 'Cave')
      save_data(m, WG.map_path(id(key)))
    end
  end

  #-----------------------------------------------------------------------------
  # Scenery drawn with walkable ground or open water that no path leads onto
  # (mountain tops, plateaus, sea beyond a line of rocks): walls: { map =>
  # [[x, y], ...] } covers the area around each tile (land and water, up to
  # ledges and bridges) with an invisible solid tile (wall_tile, made solid by
  # tile_fixes).
  #-----------------------------------------------------------------------------
  def wall_area(m, sx, sy)
    ts = TILESETS[m.tileset_id]
    open = lambda do |x, y|
      next false if !(passable_tile?(m, x, y) || Geo.water_tile?(m, x, y))
      (0..2).none? { |z| (t = m.data[x, y, z]) > 0 && [1, 15].include?(ts.terrain_tags[t]) }
    end
    raise "#{@region}: wall seed #{sx},#{sy} on map #{m.width}x#{m.height} isn't open ground or water" if !open.(sx, sy)
    seen = { [sx, sy] => true }
    queue = [[sx, sy]]
    until queue.empty?
      cx, cy = queue.shift
      [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
        n = [cx + dx, cy + dy]
        next if seen[n] || !open.(*n)
        seen[n] = true
        queue << n
      end
    end
    seen
  end

  def build_walls
    (@spec[:walls] || {}).each do |key, seeds|
      m = map(key)
      seeds.each do |sx, sy|
        area = wall_area(m, sx, sy)
        puts "#{@region} #{key}: wall at #{sx},#{sy} covers #{area.size} tiles" if ENV['VERBOSE']
        # (on the top layer where it's free, so the next build can take it off)
        area.each_key { |x, y| m.data[x, y, 2] = @spec[:wall_tile] if m.data[x, y, 2] == 0 && !event_at?(m, x, y) }
      end
    end
  end

  # More BridgeOn/BridgeOff switches where the pack's own sit too far from the
  # bridge (FullPoke turns a bridge off on land with no bridge tile beside):
  #   bridge_switches: { map => { on: [[x, y], ...], off: [...] } }
  def build_bridge_switches
    (@spec[:bridge_switches] || {}).each do |key, sw|
      m = map(key)
      sw.each do |kind, tiles|
        name = (kind == :on) ? 'BridgeOn' : 'BridgeOff'
        tiles.each do |x, y|
          new_event(m, "FP: #{name}", x, y, [new_page(trigger: 1, list: EventList.build { script("pb#{name}") })])
        end
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Interiors: one composite map with every room the region's doors need.
  #-----------------------------------------------------------------------------
  def build_rooms
    @room_requests = []
    (@spec[:towns] || {}).each do |town, t|
      t[:doors].each { |d| @room_requests << [town, d] if %i[pc mart house home lab big].include?(d[0]) }
    end
    n = @room_requests.length
    cols = 8
    rows = (n + cols - 1) / cols
    @interiors_id = IDS.get("#{@region}/interiors", name: "#{@reg.name} Interiors", parent: @root,
                            placeholder: "#{@reg.name} Interiors")
    IDS.infos[@interiors_id].name = "#{@reg.name} Interiors"
    @interiors = WG.new_map(cols * CELL_W, [rows, 1].max * CELL_H, 2)
    WG.fill_void(@interiors, 384)
    @rooms = {}
    house_i = 0
    @room_requests.each_with_index do |(town, d), i|
      ox = (i % cols) * CELL_W + 1
      oy = (i / cols) * CELL_H + 1
      kind = d[0]
      case kind
      when :pc
        WG.copy_room(@interiors, :pc, ox, oy)
        room = { origin: [ox, oy], size: [16, 10], door: [ox + 7, oy + 9], arrive: [ox + 7, oy + 8] }
      when :lab
        WG.copy_room(@interiors, :lab, ox, oy, copy_events: false)
        room = { origin: [ox, oy], size: [13, 14], door: [ox + 6, oy + 13], arrive: [ox + 6, oy + 12] }
      else
        list = ROOM_TPL[kind == :home ? :house : kind]
        tpl = list[(kind == :house ? house_i += 1 : 0) % list.length]
        copy_box(@interiors, tpl[0], tpl[1], tpl[2], tpl[3], tpl[4], ox, oy)
        ex, ey = room_exit(tpl)
        room = { origin: [ox, oy], size: [tpl[3], tpl[4]], door: [ox + ex, oy + ey], arrive: [ox + ex, oy + ey - 1] }
      end
      @rooms[[town, d[1], d[2]]] = room
    end
  end

  def room_box(room) = [room[:origin][0], room[:origin][1], room[:size][0], room[:size][1]]

  #-----------------------------------------------------------------------------
  # Map connections and warps between the real maps
  #-----------------------------------------------------------------------------
  def connect_maps
    @spec[:links].each do |a, side, b|
      d, match, = Geo.best_offset(map(a), side, map(b))
      d = @spec.dig(:offsets, [a, b]) || d
      GEO_WARNINGS << "#{@region}: #{a} #{side} #{b} lines up only #{match} tiles" if match < 2
      CONNECTIONS << Geo.connection_line(id(a), side, id(b), d)
    end
  end

  # The walkable tile next to a solid entrance tile, in the given direction (or
  # whichever side is open).
  def step_out(m, x, y, dir = nil)
    dirs = { 2 => [0, 1], 8 => [0, -1], 4 => [-1, 0], 6 => [1, 0] }
    order = dir ? [dir] + (dirs.keys - [dir]) : dirs.keys
    order.each do |dd|
      dx, dy = dirs[dd]
      return [x + dx, y + dy, dd] if passable_tile?(m, x + dx, y + dy) && !event_at?(m, x + dx, y + dy)
    end
    raise "#{@region}: nothing walkable beside #{x},#{y}"
  end

  # Gatehouses straddling a map edge: walking into (or onto) one side's tiles
  # comes out at the other side's arrival point.
  def build_gates
    (@spec[:gates] || []).each do |a, ta, oa, b, tb, ob|
      ma = map(a); mb = map(b)
      [[ma, ta, b, ob], [mb, tb, a, oa]].each do |m, tiles, dest, out|
        raise "#{@region}: #{dest} arrival #{out.inspect} isn't walkable" if !passable_tile?(map(dest), out[0], out[1])
        tiles.each { |x, y| ev_warp(m, x, y, id(dest), out[0], out[1], out[2], name: "FP: Gate to #{dest}", se: false) }
      end
    end
  end

  # Docks: surfing into a shore's solid tiles lands the player on dry ground at
  # the arrival point. [map, tiles, [x, y, facing]]
  def build_docks
    (@spec[:docks] || []).each do |key, tiles, (ax, ay, dir)|
      m = map(key)
      raise "#{@region}: dock arrival #{ax},#{ay} isn't walkable" if !passable_tile?(m, ax, ay)
      dest = id(key)
      tiles.each do |x, y|
        new_event(m, 'FP: Dock', x, y, [new_page(trigger: 1, list: EventList.build {
          script('pbCancelVehicles')   # step off the water Pokémon onto the dock
          transfer(dest, ax, ay, dir)
        })])
      end
    end
  end

  # Cave mouths, stairs, dungeon doors: [map, [x, y], map, [x, y]]. The tile is
  # the entrance itself; you arrive beside it on the other map.
  def build_warps
    (@spec[:warps] || []).each do |a, pa, b, pb, opts|
      opts ||= {}
      ma = map(a); mb = map(b)
      pa = pick_tile(ma, pa) if pa.is_a?(Hash)
      pb = pick_tile(mb, pb) if pb.is_a?(Hash)
      oa = step_out(ma, *pa, opts[:out_a]); ob = step_out(mb, *pb, opts[:out_b])
      ev_warp(ma, pa[0], pa[1], id(b), ob[0], ob[1], ob[2], name: "FP: Way to #{b}", se: !opts[:quiet])
      ev_warp(mb, pb[0], pb[1], id(a), oa[0], oa[1], oa[2], name: "FP: Way to #{a}", se: !opts[:quiet]) unless opts[:one_way]
    end
  end

  # Maps drawn as several separate areas (tower floors side by side, cave
  # levels, cliff tops, lagoons behind rocks): every area with 10+ walkable
  # (or 10+ surfable) tiles that players can't reach from
  # `link_areas: { key => [x, y] }` (or a list of points: tiles they do reach)
  # gets a two-way ladder. Reaching is worked out like t_reach.rb does: Surf,
  # one-way ledges, and warps within the map count. Where the area faces a
  # reached tile across a cliff, wall or line of rocks up to 3 tiles thick,
  # the ladder is in that wall (walk or surf into it; a wall one tile thick
  # uses two tiles side by side, one each way). Otherwise the two ends stand
  # in dead ends, where nobody steps by accident.
  def link_areas
    dirs = { 2 => [0, 1], 8 => [0, -1], 4 => [-1, 0], 6 => [1, 0] }
    back = { 2 => 8, 8 => 2, 4 => 6, 6 => 4 }
    (@spec[:link_areas] || {}).each do |key, entries|
      m = map(key)
      mid = id(key)
      ts = TILESETS[m.tileset_id]
      entries = [entries] if entries[0].is_a?(Integer)
      inside = ->(x, y) { x >= 0 && y >= 0 && x < m.width && y < m.height }
      # :land, :water, :void (nothing drawn: passable, but no place for a
      # ladder) or nil (solid). The topmost tile decides, as in the engine.
      kind = lambda do |x, y|
        return nil if !inside.(x, y)
        [2, 1, 0].each do |z|
          t = m.data[x, y, z]
          next if t == 0
          tag = ts.terrain_tags[t]
          return :land if tag == 15
          return :water if [5, 6, 7].include?(tag)
          return nil if ts.passages[t] & 0x0f == 0x0f
          return :land if ts.priorities[t] == 0
        end
        (0..2).all? { |z| m.data[x, y, z] == 0 } ? :void : :land
      end
      # Ledges are jumped in the directions their tile can be entered from
      ledge_ok = lambda do |x, y, d|
        [2, 1, 0].each do |z|
          t = m.data[x, y, z]
          next if t == 0 || ts.terrain_tags[t] != 1
          pass = ts.passages[t] & 0x0f
          return d == 2 if pass == 0
          return pass & (1 << ((10 - d) / 2 - 1)) == 0
        end
        true
      end
      land = ->(x, y) { kind.(x, y) == :land && !event_at?(m, x, y) }
      walk = lambda do |starts|
        warp = {}
        solid = {}
        m.events.each_value do |e|
          pg = e.pages[0] or next
          solid[[e.x, e.y]] = true if pg.graphic.character_name != '' && !pg.through && pg.trigger != 1
          c = pg.list.find { |cmd| cmd.code == 201 }
          warp[[e.x, e.y]] = [c.parameters[2], c.parameters[3]] if c && c.parameters[0] == 0 && c.parameters[1] == mid
        end
        seen = {}
        q = []
        starts.each { |s| (seen[s] = true; q << s) if !seen[s] }
        until q.empty?
          x, y = q.shift
          if (w = warp[[x, y]]) && !seen[w]
            seen[w] = true
            q << w
          end
          dirs.each do |d, (dx, dy)|
            n = [x + dx, y + dy]
            next if seen[n] || !inside.(*n)
            k = kind.(*n)
            if !k && (w = warp[n])   # a door or ladder in a wall: walk into it
              (seen[w] = true; q << w) if !seen[w]
              next
            end
            next if !k || (solid[n] && !warp[n]) || !ledge_ok.(*n, d)
            seen[n] = true
            q << n
          end
        end
        seen
      end
      # Each entry, or the nearest open tile if it names a door or a wall
      starts = entries.map do |ex, ey|
        (0..6).lazy.flat_map { |r| (-r..r).flat_map { |dx| [[ex + dx, ey + r - dx.abs], [ex + dx, ey - r + dx.abs]] } }
              .find { |t| kind.(*t) && !event_at?(m, *t) } || raise("#{@region}: nothing walkable near #{key} #{ex},#{ey}")
      end
      count = 0
      skipped = {}
      ladder = lambda do |wa, b, b_dir, wb, a, a_dir|
        count += 1
        ev_warp(m, wa[0], wa[1], mid, b[0], b[1], b_dir, name: "FP: Ladder #{count}")
        ev_warp(m, wb[0], wb[1], mid, a[0], a[1], a_dir, name: "FP: Ladder #{count} back")
      end
      dead_end = lambda do |tiles|
        set = tiles.to_h { |t| [t, true] }
        # Off the map edge and away from other events where possible
        tiles.select { |x, y| land.(x, y) && dirs.values.any? { |dx, dy| land.(x + dx, y + dy) } }.min_by do |x, y|
          [x > 0 && y > 0 && x < m.width - 1 && y < m.height - 1 ? 0 : 1,
           dirs.values.any? { |dx, dy| event_at?(m, x + dx, y + dy) } ? 1 : 0,
           dirs.values.count { |dx, dy| set[[x + dx, y + dy]] }, y, x]
        end
      end
      200.times do
        seen = walk.(starts)
        # Unreached areas (tiles joined both ways)
        group_of = {}
        groups = []
        m.height.times do |y|
          m.width.times do |x|
            next if group_of[[x, y]] || seen[[x, y]] || skipped[[x, y]] || !kind.(x, y) || event_at?(m, x, y)
            g = []
            q = [[x, y]]
            group_of[[x, y]] = true
            until q.empty?
              c = q.shift
              g << c
              dirs.each_value do |dx, dy|
                n = [c[0] + dx, c[1] + dy]
                next if group_of[n] || seen[n] || skipped[n] || !kind.(*n) || event_at?(m, *n)
                group_of[n] = true
                q << n
              end
            end
            # Water counts too: a lagoon behind a line of rocks
            groups << g if g.count { |t| land.(*t) } >= 10 || g.count { |t| kind.(*t) == :water } >= 10
          end
        end
        break if groups.empty?
        # Walls between an area and reached ground (or water, for a lagoon:
        # surfing through the rocks)
        wall_ok = ->(w) { inside.(*w) && !kind.(*w) && !event_at?(m, *w) }
        same = ->(t, k) { kind.(*t) == k && !event_at?(m, *t) }
        linked = groups.select do |g|
          in_g = g.to_h { |t| [t, true] }
          best = nil
          g.each do |bx, by|
            bk = kind.(bx, by)
            next if ![:land, :water].include?(bk) || event_at?(m, bx, by)
            dirs.each do |d, (dx, dy)|
              (1..3).each do |k|
                wall = (1..k).map { |s| [bx + dx * s, by + dy * s] }
                break if !wall.all?(&wall_ok)
                a = [bx + dx * (k + 1), by + dy * (k + 1)]
                next if !seen[a] || !same.(a, bk)
                if k == 1
                  # A wall one tile thick: the way back is the wall tile beside it
                  [[dy, dx], [-dy, -dx]].each do |px, py|
                    w2 = [wall[0][0] + px, wall[0][1] + py]
                    b2 = [bx + px, by + py]; a2 = [a[0] + px, a[1] + py]
                    next if !wall_ok.(w2) || !in_g[b2] || !same.(b2, bk) || !seen[a2] || !same.(a2, bk)
                    best = [1, [bx, by], d, wall[0], a2, w2]
                    break
                  end
                elsif !best || k < best[0]
                  best = [k, [bx, by], d, wall[-1], a, wall[0]]
                end
                break
              end
            end
            break if best && best[0] == 1
          end
          next false if !best
          _, b, d, wa, a, wb = best
          # Walking into the wall from the reached side climbs to b, and back
          ladder.(wa, b, back[d], wb, a, d)
          true
        end
        next if !linked.empty?
        g = groups.max_by(&:length)
        a = dead_end.(seen.keys.select { |t| inside.(*t) })
        b = dead_end.(g)
        if !a || !b
          GEO_WARNINGS << "#{@region}: #{key} has no spot for a ladder to the area around #{g[0].join(',')}"
          g.each { |t| skipped[t] = true }
          next
        end
        oa = step_out(m, *a); ob = step_out(m, *b)
        ladder.(a, ob[0..1], ob[2], b, oa[0..1], oa[2])
      end
    end
  end

  # The top- or bottom-most walkable tile of the area around `near`, or
  # (`door: [x, y]`) the building front nearest that point.
  def pick_tile(m, sel)
    return Geo.snap_door(m, *sel[:door]) if sel[:door]
    area = reachable_from(m, *sel[:near]).keys.reject { |x, y| event_at?(m, x, y) }
    raise "#{@region}: nothing walkable near #{sel[:near].inspect}" if area.size < 2
    case sel[:pick]
    when :top    then area.min_by { |x, y| [y, x] }
    when :bottom then area.max_by { |x, y| [y, -x] }
    when :left   then area.min_by { |x, y| [x, y] }
    when :right  then area.max_by { |x, y| [x, y] }
    end
  end

  # Boatmen who sail the player to another map (once they have enough of the
  # region's badges): { name:, at: [map, [x, y]], to: [map, [x, y]], badges:, dest_name: }.
  # Walking into them starts the trip, so route planners treat them as warps.
  def build_ferries
    (@spec[:ferries] || []).each do |f|
      key, (x, y) = f[:at]
      m = map(key)
      x, y = free_spot(m, x, y)
      dkey, (dx, dy) = f[:to]
      # Land beside the other boatman, not in front of him (one more step up
      # would sail straight back)
      ax, ay = free_spot(map(dkey), dx + 2, dy + 1, avoid: [[dx, dy], [dx, dy + 1], [dx - 1, dy], [dx + 1, dy]])
      region = @region
      dest_id = id(dkey)
      # completed: true sails only for the region's Champion
      cond, early = f[:completed] ? ["FullPoke.completed?(:#{region})", "once you're the Champion here"] :
                                    ["FullPoke.region_badge_count(:#{region}) >= #{f[:badges]}", "once you've earned #{f[:badges]} badges here"]
      list = EventList.build do
        if_script(cond, otherwise: proc { text("#{f[:name]}: I'll sail you to #{f[:dest_name]} #{early}.") }) do
          text("#{f[:name]}: All aboard for #{f[:dest_name]}!")
          transfer(dest_id, ax, ay, 2)
        end
      end
      new_event(m, "FP: Ferry to #{dkey}", x, y, [new_page(trigger: 1, graphic: f[:graphic] || 'trainer_SAILOR', list: list)])
    end
  end

  #-----------------------------------------------------------------------------
  # Towns: doors, Poké Centers, Marts, Gyms, houses
  #-----------------------------------------------------------------------------
  def build_towns
    (@spec[:towns] || {}).each do |town, t|
      m = map(town)
      stage = t[:stage] || 0
      t[:doors].each_with_index do |d, di|
        kind, gx, gy, label, lines, exact = d
        begin
          dx, dy = exact ? [gx, gy] : Geo.snap_door(m, gx, gy)
        rescue RuntimeError => e
          # Tilesets with no blocking set at all (the pack's tileset 26/30
          # towns): the door is a tile you step onto, at the given spot
          if [1, 2].any? { |z| m.data[gx, gy, z].to_i >= 384 } && passable_tile?(m, gx, gy + 1) && !event_at?(m, gx, gy)
            dx, dy = gx, gy
            GEO_WARNINGS << "#{@region} #{town}: door #{kind} #{gx},#{gy} placed without a building front (#{e.message})"
          else
            GEO_WARNINGS << "#{@region} #{town}: door #{kind} #{gx},#{gy} skipped (#{e.message})"
            next
          end
        end
        clear_door_approach(m, dx, dy)
        out = step_out(m, dx, dy, 2)
        if reachable_from(m, out[0], out[1]).size < 80
          GEO_WARNINGS << "#{@region} #{town}: door #{kind} #{label} at #{dx},#{dy} opens onto a small enclosed area"
        end
        case kind
        when :gym
          gym_door(town, m, dx, dy, out, t[:stage])
        when :dungeon
          dest = label   # [map key, x, y] or [map key, { near:, pick: }]
          dm = map(dest[0])
          dest = [dest[0], *pick_tile(dm, dest[1])] if dest[1].is_a?(Hash)
          inside = step_out(dm, dest[1], dest[2], 8)
          ev_warp(m, dx, dy, id(dest[0]), inside[0], inside[1], inside[2], name: "FP: Door #{dest[0]}")
          ev_warp(dm, dest[1], dest[2], id(town), out[0], out[1], 2, name: "FP: Exit to #{town}")
        when :closed
          ev_sign(m, dx, dy, "FP: Door #{label}", lines || ["It's locked."])
        else
          room = @rooms[[town, gx, gy]]
          ev_warp(m, dx, dy, @interiors_id, room[:arrive][0], room[:arrive][1], 8, name: "FP: Door #{label || kind}")
          ev_warp(@interiors, room[:door][0], room[:door][1], id(town), out[0], out[1], 2, name: "FP: Exit to #{town}")
          furnish(kind, room, town, stage, di, label, lines)
        end
      end
      name = @spec.dig(:names, town) || INFO_NAME.call(id(town))
      meta(id(town), name, battleback: 'field')
    end
  end

  def furnish(kind, room, town, stage, di, label, lines)
    box = room_box(room)
    ox, oy = room[:origin]
    case kind
    when :mart
      x, y = free_spot(@interiors, ox + 3, oy + 3, box: box, avoid: [room[:arrive]])
      new_event(@interiors, 'FP: Clerk', x, y, [new_page(trigger: 0, graphic: 'NPC 19', list: EventList.build {
        text('Welcome! How may I help you?')
        script("pbPokemonMart(#{mart_items([stage, 1].max).inspect})")
      })])
    when :home
      x, y = free_spot(@interiors, ox + 3, oy + 3, box: box, avoid: [room[:arrive]])
      new_event(@interiors, 'FP: Mom', x, y, [new_page(trigger: 0, graphic: 'NPC 06', list: EventList.build {
        text("Mom: Welcome home, dear! You look tired. Take a rest.")
        recover_all
        play_me('Pkmn healing')
        text("Mom: There, all better! Be careful out there.")
      })])
    when :lab
      @lab_room = room
    when :pc
      nil   # the copied room has the nurse and PC
    else
      text = lines || HOUSE_LINES[(Zlib.crc32("#{town}/#{di}")) % HOUSE_LINES.length]
      x, y = free_spot(@interiors, ox + box[2] / 2, oy + 3, box: box, avoid: [room[:arrive]])
      gfx = format('NPC %02d', 1 + Zlib.crc32("#{town}#{di}") % 20)
      ev_npc(@interiors, x, y, "FP: #{label || 'Resident'}", gfx, text)
    end
  end

  def gym_door(town, m, dx, dy, out, n)
    g = @gyms[:rooms][n]
    gm = @gyms[:map]
    ev_warp(m, dx, dy, @gyms[:id], g[:arrive][0], g[:arrive][1], 8, name: 'FP: Gym door',
            script_cond: "FullPoke.region_badge_count(:#{@region}) >= #{n - 1}",
            fail_text: "The Gym's door is locked. A note says: \"Gone training. Earn #{n - 1} #{@reg.name} badges and come back!\"")
    ev_warp(gm, g[:door][0], g[:door][1], id(town), out[0], out[1], 2, name: 'FP: Gym exit')
    populate_gym(@region, n, @gyms)
  end

  #-----------------------------------------------------------------------------
  # Start town: forest gate, home, the professor's lab
  #-----------------------------------------------------------------------------
  def build_start
    st = @spec[:start]
    m = map(st[:town])
    (st[:forest_gate] + [st[:arrival]]).each { |x, y| raise "#{@region}: start tile #{x},#{y} isn't walkable" if !passable_tile?(m, x, y) }
    st[:forest_gate].each { |x, y| ev_script_touch(m, x, y, 'FP: Forest gate', "FullPoke.gate_to_forest(:#{@region})") }
    ax, ay = st[:arrival]
    sx, sy = free_spot(m, ax - 1, ay - 1, avoid: [[ax, ay]] + st[:forest_gate])
    ev_sign(m, sx, sy, 'FP: Forest sign', ["#{st[:gate_dir] || 'South'}: Interregional Forest", "Paths to every region's first town."])
    home = @rooms.find { |(t, _, _), _| t == st[:town] && @spec[:towns][t][:doors].any? { |d| d[0] == :home } }&.last
    hx, hy = home ? home[:arrive] : [ax, ay]
    lab = @lab_room or raise "#{@region}: the start town needs a :lab door"
    px, py = free_spot(@interiors, lab[:origin][0] + 6, lab[:origin][1] + 4, box: room_box(lab))
    reg = @reg
    region = @region
    rival = @data[:rivals][0]
    new_event(@interiors, "FP: #{reg.professor}", px, py, [new_page(trigger: 0, graphic: 'trainer_PROFESSOR', list: EventList.build {
      if_script("FullPoke.state(:#{region}).starter", otherwise: proc {
        text("#{reg.professor}: Welcome to the #{reg.name} region! You'll need a partner for your journey.")
        script("FullPoke.give_starter(:#{region})")
        if rival
          text("#{reg.rival_name}: Hey! I got my Pokémon too. Let's see whose is stronger!")
          script("setBattleRule(\"canLose\")")
          script("FullPoke::Circuit.extra_battle(:#{region}, :#{rival}) || FullPoke.set_flag(:#{region}, :beat_#{rival})")
          text("#{reg.rival_name}: See you on the road!")
        end
        script('$player.heal_party')
      }) do
        text("#{reg.professor}: The Gyms of #{reg.name} are waiting. Use the Grove Compass to return to the forest any time.")
      end
    })])
    WORLD[:regions][@region] = { arrival: [id(st[:town]), ax, ay, st[:arrival_dir] || 8],
                                 home: [@interiors_id, hx, hy, 2], start_map: id(st[:town]) }
  end

  #-----------------------------------------------------------------------------
  # Routes: trainers, items, wild Pokémon
  #-----------------------------------------------------------------------------
  def stage_of(key) = (@spec[:stages] || {})[key]

  def build_routes
    pbs = {}
    File.foreach('PBS/encounters.txt') { |l| pbs[$1.to_i] = true if l =~ /^\[(\d+)/ }
    (@spec[:stages] || {}).each do |key, n|
      m = map(key)
      cave = m.tileset_id == 27 || (@spec[:caves] || []).include?(key)
      water = water_count(m) > 40
      if !pbs[id(key)]
        kinds = []
        kinds << (cave ? :cave : :land)
        kinds << :water if water
        WORLD[:encounters] << { map: id(key), circuit: [@region, n.clamp(1, 9), kinds] }
      end
      count = (@spec[:trainers] || {}).fetch(key, cave ? 2 : 3)
      place_route_content(key, m, n.clamp(1, 9), count)
    end
  end

  def water_count(m)
    c = 0
    m.height.times { |y| m.width.times { |x| c += 1 if Geo.water_tile?(m, x, y) } }
    c
  end

  # Spots in open ground (all four neighbours walkable, so nobody blocks a
  # one-tile path), spread out across the largest walkable area.
  def open_spots(m)
    @open_cache ||= {}
    @open_cache[m.object_id] ||= begin
      best = nil
      (2...m.height - 2).step(5) do |y|
        (2...m.width - 2).step(5) do |x|
          next if !passable_tile?(m, x, y) || (best && best[[x, y]])
          r = reachable_from(m, x, y)
          best = r if !best || r.size > best.size
        end
      end
      (best || {}).keys.select do |x, y|
        x > 2 && y > 2 && x < m.width - 3 && y < m.height - 3 && !event_at?(m, x, y) &&
          [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, -1], [1, -1], [-1, 1]].all? { |dx, dy| best[[x + dx, y + dy]] }
      end.sort
    end
  end

  def spread(spots, count, rng, min_dist)
    picked = []
    spots.shuffle(random: rng).each do |s|
      next if picked.any? { |p| (p[0] - s[0]).abs + (p[1] - s[1]).abs < min_dist }
      picked << s
      break if picked.length >= count
    end
    picked
  end

  def place_route_content(key, m, n, count)
    rng = Random.new(Zlib.crc32("geo/#{@region}/#{key}"))
    spots = open_spots(m)
    return if spots.empty?
    picks = spread(spots, count + 2, rng, 10)
    picks.first(count).each_with_index do |(x, y), i|
      idx = 10 + (Zlib.crc32(key.to_s) % 50) + i   # distinct per route within the stage's level band
      tr_type, gfx, = FullPoke::Circuit.route_trainer_class(@region, n, idx)
      # Face a way whose line of sight stays in open ground, so a trainer who
      # walks up to the player never ends up blocking a narrow path
      open = spots.to_h { |s| [s, true] }
      steps = { 2 => [0, 1], 4 => [-1, 0], 6 => [1, 0], 8 => [0, -1] }
      dirs = [2, 4, 6, 8].shuffle(random: rng)
      dir = dirs.find { |d| (1..3).all? { |k| open[[x + steps[d][0] * k, y + steps[d][1] * k]] } } || dirs.first
      sight = (1..3).take_while { |k| open[[x + steps[dir][0] * k, y + steps[dir][1] * k]] }.length
      ev_trainer(m, x, y, [sight, 1].max, gfx, dir, tr_type, 'Hey! You look like a Trainer!',
                 "FullPoke.route_trainer_battle(:#{@region}, #{n}, #{idx})", 'Good luck out there!', name_prefix: 'FP: ')
    end
    rest = picks.drop(count)
    ev_item_ball(m, *rest[0], %i[POTION POKEBALL SUPERPOTION GREATBALL HYPERPOTION ULTRABALL REVIVE FULLRESTORE MAXREVIVE][n - 1], name_prefix: 'FP: ') if rest[0]
    ev_hidden_item(m, *rest[1], %i[ETHER RARECANDY PPUP NUGGET RARECANDY MAXETHER PPMAX RARECANDY PPMAX][n - 1], name_prefix: 'FP: ') if rest[1]
  end

  #-----------------------------------------------------------------------------
  # Story battles, set pieces and gifts placed in the real world
  #-----------------------------------------------------------------------------
  def build_story
    (@spec[:story] || []).each do |s|
      key, (x, y) = s[:at]
      m = s[:interior] ? @interiors : map(key)
      if s[:interior]
        room = @rooms[s[:interior]]
        x, y = free_spot(@interiors, room[:origin][0] + room[:size][0] / 2, room[:origin][1] + 3, box: room_box(room), avoid: [room[:arrive]])
      else
        x, y = free_spot(m, x, y)
      end
      region = @region
      case s[:kind]
      when :battle
        defn = FullPoke::Teams.get(s[:key])
        nm = defn[:name] || @reg.rival_name
        intro = s[:intro] || "#{nm}: You won't get past me that easily!"
        after = s[:after] || "#{nm}: Next time will be different."
        cond = s[:requires] ? "FullPoke.region_badge_count(:#{region}) >= #{s[:requires]}" : 'true'
        new_event(m, "FP: #{nm}", x, y, [
          new_page(trigger: 0, graphic: "trainer_#{defn[:tr_type]}", direction: s[:dir] || 2, list: EventList.build {
            if_script(cond, otherwise: proc { text(s[:early] || "#{nm}: Not now. Come back later.") }) do
              text(intro)
              if_script("FullPoke::Circuit.extra_battle(:#{region}, :#{s[:key]})") { self_switch('A', true) }
            end
          }),
          new_page(trigger: 0, graphic: "trainer_#{defn[:tr_type]}", direction: s[:dir] || 2, self_switch: 'A',
                   list: EventList.build { text(after) })
        ])
      when :wild
        sp, lv = s[:species]
        flag = s[:flag]
        new_event(m, "FP: #{s[:name] || sp}", x, y, [
          new_page(trigger: 0, graphic: s[:graphic] || 'Object ball', list: EventList.build {
            text(s[:intro]) if s[:intro]
            script("setBattleRule(\"canLose\")")
            if_script("WildBattle.start(:#{sp}, FullPoke.scale_level(#{lv}, :#{region}))") do
              script("FullPoke.set_flag(:#{region}, :#{flag})")
              self_switch('A', true)
            end
          }),
          new_page(self_switch: 'A')
        ])
      when :npc
        ev_npc(m, x, y, "FP: #{s[:name]}", s[:graphic] || 'NPC 07', s[:lines], dir: s[:dir] || 2)
      when :ferry
        # A sailor who takes the player to another town (between islands).
        # Walking up to them is enough (player touch).
        dm = map(s[:to])
        tx, ty = free_spot(dm, dm.width / 2, dm.height / 2 + 2)
        to_name = @spec.dig(:names, s[:to]) || INFO_NAME.call(id(s[:to]))
        req = s[:requires] || 0
        dest = id(s[:to])
        new_event(m, "FP: Ferry to #{s[:to]}", x, y, [new_page(trigger: 1, graphic: s[:graphic] || 'NPC 18', list: EventList.build {
          if_script("FullPoke.region_badge_count(:#{region}) >= #{req}", otherwise: proc { text(s[:early] || "Sailor: The ferry to #{to_name} isn't running for you yet. Finish your trials here first!") }) do
            text("Sailor: All aboard for #{to_name}!")
            transfer(dest, tx, ty, 2)
          end
        })])
      when :gift
        item = s[:item]
        new_event(m, "FP: #{s[:name]}", x, y, [
          new_page(trigger: 0, graphic: s[:graphic] || 'NPC 07', list: EventList.build {
            s[:lines].each { |l| text(l) }
            if_script("pbReceiveItem(:#{item})") { self_switch('A', true) }
          }),
          new_page(trigger: 0, graphic: s[:graphic] || 'NPC 07', self_switch: 'A',
                   list: EventList.build { text(s[:after] || 'Use it well!') })
        ])
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Victory Road (generated) and the League
  #-----------------------------------------------------------------------------
  def build_league(gmap, gid, lrooms)
    vr = @spec[:victory_road]
    vr_id = IDS.get("#{@region}/victoryroad", name: "#{@reg.name} Victory Road", parent: @root, placeholder: 'Victory Road')
    from = map(vr[:from])
    out = step_out(from, *vr[:at][0], 2)
    league_entry = place_league(@region, @data, gid, gmap, lrooms, vr_id)
    vid, vmap = build_victory_road(@region, @root, @data, [id(vr[:from]), out[0], out[1]], league_entry)
    vr[:at].each do |x, y|
      ev_warp(from, x, y, vid, 19, 37, 8, name: 'FP: To Victory Road',
              script_cond: "FullPoke::Circuit.all_badges?(:#{@region})",
              fail_text: "The way to Victory Road is open only to Trainers with all eight #{@reg.name} badges.")
    end
    new_event(vmap, 'FP: Nurse', 22, 38, [new_page(trigger: 0, graphic: 'NPC 16', list: EventList.build {
      text('The League is ahead. Let me heal your Pokémon.')
      script('pbSetPokemonCenter')
      recover_all
      play_me('Pkmn healing')
    })])
    save_map(vid, vmap)
    WORLD[:regions][@region][:league] = league_entry
    WORLD[:regions][@region][:victory_road] = vid
  end

  #-----------------------------------------------------------------------------
  # Areas that need badges (or the starter) before you can enter them
  #-----------------------------------------------------------------------------
  def map_rules
    WORLD[:map_rules] ||= {}
    (@spec[:requires] || {}).each do |key, req|
      req = { badges: req } if req.is_a?(Integer)
      WORLD[:map_rules][id(key)] = { region: @region }.merge(req)
    end
  end
end

# Tiles of the map pack's tilesets that were never given passability (blocking
# 0, priority 0) but are drawn as parts of buildings, so players walked through
# houses. A tile counts as a building part when, on layer 1/2 of the region's
# maps, it sits directly above/below a solid tile (or between two) in at least
# 70% of the places it's used. Ground/nature tiles (the first rows of the
# tileset, and anything also used as ground) are never changed. Tileset 1 is
# Kanto's and is left alone.
FIX_PASSAGES_MIN_ID = 3000
# Tileset 1 is Kanto's; 26 already has hand-set passability in the base tilesets
FIX_PASSAGES_SKIP = [1, 26]
FIXED_TILES = {}

# Doormats, carpets, steps and curbs around a door look like building parts to
# fix_building_passages (they sit next to solid walls). From the tile in front
# of each door, the shortest way to open ground is found, and any tile on it
# that the fix made solid is made walkable again.
def clear_door_approach(map, x, y)
  ts = TILESETS[map.tileset_id]
  fixed_ids = ->(cx, cy) { [1, 2].map { |z| map.data[cx, cy, z] }.select { |t| FIXED_TILES[[map.tileset_id, t]] } }
  open = ->(cx, cy) { cx >= 0 && cy >= 0 && cx < map.width && cy < map.height && (passable_tile?(map, cx, cy) || !fixed_ids.(cx, cy).empty?) }
  start = [x, y + 1]
  return if !open.(*start)
  prev = { start => nil }
  queue = [start]
  goal = nil
  until queue.empty?
    c = queue.shift
    if passable_tile?(map, *c) && reachable_from(map, *c).size >= 80
      goal = c
      break
    end
    next if (c[0] - x).abs + (c[1] - y).abs > 12
    [[0, 1], [1, 0], [-1, 0], [0, -1]].each do |dx, dy|
      n = [c[0] + dx, c[1] + dy]
      next if prev.key?(n) || n == [x, y] || !open.(*n)
      prev[n] = c
      queue << n
    end
  end
  return if !goal
  c = goal
  while c
    fixed_ids.(*c).each { |t| ts.passages[t] = 0; FIXED_TILES.delete([map.tileset_id, t]) }
    c = prev[c]
  end
end
# Tiles that Kanto's maps use are left alone (Kanto's own fixes are in the
# tileset base and its paths are tested), so a fix for another region can't
# block a Kanto path. { tileset => { tile => true } }
def kanto_tiles
  @kanto_tiles ||= begin
    used = Hash.new { |h, k| h[k] = {} }
    FullPoke.maps_of_region(:kanto).each do |mid|
      m = (WG.load_map(mid) rescue nil) or next
      m.height.times { |y| m.width.times { |x| [1, 2].each { |z| used[m.tileset_id][m.data[x, y, z]] = true } } }
    end
    used
  end
end

def fix_building_passages(map_ids)
  by_ts = Hash.new { |h, k| h[k] = [] }
  map_ids.each { |mid| m = WG.load_map(mid); by_ts[m.tileset_id] << m }
  by_ts.each do |ts_id, maps|
    next if FIX_PASSAGES_SKIP.include?(ts_id)
    ts = TILESETS[ts_id]
    seen = Hash.new(0); hit = Hash.new(0); ground = {}
    maps.each do |m|
      m.height.times { |y| m.width.times { |x| ground[m.data[x, y, 0]] = true } }
      solid = ->(x, y) { x >= 0 && y >= 0 && x < m.width && y < m.height && [1, 2].any? { |z| (t = m.data[x, y, z]) >= 384 && ts.passages[t] & 15 == 15 } }
      m.height.times do |y|
        m.width.times do |x|
          [1, 2].each do |z|
            t = m.data[x, y, z]
            next if t < FIX_PASSAGES_MIN_ID || ts.passages[t] != 0 || ts.priorities[t] != 0
            seen[t] += 1
            hit[t] += 1 if solid.(x, y - 1) || solid.(x, y + 1) || (solid.(x - 1, y) && solid.(x + 1, y))
          end
        end
      end
    end
    fix = seen.keys.select { |t| !ground[t] && !kanto_tiles[ts_id][t] && hit[t] * 10 >= seen[t] * 7 }
    fix.each { |t| ts.passages[t] = 0x0f; FIXED_TILES[[ts_id, t]] = true }
    puts "Tileset #{ts_id}: #{fix.length} building tiles made solid"
  end
end

INFO_NAME = ->(mid) { IDS.infos[mid].name.strip.split.map(&:capitalize).join(' ') }

# Gym room n of a region's Gym map: the Leader and two Gym trainers.
def populate_gym(region, n, gyms)
  st = FullPoke::Circuit.stage(region, n)
  g = gyms[:rooms][n]
  leader = FullPoke::Teams.get(st[:leader])
  lgfx = "trainer_#{leader[:tr_type]}"
  lx, ly = free_spot(gyms[:map], g[:leader][0], g[:leader][1], box: [g[:origin][0], g[:origin][1], 13, 16])
  new_event(gyms[:map], "FP: Leader #{leader[:name]}", lx, ly, [new_page(trigger: 0, graphic: lgfx, list: EventList.build {
    text("I'm #{leader[:name]}. Show me what you've got!")
    if_script("FullPoke::Circuit.challenge(:#{region}, #{n})") { text("That was a great battle. Keep going!") }
  })])
  types = leader[:types] || [:NORMAL]
  2.times do |i|
    key = :"#{region}_gym#{n}_t#{i}"
    sp = FullPoke::Teams.candidate_pool(types, region, []).first(6)
    sp = FullPoke::Circuit.route_species(region, n) if sp.empty?
    top = FullPoke::Circuit.leader_top_level(st[:leader])
    GYM_TRAINERS << [key, region, (sp.empty? ? '' : "#{sp[(n + i) % sp.length]}:#{[top - 3, 2].max}"), i]
    tx, ty = free_spot(gyms[:map], g[:origin][0] + (i == 0 ? 3 : 9), g[:origin][1] + (i == 0 ? 10 : 8),
                       box: [g[:origin][0], g[:origin][1], 13, 15], avoid: [[g[:arrive][0], g[:arrive][1] - 1]])
    ev_trainer(gyms[:map], tx, ty, 2, (i == 0 ? 'trainer_COOLTRAINER_M' : 'trainer_COOLTRAINER_F'), (i == 0 ? 6 : 4),
               (i == 0 ? :COOLTRAINER_M : :COOLTRAINER_F), "You'll have to beat me before you face our Leader!",
               "FullPoke.trainer_battle(:#{key})", 'Our Leader is waiting.')
  end
end

# Tiles a tileset left unset but another tileset draws identically and does set
# up (geo/tileset_inherit.json, made by tileset_inherit.rb): e.g. the forest
# and water tiles of Outside2WATERSEA, a copy of Kanto's outdoor image.
TILESET_INHERIT = File.join(__dir__, 'geo', 'tileset_inherit.json')
def inherit_tileset_settings
  return if $tileset_inherited || !File.exist?(TILESET_INHERIT)
  $tileset_inherited = true
  JSON.parse(File.read(TILESET_INHERIT)).each do |ts_id, d|
    ts = TILESETS[ts_id.to_i]
    d['tiles'].each do |t, (pass, prio, tag)|
      t = t.to_i
      next if ts.passages[t] != 0 || ts.priorities[t] != 0 || ts.terrain_tags[t] != 0
      ts.passages[t] = pass; ts.priorities[t] = prio; ts.terrain_tags[t] = tag
    end
    # Hand corrections of the pack's own settings (documented in the JSON's maker)
    (d['overrides'] || {}).each do |t, (pass, prio, tag)|
      ts.passages[t.to_i] = pass; ts.priorities[t.to_i] = prio; ts.terrain_tags[t.to_i] = tag
    end
    puts "Tileset #{ts_id}: #{d['tiles'].length} tiles set up like tileset #{d['from']}"
  end
end

# A region's own corrections to the shared tilesets, kept as data in its spec:
# `tile_fixes: { tileset => { solid: [tiles], open: [tiles], tags: { tile => terrain tag } } }`.
# Tilesets are rebuilt from the base every run, so fixes never compound.
def apply_tile_fixes(region)
  (GEO_SPEC[region][:tile_fixes] || {}).each do |ts_id, fx|
    ts = TILESETS[ts_id]
    (fx[:solid] || []).each { |t| ts.passages[t] |= 0x0f }
    (fx[:open] || []).each { |t| ts.passages[t] &= ~0x0f }
    (fx[:tags] || {}).each { |t, tag| ts.terrain_tags[t] = tag }
  end
end

def build_geo_region(region)
  inherit_tileset_settings
  apply_tile_fixes(region)
  fix_building_passages(GEO_SPEC[region][:maps].values)
  GeoRegion.new(region).build
end
