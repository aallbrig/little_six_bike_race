# Spec 002 — Attract Mode & Game Flow

**Depends on:** Spec 001 (Project Structure)  
**Last Updated:** 2026-04-10  

---

## Overview

Implement the full attract mode loop (Logo → Cinematic → Title → Demo → loop) and the top-level game flow that a player traverses from first tap to main hub. This spec covers scene implementations, transitions, and the attract mode state management.

---

## Requirements

### REQ-002-001: Logo Scene
`scenes/logo/Logo.tscn` displays the studio logo and transitions to the cinematic.

- Black background (Color `#000000`)
- Logo image centered: `assets/ui/studio_logo.png` (placeholder: white text "LITTLE SIX STUDIOS")
- Fade-in: 0.5s linear
- Hold: 2.0s
- Fade-out: 0.5s linear
- After fade-out: call `GameManager.transition_to(GameManager.GameState.CINEMATIC)`
- Logo scene is NOT skippable

### REQ-002-002: Intro Cinematic Scene
`scenes/cinematic/IntroCinematic.tscn` plays the 30-second intro sequence.

- Implement as a real-time 3D sequence using the race track assets
- Camera follows a `PathFollow3D` along a pre-defined `Path3D`
- `AnimationPlayer` named `CinematicTimeline` drives: camera position, camera FOV, UI overlay opacity, music
- Seven shots (see GDD Section 3.3 and Level Design camera paths)
- Title card "LITTLE SIX" appears at second 22 (Press Start 2P font, Crimson color, drops in from above)
- Subtitle "The World's Greatest College Weekend" fades in at second 25
- Fade to black at second 28, complete at second 30
- **Skippable** after 5 seconds: "SKIP" button appears top-right (small, secondary style), tapping transitions immediately to `TITLE` state
- After completion: `GameManager.transition_to(GameManager.GameState.TITLE)`
- Emit `EventBus.music_track_requested("attract", 1.0)` at scene start

### REQ-002-003: Title Screen Scene
`scenes/title/TitleScreen.tscn` is the main attract-mode landing screen.

**Visual elements:**
- Animated background: 3D race track scene (simplified, same assets as demo race) with slow camera orbit
- "LITTLE SIX" title: Press Start 2P, 48px, Crimson, centered horizontally at 35% from top
- Subtitle "The World's Greatest College Weekend": Nunito, 18px, Cream, centered, 45% from top
- "TAP TO START" text: Press Start 2P, 24px, Cream, centered, 65% from top
  - Pulses in opacity: 1.0 → 0.3 → 1.0, period = 1.2 seconds

**Behavior:**
- Any tap or click: transitions to either `CREATE_RACER` (if no save) or `MAIN_HUB` (if save exists)
  - Check `SaveManager.player_data != null`
- After 10 seconds of no input: automatically transition to `DEMO`
- Reset 10-second timer if user taps (do not trigger game start on timer reset taps)
- Music: `attract` track continues from cinematic (no restart if already playing)

### REQ-002-004: Demo Race Scene
`scenes/demo/DemoRace.tscn` plays an AI-only race as the attract-mode demo.

**Requirements:**
- Load and run the full `RaceTrack.tscn` scene with 6 AI-controlled riders
- No human input processed
- No HUD shown (clean cinematic view)
- "DEMO" watermark: top-right, Nunito 14px, Cream at 40% opacity
- "TAP TO PLAY" button: bottom-center, secondary button style, always visible
  - Tapping transitions to `CREATE_RACER` or `MAIN_HUB`
- Camera follows the lead AI rider (whichever is in 1st place)
  - Use demo camera (follow cam, same as race)
- After 60 seconds: `GameManager.transition_to(GameManager.GameState.CINEMATIC)` (loop)
- Race AI runs normally; random outcomes fine
- Music: `race_normal` track

### REQ-002-005: Attract Mode Loop Controller
The attract mode loop is managed by `GameManager`. When in LOGO, CINEMATIC, TITLE, or DEMO states:
- Input is monitored
- User tap during TITLE → exit attract
- User tap during DEMO ("TAP TO PLAY") → exit attract
- Timeout in TITLE (10s) → DEMO
- Timeout in DEMO (60s) → CINEMATIC
- CINEMATIC complete → TITLE
- LOGO complete → CINEMATIC

### REQ-002-006: Create Racer Scene
`scenes/hub/CreateRacer.tscn` — first-run player creation.

**Steps (single scrollable panel on mobile):**

Step 1 — Welcome:
- Flavor text: "Since 1951, the cinder oval has decided glory."
- "BEGIN YOUR STORY" primary button

Step 2 — Choose Background:
- 4 cards (2×2 grid on mobile), one per background
- Each card: background name, stat preview (5 mini bars), flavor quote
- Tap card to select; selected card has Crimson border highlight
- Backgrounds: Weekend Warrior, Ex-Track Star, Distance Rider, Complete Newbie (see GDD 4.2)

Step 3 — Name Your Racer:
- Text input, placeholder "Enter racer name"
- Max 16 characters, min 2 characters
- Validation: no special characters except spaces and hyphens
- Default: "My Racer"

Step 4 — Choose Jersey:
- 8 preset color swatches (row of circles, 44px each)
- Selected swatch has white ring indicator
- Preview shows racer model with selected jersey (3D preview in SubViewport, or 2D illustration)

