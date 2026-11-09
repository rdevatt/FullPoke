# Generation 9 Pack: review and install plan

_Reviewed 2026-11-08. Nothing in this document has been run: the pack's code
stays in `git stash` until you approve installing it._

## What's in the stash

`stash@{0}` ("Gen 9 Pack 3.3.8 + v21.1 Hotfixes install") holds:

| Part | Contents |
| --- | --- |
| `Plugins/Generation 9 Pack Scripts/` | 32 Ruby files. Generation 9 Pack v3.3.8 for Essentials 21.1, credited to Caruban, Lucidious89 and others ([eeveeexpo resource 1101](https://eeveeexpo.com/resources/1101)). Needs the hotfixes below. |
| `Plugins/v21.1 Hotfixes/` | 4 Ruby files. Maruno's v21.1 Hotfixes 1.0.9 ([eeveeexpo resource 1376](https://www.eeveeexpo.com/resources/1376)). |
| PBS | `abilities.txt`, `items.txt`, `moves.txt`, `pokemon.txt` and `pokemon_forms.txt` replaced with the pack's "vanilla PBS with updates", plus six `*_Gen_9_Pack.txt` files. |
| Assets | 7,258 new Graphics/Audio files (sprites, icons, cries, item icons, animations). None of them overwrites an existing file. |
| `docs/third_party/` | The pack's credits and PBS guide. |

The installed files are byte-identical to the downloaded archives.

## Security review

Both plugins were read in full (not run). They contain:

- no `eval` of strings, `system`, backticks, `IO.popen`, `Process`, `Win32API`
  or other DLL calls;
- no network access;
- no file deletion;
- no obfuscated or encoded code.

Things worth knowing:

- `[000] General/[003] PBS Updater.rb` defines `Compiler.update_gen9`. It
  rewrites the PBS files from `PBS/Gen 9 backup/Auto-Updates/`. Nothing calls
  it, and it does nothing because that folder isn't in the stash.
- `Misc bug fixes.rb` uses `instance_eval` with a block (not a string) in a
  save-file conversion.

There's no licence text; the only condition is credit. The game should show
the pack's credits list (`docs/third_party/Gen9Pack_Credits.txt`) and credit
Maruno for the hotfixes.

## Conflicts with FullPoke

**Load order:** Hotfixes, then the Gen 9 Pack, then FullPoke Core (FullPoke
has no `Requires`, so it loads last). FullPoke's wrappers therefore sit on top
of the pack's.

**Overlapping methods (compatible):**

- `Battle#pbStorePokemon`: the hotfix replaces it; FullPoke wraps the
  hotfixed version.
- `Battle#pbGainExpOne`: the pack's version still calls
  `GrowthRate#add_exp`/`level_from_exp`, so FullPoke's level cap and
  experience pacing still apply.

**No overlap:** FullPoke's other hooks (growth rates, the forest encounter
override, trainer skill, badge count, encounter loading, save data and event
handlers).

**Problems to fix during the install:**

1. **The Grove Compass would be deleted.** The stashed `PBS/items.txt` was
   made before the Grove Compass existed, so it lacks `[GROVECOMPASS]` (Oak's
   Package and Joe's Mail are there). `git stash pop` will conflict on that
   file. Fix: take the stashed file and add the `[GROVECOMPASS]` block back.
2. **Battle mechanics would change.** The pack sets
   `MECHANICS_GENERATION = 9` (the game uses 8) and
   `CHAMPIONS_MECHANICS = true`. The latter changes PP to 8/12/16/20 and how
   sleep, freeze and paralysis work. Recommendation: set it to `false`, and
   keep generation 8 unless you want Gen 9 rules.
3. **Status icons:** the pack's new Drowsy and Frostbite statuses need the
   pack's taller `Graphics/UI/statuses.png` and
   `Graphics/UI/Battle/icon_statuses.png`. Those weren't copied (the project
   had its own), so they need to be swapped in.
4. **Missing sprites:** 1,845 back, back-shiny and icon sprites for alternate
   forms are in neither the project nor the stash. Those forms show
   placeholder graphics until the sprites are added.
5. **Line endings:** the stashed PBS files are CRLF; the repo's are LF.
   Normalise them.
6. **Team changes after install:** the extra species change which Pokémon
   enhanced teams draw from, and Paldea unlocks automatically (it needs
   Sprigatito, Fuecoco and Quaxly). The pack's 22 Paradox Pokémon are already
   excluded from enhanced teams.

## Install plan (after approval)

1. Restore the stash's new files without popping it:
   `git checkout 'stash@{0}^3' -- Plugins docs/third_party PBS/*_Gen_9_Pack.txt Graphics Audio`.
2. Take the stashed versions of `abilities.txt`, `moves.txt`, `pokemon.txt`,
   `pokemon_forms.txt` and `items.txt` from `stash@{0}`. Re-add the
   `[GROVECOMPASS]` block from the current `items.txt` and normalise to LF.
   Check that `OAKSPACKAGE` and `JOESMAIL` are still there.
3. Set `CHAMPIONS_MECHANICS = false` and `MECHANICS_GENERATION = 8` (or 9 if
   you prefer).
4. Copy the pack's status icon sheets into `Graphics/UI`.
5. Add a Paldea Pokédex (`[8]`) to `PBS/regional_dexes.txt` and to
   `Settings.pokedex_names`.
6. Delete `Data/PluginScripts.rxdata`, then run `tools/headless/run.sh t_compile.rb`.
7. Run the checks:
   - `t_systems.rb`: the Grove Compass exists and works, plus levels, scaling
     and storage.
   - `t_journey.rb`, `t_kanto.rb`, `t_ui.rb`: the summary screen with the new
     status icons.
   - `t_journey9.rb`: Paldea is no longer locked.
   - `REGIONS=paldea tools/headless/run.sh t_regions.rb`.
   - A new Gen 9 test covering:
     - species data, moves, abilities, items and evolutions (including
       Clodsire, Kingambit, Annihilape and Gholdengo);
     - Paldean forms (Paldean Tauros and Wooper);
     - a battle with Gen 9 moves and abilities;
     - Paldea's encounter tables.
8. Commit the install as its own commit, then unlock and test Paldea.
