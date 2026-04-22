# Spec 010 — Race Physics & Simulation

**Depends on:** Spec 004  
**Last Updated:** 2026-04-10  

---

## Overview

Define the complete physics simulation for the race: coaster brake bike model, track spline following, cornering model, collision detection, spring series event mechanics (Miss-N-Out elimination, Team Pursuit), and qualifying time trial. This spec provides the mathematical and implementation details for all race physics.

---

## Requirements

### REQ-010-001: Bike Physics Model
The Little Six bike is a single-speed coaster brake bike. The physics model must reflect this accurately.

**Coaster brake behavior:**
- Pedaling forward → friction force removed → bike accelerates
- Releasing pedals → no pedal friction, but rolling resistance applies → very slow coast deceleration
- Pedaling backward → coaster brake engages → strong deceleration force
- In-game abstraction: "hold to pedal" is implicit (auto-pedaling), explicit brake button = coaster brake engaged

**Force model:**
```
Net force = Pedal force - Aerodynamic drag - Rolling resistance - Brake force

Pedal force (when accelerating):
  F_pedal = m × a_desired   where a_desired = ACCEL = 5.0 m/s²

Aerodynamic drag (always present):
  F_drag = 0.5 × Cd × A × ρ × v²
  Cd = 1.0 (upright rider, modest streamlining)
  A = 0.5 m² (frontal area, upright position)
  ρ = 1.2 kg/m³ (air density)
  Simplified: F_drag = 0.3 × v² (Newton)
  At terminal velocity (max speed): F_pedal = F_drag → v_max = sqrt(F_pedal / 0.3)

Rolling resistance (always present):
  F_roll = μ_r × m × g   where μ_r = 0.005 (cinder track), m = 85 kg, g = 9.8
  F_roll = 4.2 N (≈ constant, simplified to COAST_DECEL = 0.05 m/s²)

Brake force:
  F_brake = μ_b × m × g   where μ_b = 0.7 (coaster brake coefficient)
  F_brake = 582 N
  Deceleration = F_brake / m = 6.85 m/s² → game constant BRAKE_DECEL = 7.0 m/s²
  (Slightly less than real for game feel — not an instant stop)
```

**Racer mass:** 85 kg (rider + bike). Not exposed to player; used internally for force calculations.

### REQ-010-002: Track Spline System
The track is an oval. Define it as a `Path3D` for camera following and AI pathfinding.

Track path definition (4 control points, Bezier):
```
# Front straight start (near pit lane)
P0 = Vector3(-50, 0, 0)    # Start/finish line left edge

# Turn 1 entry → apex → exit
P1 = Vector3(50, 0, 0)     # Right of front straight
P2 = Vector3(90, 0, -40)   # Turn 1 (Bezier handle)
P3 = Vector3(50, 0, -80)   # Back straight right entry

# Back straight
P4 = Vector3(-50, 0, -80)  # Back straight left exit

# Turn 2 entry → apex → exit  
P5 = Vector3(-90, 0, -40)  # Turn 2 (Bezier handle)
P6 = Vector3(-50, 0, 0)    # Returns to P0

Track Path3D curve is closed (loop).
Track width: 8m either side of the centerline path.
```

**Track following for AI:**
- AI rides `PathFollow3D` along the track path, offset by their lane position
- Human riders are free (CharacterBody3D), but AI follows the path with some noise

**Track zone detection:**
- Turns defined as sections where path tangent changes by > 20°
- Straights: everywhere else
- Zones stored as float ranges (0.0–1.0) of `PathFollow3D.progress_ratio`

```gdscript
const TURN_ZONES := [
    [0.22, 0.38],   # Turn 1 (25% - 38% of lap)
    [0.72, 0.88],   # Turn 2 (72% - 88% of lap)
]

func is_in_turn(progress_ratio: float) -> bool:
    for zone in TURN_ZONES:
        if progress_ratio >= zone[0] and progress_ratio <= zone[1]:
            return true
    return false
```

### REQ-010-003: Lap Progress Tracking
Track each rider's progress around the lap using `PathFollow3D` projection:

