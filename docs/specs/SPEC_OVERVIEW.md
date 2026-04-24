# Spec Overview — Little Six

**Version:** 1.0  
**Status:** Implementation-Ready  
**Last Updated:** 2026-04-24  

This document is the index of all implementation specs. Each spec contains numbered requirements, data structures, Godot scene/node hierarchies, signal interfaces, and acceptance criteria. An implementing agent should work through specs in the order listed below.

---

## Implementation Order

Work through specs in this order. Each spec builds on previous ones. Do not start a spec until its dependencies are complete.

| # | Spec | Dependencies | Est. Complexity |
|---|---|---|---|
| 1 | [Godot Project Structure](spec_001_godot_project_structure.md) | None | Low |
| 2 | [Attract Mode & Game Flow](spec_002_attract_mode_flow.md) | Spec 1 | Medium |
| 3 | [Training System (Tamagotchi)](spec_003_training_tamagotchi.md) | Spec 1 | Medium |
| 4 | [Multiplayer Race](spec_004_multiplayer_race.md) | Spec 1, 3 | High |
| 5 | [Networking Layer](spec_005_networking_layer.md) | Spec 4 | High |
| 6 | [AWS Infrastructure](spec_006_aws_infrastructure.md) | Spec 5 | Medium |
| 7 | [Mobile UI/UX](spec_007_mobile_ui_ux.md) | Spec 1, 2 | Medium |
| 8 | [Audio System](spec_008_audio_system.md) | Spec 1 | Low |
| 9 | [Player Progression & Persistence](spec_009_player_progression.md) | Spec 3, 4 | Medium |
| 10 | [Race Physics & Simulation](spec_010_race_physics_simulation.md) | Spec 4 | High |
| 11 | [Static Marketing Website & Game Host](spec_011_static_website.md) | Spec 1, 6 | Low |

---

## Completion Checklist

Use this table to track implementation progress:

| Spec | Status | Notes |
|---|---|---|
| 001 — Project Structure | Complete | All autoloads, data classes, and core structure implemented |
| 002 — Attract Mode | Complete | Logo, Cinematic, Title, Demo scenes with iris transitions and loop |
| 003 — Training System | Not started | |
| 004 — Multiplayer Race | Not started | |
| 005 — Networking | Not started | |
| 006 — AWS Infrastructure | Not started | |
| 007 — Mobile UI/UX | Not started | |
| 008 — Audio System | Not started | |
| 009 — Progression | Not started | |
| 010 — Race Physics | Not started | |
| 011 — Static Website | Complete | Marketing site with game host, mobile responsive, assets placeholders |

---

## Spec Format

Each spec follows this format:

```
# Spec NNN — [Name]

## Overview
## Requirements (numbered REQ-NNN-001 format)
## Data Structures
## Scene/Node Hierarchy
## Signal Interface (emits / listens)
## Acceptance Criteria
## Implementation Notes
```

Requirements use `REQ-{spec_number}-{seq}` identifiers, e.g., `REQ-003-007`.  
Acceptance criteria are written as testable pass/fail statements.

---

## Key Constraints (apply to all specs)

1. **Mobile-first:** All touch targets ≥ 44×44 px. No hover states required. Support portrait (menus) and landscape (race).
2. **Event-driven:** No direct cross-system calls. All inter-system communication via `EventBus` signals.
3. **Offline-capable:** All single-player features (training, solo race) work without server connection.
4. **Performance:** Target 60 FPS on mid-range 2022 Android/iOS. No > 50 draw calls in race scene.
5. **Godot 4.6 only:** Use Godot 4.x APIs. No Godot 3.x patterns (no `yield`, use `await`; no `connect()` with string, use lambdas or `Callable`).
6. **Web export:** All code must be compatible with the Godot HTML5/WASM export target. No GDNative; no platform-specific filesystem paths except `user://`.
7. **Compatibility renderer only:** Godot must be configured to use the **Compatibility** renderer (OpenGL ES 3.0 / WebGL 2.0). The `forward_plus` and `mobile` renderers are Vulkan-based and do not run in mobile phone web browsers — our primary target platform. See Spec 001 REQ-001-001.
8. **Hosted inside a static website:** The game ships embedded in a small Bootstrap static site (Spec 011). The Godot game signals quit events to the host page via `postMessage`, and the host owns top-level navigation back to the home page.

---

## Architecture Diagram

```
┌───────────────────────────────────────────────────────────────┐
│  STATIC WEBSITE (Bootstrap 5 — Spec 011)                      │
│  ┌────────────────┐                   ┌────────────────────┐  │
│  │  /  (home)     │  "Play Now" ───▶  │  /play  (host)     │  │
│  │  trailer + CTA │                   │  full-screen canvas│  │
│  └────────────────┘  ◀── navigate back on "quit" postMessage  │
│                                              │                │
│                                              │ embeds         │
│                                              ▼                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │     GODOT WEB EXPORT (Compatibility / WebGL 2.0)         │  │
│  │                                                          │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────┐ ┌────────┐   │  │
│  │  │EventBus  │ │SaveMgr   │ │AudioManager  │ │HostBrdg│──▶│  │
│  │  │(signals) │ │(JSON I/O)│ │(music/sfx)   │ │postMsg │   │  │
│  │  └────┬─────┘ └──────────┘ └──────────────┘ └────────┘   │  │
│  │       │                                                  │  │
│  │  ┌────▼─────────────────────────────────────────────┐    │  │
│  │  │           GameManager (state machine)             │    │  │
│  │  │ LOGO→CINEMATIC→TITLE→DEMO→HUB→TRAINING→RACE→QUIT │    │  │
│  │  └────┬─────────────────────────────────────────────┘    │  │
│  │       │                                                  │  │
│  │  ┌────▼─────┐  ┌──────────────────────────────────┐     │  │
│  │  │NetworkMgr│  │         Active Scene               │   │  │
│  │  │(WSS peer)│  │  (Logo|Cinematic|Title|Race|etc.) │   │  │
│  │  └──────────┘  └──────────────────────────────────┘    │  │
│  └─────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```
