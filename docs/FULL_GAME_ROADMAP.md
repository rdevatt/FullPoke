# FullPoke: full game roadmap

_Last updated 2026-11-08. Companion to [PROJECT_STATUS.md](PROJECT_STATUS.md)
(engine migration, Kanto opening, Windows checklist)._

Status words used below:

- **Done, tested**: implemented and covered by a headless test that passes.
- **Done, untested**: implemented, but no automated test covers it.
- **Partial**: works, with stated gaps.
- **Missing**: not built yet.

"Tested" always means the headless harness (`tools/headless/`), which runs the
game's real scripts with no graphics or sound. Nothing here has been
playtested in Game.exe or opened in RPG Maker XP yet; see
[What needs Windows](#what-needs-windows--rpg-maker-xp).

## How the game is put together

```
New game -> intro -> choose a starting region + mode
                         |
        Interregional Forest (9 maps, 9 gates)  <-- Grove Compass from anywhere
          |      |      |      |      |      |      |      |      |
        Kanto  Johto  Hoenn  Sinnoh Unova  Kalos  Alola  Galar  Paldea
        (map-pack maps) (generated "circuit" per region)       (needs Gen 9)
```

| Piece | Where |
| --- | --- |
| Region data, modes, offsets, scaling, teams, forest pool, gates | `Plugins/FullPoke Core/*.rb` |
| Each region's Gym Leaders, Elite Four, Champion, rivals, villains | `100_Data_Kanto.rb`, `110_Data_Regions.rb` |
| Generated maps (forest, circuits, Kanto League hookup) | built by `tools/headless/build_world.rb`; IDs in `tools/headless/world_ids.json`; world data in `091_World_Generated.rb` |
| Tests | `tools/headless/t_systems.rb`, `t_regions.rb`, `t_journey9.rb`, `t_reach.rb`, plus the earlier ones |

## Milestones

### 1. Progression and mode selection: done, tested
- Per-region state (mode, offset, baseline, continuous index, max level,
  completion order, starter, story flags, badges) saved in the save file as
  `:fullpoke_progress`.
- Mode is chosen at the forest gate (or at New Game) and can never change.
- Each region counts as completed once, only when its final battle is won.
- Independent adventures get their own party, PC boxes, bag and Day Care.
  These swap in automatically on entering the region's maps. Pokémon from
  outside the regional Pokédex go to the main PC instead.
  - On completion everything merges into the main set; nothing is copied or
    lost (`FullPoke.duplicate_pokemon` checks this).
- Badges are kept per region (32 slots each, Kanto keeps 0–7). Field-move and
  badge checks inside a region count only that region's badges.
- Blacking out returns you to the region you're in.
- `t_systems.rb` (170 checks): all of the above, plus save/load of party sets.

### 2. Levels above 100 and scaling: done, tested
- Levels go up to 999. Independent adventures keep the traditional cap of 100.
- Experience curves:
  - Every growth rate continues past 100 with its own formula.
  - Essentials' Fluctuating formula was wrong above 100 and is replaced.
  - All six curves are checked to rise strictly up to level 999.
- Continuous offset is the highest level reached in the most recently
  completed continuous region, minus 5. It's fixed when the region begins.
  Independent completions never change it.
- Every wild Pokémon, trainer, Gym Leader, Totem/Titan and legendary in a
  continuous region gets the offset. Pokémon are evolved to suit the scaled
  level; the forest's rare Pokémon keep their species.
- Experience pacing: in a scaled region, experience is converted so a level
  takes about as many battles as it would unscaled. Without this, the player
  would fall far behind past level 100.
- Tested at levels 5, 70, 80, 130, 200, 350, 500, 650 and 999:
  - Stats, moves and saving work at every level.
  - Battles at 130 through 998 run to a result.
  - The design's examples check out exactly: 2→67, 3→68, 8→73, 15→80, 65→130,
    30→95 and 50→115.

### 3. Interregional Forest: done, tested
- Nine 48×42 maps in a 3×3 grid, joined seamlessly. Each has winding maze
  paths with loops, Cut-tree shortcuts, tall grass, a named landmark, hidden
  items, item balls and two trainers.
- The center, the Heart Clearing, has a Ranger who heals and a PC.
- Nine gates, each signposted, lead to Pallet Town, New Bark Town, Littleroot
  Town, Twinleaf Town, Nuvema Town, Vaniville Town, Iki Town (Melemele), Postwick
  and Cabo Poco.
  - Every region has a gate back: Pallet Town for Kanto, otherwise its start
    town.
  - The Grove Compass key item returns you to your region's gate from anywhere.
- `t_reach.rb` confirms the forest and Pallet Town connect on foot.
  `t_regions.rb` uses the gates in both directions.

### 4. Rare forest Pokémon: done, tested
- The pool is worked out from the real encounter tables of completed regions'
  maps, with a species' slots summed per location and method; 5% or less
  counts as rare.
- Before any region is completed there are no wild Pokémon.
- Each species has at most 5% per encounter chance, and all together at most
  50%; the rest of the time nothing appears.
- Grass draws from land and cave rares; water and fishing draw from water
  rares.
- `t_systems.rb` checks that common species are excluded and that species
  from uncompleted regions are absent. It also checks there are no duplicates
  and that the per-species share stays at or under 5% over 20,000 samples.
- The rule is applied literally: a species counts as rare in a region if any
  one location/method gives it 5% or less. So Pidgey qualifies from Kanto,
  because it's a 5% slot on one route even though it's common on Route 1.
  Ask if you'd rather require "rare everywhere".

### 5. Stronger teams: done, tested
- From the second continuous region on, the enhanced teams are:
  - Gym Leaders (and kahunas, trial captains, Galar and Paldea leaders): exactly
    5 fully evolved Pokémon of their type.
  - Elite Four, Champions, villains and late rivals: 6 Pokémon.
- Enhanced teams also get:
  - The leader's signature line where its final form keeps the type.
  - Competitive moves: STAB, coverage and a setup or support move.
  - The best-rated ability, held items, rising IVs and EVs, and the AI's best
    skill.
- Later Gyms and later regions draw stronger species.
- Independent mode and the first continuous region keep the traditional teams.

### 6. Kanto: partial
- The opening through Brock works and is tested (`t_journey.rb`).
- Gyms 2–8 now have Leader events in the map pack's Gym rooms (Misty through
  Giovanni) with FireRed/LeafGreen teams.
