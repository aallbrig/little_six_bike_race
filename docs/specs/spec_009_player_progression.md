# Spec 009 — Player Progression & Persistence

**Depends on:** Spec 003, Spec 004  
**Last Updated:** 2026-04-10  

---

## Overview

Implement the full player progression system: season ladder (ELO), Cred Points economy, cosmetic unlocks, career stats, leaderboard, and the server-side save sync. This spec ties together the training and race systems into a persistent player journey.

---

## Requirements

### REQ-009-001: ELO Rating System
ELO calculation happens server-side after each race. Client displays the result.

```
Base ELO: 1000 (all new players)
K-factor: 32 (rating sensitivity)
Expected score: E = 1 / (1 + 10^((opponent_avg - player) / 400))
Actual score: 1.0 for win, 0.5 for mid, 0.0 for last
ELO change: ΔR = K × (S - E)
```

For 6-player races, calculate pairwise against field average:
```javascript
// Server-side
function calculateEloChange(playerElo, results) {
    const opponents = results.filter(r => r.player_id !== playerId);
    const opponentAvg = opponents.reduce((s, r) => s + r.elo, 0) / opponents.length;
    const position = results.findIndex(r => r.player_id === playerId) + 1;
    const score = 1 - ((position - 1) / (results.length - 1));  // 1.0 for 1st, 0.0 for last
    const expected = 1 / (1 + Math.pow(10, (opponentAvg - playerElo) / 400));
    return Math.round(32 * (score - expected));
}
```

ELO divisions:
| Division | ELO Range | Badge Color |
|---|---|---|
| Freshman | 0–1099 | Gray |
| Sophomore | 1100–1249 | Bronze |
| Junior | 1250–1399 | Silver |
| Senior | 1400–1599 | Gold |
| Crimson | 1600–1799 | Crimson |
| Legend | 1800+ | Animated Gradient |

Division shown as badge in MainHub, Lobby, and results screen.

### REQ-009-002: Cred Points Economy
CP is earned, never purchased. Spent only on cosmetics.

**Earning CP (implemented server-side, sent in RACE_FINISHED payload):**

| Source | Amount |
|---|---|
| Complete training day | 10 |
| Spring Series: participate | 25 |
| Spring Series: top 3 | +50 (1st), +35 (2nd), +20 (3rd) |
| Main race: participate | 75 |
| Main race: 1st | +300 |
| Main race: 2nd | +175 |
| Main race: 3rd | +100 |
| Personal best (any timed event) | +25 |
| First race of the day | +15 |

**Training CP** is purely local (no server needed). Add 10 CP to `PlayerData.cred_points` and save.

**Race CP** comes from server payload:
```json
{
  "type": "RACE_FINISHED",
  "payload": {
    "results": [...],
    "your_cp_earned": 225,
    "your_elo_change": +18,
    "new_elo": 1243
  }
}
```

### REQ-009-003: Cosmetic Unlock System
Implement `scripts/progression/CosmeticManager.gd`:

```gdscript
const COSMETIC_CATALOG := {
    # Jersey Colors (jersey_color_id: int → Color)
    "jersey_0": { "type": "jersey", "name": "Crimson Classic", "cp_cost": 0, "colors": [Color("B31B1B"), Color("FAF3E0")] },
    "jersey_1": { "type": "jersey", "name": "Navy Tradition", "cp_cost": 0, "colors": [Color("1E3A5F"), Color("F59E0B")] },
    "jersey_2": { "type": "jersey", "name": "Forest Pride", "cp_cost": 0, "colors": [Color("166534"), Color("FFFFFF")] },
    "jersey_3": { "type": "jersey", "name": "Midnight Racer", "cp_cost": 150, "colors": [Color("0F172A"), Color("818CF8")] },
    "jersey_4": { "type": "jersey", "name": "Sunrise Sprint", "cp_cost": 150, "colors": [Color("F97316"), Color("FEF08A")] },
    "jersey_5": { "type": "jersey", "name": "Campus Green", "cp_cost": 200, "colors": [Color("166534"), Color("BBF7D0")] },
    "jersey_6": { "type": "jersey", "name": "Steel City", "cp_cost": 200, "colors": [Color("374151"), Color("E5E7EB")] },
    "jersey_7": { "type": "jersey", "name": "Violet Storm", "cp_cost": 250, "colors": [Color("581C87"), Color("DDD6FE")] },
    
    # Bike Skins (swap albedo texture)
    "bike_freshman": { "type": "bike", "name": "Freshman", "cp_cost": 0 },
    "bike_sophomore": { "type": "bike", "name": "Sophomore", "cp_cost": 100 },
    "bike_junior": { "type": "bike", "name": "Junior", "cp_cost": 250 },
    "bike_senior": { "type": "bike", "name": "Senior", "cp_cost": 500 },
    "bike_legend": { "type": "bike", "name": "Legend", "cp_cost": 1000, "requirement": "legend_division" },
    
    # Celebrate Animations
    "celebrate_0": { "type": "celebrate", "name": "Fist Pump", "cp_cost": 0 },
    "celebrate_1": { "type": "celebrate", "name": "Double Point", "cp_cost": 75 },
    "celebrate_2": { "type": "celebrate", "name": "Wheelie Attempt", "cp_cost": 150 },
}

func unlock_cosmetic(cosmetic_id: String) -> bool:
    var item = COSMETIC_CATALOG.get(cosmetic_id)
    if item == null: return false
    if SaveManager.player_data.unlocked_cosmetics.has(cosmetic_id): return false
    
    # Check CP
    if SaveManager.player_data.cred_points < item["cp_cost"]: return false
    
    # Check special requirements
    if item.has("requirement"):
        if item["requirement"] == "legend_division":
            if SaveManager.player_data.elo_rating < 1800: return false
    
    SaveManager.player_data.cred_points -= item["cp_cost"]
    SaveManager.player_data.unlocked_cosmetics.append(cosmetic_id)
    SaveManager.save_game()
    EventBus.sfx_requested.emit("unlock", Vector3.ZERO)
    return true
```

