# Spec 003 — Training System (Tamagotchi)

**Depends on:** Spec 001 (Project Structure)  
**Last Updated:** 2026-04-10  

---

## Overview

Implement the Tamagotchi-style training system: the daily training day UI, activity selection, stat resolution, random events, fatigue management, injury system, and season progression logic. This is the non-race half of the core game loop.

---

## Requirements

### REQ-003-001: Training Day Scene
`scenes/training/TrainingDay.tscn` displays the training activity selection screen.

**Visual layout (portrait):**

Top area:
- Header: "WEEK X — DAY Y" (Press Start 2P, 24px)
- Racer portrait: 3D in SubViewport (idle or context-appropriate animation)
- Stat bars: 5 horizontal bars (Speed, Endurance, Recovery, Handling, TeamChem)
  - Each bar: label left, colored fill bar, numeric value right
  - Color: Green < 60, Amber 60–79, Crimson ≥ 80
- Fatigue indicator: arc gauge (semicircle at bottom of racer portrait area)
  - Color: Green 0–30, Amber 31–70, Red 71–100
  - Label: "FRESH" / "TIRED" / "OVERLOADED" / "DANGER"

Middle area — Activity Selection Grid:
- 2 × 4 grid of activity cards
- Each card: icon + activity name + brief effect preview (e.g., "+Speed +Fatigue")
- Selected slot 1: crimson ring highlight
- Selected slot 2: cream ring highlight
- Grayed-out cards: REST_DAY when one slot already filled with non-rest; fatigue-gated activities

Bottom area:
- Slot display: "Slot 1: [activity name or empty]" / "Slot 2: [activity name or empty]"
- "CONFIRM DAY" primary button (disabled if Slot 1 is empty)
- "CONFIRM DAY" enables when at least Slot 1 is filled

### REQ-003-002: Activity Selection Logic
Implement in `scripts/training/TrainingManager.gd`:

```
Rules:
1. REST_DAY selected in Slot 1 → Slot 2 locked (REST_DAY consumes both slots)
2. REST_DAY selected in Slot 2 → error; swap REST_DAY to Slot 1 automatically
3. Same activity cannot be in both Slot 1 and Slot 2
4. If racer.fatigue >= 80: only REST_DAY, RECOVERY_SPIN, NUTRITION_PLAN are selectable
   - Other cards are visually grayed out and show "Need Rest" tooltip on tap
5. If racer.is_injured and injury_days_remaining > 0: only REST_DAY is selectable
   - Show "INJURED — Forced Rest" tooltip
```

### REQ-003-003: Activity Resolution
When player taps "CONFIRM DAY":

1. Transition to a "resolution" sub-view (animate out the activity grid, animate in resolution)
2. Show Activity 1 icon + name + resolving animation (racer animation matches activity)
3. Compute stat changes:
   ```
   base_changes = TrainingActivity.EFFECTS[activity_type]
   fatigue_mult = _get_fatigue_multiplier(racer.fatigue)
   # Apply multiplier only to positive gains, not fatigue cost
   for stat, delta in base_changes:
       if stat != "fatigue" and delta > 0:
           effective_delta = round(delta * fatigue_mult)
       else:
           effective_delta = delta
   ```
4. Apply soft cap:
   ```
   If racer[stat] + delta > 85:
       effective_delta = max(0, 85 - racer[stat]) / 2   # Gains above 85 halved
   If racer[stat] + delta > 90:
       effective_delta = max(0, 90 - racer[stat]) / 4   # Gains above 90 quartered
   ```
5. Show stat changes one by one with animation (each stat bar animates to new value, +N or -N floats up)
6. Emit `EventBus.training_activity_resolved` for each activity
7. Repeat for Activity 2 if present
8. After both activities: roll for random event (see REQ-003-005)
9. Advance season day counter
10. Transition to TrainingResults scene

### REQ-003-004: Fatigue Multiplier
Implement `_get_fatigue_multiplier(fatigue: int) -> float` in TrainingManager:

| Fatigue | Label | Multiplier | Morale effect |
|---|---|---|---|
| 0–30 | FRESH | 1.1 | +0/day |
| 31–55 | GOOD | 1.0 | +0/day |
| 56–70 | TIRED | 0.8 | -0/day |
| 71–85 | OVERLOADED | 0.6 | -1/day |
| 86–100 | DANGER ZONE | 0.4 | -2/day |