- The League:
  - Route 23 has a gate that needs all 8 badges and leads to the Indigo
    Plateau.
  - The Plateau's door now leads to the map pack's own League map, with
    Lorelei, Bruno, Agatha, Lance and the rival as Champion.
  - Beating the Champion completes Kanto.
- Mewtwo appears after completion (Cerulean City).
- The rival and Team Rocket battles are optional: Cerulean, Vermilion,
  Celadon, Saffron and Route 22.
- On foot from Pallet Town, `t_reach.rb` reaches all eight Gym towns and the
  League.
- **Gaps:**
  - Lavender Town, Rock Tunnel, Routes 12–14, 17 and 20, and Victory Road can't
    be reached (broken map-pack warps). Route 23 skips Victory Road.
  - The story beats in between (S.S. Anne, Pokémon Tower, Silph Co., Snorlax,
    Safari Zone) have no events.
  - Gyms 2–8 have no Gym trainers.

### 7. The other eight regions: partial (playable circuits)
Johto through Galar have each been played start to finish by `t_regions.rb`
(see Testing). Each region is a complete circuit:

- **Start town:** forest gate, home, the professor's starter choice and the
  first rival battle.
- **8 stages**, each a route plus a town:
  - **Route:** 3 trainers, tall grass with wild Pokémon from the regional
    Pokédex, an item and a hidden item.
  - **Town:**
    - A Poké Center with a nurse, PC and shop.
    - A Gym with 2 Gym trainers and the Leader.
    - Story battles: rival and villain.