```gdscript
# In RaceController, per rider:
func _update_rider_progress(rider: CharacterBody3D, track_path: Path3D) -> void:
    # Project rider's global position onto the track path
    var offset = track_path.curve.get_closest_offset(rider.global_position)
    var total_length = track_path.curve.get_baked_length()
    var progress = offset / total_length  # 0.0 to 1.0
    
    rider.set_meta("track_progress", progress)
    rider.set_meta("track_offset", offset)

# Lap counting: when progress crosses 0.0 (start/finish) from forward direction
func _check_lap_completion(rider: CharacterBody3D) -> void:
    var old_progress = rider.get_meta("prev_track_progress", 0.5)
    var new_progress = rider.get_meta("track_progress", 0.5)
    
    # Detect crossing the start/finish line (0.0 or 1.0 threshold)
    if old_progress > 0.9 and new_progress < 0.1:
        # Forward lap completion
        _on_lap_completed(rider)
    elif old_progress < 0.1 and new_progress > 0.9:
        # Going backwards (crash recovery?) — do not count
        pass
    
    rider.set_meta("prev_track_progress", new_progress)
```

### REQ-010-004: Race Position Calculation
Positions are calculated every 0.5 seconds (not every frame — too expensive for 6 riders):

```gdscript
func _update_race_positions() -> void:
    # Sort by: laps_completed DESC, track_progress DESC
    var sorted = racers.duplicate()
    sorted.sort_custom(func(a, b):
        if a.laps_completed != b.laps_completed:
            return a.laps_completed > b.laps_completed
        return a.get_meta("track_progress", 0.0) > b.get_meta("track_progress", 0.0)
    )
    
    for i in sorted.size():
        var old_pos = sorted[i].get_meta("race_position", i + 1)
        var new_pos = i + 1
        sorted[i].set_meta("race_position", new_pos)
        if old_pos != new_pos:
            EventBus.racer_position_changed.emit(sorted[i].get_meta("racer_id"), new_pos)
```

### REQ-010-005: Qualifying Time Trial
A solo 4-lap time trial. Same track, no other riders, pure speed.

**Qualifying scene:** Reuse `RaceTrack.tscn` with modifications:
- Set racer count to 1 (local player only)
- No pit zones needed
- Ghost rider: show the player's best previous qualifying time as a ghost
  - Ghost position stored as `Array[float]` of track offsets at each 0.1s interval
  - Ghost replayed at same speed

**Time calculation:**
```gdscript
var qual_start_time: float = 0.0
var lap_times: Array[float] = []

func _on_lap_completed(rider: CharacterBody3D) -> void:
    var lap_time = Time.get_ticks_msec() / 1000.0 - qual_start_time
    lap_times.append(lap_time)
    
    if lap_times.size() == 4:
        # Qualifying complete: use lap 2+3+4 time (lap 1 is flying start warmup)
        var official_time = lap_times[1] + lap_times[2] + lap_times[3]
        _finish_qualifying(official_time)

func _finish_qualifying(time: float) -> void:
    SaveManager.player_data.current_season.qualifying_time = time
    # If this is better than previous: save as personal best
    var pb = SaveManager.get_setting("qual_pb", 999999.0)
    if time < pb:
        SaveManager.set_setting("qual_pb", time)
    SaveManager.save_game()
    EventBus.game_state_changed.emit(GameManager.GameState.RACE_RESULTS)
```

### REQ-010-006: Miss-N-Out Event
8 riders start. Last rider on each lap is eliminated. Final 2 do a head-to-head finish.

**Implementation:**
- Load `RaceTrack.tscn`, set rider count to 8 (1 human + 7 AI)
- After each lap completes: check if any rider is last place
  - Last place at each lap crossing = eliminated
  - "Double save" rule: if two riders are within 0.3 seconds at lap completion, neither eliminated
- Elimination animation: rider's model fades out, exits track to infield
- `HUD` shows elimination indicator: "4 riders remain" counter
- When 2 riders remain: both sprint bars refill, "HEAD-TO-HEAD!" overlay, 1 lap final

```gdscript
func _check_elimination_after_lap() -> void:
    if riders.size() <= 2: return
    
    # Find last-place rider(s)
    var positions = _get_sorted_positions()
    var last = positions.back()
    var second_last = positions[positions.size() - 2]
    
    # Double save check
    var time_gap = abs(last.get_meta("lap_time") - second_last.get_meta("lap_time"))
    if time_gap < 0.3:
        return  # Double save — no elimination this lap
    
    _eliminate_rider(last)
```

