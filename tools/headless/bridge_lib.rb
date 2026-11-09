# Bridges as the engine has them (Game_Map#playerPassable?). Stepping on a
# BridgeOn event (pbBridgeOn) puts the player up on the map's bridges (level
# 1); a BridgeOff event (pbBridgeOff) or a new map takes them down (level 0).
# Up on a bridge, a bridge tile's own flags decide, side rails included. Down,
# bridge tiles are ignored and the ground under them decides.
# Used by the audit (t_reach.rb), the walkthrough planner (world_route.rb) and
# the build's area linking (build_geo.rb), so all three agree with the game.
module BridgeLib
  TAG = 15

  module_function

  # The bridge tile at (x, y), or nil
  def tile(ts, m, x, y)
    [2, 1, 0].each do |z|
      t = m.data[x, y, z]
      return t if t && t > 0 && ts.terrain_tags[t] == TAG
    end
    nil
  end

  # {[x, y] => 1 (BridgeOn) or 0 (BridgeOff)} for a map's switch events
  def switches(m)
    sw = {}
    m.events.each_value do |e|
      txt = e.name + ' ' + e.pages.flat_map { |pg| pg.list.select { |c| [355, 655].include?(c.code) }.map { |c| c.parameters[0].to_s } }.join(' ')
      if txt =~ /BridgeOn/ then sw[[e.x, e.y]] = 1
      elsif txt =~ /BridgeOff/ then sw[[e.x, e.y]] = 0
      end
    end
    sw
  end

  # Up on a bridge: whether the bridge tile at (x, y) lets the player leave it
  # (or enter it) in direction d. nil when there's no bridge tile there or the
  # player is down (the usual rules apply).
  def side_ok(ts, m, x, y, d, level)
    return nil if level == 0
    t = tile(ts, m, x, y) or return nil
    pass = ts.passages[t]
    pass & (1 << (d / 2 - 1)) == 0 && pass & 0x0f != 0x0f
  end

  # Level after stepping onto (x, y): a switch there sets it; otherwise the
  # player comes down on land with no bridge tile on or beside it (FullPoke's
  # bridge reset in 090_World.rb)
  def level_after(ts, m, sw, x, y, level)
    return sw[[x, y]] if sw.key?([x, y])
    return level if level == 0
    near = [[0, 0], [0, 1], [0, -1], [1, 0], [-1, 0]].any? do |dx, dy|
      nx, ny = x + dx, y + dy
      nx >= 0 && ny >= 0 && nx < m.width && ny < m.height && tile(ts, m, nx, ny)
    end
    near ? 1 : 0
  end

  # Level on arriving at (x, y) on another map (an edge or a warp): up only if
  # the player was up and lands on a bridge tile
  def arrival_level(ts, m, x, y, level) = level == 1 && tile(ts, m, x, y) ? 1 : 0
end