### REQ-009-004: Cosmetics Shop Scene
`scenes/hub/CosmeticsShop.tscn` — accessible from "My Racer" section.

Layout:
- Tab bar: Jersey | Bike | Celebrate
- Per tab: Grid of cosmetic cards
- Each card: preview, name, cost OR "OWNED" badge OR locked (grayed + cost)
- Bottom: "Current CP: [N]" always visible
- Tapping owned item: equip it (mark as active)
- Tapping purchasable item: confirmation dialog with preview

### REQ-009-005: Leaderboard
`scenes/hub/Leaderboard.tscn`

Tabs:
1. **Season Ladder** — top 100 by ELO, current season
2. **Best Times** — top 100 fastest qualifying times
3. **Most Wins** — top 100 by career race wins

Each row:
- Rank badge
- Player name
- Division badge
- Stat (ELO / time / wins)
- "YOU" highlight if local player's row

Implementation: pull from API via `GET /api/leaderboard?type=elo&season=current`

Offline fallback: show "Connect to see the live leaderboard" message with last-cached data.

### REQ-009-006: Career Stats Panel
Accessible from My Racer screen.

Stats tracked (local + server):
```
Races entered: int
Races finished: int
Race wins: int
Best qualifying time: float (seconds)
Most laps led: int
Total training days: int
Seasons completed: int
Highest ELO: int
Total CP earned (lifetime): int
```

Display:
- Two-column grid of stat name + value
- Season history: last 3 seasons, each showing: season number, best race position, ELO start/end

### REQ-009-007: Server Save Sync
When online, player data syncs to server after each significant action.

Sync triggers:
1. Training day complete
2. Race results received
3. Cosmetic purchased/equipped
4. Settings changed (only local, no server sync)

Sync implementation in `SaveManager`:
```gdscript
func save_and_sync() -> void:
    save_game()  # Always save locally first
    if NetworkManager.state == NetworkManager.ConnectionState.DISCONNECTED:
        return  # Skip sync if offline
    _sync_to_server()

func _sync_to_server() -> void:
    var save_json = export_save_json()
    MatchmakingClient.new().sync_save(save_json)
    # Fire and forget — don't block on sync result
    # If sync fails, local save is still good
```

Server reconciliation on login:
```javascript
// Lambda: POST /api/player/save
// Compare server's updated_at vs client's updated_at
// If server is newer: return server data (client should update)
// If client is newer: overwrite server data
// Client handles the response and updates local save if needed
```

### REQ-009-008: Daily Bonus
Track last play date for first-race-of-day bonus:

```gdscript
func check_daily_bonus() -> bool:
    var last_play = SaveManager.get_setting("last_play_date", "")
    var today = Time.get_datetime_string_from_system().substr(0, 10)  # YYYY-MM-DD
    if last_play != today:
        SaveManager.set_setting("last_play_date", today)
        return true  # Grant +15 CP bonus
    return false
```

### REQ-009-009: Season Reset Flow
At the end of each season (main race complete):

1. Show season summary screen:
   - Final ELO and division change (animated)
   - Season stats overview
   - CP earned this season total
2. Option: "START NEW SEASON"
   - Creates new `SeasonData` with `season_id = uuid4()`
   - Keeps all racer stats (no stat reset)
   - ELO carries over
   - CP carries over
   - Season-specific data (qualifying time, spring series results) resets
3. Option: "VIEW SEASON RECORD" (view-only mode for completed season)

### REQ-009-010: Season Calendar (data-driven)
Little Six runs **four seasons per calendar year**, rotating continuously. Only the **Spring Series** is anchored to the real IU Little 500 schedule; the other three are anchored to calendar quarters. The product rationale lives in [ADR 0001](../adr/0001-schedule-alignment-with-little-500.md); this requirement encodes it as data so that the UI and matchmaking can render the correct season without hard-coded dates.

