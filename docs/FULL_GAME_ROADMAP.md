# FullPoke: full game roadmap

_Last updated 2026-11-08. Companion to [PROJECT_STATUS.md](PROJECT_STATUS.md)
(engine migration, Kanto opening) and [GEN9_INTEGRATION.md](GEN9_INTEGRATION.md)
(the Generation 9 review and install plan)._

Status words used below:

- **Done, tested**: implemented and covered by a headless test that passes.
- **Done, untested**: implemented, but no automated test covers it.
- **Partial**: works, with stated gaps.
- **Missing**: not built yet.

"Tested" means the headless harness (`tools/headless/`), which runs the
game's real scripts with no graphics or sound, unless a section says the real
Game.exe was used. What was checked in Game.exe is listed under
[Windows](#windows-gameexe).

## How the game is put together

```
New game -> intro -> choose a starting region + mode
                         |
        Interregional Forest (9 maps, 9 gates)  <-- Grove Compass from outdoors
          |      |      |      |      |      |      |      |      |
        Kanto  Johto  Hoenn  Sinnoh Unova  Kalos  Alola  Galar  Paldea
```

The regions are built in three ways:

| Kind | Regions | How |
| --- | --- | --- |
| **Map pack maps with story** | Kanto | The pack's FireRed/LeafGreen-style maps, repaired, with story events (`kanto_story.rb`, plugin 105). |
| **Map pack maps, wired** | Johto | The pack's HeartGold/SoulSilver-style maps, connected and populated from `tools/headless/geo/johto.rb` by `build_geo.rb`. |
| **Generated, real layout** | Kalos, Alola, Galar, Unova, Paldea | Every real location is its own generated map, joined in the real order (`plans/<region>.rb`, `gen_region.rb`), then populated by the same builder. |
| **Map pack maps, wired** | Hoenn | The pack's Hoenn maps, wired from `geo/hoenn.rb` (see [Hoenn and Sinnoh](#hoenn-and-sinnoh)). |
| **Generated circuit (old)** | Sinnoh, until its real maps are merged | One route plus one town per Gym (the previous phase's placeholder). |

| Piece | Where |
| --- | --- |
| Region data, modes, offsets, scaling, teams, forest pool, gates, field skills | `Plugins/FullPoke Core/*.rb` |
| Gym Leaders, Elite Four, Champions, rivals, villains | `100_Data_Kanto.rb`, `110_Data_Regions.rb` |
| Kanto story | `105_Kanto_Story.rb`, `075_FieldMoves.rb`, `tools/headless/kanto_story.rb` |
| World build | `tools/headless/build_world.rb` (+ `build_geo.rb`, `gen_region.rb`, `geo/`, `plans/`); IDs in `world_ids.json`; output in `091_World_Generated.rb` |
| Tests | `tools/headless/t_*.rb`; see [Testing](#testing) |

## Milestones

### 1. Progression and mode selection: done, tested
- Per-region state (mode, offset, baseline, continuous index, max level,
  completion, starter, story flags, badges) is saved as `:fullpoke_progress`.
- The mode is chosen at the forest gate (or New Game) and can't change.
- Each region counts as completed once, when its final battle is won.
- Independent adventures have their own party, PC boxes, bag and Day Care,
  merged into the main set on completion with nothing copied or lost.
- Badges are kept per region; field moves and badge checks count the current
  region's badges.

### 2. Levels above 100 and scaling: done, tested
- Levels go to 999 (100 in independent adventures).
- Continuous offset = the highest level reached in the most recently completed
  continuous region − 5, fixed when the region begins. The examples from the
  design (2→67, 3→68, 8→73, 15→80, 65→130, 30→95, 50→115) pass.
- **Experience pacing, rewritten this phase.** In a scaled region a battle's
  Exp. is worked out at the unscaled levels, added there, and carried back up
  by the offset. The old approximation gave +11 levels where the unscaled game
  gives +5, so a continuous team outgrew a region by 60 levels.
- **New: party-wide Exp. Share** (Gen 6+ behaviour, Essentials' Exp. All). The
  no-boost playtest couldn't beat the first Gym Leaders without it.
- **New level curve:** each stage's wild Pokémon and route trainers climb from
  just under the previous Leader's level to three under the next Leader's.

### 3. Interregional Forest: done, tested
Unchanged: 9 maps, 9 two-way gates, the Heart Clearing (healing and PC).

**Grove Compass, new limits:** it works only where an Escape Rope or Teleport
would, which means outdoors or in caves. It never works:
- indoors or underwater;
- in battle or during a scripted scene;
- with a partner trainer or a follower;
- in the Safari Zone or Bug-Catching Contest;
- while a story sequence has locked it (`FullPoke.lock_compass`).

Surfing ends on arrival. `t_systems.rb` checks each case.

### 4. Rare forest Pokémon: done, tested (rule changed)
- A species counts as rare in a region only if it's at 5% or less (slots
  summed) on **every** map and method of that region where it appears. If
  it's common anywhere there, it's out: Pidgey no longer qualifies from Kanto.
- Only completed regions contribute.
- Each species has at most 5% per opportunity, and the total is at most 50%.
- `t_systems.rb` checks that every species above 5% anywhere in Kanto is
  excluded, including Pidgey. `t_journey9.rb` checks the pool after each
  region.

### 5. Stronger teams: done, tested
Unchanged. From the second continuous region:
- Gym Leaders have 5 fully evolved Pokémon of their type.
- The Elite Four, Champions and villains have 6.
- Teams get competitive moves, abilities, items, IVs and EVs.

### 6. Kanto: done, tested (with stated stand-ins)
- **Reachable on foot:** Lavender Town, Rock Tunnel, Routes 12–14, 17 and 20,
  Victory Road and the League, each at the right point in the story.
- **Route 23:** you surf across it and go through Victory Road (1F → 2F → 3F →
  a hole → 2F → the exit) to the Indigo Plateau.
- **Story events, in order:**
  - S.S. Anne: ticket, rival battle, HM Cut.
  - Rocket Game Corner hideout: Giovanni, Silph Scope.
  - Pokémon Tower: the Marowak ghost and Mr. Fuji, Poké Flute.
  - Silph Co.: rival, Giovanni, Lapras.
  - The two Snorlax.
- **Gyms:** Gym trainers in Gyms 2–8.
- **HMs and badges:** HMs come from NPCs, and badges gate the field moves.
- **Stand-ins:**
  - Silph Co. uses an elevator between 1F, 7F and 11F instead of the
    warp-pad maze.
  - The Rocket Hideout skips its spin-tile floor (B2F).
  - Saffron's gates check for 4 badges instead of the Tea.
  - Victory Road 2F has ladder tiles drawn in.
- **Not repaired:**
  - Seafoam Islands and Cerulean Cave's inside.
  - The Celadon Dept. Store doors.
  - Underground Path 7–8.
  - Victory Road's boulders.
  - The Safari Zone.
  - Cycling Road's Bicycle requirement.

### 7. Johto on its real maps: done, tested
- **Maps:** the pack's 35 Johto towns, routes and caves, connected in
  HeartGold/SoulSilver geography:
  - New Bark → Cherrygrove → Violet → Union Cave → Azalea → Ilex Forest →
    Goldenrod → National Park area → Ecruteak → Olivine → the sea routes →
    Cianwood.
  - Ecruteak → Mahogany → Lake of Rage, and the Ice Path → Blackthorn.
  - Routes 27/26 → Victory Road → League.
- **How they're joined:**
  - Map connections are lined up automatically on the open ground of each
    shared edge, with eight hand-set where the art doesn't line up.
  - Gatehouses and cave mouths are warps.
  - The pack's wrong links were removed.
- **Inside the towns:**
  - About 90 doors lead into a generated Johto Interiors map: Poké Centers,
    Marts, houses with residents, the player's home (Mom heals you) and Elm's
    lab (the starter and the first rival battle).
  - The Gyms have Leaders and Gym trainers.
- **Out on the routes:** 26 areas have route trainers, items and wild
  Pokémon. Tables come from the pack where they exist, otherwise from the
  Johto dex, matched to the area's level band and terrain (grass, cave, water
  and fishing).
- **Story battles at their HGSS places:**
  - The rival at Azalea and at the Burned Tower.
  - Archer under Mahogany's shop.
  - The Red Gyarados and Sudowoodo encounters.
  - A Rocket grunt at Azalea.
- **Badges open areas in order.** Without them you're turned back: Union Cave
  and Azalea need 1, Ilex needs 2 plus the Azalea rival, and so on, up to 8
  for Routes 26/27. `t_reach.rb` with `RULES=johto:N` confirms each badge
  opens exactly the next Gym town.
- **Field skills:** outside Kanto, a region's badges let the party use Cut,
  Surf, Strength, Waterfall and so on without a Pokémon knowing the move.
  Essentials' own badge numbers apply (Surf after 4).
- **Tileset repairs** (the pack's Johto tileset had walk-through houses and
  untagged grass):
  - Tall grass is tagged.
  - 525 building tiles are made solid, except tiles Kanto also uses.
  - Doormats and carpets in front of doors are reopened.
  - The cave tileset's black filler is made solid.
- **Stand-ins:** Sprout Tower, the Burned Tower and the Bell Tower doors are
  signs (their tower maps aren't wired yet). Johto's Victory Road and League
  are generated rooms reached from Route 26.

### 8. Generated regions with real layouts: done, tested (Kalos, Galar, Unova); Alola being re-run; Paldea locked
Every real location is a separate map with its real name, joined in the real
order. Each region has a start town with home and lab, Poké Centers, Marts,
houses, Gyms or trial sites, routes, forests, caves, ponds, route trainers,
items, wild Pokémon by level band and terrain, badge-gated areas and story
battles.

| Region | Maps | Structure |
| --- | --- | --- |
| Kalos | 37 | Vaniville → Aquacorde → Santalune Forest → Santalune (Viola) → Lumiose hub → Camphrier → Connecting Cave → Ambrette → Glittering Cave → Cyllage (Grant) → Geosenge → Reflection Cave → Shalour (Korrina) → Coumarine (Ramos) → Lumiose (Clemont) → Laverre (Valerie) → Dendemille → Anistar (Olympia) → Couriway → Snowbelle (Wulfric) → Route 21 → Victory Road. Shauna at Santalune, Lysandre in Lumiose. |
| Alola | 32 | Four islands linked by ferries. Ilima's trial at Verdant Cavern, Hala in Iki Town, Lana at Brooklet Hill, Kiawe at Wela Volcano Park, Mallow in the Lush Jungle, Olivia in Konikoni, Acerola at the Thrifty Megamart, Guzma in Po Town, Nanu in Malie, then Poni and Mount Lanakila. Trials (captain plus Totem), not Gyms. |
| Galar | 26 | Postwick → Wedgehurst → Rolling Fields (Wild Area) → Motostoke → Galar Mine → Turffield → Hulbury → back to Motostoke (Kabu, Hop) → Dusty Bowl → Hammerlocke hub → Stow-on-Side → Glimwood Tangle → Ballonlea → Circhester → Spikemuth; Rose at Hammerlocke; Route 10 → Wyndon → Champion Cup. |
| Unova | 25 | Nuvema → Accumula → Striaton → Wellspring Cave → Nacrene → Pinwheel Forest → Castelia → Desert Resort → Nimbasa → Driftveil → Chargestone Cave → Mistralton → Twist Mountain → Icirrus → Opelucid → Route 10 → Victory Road. Cheren at Striaton, Ghetsis at Opelucid. |
| Paldea | 21 | Open world around Mesagoza. Victory Road Gyms in their towns; Path of Legends Titans in the wild (a Titan beaten there counts for its Gym); Team Star bases; League north of Mesagoza; Nemona's final battle needs all three stories. **Built, but locked until Generation 9 is installed.** |

What the generated maps look like:
- **Tiles:** Kanto's outdoor tileset (buildings copied from Pewter and Pallet,
  paved streets, flower beds, tree-lined winding routes, ponds) and the Johto
  cave tileset (caves with rock piles).
- **Region tilesets:** the pack has no Kalos, Alola, Galar or Paldea
  tilesets. Its Unova tileset (32) isn't used yet.
- **Unova's hand-made maps** (Nuvema to Castelia, Routes 1–3, tileset 32)
  are kept but not wired. Their exits are gatehouses that need placing by
  hand, like Johto's. The generated Unova has the same names, marked
  "(generated)" in the map tree.

### Hoenn and Sinnoh
**Hoenn on its real maps: done, tested.** `t_geo.rb` plays it start to finish on
foot (27/27): all eight Gyms, Victory Road, the League and the Hall of Fame.
- **Maps:** the pack's maps from Littleroot to Ever Grande, with Petalburg
  Woods between Route 104's halves.
- **Towns:** doors for 16 towns, with Gyms, route trainers, encounters and
  badge rules.
- **Story battles:** May on Routes 110 and 119, Maxie above Route 112.
- **Stand-ins:**
  - Mr. Briney sails Route 104 ↔ Dewford ↔ Slateport.
  - Sailors replace Dive into Sootopolis and the surf to Ever Grande.
  - A Weather Institute guide crosses Route 119's north half, where the
    pack's river and bridges block every way through.
  - Victory Road is the generated one.
- **Fixes:** the pack's sea tileset (28) gets passability from Kanto's tileset
  where the tiles are pixel-identical.
- **Tests:**
  - The badge-rule check opens exactly the next town at each badge count.
  - The walkthrough wins Gyms 1–6 on foot. In the helper's runs it stalled on
    Route 120 heading for Mossdeep; see the latest result under
    [Testing](#testing).
- **Not wired:** Granite Cave, Meteor Falls, Mt. Pyre, Jagged Pass,
  Pacifidlog, the Battle Frontier and several sea routes.

**Sinnoh on its real maps: partial (merged).**
- **Real maps:** Twinleaf, then Rowan's lab in Sandgem, through to Sunyshore.
- **Badge checks:** each badge opens the next Gym town.
- **Walkthrough:** passes five of eight Gyms on foot (through Fantina). It then
  stops on Route 206 (the Cycling Road). The pack's BridgeOn/BridgeOff tiles
  switch which layer you walk on, and the test route planner doesn't model that
  switch, so the way to Canalave can't be walked by the test. Whether the
  bridge works in the game itself is unverified.
- **Gaps:** six house doors are missing, Route 216 west isn't reachable, and
  the Mt. Coronet passes are cave warps.
- **Bridge fix:** bridges now switch off on a new map, a fix in `090_World.rb`.

**Latest results:**
- On foot: Paldea 31/31, Hoenn 27/27, Johto 27/27, Kalos 26/26, Alola 26/26,
  Galar 26/26 and Unova 26/26.
- Sinnoh reaches the fifth Gym.
- Regressions: t_systems 182/182, t_journey9 235/235, t_gen9 59/59, Kanto
  27/27 in both modes, t_kanto_reach 35/35, and t_journey passes.

### 9. Balance (no level boosts): measured
`t_balance.rb` plays a region's battles in order and grants no levels. The
party gains Exp. only from the route trainers, story battles, Gym trainers,
Leaders and League, plus wild battles when it has to train. The AI plays both
sides, which is weaker than a careful player, so training counts are an upper
bound.

**Johto, independent, from level 5.** The final run, with 6 route trainers
per stage and the Victory Road band raised, took 286 battles, 187 of them
training. Party levels are lowest–highest:

| Battle | Ace | Party | Training battles |
| --- | --- | --- | --- |
| Falkner | 13 | 10–14 | 27 |
| Bugsy | 17 | 13–19 | 27 |
| Whitney, Morty, Chuck, Jasmine | 19–35 | 16–36 | 0 |
| Archer | 40 | 34–38 | 19 |
| Pryce, Clair, final rival, Will, Bruno, Karen | 34–47 | 36–47 | 0 |
| Koga | 44 | 40–45 | 8 |
| Lance | 50 | 43–47 | 45 (won on the 4th try) |

The first run (3 route trainers per stage, Victory Road at 38–44) needed 367
training battles and gave up on Lance. Falkner and Bugsy remain the early
spikes for an AI that leads with a Grass starter; a player who catches a
Geodude or Mareep has an easier time.

**Sinnoh, continuous, after Kanto → Johto → Hoenn** (offset 165, levels
170–282):
- Every Gym was won in 1–5 tries with at most 16 training battles.
- The final rival took 11 tries and 52 training battles.
- The Elite Four and Cynthia (227) were each won within 2 tries.
- Battles above level 100 (up to 282) ran without errors.
- After the pacing fix, the team's lowest member stays at the foes' levels;
  its highest ends about 55 above the Champion.

Next balance steps: rerun Johto with 6 trainers per stage; ease Bugsy and
Morty if they still need 50+ training battles; then measure Kanto, a
generated region, and continuous play after 6 or more regions.

## Generation 9: installed (with your approval)

The community **Generation 9 Pack** 3.3.8 and Maruno's **v21.1 Hotfixes** 1.0.9
are installed:
- Generation 9 battle rules, with the pack's "Champions" rules off.
- The Grove Compass and S.S. Ticket kept.
- Two evolutions the pack lacked added: Primeape → Annihilape and
  Bisharp → Kingambit.
- A Paldea Pokédex (number 8) added.
- The pack's status icons copied in.

The review, the plan and an exact record of what was installed are in
[GEN9_INTEGRATION.md](GEN9_INTEGRATION.md). `t_gen9.rb` verifies:
- species, forms and evolutions;
- moves, abilities and items;
- battles with Generation 9 moves and abilities up to level 150;
- levels past 100 and save/load;
- Paldea's encounters, trainers and gate.

**Still missing:** 1,845 alternate-form back/icon sprites, and
Terastallization (the pack doesn't include it).

## Windows (Game.exe)

**Checked in the real Game.exe on Windows 11 (RTX 2060), this phase,** from a
copy in `%TEMP%`, with screenshots of the game window. These rendered and
behaved correctly:
- the title screen and main menu;
- Oak's intro, the controls help and the name entry screens;
- FullPoke's region choice (all eight available regions listed) and the
  mode explanation and confirmation;
- the new game starting in the player's home in Johto (a generated room,
  Mom present);
- walking out the door into the pack's real New Bark Town, with night
  tinting from the real clock and Route 29 visible across the seamless map
  edge;
- the pause menu.

**Not checked in Game.exe** (headless only, or not at all):
- walking around beyond a few steps (simulated input from outside the
  window was unreliable);
- battles and their animations;
- music and sound;
- saving and loading;
- every other map, including the forest, the generated regions and the
  League;
- large-number display above level 100.

There's no test save: the game folder it created in `%APPDATA%` was empty
and has been removed.

**To check by hand:**
1. Launch Game.exe.
2. Start a New Game in each region in turn.
3. Walk from the start town through the first route and town.
4. Fight a wild battle and a trainer.
5. Save, quit and load.
6. Open the summary of a Pokémon above level 100 (use debug mode to set it).
7. Open the maps in RPG Maker XP. The Johto, Kalos, Alola, Galar, Unova and
   Paldea folders now hold the wired or generated maps.

## Testing
| Test | What it covers | Latest result |
| --- | --- | --- |
| `t_compile.rb` | PBS + plugin compile | pass |
| `t_systems.rb` | modes, levels to 999, offsets, isolation, enhanced teams, forest pool (new rule), Grove Compass limits, save/load | 181/181 |
| `t_journey9.rb` | all nine regions, mixed modes: offsets, scaling, team rules, a Champion battle each, forest unlocks, completion, save/load; Paldea locked | 209/209 |
| `t_kanto.rb` | Kanto Gyms 2–8 with Gym trainers, Route 22 gate, surfing Route 23, Victory Road, League, Hall of Fame | 27/27 continuous, 27/27 independent |
| `t_kanto_reach.rb` | every Kanto location reachable at the right story point | 35/35 |
| `t_kanto_story.rb` | each story gate tried before and after its requirement | 60/60 |
| `t_geo.rb` | walks a real-layout region on foot: forest gate → lab → every Gym/trial in order over the real routes, gates, caves and sea → story battles → badge-gated areas push back → Victory Road → League → Hall of Fame | Unova 26/26; Kalos and Galar reached the Hall of Fame (re-run with fixes); Johto through Morty, re-run in progress; Alola through Olivia, re-run in progress |
| `t_reach.rb` | on-foot reachability, optionally with badge rules (`RULES=`) and Surf | Johto: each badge count opens exactly the next town |
| `t_balance.rb` | battles with no level boosts | see Balance |
| `t_newgame.rb` | New Game → region/mode → start town | Alola, Unova pass |
| `t_journey.rb`, `t_ui.rb`, `t_release.rb` | Kanto opening to Brock, menus and battle scene, release boot | pass |

## Next steps (priority)
1. Install Generation 9 after approval, then play Paldea through
   (`REGIONS=paldea t_geo.rb`).
2. Merge Hoenn and Sinnoh on their real maps.
3. Wire Unova's hand-made maps (Nuvema to Castelia) into the generated Unova.
4. Johto's towers (Sprout, Burned, Bell), Slowpoke Well, the Rocket Hideout
   and Radio Tower interiors; the Kanto items listed as not repaired.
5. Region-specific tilesets for generated regions (Unova's tileset 32 for
   Unova and Galar), plus per-character trainer sprites.
6. Balance passes from `t_balance.rb` results.
7. A playtest in Game.exe (see Windows).
