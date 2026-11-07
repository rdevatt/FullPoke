# FullPoke
a complete pokemon game from gens 1-9

Built with **Pokémon Essentials v21.1** (RPG Maker XP project, mkxp-z runtime).

- **Play:** run `Game.exe`. To playtest with the Debug menu, open
  `Game.rxproj` in RPG Maker XP and press Playtest (F12).
- **Status, known issues and the to-do list:** [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md)
- **Headless tests and data tools** (compile PBS, play scripted sessions, inspect
  maps without Windows): [tools/headless/README.md](tools/headless/README.md)

## Layout

| Folder | Contents |
| --- | --- |
| `Data/` | RPG Maker XP data (maps, scripts) and compiled game data (`*.dat`) |
| `PBS/` | Editable game data (Pokémon, moves, trainers, encounters, maps). `PBS/_archive_v18/` holds the original v18-format files for reference only. |
| `Plugins/` | Project plugins (`FullPoke Core`) |
| `Graphics/`, `Audio/`, `Fonts/` | Assets |
| `tools/` | Development tools. Not part of the game; don't ship. |

After editing anything in `PBS/`, playtest once in Debug mode (or run
`tools/headless/run.sh t_compile.rb`) so the compiled `Data/*.dat` files are
updated. Release builds only read those.
