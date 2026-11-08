# FullPoke: project status

_Last updated 2026-11-08._

> **The nine-region game (Interregional Forest, play modes, level scaling,
> region circuits, Gen 9 status) is tracked in
> [FULL_GAME_ROADMAP.md](FULL_GAME_ROADMAP.md).** This document covers the
> engine migration, the Kanto opening and the map-pack cleanup.

FullPoke runs on **Pokémon Essentials v21.1** (mkxp-z `Game.exe`, Ruby 3.1).
The maps come from an all-regions map pack built for Essentials v18. This
document records what was broken, what works now and how that was checked, and
what's left, in priority order.

## Where things stand

You can now play the opening from a new game through the first Gym:

> intro (name yourself and your rival) → Pallet Town → Oak stops you at the
> tall grass → Oak's Lab: choose Bulbasaur, Charmander or Squirtle → rival
> battle → Route 1 → Viridian City Mart (Oak's Parcel) → back to Oak (Pokédex
> + 5 Poké Balls) → Route 2 → Viridian Forest (Bug Catchers) → Pewter City
> Pokémon Center → Pewter Gym → **Brock (Boulder Badge)**

After Brock, Kanto's Gyms 2–8, the Indigo Plateau and the League are now
playable (see FULL_GAME_ROADMAP.md, milestone 6); Kanto's mid-game story
events still aren't built.

## What was broken and what was done

