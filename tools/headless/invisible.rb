# A fully transparent tile no map draws, per tileset (found by
# invisible_tiles.rb). build_world.rb makes it solid, so it walls off what the
# player shouldn't walk on without showing anything; t_reach.rb SEAL=1 puts it
# on the small pockets nothing reaches.
INVISIBLE_TILES = { 1 => 897, 2 => 802, 3 => 1115, 6 => 486, 7 => 1181, 23 => 1115, 26 => 897, 27 => 445, 28 => 897,
                    29 => 417, 30 => 723, 31 => 532, 32 => 386 }.freeze
