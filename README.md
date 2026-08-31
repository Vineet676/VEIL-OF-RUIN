# project_name (Working Title — TBD)

> **Note:** The title **"project_name"** is a temporary placeholder. Once a final game title is determined, use search-and-replace across this repository to update the project name and references.

---

## Overview
**project_name** is a 2D metroidvania game built in Godot 4.x featuring dual character origin paths, interconnected stage progression, atmospheric NPC dialogue encounters, tactical enemy combat, and multi-phase boss encounters.

---

## Key Features & Structure

### Starting Paths
- **Scavenger**: Survival and exploration-focused starting archetype and introductory routing.
- **Initiate**: Combat and ritual-focused starting archetype and introductory routing.

### 5 Stages
1. **Stage 1: Scavenger Opening** (`scenes/stages/stage_1_scavenger/`) — Opening area for the Scavenger path.
2. **Stage 2: Initiate Opening** (`scenes/stages/stage_2_initiate/`) — Opening area for the Initiate path.
3. **Stage 3: Collapse / Convergence** (`scenes/stages/stage_3_collapse/`) — Convergence point where paths meet amid a world-altering collapse event.
4. **Stage 4: Descent Through Ruins** (`scenes/stages/stage_4_descent/`) — Vertical descent through ancient ruin layers.
5. **Stage 5: Construction Chamber & Final Boss** (`scenes/stages/stage_5_chamber/`) — Climax zone housing the final encounter with The Crown.

### Characters & Dialogue System
- **Observer** (`scenes/characters/observer/`): Guide and cryptic observer entity.
- **Side Character** (`scenes/characters/side_character/`): Secondary narrative NPC.
- **Dialogue System** (`scripts/dialogue/`, `scenes/ui/dialogue_box/`, `resources/`): Modular narrative graph and dialogue box UI.

### Enemies & Bosses
- **Enemies**:
  - **Guard** (`scenes/enemies/guard/`): Disciplined patrol unit with melee/ranged attack routines.
  - **Broken** (`scenes/enemies/broken/`): Erratic, damaged mechanical/organic threat.
  - **Machine** (`scenes/enemies/machine/`): Heavy construct with high armor and area-denial attacks.
- **Bosses**:
  - **Mini-Boss** (`scenes/bosses/mini_boss/`): Mid-game gatekeeper encounter.
  - **The Crown** (`scenes/bosses/the_crown/`): The final boss of the game.

---

## Project Directory Structure

```text
/
├── project.godot                     # Godot 4.x project configuration
├── README.md                         # Project documentation and specifications
├── .gitignore                        # Standard Godot 4 ignore rules
├── scenes/                           # Godot packed scenes (.tscn)
│   ├── player/                       # Player character scenes
│   ├── enemies/                      # Enemy scenes
│   │   ├── guard/
│   │   ├── broken/
│   │   └── machine/
│   ├── bosses/                       # Boss encounter scenes
│   │   ├── mini_boss/
│   │   └── the_crown/
│   ├── stages/                       # Stage level layouts and tilemaps
│   │   ├── stage_1_scavenger/
│   │   ├── stage_2_initiate/
│   │   ├── stage_3_collapse/
│   │   ├── stage_4_descent/
│   │   └── stage_5_chamber/
│   ├── characters/                   # NPC scenes
│   │   ├── observer/
│   │   └── side_character/
│   └── ui/                           # User interface scenes
│       ├── hud/
│       ├── dialogue_box/
│       ├── main_menu/
│       └── ending_choice/
├── scripts/                          # GDScript code files (.gd)
│   ├── player/                       # Player controller and movement logic
│   ├── enemies/                      # Enemy AI and behavior logic
│   ├── bosses/                       # Boss state machines and phase logic
│   ├── systems/                      # Core systems (state machines, health/damage, save/checkpoint, difficulty scaling)
│   ├── dialogue/                     # Narrative parsers and conversation runners
│   └── autoload/                     # Singletons: GameState, DifficultyManager, StageManager
├── assets/                           # Raw and imported media assets
│   ├── sprites/                      # 2D Sprite sheets and textures
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── bosses/
│   │   ├── characters/
│   │   └── ui/
│   ├── environment/                  # Stage-specific environment art and tilesets
│   │   ├── stage_1/
│   │   ├── stage_2/
│   │   ├── stage_3/
│   │   ├── stage_4/
│   │   └── stage_5/
│   ├── audio/                        # Audio tracks and sound effects
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/                        # Typography and bitmap/vector fonts
├── resources/                        # Custom Resource (.tres) files: stats, dialogue, presets
└── docs/                             # Story documents, design specs, attack pattern specs
```

---

## Technical Specifications
- **Engine**: Godot Engine 4.7.x (4.7.1-stable)
- **Target Resolution**: 1280 × 720 (Canvas Items stretch mode, aspect keep)
- **Texture Filter**: Nearest / Pixel (configured for 2D pixel-art rendering)
