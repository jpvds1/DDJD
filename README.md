# [Heaven Run] — High-Speed Platformer

**Academic project for PUC / FEUP — placeholder.**

Welcome to the project. This is a Godot 4.6 2D platformer prototype focused on high-speed movement and time-trial gameplay. This README targets engineering students and professors: concise, technical, and implementation-oriented.

**Contents**
- Overview
- How to Play (controls & mechanics)
- Key Features (Time-Trial & Competitive MVP)
- Scenes, objects and important scripts
- Levels & Building (dynamic level system)
- Sound Design (forward-looking)
- Backend & Authentication (placeholder)
- Developer guide (open, test, extend)
- Contributing & Technical Standards
- Credits & License

## Overview

`Game` is a platformer prototype emphasizing mobility and agile controls. Players traverse levels full of hazards (lava, saws, lasers, etc.) and can compete via time trials or leaderboards.

The project is organized to make level creation and component reuse straightforward in Godot.

## How to Play

- Goal: reach the end of the level, activate checkpoints and collect gear/items. Some levels may include timed challenges or leaderboard integration.
- Default controls (project defaults):
	- Move: `A` / `D` (or left/right arrows)
	- Jump: `Space`
	- Sprint / Hold speed: `Shift`
	- Dash / Quick ability: `Q`
	- Interact / Confirm: `E`
	- Menu / Pause: `Esc`

Note: input mappings are defined in `platformer-game/project.godot` and can be changed in the Godot editor.

## Key Mechanics & Features

**Time-Trial Focus (Primary):** the core loop is traversal with millisecond precision and leaderboard ranking.

- **Precise movement:** responsive running, jump, double jump and dash.
- **Global inventory:** manage items/consumables with session persistence (non-equip system).
- **Checkpoints:** checkpoint activation and checkpoint-based respawn logic.
- **Hazards & obstacles:** lava, spikes, saws, wrecking balls, lasers, moving platforms, water (with special physics).
- **UI:** menus for level selection, time trials, leaderboards and settings.
- **Backend-ready:** placeholder hooks for leaderboard persistence (`scripts/supabase.gd`).

### Competitive MVP

- **Precision Timer:** timing measured in milliseconds for all runs.
- **Global Leaderboard integration:** per-level leaderboards with user and time.
- **Checkpoint-based respawn logic:** partial progress preserved via checkpoints; final run time accounts for checkpointed runs consistently.

## Scenes (summary)

Project scenes are stored in the `scenes/` folder:

- `scenes/levels/` — playable levels (e.g. `level_1.tscn`, `tutorial.tscn`, `empty_level.tscn`).
- `scenes/player/` — player scene (`capsule_character.tscn`).
- `scenes/ui/` — menus and HUD (`main_menu.tscn`, `main_UI.tscn`, `customization_menu.tscn`, etc.).
- `scenes/building_materials/` — reusable building blocks for levels (platforms, traps, checkpoints, water, etc.).

Each scene usually has an associated script under `scripts/` or `scripts/systems/` for its behavior.

## Important Scripts & Components

- Autoloads (configured in `project.godot`):
	- `scripts/global.gd` — global state and utilities.
	- `scripts/supabase.gd` — connection and leaderboard functions (requires credentials).
	- `scripts/sound_manager.gd` — (planned) singleton for SFX/BGM routing.
	- `scripts/player/global_inventory.gd` — global inventory and equipment handling.
- Player:
	- `scripts/player/capsule_character.gd` — movement, physics and ability code.
	- `scripts/player/stats_manager.gd` — stats and gear effects.
- Level systems & hazards:
	- `scripts/systems/lava_hazard.gd`, `spikes.gd`, `wreckingball.gd`, `laser.gd` — damage and collision behaviors.
	- `scripts/systems/checkpoint_platform.gd` — checkpoint activation and respawn.
- UI / Menus:
	- `scripts/ui/main_menu.gd`, `main_UI.gd`, `customization_menu.gd` — UI navigation and events.