When fatigue crosses a threshold boundary (up or down), emit:
`EventBus.fatigue_threshold_crossed(old_label, new_label)`
AudioManager listens and plays `fatigue_warning` SFX on crossing into OVERLOADED or DANGER ZONE.

### REQ-003-005: Random Event System
Implement `scripts/training/EventRNG.gd`:

After both activities resolve, roll for random event:
```
Base probability: 25% per training day
If week >= 4: probability increases to 35%
If fatigue >= 71: add +10% chance
```

If event fires, select from weighted event table:
```gdscript
const EVENTS := [
    { "id": "breakthrough", "weight": 10, "condition": "fatigue < 50 and week >= 3" },
    { "id": "minor_strain", "weight": 20, "condition": "fatigue > 60" },
    { "id": "rival_encounter", "weight": 15, "condition": "true" },
    { "id": "rain_day", "weight": 15, "condition": "week <= 4" },
    { "id": "equipment_check", "weight": 10, "condition": "true" },
    { "id": "coach_pep_talk", "weight": 10, "condition": "morale < 40" },
    { "id": "overtraining_warning", "weight": 20, "condition": "fatigue > 75" },
    { "id": "nutrition_win", "weight": 8, "condition": "nutrition_plan_chosen_today" },
    { "id": "weather_perfect", "weight": 12, "condition": "true" },
    { "id": "illness_risk", "weight": 15, "condition": "fatigue > 80" },
]
```

Events with failing conditions are excluded from the roll pool.
Weight is relative (sum of eligible weights = denominator).

Event effects (see GDD Section 6.4 for descriptions):

| Event ID | Effect |
|---|---|
| `breakthrough` | +5 to the stat trained most today |
| `minor_strain` | +3 fatigue, -1 to last trained stat |
| `rival_encounter` | +2 speed, +3 morale |
| `rain_day` | Next training day: only REST_DAY, RECOVERY_SPIN, VIDEO_STUDY, NUTRITION_PLAN available (store flag in SeasonData) |
| `equipment_check` | One fewer activity slot available next training day |
| `coach_pep_talk` | +10 morale |
| `overtraining_warning` | Force REST_DAY on next training day (store flag) |
| `nutrition_win` | Double Nutrition Plan effect if Nutrition Plan was chosen today |
| `weather_perfect` | All fatigue gains halved for today (retroactively applied) |
| `illness_risk` | 30% chance: trigger injury (see REQ-003-006) |

Emit `EventBus.training_random_event_fired(event_id, effect_dict)`.

### REQ-003-006: Injury System
When an injury occurs:
1. Select a stat to affect: the stat with the highest training today (or Speed if none)
2. Reduce that stat by random(5, 10) points temporarily (stored as `injury_delta: int` in SeasonData)
3. Set `racer.is_injured = true`
4. Set `racer.injury_days_remaining = random(2, 3)`
5. Each subsequent training day: decrement `injury_days_remaining`; when reaches 0, heal
6. Healing: restore `injury_delta` points to the stat (not above the pre-injury value if player trained it higher — use `min(current + delta, max_at_injury)`)
7. Visual: racer sprite shows bandage overlay during injury
8. Emit `EventBus.injury_occurred(stat_name, days_remaining)`

### REQ-003-007: Training Results Scene
`scenes/training/TrainingResults.tscn` — shown after activity resolution.

