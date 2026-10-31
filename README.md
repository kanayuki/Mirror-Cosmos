# 镜像星域 · Mirror Cosmos

> 3D mirror-reflection puzzle game — Godot 4.3 — GDScript

A first-person / overhead hybrid puzzle game set in deep space. Place mirrors in overhead design mode, then drop into first-person explore mode to watch the star-beam trace its path through your solution.

---

## Quick Start (Players)

1. Open `project.godot` in **Godot 4.3+** and press **F5** to run, or launch the exported binary.
2. From the main menu, choose **新游戏** (New Game) or **继续** (Continue) if a save exists.
3. Solve each puzzle by directing the star-beam from its emitter (blue cube) to the target (gold cube).
4. Progress saves automatically when each puzzle is solved.

### Controls

| Key | Action |
|-----|--------|
| Tab / F2 | Toggle Design ↔ Explore mode |
| W A S D | Walk (Explore mode) |
| Space | Jump (Explore mode) |
| E | Interact / collect memory fragment |
| Left-click | Place mirror (Design) / Rotate mirror (Design, on existing) |
| Right-click | Remove mirror (Design mode) |
| R | Rotate placement preview (Design mode) |
| L | Open / close log viewer |
| Esc | Pause menu |

---

## Quick Start (Developers)

```
git clone <repo>
# Open in Godot 4.3+ — no extra plugins required
```

All GDScript files pass the built-in static analyser with typed variables throughout. No third-party dependencies.

---

## Project Structure

```
Mirror-Cosmos/
├── autoload/
│   ├── game_manager.gd       # Central singleton — mode, signals, level loading
│   ├── log_manager.gd        # Collected LogEntry deduplication
│   └── save_system.gd        # user://save.json — level index + log IDs
├── resources/
│   ├── levels/               # LevelData .tres files (level_01 – level_04)
│   └── logs/                 # LogEntry .tres files (narrative fragments)
├── scenes/
│   ├── main.tscn             # Game scene root
│   ├── ui/                   # main_menu, pause_menu, level_complete, log_viewer
│   └── world/                # player, memory_fragment
├── scripts/
│   ├── main.gd               # Level geometry builder + fragment spawner
│   ├── star_beam.gd          # Iterative RayCast3D reflection chain
│   ├── mirror_spawner.gd     # 3D mirror node lifecycle (single owner)
│   ├── placement_system.gd   # Input → GameManager calls (Design mode only)
│   ├── grid_overlay.gd       # ImmediateMesh grid drawn in Design mode
│   └── hud.gd                # Reacts to GameManager signals
└── project.godot
```

---

## Architecture Notes

**Signal flow** — `GameManager` is the sole emitter of core game signals:

```
beam_updated  →  StarBeam._recalculate()
              →  GridOverlay (beam highlight)

mirror_placed / mirror_removed / mirror_rotated
              →  MirrorSpawner (3D node lifecycle)
              →  beam_updated emitted after each

puzzle_solved →  LevelCompleteUI.show()
              →  SaveSystem.save()

level_loaded  →  main.gd builds geometry
              →  MirrorSpawner clears mirrors
```

**Mode switching** — Tab triggers a 0.15 s fade Tween; Player + first-person camera shown in Explore, hidden in Design (overhead orthographic camera active).

**Beam reflection** — iterative `RayCast3D` with `EPSILON = 0.015` offset after each bounce, `MAX_BOUNCES = 10`. `force_raycast_update()` called per segment to avoid one-frame lag.

**Export safety** — log paths are a compile-time constant array (`LOG_PATHS` in `main.gd`); no `DirAccess.open("res://...")` calls that would silently fail in exported builds.

---

## Levels (Chapter 1 — Lunar Station)

| # | Layout | Mirrors needed | Notes |
|---|--------|---------------|-------|
| 1 | Open room | 1 | Tutorial — single bounce |
| 2 | Central pillar | 2 | Two-bounce solution required |
| 3 | Two parallel pillars | 2–3 | Beam must snake between them |
| 4 | Cross obstacle | 3–4 | Emitter and target on same wall |

Memory fragment log entries (Elara's journal) unlock in levels 3 and 4.

---

## Save System

Save file location: `user://save.json`

```json
{
    "level_index": 2,
    "collected_log_ids": ["elara_day01", "elara_day07"]
}
```

Delete save: **主菜单 → 新游戏** overwrites the file, or delete `save.json` from the Godot user data directory manually.

---

## Status

- [x] Phase 1 — Core loop (design/explore modes, beam, 4 levels)
- [x] Phase 2 — Story system (LogEntry, MemoryFragment, log viewer)
- [x] Phase 3 — Polish (main menu, pause menu, save/load, level complete UI)
- [ ] Audio (SFX + ambient tracks)
- [ ] Export templates configured for Windows / macOS / Web

---

*Engine: Godot 4.3+ · Language: GDScript · License: see LICENSE*