## Items

Some levels include collectable items and consumables (for example: time bonuses, keys, or health pickups). Items are managed by the global inventory system and applied by relevant scripts (see `scripts/player/global_inventory.gd` and `scripts/player/stats_manager.gd`).

## Levels & Building

**Dynamic Level System (automatic detection)**

- The level selection menu is dynamic: the game scans `scenes/levels/` at runtime and lists scenes that match the naming convention below.
- **Naming convention (required):** any new level scene MUST be named following the pattern `level_nro.tscn` (for example: `level_1.tscn`, `level_2.tscn`). Scenes not following this pattern will be ignored by the automatic level selector.

Workflow to add a level:

1. Duplicate `scenes/levels/empty_level.tscn`.
2. Name the duplicate using the required convention (`level_3.tscn`).
3. Compose the level using assets from `scenes/building_materials/`.
4. Test the scene in the editor and ensure the start/goal nodes and checkpoints are present.

**Best practices:** place checkpoints before difficult sections and balance hazard spawns for a fair challenge.

## Leaderboard Integration (Supabase)

The project includes `scripts/supabase.gd` to send and fetch times/scores. You will need a Supabase project (URL and KEY) and configure these credentials in the script or via a secure resource.

## Backend & Authentication (placeholder)

This section is reserved for planned backend integration. The intended design uses Supabase to provide:

- **User authentication / Login** (email or OAuth).
- **Leaderboard persistence** (per-level scores, user metadata).

Implementation notes: keep client keys out of the repository; read credentials from secure environment variables or an external config resource.

## Open & Run the Project (developers)

Minimum requirements:
- Godot 4.6 (project features reference 4.6 in `project.godot`).

To run locally:

1. Open Godot and select the project folder: `platformer-game/`.
2. Ensure imported assets are present (check `platformer-game/assets/`).
3. Open a level scene (for example `scenes/levels/tutorial.tscn`) to play/test mechanics.

Exporting:
- Use Godot's export system to build for target platforms (ensure export templates match your Godot version).

## Sound Design

**Forward-looking architecture:** the project will use a `SoundManager` Autoload (singleton) responsible for:

- loading and routing all SFX and BGM,
- grouping sounds into categories,
- global volume and ducking rules.

**Required categories:**

- **Movement:** Jump, Dash
- **Hazards:** Lasers, Saws
- **Ambient:** Lava, Water

Implementation hint: place `sound_manager.gd` in `scripts/` and register it as an Autoload in `project.godot`.

## Repository Structure (summary)

- `platformer-game/` — Godot project files (project.godot, icon, imported assets).
- `scenes/` — game scenes organized by type.
- `resources/` — reusable resources, including level assets and item resources.
- `scripts/` — game logic in GDScript organized into subfolders (player, systems, ui, traps, helpers).

## Contributing

- File issues or feature requests in the repository tracker.
- To add a level: follow the Dynamic Level System naming convention and test with existing mechanics.
- To add items: create a new resource in `resources/` and register its behavior in the appropriate script under `scripts/`.
- If you add external services (e.g. Supabase), document setup instructions in `scripts/supabase.gd`.

**Technical Standards**

- **All reusable level assets must be stored in `scenes/building_materials/` to maintain modularity.**
- Keep scene logic modular and rely on `scripts/systems/` for reusable behaviors.
- Use clear node naming and keep exported variables documented at the top of scripts.

## Debugging & Testing

- Use Godot's output console to view `print()` logs and errors.
- Enable debug flags in `scripts/global.gd` for extra tracing.

## Credits

**Authors:**

| Name |
|---|
| Pedro Rojas Izquierdo |
| João Pacheco Veiga Dias da Silva |
| Luís Miguel Melo Arruda |
| Tomás de Campos Sucena de Sequeiros Lopes |

**Assets & resources:** check `platformer-game/assets/` and `resources/` for specific attributions.

## License

Add the project's license information here (MIT, GPL, etc.). If there is no license, add one and document the terms.