- **Victory Road:** trainers, the last rival battle, and the region's
  legendary after completion.
- **League:** 4 Elite Four rooms, then the Champion.

| Region | Start town | Challenges | Final | Status |
| --- | --- | --- | --- | --- |
| Johto | New Bark Town (map-pack layout) | 8 Gyms (Falkner–Clair), rival ×4, Archer | Will, Koga, Bruno, Karen → Lance; Ho-Oh | built |
| Hoenn | Littleroot Town (map-pack layout) | 8 Gyms (Roxanne–Juan), rival ×3, Maxie | Sidney, Phoebe, Glacia, Drake → Steven; Rayquaza | built |
| Sinnoh | Twinleaf Town (map-pack layout) | 8 Gyms (Roark–Volkner), rival ×3, Cyrus | Aaron, Bertha, Flint, Lucian → Cynthia; Giratina | built |
| Unova | Nuvema Town (map-pack layout) | 8 Gyms (Cilan–Drayden), rival ×3, Ghetsis | Shauntal, Grimsley, Caitlin, Marshal → Iris; Reshiram | built |
| Kalos | Vaniville Town | 8 Gyms (Viola–Wulfric), rival ×3, Lysandre | Malva, Siebold, Wikstrom, Drasna → Diantha; Xerneas | built |
| Alola | Iki Town | 4 island trials with Totems (Ilima, Lana, Kiawe, Mallow, Acerola) and the kahunas' grand trials (Hala, Olivia, Nanu); rival ×3, Guzma | Hala, Olivia, Acerola, Kahili → Kukui; Solgaleo | built |
| Galar | Postwick | 8 Gyms (Milo–Raihan), Hop ×3, Chairman Rose | Champion Cup: Marnie, Bede, Hop, Raihan → Leon; Zacian | built |
| Paldea | Cabo Poco | Victory Road (8 Gyms) + Path of Legends (5 Titans) + Starfall Street (5 Team Star bosses) | Rika, Poppy, Larry, Hassel → Geeta, then Nemona (needs all three stories); Koraidon | built, **locked until Gen 9 data is installed** |

**Gaps in the circuits:**

- **Generated layouts:**
  - The circuits use generated maps built from Kanto tile art, not the regions'
    real geography.
  - Towns are named after the real ones. They reuse the map pack's empty
    placeholder maps where those exist (Kalos, Alola, Galar, part of Unova);
    otherwise they're new maps (IDs 909–972).
  - The map pack's hand-made Johto, Hoenn and Sinnoh town and route layouts are
    kept untouched but aren't part of the circuit yet. Their warps and map
    connections are broken, and their building art can't be recognized
    automatically.
- **Simplified content:**
  - One route per Gym.
  - No HM obstacles, side areas, caves, water routes or fishing spots.
  - No Battle Frontier or other postgame beyond the legendary.
- **Placeholder art:**
  - The new characters use generic trainer classes and sprites (Gym Leader,
    Elite Four, Champion, Kahuna…). They're told apart by name only.
  - Per-character battle sprites and overworld sprites are missing.