### REQ-010-007: Team Pursuit Event
Two teams of 2 riders each. Teams start on opposite sides of the track (start/finish line and mid-back-straight). First team to catch the other (or complete 10 laps) wins.

**Team Pursuit Scene:**
- Modified `RaceTrack.tscn`: 4 riders, 2 teams
- Team A starts at start/finish line (P0)
- Team B starts at the 180° opposite point (mid-back-straight)
- Race direction: clockwise
- Catch condition: any rider from Team A passes any rider from Team B
- Lap condition: after 10 laps, measure the gap (team with more track progress wins)

**Team gap visualization:**
- Minimap shows both teams' lead riders with a connecting line
- Gap indicator: "Team A ← 12.3m → Team B" in HUD

**Team relay mechanics (Team Pursuit only, even in Phase 1):**
- Each team has 2 riders alternating every lap
- Rider 1 leads lap 1; Rider 2 leads lap 2; etc.
- In solo play: player controls their lap; AI rides the "off" lap
- Exchange is automatic at lap completion (not manual exchange zone)

### REQ-010-008: Starting Grid Generation
For the main race, starting positions are determined by qualifying time:

```gdscript
func generate_starting_grid(qualifiers: Array[Dictionary]) -> Array[Vector3]:
    # qualifiers sorted by qualifying_time ASC (fastest first)
    var positions := []
    
    # Grid: single-file line before start/finish
    var START_POSITION := Vector3(-50.0, 0.0, 1.0)  # Track left edge at SF line
    var RIDER_SPACING := 1.5  # meters between riders
    
    for i in qualifiers.size():
        var pos = START_POSITION + Vector3(0, 0, i * RIDER_SPACING)
        positions.append(pos)
    
    return positions
# Fastest qualifier (position 0) is closest to the start line
# Riders start in reverse direction, then turn when race begins
```

### REQ-010-009: Collision Model
Rider collisions are simplified (not full rigid body physics):

**Rider-to-rider collisions:**
- When two `CharacterBody3D` riders are within 0.6m of each other:
  - Overlapping detection via Area3D (separate from crash — this is just contact)
  - Apply a small separation force (push outward)
  - No "pinball" physics — just gentle repulsion
  - Crash only triggers on CORNERING over speed cap

**Rider-to-wall collisions:**
- Track has invisible `StaticBody3D` walls 0.5m inside the actual track edge
- On wall contact: velocity component along wall normal set to zero, slight speed reduction
- No bouncing

**Collision categories:**
```
Groups:
  "rider"  → CharacterBody3D (each racer)
  "wall"   → StaticBody3D (track boundary)
  "pit"    → Area3D (pit zone triggers)
  "finish" → Area3D (start/finish line trigger)
```

---

## Acceptance Criteria

- [ ] Coaster brake: releasing accelerate does not slow the bike appreciably (< 0.05 m/s² deceleration when coasting)
- [ ] Brake button decelerates at ≥ 6.0 m/s² from max speed
- [ ] Rider cannot steer outside track boundary (wall stops them)
- [ ] Track progress calculation is monotonically increasing (going forward increases progress)
- [ ] Lap counted exactly once per start/finish line crossing
- [ ] Backward movement across start line does NOT increment lap
- [ ] Position sort: rider with more laps always ranked higher than rider with fewer laps
- [ ] Qualifying time: 3-lap aggregate (laps 2+3+4) correctly calculated
- [ ] Ghost rider in qualifying matches stored data timing
- [ ] Miss-N-Out: last rider eliminated each lap; double save within 0.3s
- [ ] Miss-N-Out: final 2 riders compete head-to-head
- [ ] Team Pursuit: gap between teams visible on minimap
- [ ] Team Pursuit: catch condition correctly detected
- [ ] Starting grid: fastest qualifier at front of grid
- [ ] Rider-to-rider collision: gentle separation, no teleporting
- [ ] At high speed in corners: crash probability increases (test at 120% of corner speed cap)
