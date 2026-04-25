# Spec 013: Dynamic Camera System

## Overview
Transform the static race camera into a dynamic, cinematic system that tells the story of Little 500 racing. The camera should feel alive, dramatic, and enhance the excitement of cycling rather than just following the rider.

## Requirements

### REQ-013-001: Multiple Camera Modes
- **Chase Camera**: Standard follow camera with smooth damping
- **Action Camera**: Dynamic angles during sprints and key moments
- **Cinematic Camera**: Dramatic shots during race highlights
- **POV Camera**: First-person view for immersive sprinting
- **Spectator Camera**: Overview shots of the pack

### REQ-013-002: Automatic Camera Switching
- Switch based on race events (`sprint_activated`, `lap_completed`, `exchange_executed`)
- Smart camera selection based on race situation (final lap vs early race)
- Smooth transitions between camera modes (0.5-1.0s blends)
- Player override capability (manual camera switching)

### REQ-013-003: Cinematic Moments
- Dramatic camera work during:
  - Final lap bell ring
  - Successful sprint finishes
  - Rider exchanges and burns
  - Crashes and recoveries
  - Race victory moments

### REQ-013-004: Mobile Optimization
- All camera modes must work on portrait mobile screens
- Touch gestures for manual camera control (swipe to change angles)
- Performance-friendly camera calculations
- Fallback to simple chase camera on low-end devices

### REQ-013-005: Camera Behaviors
- Dynamic follow distance based on speed
- Anticipatory camera movement (looks ahead during sprints)
- Shake effects for crashes and high-intensity moments
- Smooth target tracking for multi-rider scenes

## Camera State Machine
```gdscript
enum CameraMode {
    CHASE,
    ACTION,
    CINEMATIC,
    POV,
    SPECTATOR
}

# Camera priorities for automatic switching
const CAMERA_PRIORITIES = {
    CameraMode.CINEMATIC: 100,
    CameraMode.ACTION: 80,
    CameraMode.POV: 60,
    CameraMode.CHASE: 40,
    CameraMode.SPECTATOR: 20
}
```

## Signal Interface
**Listens to:**
- `race_started()`
- `sprint_activated(racer_id: int)`
- `lap_completed(racer_id: int, lap_number: int, lap_time: float)`
- `exchange_executed(...)`
- `crash_occurred(racer_id: int)`
- `race_finished(results: Array)`
- `bell_lap_triggered()`

**Emits:**
- `camera_mode_changed(new_mode: CameraMode)`

## Scene/Node Hierarchy
- `RaceCamera` (child of RaceTrack)
- `CameraController` script managing state machine
- Multiple `Camera3D` nodes for different modes
- `CameraTransitionManager` for smooth blends

## Acceptance Criteria
- [ ] Camera feels dynamic and exciting during races
- [ ] Automatic camera switching enhances key moments
- [ ] All camera modes work on mobile portrait orientation
- [ ] Smooth transitions between camera states
- [ ] Camera work tells the story of the race
- [ ] Playtesters describe camera as "cinematic" or "immersive"

## Implementation Notes
- Start with chase + action camera modes
- Use Godot's Camera3D with custom scripts for behaviors
- Implement camera shake using noise or tween systems
- Create camera presets that can be tuned in editor
- Integrate with RaceController events for automatic switching

**Priority:** High  
**Sprint:** 3 - Polish & Engagement  
**Owner:** Camera Specialist  
**Target Completion:** End of Week 1

---
**Status:** [ ] Not Started
**Related Documents:** `docs/sprint/Sprint_03_Polish_and_Engagement.md`, `docs/specs/spec_004_multiplayer_race.md`