| Problem | Effect | Fix |
| --- | --- | --- |
| Commit `2ebedbc2` copied a v18 project over the v21.1 base: v18 `Scripts.rxdata` on the v21 runtime | **Game couldn't start** | Restored the v21.1 scripts |
| 11 PBS files in v18 format, plus stale v18 `.dat` files | **v21 compiler failed at `types.txt`**; release builds would load v18 data | v21.1 data for types/abilities/moves/items/pokemon/phone; converted encounters, trainers and 54 custom trainer types; wrote v21 `metadata.txt`; recompiled every `.dat`. v18 files kept in `PBS/_archive_v18/` |
| Data errors in the converted/user files | Compile errors | 5 species typos (`TENACRUEL`, `LEYBA`, …), Route 35 defined twice, Mr. Mime/Chansey/Sudowoodo listed twice in the dexes (folded the babies into their families' lines) |
| No starter Pokémon anywhere; Oak's event warped to Dragon's Den and depended on script switches | **Story couldn't progress** | Built the opening (Oak's Lab, starters, rival battle, parcel → Pokédex), using the map pack's existing parcel/rival flags |
| v18 event syntax (`PBItems::`, `PBTrainers::`, `pbTrainerBattle`, `$Trainer`, …) | Script errors | Converted, then ran v21's own event updater over all 911 maps |
| 83 warps pointing at the wrong map ID (map-pack numbering) | Doors leading to other regions, or off the map | Repaired by pairing each warp with the warp that leads back (e.g. Viridian Mart, Viridian Forest gates, Pewter buildings, Rock Tunnel ↔ Route 10) |
| Door exit pages on switch 12 ("Defeated Elite Four") | Door step-out animation never played | Moved to `s:tsOff?("A")`; v21 rebuilt them as standard doors (87 doors) |
| Nurses on switch 5/3 | Beating Gym 2 would be undone at the next Pokémon Center; no healing after a blackout | Moved to v21's switches 1/2 (12 nurses) |
| 19 trainer events missing the `Battle:` colon | **Trainers re-battled forever** | Fixed; the v21 compiler now generates proper two-page trainer events |
| 22 NPC charsets that don't exist | Invisible nurses, clerks, Brock, Misty, Oak, rival… | Pointed at existing graphics for the same role |
| Numbered v18 trainer sprites (`trainer039.png`) | Custom trainer types had no battle sprite | Copied to v21 names (`KANTOLEADER_Brock.png`) |
| Town Map images were the Essentials demo region | Wrong Town Map | Installed the project's region maps 0–7 |
| `BattleBack = cave` (doesn't exist), Pokédex names for only 2 of 8 dexes, healing jingle name | Black battle background / missing dex names / silent heal | Fixed |
| 10 warps whose destination doesn't exist and can't be inferred | Player stranded off-map | `Plugins/FullPoke Core` blocks them with "This way isn't finished yet." (Debug console names the event) |

## How it was verified

There's no Windows or RPG Maker XP here, so everything was checked by running
the game's own v21.1 scripts headlessly (`tools/headless/`, see its README).
That runs the real compiler, interpreter, movement, battles, menus and save code,
but draws nothing and plays no sound.

| Check | Result |
| --- | --- |
| Compile all PBS + process all 911 maps (Debug-mode compile) | Passes |
| Boot as a player would (no Debug): splash → title → New Game → intro | Passes, using only the shipped `.dat` files and plugin |
| Play new game → Boulder Badge → save → load (`t_journey.rb`) | Passes (repeated runs). The AI picks moves for the player; the test raises the starter's level after the lab so the AI reliably wins. That's a test setting, not a game change. |
| Every map loads; all event scripts parse | No crashes on any of the 911 maps |
| Menus: party, summary, bag, Pokédex, Town Map, trainer card, PC boxes, options, Poké Mart, evolution | All open, navigate and close without errors |
| Wild and trainer battle with the real battle scene (sprites, databoxes, move animations) | Pass |
| Sprites: all 1,237 species/forms (Gen 1–8) have front, back and icon graphics | Pass |

## What needs Windows / RPG Maker XP testing

The headless runs can't check these. Do them once on Windows:

1. **Open the project in RPG Maker XP** and open a few maps (Pallet Town 23,
   Oak's Lab 175, Viridian 173). The maps were re-saved by the Ruby 3.1
   compiler, the same way Essentials' own compiler re-saves them. They should
   look identical. Save in RMXP once and confirm nothing changes.
2. **Playtest from RMXP (Debug)**. The first run may recompile (the console
   says "Compiling PBS file…"). That's expected.
3. **Run Game.exe directly (no Debug)**: title screen, text, fonts, window
   scaling, music/SFX.
4. **Play the opening** and look for anything visual: intro picture placement
   (Oak/Marill/boy/girl portraits), Oak walking up to you in Pallet Town, the
   three Poké Balls on the lab table and where Oak and your rival stand, door
   animations, battle backgrounds.
5. **Wild encounter rates**. v18 densities were converted to v21 step chances
   (Land 21, Cave 5, Water 2 for the default density). Adjust if they feel off.

## Remaining work (priority order)

### 1. Story and content (game progression)
- **Kanto's story after Brock** (S.S. Anne, Pokémon Tower, Silph Co., Snorlax,
  Safari Zone) has no events. Gyms 2–8 and the League now work (see the
  roadmap). `trainers.txt` has the
  early-route trainers, Brock and the rival only. Several map-pack events are
  marked `INCOMPLETE EVENT` (the Route 22 rival rematch; the Cerulean rival
  battle uses the Route 22 party).
- **Other regions have no story.** Of 911 maps, 79 have any events, 268 are
  layouts with no events, and 564 are empty placeholders (folders and
  unfinished maps). Only 51 maps have wild encounter tables (Kanto routes and
  some Johto).
- **Generation 9 isn't in the game.** Essentials v21.1 includes Gen 1–8 (898
  species). The standard way to add Gen 9 is the community *Generation 9 Pack*
  plugin for v21.1 (it needs the *Deluxe Battle Kit*). It adds the Paldea
  species, forms, moves, abilities, items and graphics. After installing, add a
  `[8]` Paldea dex to `regional_dexes.txt` and `Settings.pokedex_names`. The map
  pack has no Paldea or Hisui maps.
- `map_metadata.txt`'s `HealingSpot` TODO (your note) is still open. Kanto
  Pokémon Centers all share map 182, so use town-side coordinates.

### 2. Data cleanup from the map pack
- **10 unfinished warps** (blocked by the plugin): Indigo Plateau → map 285,
  two in the Indigo Marts → map 16, the Route 7/12 gatehouses on map 12, the
  Underground Path exit, Rock Tunnel's ev 5, and Kanto Town Interiors ev 64.
  Run `tools/headless/run.sh t_validate_maps.rb` for the list.