**Elements:**
- "TRAINING COMPLETE" header
- Day/Week indicator
- Stats change summary: list of stat names with +N / -N badges (green/red)
- Random event card (if one fired): event name + flavor text + effect
- Race Form indicator updated: "HOT / WARM / COLD"
- Fatigue bar updated (animated from old to new value)
- "NEXT DAY" button → returns to MainHub (or advances to Spring Event scene if it's event day)

### REQ-003-008: Season Structure
Implement in `scripts/training/SeasonManager.gd` (or within TrainingManager):

```
Season = 7 weeks
Week 1–6: 3 training days + 1 spring event
Race Week (Week 7): 2 qualifying time trials + Race Day

Spring Event Schedule (fixed):
  Week 1 Event: Individual Time Trial (unranked, tutorial)
  Week 2 Event: Miss-N-Out
  Week 3 Event: Team Pursuit
  Week 4 Event: Individual Time Trial (ranked)
  Week 5 Event: Miss-N-Out (ranked)
  Week 6 Event: Qualifying Time Trial (sets race grid position)
  Race Week: Main Race

Season progression stored in SeasonData:
  - current_week: int (1-7)
  - current_day: int (1-4, where 4 = event day)
  - completed_training_days: Array of { week, day, activities_chosen, changes }
  - spring_event_results: Array of { event_type, result, rank, cp_earned }
  - qualifying_time: float (set during Week 6)
  - qualifying_position: int
```

### REQ-003-009: Season Completion
When the main race completes:
- Show season summary screen
- Award career stats: races, wins, best times
- Award Cred Points for the season total
- Option: "Start New Season" → creates new SeasonData, keeps RacerData stats (no reset)
- Option: "Return to Hub" → stays on current completed season data (view only)

### REQ-003-010: Racer Stats Screen
Accessible from MainHub "MY RACER" card → "View Stats" secondary action.

Displays:
- Racer name + jersey preview
- All 5 stat bars with numeric values and "soft cap" indicator above 85
- Fatigue arc gauge with label
- Morale bar
- Race Form (HOT/WARM/COLD) with explanation tooltip
- Career stats: wins, races, seasons played
- Season history (last 3 seasons: position achieved)

---

## Data Structures

### WeekData (in SeasonData)
```gdscript
class_name WeekData
extends RefCounted

var week_number: int
var training_days: Array[TrainingDayRecord] = []
var event_result: EventResult = null
var rain_day_flag: bool = false
var forced_rest_flag: bool = false
```

### TrainingDayRecord
```gdscript
class_name TrainingDayRecord
extends RefCounted

var week: int
var day: int
var activities: Array[int] = []     # TrainingActivity.Type values
var stat_changes: Dictionary = {}   # stat_name → final_delta
var event_fired: String = ""        # event id or ""
```

---

## Signal Interface

### Emitted via EventBus:
```
training_day_started(week: int, day: int)
training_activity_chosen(activity: TrainingActivity.Type, slot: int)
training_activity_resolved(activity: TrainingActivity.Type, changes: Dictionary)
training_random_event_fired(event_id: String, effects: Dictionary)
training_day_completed(week: int, day: int, summary: Dictionary)
fatigue_threshold_crossed(old_level: String, new_level: String)
injury_occurred(stat_affected: String, duration_days: int)
racer_stat_changed(stat: String, old_value: int, new_value: int)
```

### Listens to EventBus:
```
game_state_changed → react to entering TRAINING_DAY state
```

---

## Acceptance Criteria

- [ ] TrainingDay shows all 8 activity cards
- [ ] Fatigue ≥ 80: only 3 recovery activities are selectable; others visually grayed
- [ ] REST_DAY locks both slots (can't select a second activity)
- [ ] Same activity cannot be selected twice
- [ ] Stat resolution animates each bar to new value in sequence
- [ ] Soft cap: gaining past 85 is visually possible but slowed (test: stat at 84 + 5 gain = 86.5 → rounds to 87 but only +1.5 effective above 85 → stat becomes 86)
- [ ] Fatigue multiplier verified: with fatigue=75 (OVERLOADED), Sprint Intervals gives +1 Speed (+3 × 0.6 = +1.8 → floor = 1)
- [ ] Random event fires approximately 25% of days (test over 20 days)
- [ ] Injury flag prevents non-rest activity selection
- [ ] Injury heals after specified days
- [ ] Season advances correctly: 3 training days → 1 event → next week
- [ ] TrainingResults scene shows accurate delta summary
- [ ] SaveManager.save_game() called after each training day completes

---

## Implementation Notes

1. **Racer animation:** The 3D racer in the SubViewport should play different AnimationPlayer clips based on selected activity (e.g., "sprint_intervals" animation shows the racer sprinting, "rest" shows them sleeping). Use a placeholder idle animation if specific animations aren't yet created.
2. **Stat change math precision:** Always compute on integer stats. Round halves toward zero. Never let stats go below 0 or above 100.
3. **Race Form calculation:** `race_form = clamp((recent_training_consistency × 0.6) + (morale × 0.2) + ((100 - fatigue) × 0.2), 0, 100)`. Show HOT if > 70, WARM if 40-70, COLD if < 40. Recalculate at end of each training day.
4. **Morale decay:** Morale is not explicitly trained. It decays based on fatigue level (see REQ-003-004 table) and recovers via Team Meeting and Rest Day. Morale starts at 50; floor is 10; ceiling is 100.
5. **Rain day flag:** Store in `SeasonData.next_day_rain: bool`. Checked at start of next TrainingDay; if true, restrict available activities and show "Rain Day" banner at top of scene.
