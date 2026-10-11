# Brisa de Aço Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. The user explicitly requested execution and functional delivery in this session.

**Goal:** Deliver a playable macOS 1×1 artillery prototype against CPU.
**Architecture:** Pure terrain/combat/match/profile models consumed by a Godot scene. Shared trajectory integration for CPU and live projectiles; UI never owns combat outcomes.
**Tech Stack:** Godot 4.7.2, GDScript, Compatibility renderer, GPT Images.
**Spec:** docs/superpowers/specs/2026-10-11-prototype-design.md

## Global Constraints
macOS validated; engine supports Windows/Linux/Android/iOS. Offline only, no ranking. Original artwork. Local profile. User has authorized proceeding without intermediate approvals.

## Review Focus
Fast projectiles must not cross terrain or tanks. Terrain collapse must settle both actors before deciding victory. Menu/pause/restart must not leak pending CPU actions. Rewards must not be duplicated by repeating result/revanche. Corrupt profile must recover with safe defaults.

### Task 1: deterministic combat models
Files: scripts/terrain.gd, scripts/combat.gd, scripts/match.gd; tests/test_runner.gd.
- [x] Write failing headless behavior tests with hand-checked ballistic values, high-speed thin-wall collision, crater center/edge samples, delay ordering, special availability, fall elimination and timeout.
- [x] Run `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd`; verify missing behavior fails before implementation.
- [x] Implement the mask and fixed-step ballistic integration. `Combat.advance(position, velocity, wind, delta)` returns updated position/velocity; `Combat.trace_segment(from, to, terrain, actors, ignored)` returns first collision. Match owns actors, scheduler, projectiles and result.
- [x] Re-run the suite and fix until zero failures; add full-match CPU simulation coverage.

### Task 2: profile and playable presentation
Files: scripts/profile.gd, scripts/game.gd, scripts/sound.gd, scenes/main.tscn, project.godot, assets/art/*.
- [x] Add failing profile tests for save/load, corrupted JSON recovery, XP/level and reward-once behavior.
- [x] Implement profile persistence with configurable path for test isolation.
- [x] Create menu, arena, HUD, keyboard/button controls, pause/help/result, event-based sounds and visual effects. Generated sprites are imported into project assets.
- [x] Test launch, movement, charged/direct fire, weapon restrictions, pause and complete a match in the live app; verify restart keeps profile but resets arena/special.

### Task 3: package and deliver
Files: export_presets.cfg, README.md, docs/VALIDACAO.md, docs/ART.md, builds/Brisa de Aco.app.
- [x] Run the entire headless suite and live smoke checks; document measured results.
- [x] Request an independent code review, address material findings and repeat affected tests.
- [x] Export macOS Universal with local ad-hoc signing; launch exported app and verify clean logs.
- [x] Provide executable link, short controls, known prototype limitations and readable source/documentation.