- **Map connections:** 171 connections whose edges never touch (offsets past
  the map size), 8 to empty folder maps, and some overlapping neighbours (e.g.
  Routes 26/27 on Route 28). Run `t_connections.rb` for the list.
- The Mart exit on map 181 event 9 picks its destination from Variable 51, and
  those branches lead to Ferrum maps (312–316).
- Saffron-area gatehouses (map 12 ↔ Routes 5–8): both directions point at
  wrong maps, so they couldn't be repaired automatically.

### 3. Missing assets (non-fatal: silent or placeholder)
- **48 map BGM tracks** aren't in `Audio/BGM` (the `REG0_*` Kanto set and the
  numbered HGSS Johto set, e.g. `REG0_22_PalletTown`, `004 New Bark Town`).
  Those maps play no music until the files are added under those names.
- 413 Pokémon cries (Gen 6–8), 177 item icons (placeholder icon), 14 door
  charsets (doors work, the opening animation isn't visible), 2 location-sign
  pictures (Viridian Forest, Mt. Moon), and a Johto Poké Fan sprite (Poké
  Maniac used as a stand-in). The trainer types `COOLCOUPLE`, `CRUSHKIN`,
  `SISANDBRO` and `TEAMROCKET_PETREL` have no overworld charset.
- Town Map: check Pallet Town's position (`MapPosition = 0,6,14`). On the Kanto
  image Pallet looks to be at about (6,18).
- Pokémon Center counters: part of the counter is walkable in the tileset's
  passability settings.

## Reference: story switches and variables

| ID | Name | Set by → read by |
| --- | --- | --- |
| Switch 1 | Starting over | v21 blackout → nurse's heal page |
| Switch 22 | `s:tsOff?("A")` | door step-out pages |
| Switch 38 | Kanto: Carrying Oak's Parcel | Viridian Mart → Oak, Route 22 rival |
| Switches 40/41/42 | Kanto: Chose Bulbasaur/Charmander/Squirtle | lab → rival's party in Route 22 battle |
| Switch 44 | Kanto: Parcel errand (Mart clerk) | lab → Viridian Mart clerk, Route 22 rival |
| Switch 61 | Kanto: Oak stops player | intro → Pallet Town north exit |
| Switch 62 | Kanto: Oak walking in Pallet | Oak's sprite in Pallet Town |
| Switch 63 | Kanto: Oak's Lab scene | arrival scene in the lab |
| Switch 64 | Kanto: Choosing starter | starter balls, Oak, rival in the lab |
| Switch 65 | Kanto: Has starter | Oak's later dialogue |
| Switch 66 | Kanto: Rival lab battle done | rival leaves the lab |
| Switch 68 | Kanto: Has Pokédex | |
| Variable 27 | Kanto: Rival name | intro name entry; `\v[27]` in text; trainer types `KANTORIVAL1/2` show this name (`Settings::RIVAL_NAMES`) |
| Variable 43 | (map pack) party size for the healing machine | nurses |
| Variable 52 | (map pack) set after Brock | skips the Route 22 rival rematch |

Rival parties are `[KANTORIVAL1,RIVAL,1-3]` (lab, level 5) and `[…,4-6]`
(Route 22). The rival always has the starter strong against yours.

## Adding content safely

- Write event scripts in v21 syntax (`TrainerBattle.start(:TYPE, "Name")`,
  `pbReceiveItem(:POTION)`, `$player`, `$bag`). v18 syntax won't run.
- Trainer events: name them `Trainer(N)` (N = sight range) and use comments
  `Battle: …`, `Type: …`, `Name: …`, `EndBattle: …`. The compiler builds the
  rest. Note the colon after `Battle`.
- When bringing over more maps from the pack, run
  `tools/headless/rb.sh warp_pairs.rb /game/Data` and the `remap_*` tools.
  The pack's map IDs and switch numbers don't match this project.
- After editing PBS files, playtest from RMXP (Debug) or run
  `tools/headless/run.sh t_compile.rb` so `Data/*.dat` is regenerated. A
  release build only reads the `.dat` files.