Step 5 — Confirm:
- Summary card showing name + background + jersey preview
- "RIDE ON" primary button → creates `PlayerData` + `RacerData`, calls `SaveManager.save_game()`, transitions to `MAIN_HUB`
- "BACK" secondary button → returns to Step 4

**Navigation:**
- "NEXT" advances between steps
- "BACK" or swipe-right returns to previous step
- Step indicator dots at top (5 dots, current step highlighted)

### REQ-002-007: Main Hub Scene
`scenes/hub/MainHub.tscn` — the game's home screen.

**Visual layout (portrait, scrollable):**

Top section:
- Player name + ELO rating badge
- Racer portrait (3D in SubViewport, idle animation)
- Season progress bar: "Week X / Race Week"
- Race Form indicator: "HOT 🔥 / WARM / COLD" (text + colored badge, no emoji in code — use icon image)

Action cards (full-width, stacked):
1. **MY RACER** — "Train today. Stats: [Speed][Endurance]...[Fatigue bar]" → opens Training Day
2. **RACE NOW** — "Enter the multiplayer race. [player count online] online" → opens Room Select
3. **SPRING SERIES** — "Next event: [event name]. [days until next]" → opens current Spring event
4. **LEADERBOARD** — "Season standings" → opens Leaderboard

Bottom nav (fixed):
- My Racer | Race | Season | Settings (tabs)

**Behavior:**
- Hub checks if training day is available: if current week/day training not yet done, MY RACER card pulses
- Music: `hub` track (fade from whatever was playing)

### REQ-002-008: Scene Transition Effects
All scene transitions use the iris-wipe effect from the Art Bible.

Implement `TransitionManager` (Node, child of GameManager or separate autoload):
- `transition_out(callback: Callable, duration: float = 0.3) -> void` — iris closes (circle shrinks to center)
- `transition_in(duration: float = 0.3) -> void` — iris opens (circle expands from center)
- Transition overlay: full-screen `ColorRect` black with a circular mask shader
- `GameManager.transition_to` always calls `transition_out` before loading new scene, then `transition_in` after scene is ready

---

## Data Structures

No new data structures beyond Spec 001. CreateRacer writes to `PlayerData` and `RacerData`.

---

## Scene/Node Hierarchy

### Logo.tscn
```
Logo (Control)
├── Background (ColorRect) [color: #000000, full rect]
└── LogoContainer (CenterContainer)
    └── LogoImage (TextureRect) [texture: assets/ui/studio_logo.png]
    └── AnimationPlayer [animations: "show" (fade in/out)]
```

### TitleScreen.tscn
```
TitleScreen (Node)
├── BackgroundViewport (SubViewportContainer)
│   └── SubViewport
│       └── TrackBackground (preloaded track scene, no game logic)
├── UI (CanvasLayer)
│   ├── TitleLabel (Label) ["LITTLE SIX"]
│   ├── SubtitleLabel (Label)
│   ├── TapLabel (Label) ["TAP TO START", with AnimationPlayer for pulse]
│   └── IdleTimer (Timer) [wait_time: 10.0, autostart: true]
```

### MainHub.tscn
```
MainHub (Control)
├── ScrollContainer (full screen)
│   └── VBoxContainer
│       ├── PlayerHeader (HBoxContainer)
│       │   ├── RacerPreview (SubViewportContainer)
│       │   └── PlayerInfo (VBoxContainer)
│       ├── SeasonProgress (ProgressBar)
│       ├── ActionCards (VBoxContainer)
│       │   ├── MyRacerCard (PanelContainer)
│       │   ├── RaceNowCard (PanelContainer)
│       │   ├── SpringSeriesCard (PanelContainer)
│       │   └── LeaderboardCard (PanelContainer)
│       └── (padding for bottom nav)
└── BottomNav (HBoxContainer) [anchored to bottom]
    ├── NavRacer (Button)
    ├── NavRace (Button)
    ├── NavSeason (Button)
    └── NavSettings (Button)
```

---

## Signal Interface

### Emitted via EventBus:
- `game_state_changed` — on every transition
- `music_track_requested` — on scene entry (appropriate track per scene)

### Listens to EventBus:
- `game_state_changed` — transition scenes accordingly (GameManager drives this)

### Local signals (within scenes):
- `TitleScreen._on_idle_timer_timeout` → `EventBus.game_state_changed` → Demo
- `TitleScreen._input` → detect any tap → transition to game

---

## Acceptance Criteria

- [ ] On fresh launch: Logo → Cinematic → Title screen plays in sequence
- [ ] Logo plays for exactly 3 seconds (0.5 fade in + 2 hold + 0.5 fade out)
- [ ] Cinematic: "SKIP" button appears after 5 seconds
- [ ] Tapping "SKIP" immediately shows title screen
- [ ] Title screen: "TAP TO START" pulses continuously
- [ ] Title screen auto-advances to Demo after 10 seconds of no input
- [ ] Demo plays for 60 seconds then returns to Cinematic
- [ ] Attract loop runs at least 3 cycles without errors
- [ ] Tapping Title screen with no save → CreateRacer scene
- [ ] Completing CreateRacer → MainHub scene
- [ ] Tapping Title screen with existing save → MainHub scene
- [ ] All transitions use iris-wipe (circle mask opens/closes)
- [ ] Music crossfades correctly between scenes (no hard cuts except bell lap)
- [ ] MainHub shows correct player name and season progress after creation
