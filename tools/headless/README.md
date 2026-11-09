# Headless test harness

These tools run FullPoke's real Pokémon Essentials v21.1 scripts (from
`Data/Scripts.rxdata`) under Ruby 3.1 without a window, using small stand-ins for
the mkxp-z/RGSS classes (graphics, audio, input). That makes it possible to
compile the PBS files, convert/repair map events and play scripted sessions
(new game → Boulder Badge) on any machine with Docker, including CI.

**Don't ship this folder with the game.** RPG Maker XP and Game.exe ignore it.

## What it can and can't tell you

It executes the same Ruby game logic Game.exe does: the compiler, event
interpreter, map/movement/passability code, battles (with the AI choosing moves
for the player), menus, saving and loading. It does **not** draw anything, play
sound or read a keyboard. Image files are checked to exist and their sizes are
read, but nothing is rendered. So a passing run means "no crashes, the story
flags/warps/battles work"; it doesn't mean "it looks and sounds right". Check
that in Game.exe.

## Usage

Everything runs in the official `ruby:3.1-slim` Docker image (the same Ruby
version as the game's `x64-msvcrt-ruby310.dll`). Run from the repo root:

```bash
tools/headless/run.sh t_compile.rb          # compile PBS -> Data/*.dat (as Debug mode does)
tools/headless/run.sh t_validate_maps.rb    # load every map; report bad warps/graphics/scripts
tools/headless/run.sh t_assets.rb           # sprites/cries/icons/battlebacks coverage
tools/headless/run.sh t_connections.rb      # map connection geometry
tools/headless/run.sh t_journey.rb          # play: new game -> Pokédex -> Brock -> save/load
tools/headless/run.sh t_ui.rb               # open every menu screen + real battle scene
HEADLESS_DEBUG=0 tools/headless/run.sh t_release.rb   # boot like a player (no Debug)
tools/headless/run.sh t_systems.rb          # regions/modes/levels/scaling/teams/forest pool (no walking)
tools/headless/run.sh t_journey9.rb         # simulated nine-region journey (ORDER=kanto:c,johto:i,...)
REGIONS=johto MODE=continuous tools/headless/run.sh t_geo.rb       # walk a real-map region on foot: gate -> Gyms -> League
REGIONS=johto MODE=independent tools/headless/run.sh t_balance.rb  # play its battles with no level boosts
REGIONS=sinnoh MODE=continuous PRIOR=kanto,johto,hoenn tools/headless/run.sh t_balance.rb
MODE=continuous tools/headless/run.sh t_kanto.rb   # Kanto Gyms 2-8, Route 23, Victory Road, League
tools/headless/run.sh t_kanto_reach.rb             # every Kanto location reachable at the right point
tools/headless/run.sh t_kanto_story.rb             # S.S. Anne, Pokémon Tower, Rocket Hideout, Silph Co., Snorlax
tools/headless/run.sh t_reach.rb 23 13 9 33 292   # which maps are reachable on foot from Pallet Town
RULES=johto:3 SURF=1 tools/headless/run.sh t_reach.rb 7 11 25 85 90   # ... with 3 Johto badges, surfing
GRID=59 tools/headless/run.sh t_reach.rb 7 11 25 59                  # print which tiles of map 59 were reached
```

Tests walk between maps with `world_route.rb` (`travel_to(map, x, y)`): it
plans over walkable tiles, map connections, warps and water (surfing when the
party can) and avoids areas whose badge requirement isn't met yet.

The world (Interregional Forest; Johto from the map pack's real maps; Kalos,
Alola, Galar and Unova generated as separate maps; the old one-route-per-Gym
circuits for regions without either; the Kanto story and League hookup; the
New Game region choice) is built by:

```bash
tools/headless/run.sh build_world.rb   # rebuild generated maps (IDs kept in world_ids.json)
tools/headless/run.sh t_compile.rb     # then recompile (map metadata/connections)
```

It only replaces maps it generated and events named `FP: ...` on map-pack
maps, so it's safe to re-run. Edit the builder or the region data in
`Plugins/FullPoke Core/1xx_Data_*.rb`, not the generated maps.

- **Real-map regions** are described in `geo/<region>.rb`: which maps border
  which (offsets are found automatically from the open ground on the shared
  edge, `offsets:` overrides them), gatehouse and cave warps, each town's
  doors (snapped to the building front), level bands, badge requirements and
  story battles. `build_geo.rb` turns that into connections, doors and
  generated interiors, Gyms, trainers, wild Pokémon and the League.
- **Generated regions** are described in `plans/<region>.rb` (the real
  locations in order); `gen_region.rb` draws each place as its own map and
  hands a spec to the same builder. It writes `geo/gen_<region>.rb` for the
  tests.
- **Tilesets** are rebuilt every run from `data/Tilesets_base.rxdata` (the map
  pack's tilesets plus the Kanto passability fixes): untagged tall grass is
  tagged, the cave tileset's black filler is made solid, and building tiles
  the pack left walkable are made solid (tiles Kanto uses are left alone).

Finding coordinates for a geo spec: `render.sh <map> [x y w h scale]` for a
picture, `rb.sh pass_grid.rb <map> x y w h` for a walkability grid, and
`rb.sh geo_probe.rb <region>` for the automatic edge offsets and each map's
open edges.

`t_compile.rb` rewrites `Data/*.dat` and may re-save maps (the compiler upgrades
old-style door/trainer events). It also re-saves `Data/Tilesets.rxdata` and
`Data/PkmnAnimations.rxdata` with identical content; discard those two with
`git checkout` if nothing in them changed.

Data inspection tools (no game scripts needed):

```bash
tools/headless/rb.sh dump_events.rb /game/Data 23     # Pallet Town's events, readable
tools/headless/rb.sh warps.rb /game/Data 173 181       # warps and where they lead
tools/headless/rb.sh warp_pairs.rb /game/Data          # warps with no way back (report)
tools/headless/rb.sh switch_usage.rb /game/Data        # every switch/variable events use
docker build -t fullpoke-ruby tools/headless/docker && tools/headless/render.sh 175
```

`render.sh` writes PNGs to `tools/headless/renders/` (git-ignored); with
`PASS=1` it marks blocked tiles (red X) and counter tiles (orange).

## Files

| File | Purpose |
| --- | --- |
| `boot.rb`, `rgss_stubs.rb`, `rpg_classes.rb` | Load the game scripts headlessly; RGSS1 data classes that Marshal-load/save maps byte-compatibly |
| `play_lib.rb`, `battle_trace.rb` | Drive Scene_Map frame by frame: pathfinding, doors, choices, battles with the AI on both sides |
| `event_builder.rb`, `build_kanto_opening.rb` | DSL over the v21 compiler's `push_*` helpers; builds the Kanto opening (re-runnable: replaces `FP:` events) |
| `t_*.rb` | Checks and playthrough tests listed above |
| `convert_pbs.rb`, `convert_events.rb`, `remap_*.rb`, `fix_*.rb`, `warp_pairs.rb`, `warp_mutual.rb`, `patch_*.rb` | The one-time v18 → v21 migration steps, kept for reference and re-use on newly imported maps |
| `render_map.rb`, `dump_events.rb`, `warps.rb`, `switch_usage.rb`, `extract_scripts.rb`, `map_tree.rb`, `tile_stats.rb`, `room_at.rb` | Inspection |
| `world_lib.rb`, `build_world.rb`, `world_ids.json` | The generated world (see above) |
| `build_geo.rb`, `geo_lib.rb`, `geo/*.rb` | Regions built from the map pack's real maps |
| `gen_region.rb`, `plans/*.rb` | Regions generated as separate maps in their real order |
| `kanto_story.rb`, `fix_tileset_passability.rb`, `t_kanto_*.rb` | Kanto story events, the cave tileset fix, their tests |
| `world_route.rb` | Multi-map routing for tests |
| `pass_grid.rb`, `geo_probe.rb`, `room_list.rb` | Inspection for geo specs |
| `test_lib.rb` | `check`/`section`/`on_map` helpers for the newer tests; evolution without the animation |

`build_kanto_opening.rb` overwrites the events it owns (names starting `FP:` in
Oak's Lab, Oak's two "stop the player" events in Pallet Town, and the intro's
picture/flag commands). If you edit those in RPG Maker XP, don't re-run it.