**Data location:** `res://data/season_calendar.json`, loaded on startup by a new `SeasonCalendar` helper (plain GDScript class, not an autoload). The file is plain JSON so an ops task can update it each year.

**Schema:**

```json
{
  "seasons": [
    {
      "id": "spring_2026",
      "label": "Spring Series 2026",
      "kind": "spring_series",
      "aligned_to_little_500": true,
      "little_500_year": 2026,
      "quals_date": "2026-03-21",
      "race_weekend": { "womens": "2026-04-17", "mens": "2026-04-18" },
      "window_start": "2026-01-01",
      "window_end": "2026-04-18"
    },
    {
      "id": "summer_2026",
      "label": "Summer Circuit 2026",
      "kind": "summer_circuit",
      "aligned_to_little_500": false,
      "window_start": "2026-04-19",
      "window_end": "2026-06-30"
    },
    {
      "id": "autumn_2026",
      "label": "Autumn Invitational 2026",
      "kind": "autumn_invitational",
      "aligned_to_little_500": false,
      "window_start": "2026-07-01",
      "window_end": "2026-09-30"
    },
    {
      "id": "winter_2026",
      "label": "Winter Trials 2026",
      "kind": "winter_trials",
      "aligned_to_little_500": false,
      "window_start": "2026-10-01",
      "window_end": "2026-12-31"
    }
  ]
}
```

**Derivation rule (Spring Series dates):** For any year `Y`, once IU publishes that year's Little 500 dates, Spring Series dates are computed as:

```
spring_series.quals_date      = iu_little_500.quals_date      - 7 days
spring_series.race_weekend.*  = iu_little_500.race_weekend.*  - 7 days
spring_series.window_end      = spring_series.race_weekend.mens (or combined race day)
```

This is a one-time ops task per year (update the JSON); no runtime computation against external APIs.

**`SeasonCalendar` interface:**

```gdscript
class_name SeasonCalendar

static func load() -> Array[Dictionary]          # Reads season_calendar.json
static func current(now: String = "") -> Dictionary  # Season whose window contains `now` (defaults to today)
static func next_of_kind(kind: String, now: String = "") -> Dictionary
static func days_until_race_weekend(season: Dictionary, now: String = "") -> int
```

All date arithmetic uses ISO 8601 strings and the `Time` singleton. Time zone is fixed to America/Indiana/Indianapolis for Spring Series; other seasons are timezone-naive (calendar-quarter boundaries).

**Main Hub integration:** The Season action card on `MainHub.tscn` (Spec 002 REQ-002-007) displays:
- The current season label (`SeasonCalendar.current().label`).
- Days until that season's Race Weekend.
- For Spring Series specifically, an additional line: *"Real Little 500: <date>"* — making the one-week offset explicit to the player.

**Ops annual checklist:** Add a runbook entry "When IUSF publishes next year's Little 500 dates, update `season_calendar.json` Spring Series anchors (`iu_dates - 7 days`) and file a deploy." This is also noted in [ADR 0001](../adr/0001-schedule-alignment-with-little-500.md) follow-ups.

---

## Signal Interface

### Emitted via EventBus:
```
racer_stat_changed(stat, old, new)   # From training resolution
player_cp_changed(old_amount, new_amount)
cosmetic_unlocked(cosmetic_id)
elo_changed(old_elo, new_elo, delta)
season_completed(season_id, final_position)
```

### Listens to:
```
EventBus.race_finished(results) → award CP + ELO update
EventBus.training_day_completed → award training CP
```

---

## Acceptance Criteria

- [ ] ELO changes after race completion (test: finish 1st → ELO increases; finish last → ELO decreases)
- [ ] Division badge updates when ELO crosses threshold
- [ ] CP awarded after training day (10 CP, local)
- [ ] CP awarded in RACE_FINISHED payload and added to player total
- [ ] Cosmetic purchase deducts CP, adds cosmetic to unlocked list
- [ ] Cannot purchase cosmetic with insufficient CP (button disabled)
- [ ] Legend bike: unlockable only at ELO ≥ 1800
- [ ] Jersey equip changes racer model color in preview
- [ ] Leaderboard loads from API when online
- [ ] Leaderboard shows offline message when disconnected
- [ ] Career stats increment correctly (test: race enters → races_entered + 1)
- [ ] New season: SeasonData resets but stats/ELO/CP carry over
- [ ] Server sync fires after race complete (verify with network log)
- [ ] Daily bonus awards 15 CP on first race of new day
- [ ] `res://data/season_calendar.json` is present and parses successfully on startup
- [ ] `SeasonCalendar.current()` returns the correct season for at least one known date in each of the four quarterly windows
- [ ] Spring Series dates in the bundled calendar match `IU Little 500 dates − 7 days` for the current year
- [ ] Main Hub Season card renders the current season label and the correct days-until-Race-Weekend value
- [ ] Main Hub Season card, while Spring Series is active, also shows the real IU Little 500 date