### 8. Testing: done for everything but Paldea (headless)
| Test | What it covers | Result |
| --- | --- | --- |
| `t_compile.rb` | PBS + plugin compile | pass |
| `t_systems.rb` | milestones 1, 2, 4, 5 (levels to 999, offsets, isolation, enhanced teams, forest pool, save/load) | 170/170 |
| `t_regions.rb` | walks a whole region on foot: forest gate → mode → professor/starter/rival → 8 stages (route trainers, story battles, Gym trainers, Leader/Totem) → Victory Road → 4 Elite Four rooms → Champion → completion → Hall of Fame → home | **27/27 for each of Johto (continuous), Hoenn (independent), Sinnoh (continuous), Unova (independent), Kalos (independent), Alola (continuous), Galar (independent)** |
| `t_kanto.rb` | Kanto Gyms 2–8 through the real Gym doors, Route 23 → Indigo Plateau → Elite Four → Champion → Hall of Fame | 23/23 in continuous and in independent mode |
| `t_newgame.rb` | New Game → intro → choose region and mode → that region's first town, right party set | pass for all 7 generated regions (Kanto via `t_release.rb`) |
| `t_journey9.rb` | all nine regions in a mixed order and modes: offsets (0 → 63 → 113 → 175 → 234 → 292 …), wild/trainer scaling, team rules, a real Champion battle per region (up to level 357), forest unlocks, completion counting, no duplicates, save/load after each region; Paldea locked | 213/213 |
| `t_reach.rb` | on-foot reachability audit | all 8 Kanto Gym towns + Indigo Plateau + League reachable from Pallet Town |
| `t_journey.rb`, `t_ui.rb`, `t_release.rb` | Kanto opening → Boulder Badge → save/load; every menu and the real battle scene; release-mode boot | pass |

The tests let the AI play the player's side and raise the team's level before
big battles. That's a test setting; game balance hasn't been playtested.

## Generation 9

The community **Generation 9 Pack** (v3.3.8) and Maruno's **v21.1 Hotfixes**
plugin (which it requires) were downloaded and unpacked. The installation
(plugins, PBS data, sprites, cries) is kept in a git stash:
`stash@{0}: Gen 9 Pack 3.3.8 + v21.1 Hotfixes install`.

It isn't applied because running third-party plugin code needs your
approval. Nothing from it has been executed. To install:

1. Review `Plugins/Generation 9 Pack Scripts` and `Plugins/v21.1 Hotfixes`
   from the stash.
2. Run `git stash pop`. If the pop reports conflicts in generated files (for
   example `Data/*.dat`), keep the current version.
3. Run `tools/headless/run.sh t_compile.rb`.
4. Add a `[8]` Paldea dex to `PBS/regional_dexes.txt` and to
   `Settings.pokedex_names`.

Paldea then unlocks automatically: its forest gate, starters, trainers and
encounters already exist. The stash uses the vanilla PBS files with Gen 9
updates (Oak's Parcel, Joe's Mail and the Grove Compass need re-adding to
`items.txt` if the pop conflicts) and only adds new sprites. Existing Gen 1–8
sprites are kept. The pack's `CHAMPIONS_MECHANICS` setting is switched off.

## What needs Windows / RPG Maker XP

1. Open the project in RPG Maker XP. The map tree has a new **Interregional
   Forest** folder and a **Paldea Region** folder. The circuit maps are under
   each region (the Kalos, Alola, Galar and Unova placeholders now have
   content). Check that the maps open and look right.
2. In Game.exe, look at the generated maps:
   - Tree edges in the forest. The generator uses Viridian Forest's tree
     pattern; seams are possible where tree blocks meet.
   - Building placement in towns.
   - Gym and League rooms.
3. Placeholder trainer art: the FP_* trainer types reuse generic sprites.
4. Large numbers: databoxes and the summary screen at levels 100–999, and HP
   above 1,000.
5. Feel and balance:
   - Continuous offsets and experience pacing.
   - The forest's encounter rate.
   - Enhanced teams (whether 5-Pokémon Gyms are fun rather than walls).

## Next steps (priority)
1. Install the Gen 9 pack (needs your approval), then play Paldea through.
2. Kanto: repair Lavender, Rock Tunnel and Victory Road links; build the story
   events (S.S. Anne, Pokémon Tower, Silph Co.); add Gym trainers.
3. Move the circuits onto the map pack's real Johto, Hoenn and Sinnoh layouts
   by placing doors and links by hand.
4. Per-character trainer sprites and overworld graphics.
5. Water, cave and fishing encounters in the circuits. Kanto and Johto's
   map-pack maps have them; the generated circuits only have tall grass.
6. The trainer card shows Kanto's eight badges only; make it show the
   current region's.
7. More postgame: rematches, Battle Frontier-style facilities.
