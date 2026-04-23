# Spec 012 — Weekly Races, Leagues & Leaderboards

**Depends on:** Spec 004 (Multiplayer Race), Spec 005 (Networking), Spec 006 (AWS Infrastructure), Spec 009 (Progression)
**Last Updated:** 2026-04-22

---

## Overview

This spec implements the three-day weekly race cadence, the Women's/Men's league selection, the persistence of weekly race results, and the leaderboard UI (with rank-change delta symbols) that surfaces them. It also defines **Season Momentum** — the transient stat that rewards weekly participation without overwhelming finale skill.

The product rationale is in [ADR 0002 — Weekly Race Format & League Selection](../adr/0002-weekly-race-format-and-leagues.md). The control-scheme context (weekly races share the same inputs as finales) is in [ADR 0003 — Input Control Scheme](../adr/0003-input-control-scheme.md).

---

## Requirements

### REQ-012-001: Weekly Race Format

Every week of every season (Spring Series, Summer Circuit, Autumn Invitational, Winter Trials — see [Spec 009 REQ-009-010](spec_009_player_progression.md)) runs three scheduled races:

| Day offset in week | Race | Eligibility | Lap count | Time cap |
|---|---|---|---|---|
| Day 1 (anchor: Friday) | **Women's Weekly** | Women's League | 150 laps | 5 min |
| Day 2 (anchor: Saturday) | **Men's Weekly** | Men's League | 150 laps | 5 min |
| Day 3 (anchor: Sunday) | **Mixed Weekly** | Both leagues | 150 laps | 5 min |

- **Lap count** is fixed at 150; at the standard 1.5–2.0 sec/lap pacing this lands inside the 5-minute cap with a small buffer.
- **Time cap** is a hard ceiling: if at 5:00 the leader has not crossed lap 150, the race ends at that moment and current positions freeze. This is a safety net; normal races finish well inside 5:00.
- Default scheduled start times: **Friday 20:00, Saturday 20:00, Sunday 15:00** in America/Indiana/Indianapolis. All three times are configurable per-season via `season_calendar.json` (see REQ-012-004).
- Races run **whether or not** the lobby is full. Minimum 1 human; AI fills up to 6 racers.

### REQ-012-002: League Selection

Add to `PlayerData` (Resource):

```gdscript
@export var league: String = "women"   # "women" | "men"
@export var league_selected_at: String = ""   # ISO 8601 timestamp
```

- Default: prompt the player during Create Racer (Spec 002 REQ-002-006) with a **Step 2.5 — League** between Background and Name. Copy: *"Which weekly league do you want to race in? This only changes which weekly races you're eligible for. The mixed race always includes everyone."*
- Two cards: **Women's League** / **Men's League**. Each card shows an illustration and a one-line description. No default pre-selection; the player must tap to advance.
- **Re-selection:** Settings → Account → "Change League" is always available. Re-selection takes effect on the next unraced weekly cycle (does not retro-revoke eligibility for a currently-scheduled race the player has entered).
- League is **cosmetic-adjacent** (ADR 0002 §4) — it does not alter stats, training, matchmaking outside the weekly eligibility gate, or any finale logic. The finale field is unified.

### REQ-012-003: Race Eligibility Gate

Before joining any weekly race room, the matchmaking Lambda validates:

```
function canEnterWeekly(player, weekly) {
  if (weekly.type === "mixed") return true;
  return player.league === weekly.type; // "women" or "men"
}
```

- If the player is ineligible, return HTTP 403 with a structured body:
  ```json
  { "error": "league_mismatch", "your_league": "women", "race_type": "men",
    "next_eligible_race": { "id": "...", "starts_at": "..." } }
  ```
- The client renders a friendly, non-scolding message — "You're in the Women's League. The Men's Weekly is for Men's League players. The Mixed Weekly opens to everyone tomorrow at 3:00 PM ET." — never "you are not allowed."
- The Race Now card on Main Hub **hides** the ineligible race from the schedule preview rather than showing it greyed-out. The schedule page (REQ-012-007) still lists all three for awareness.

### REQ-012-004: Weekly Schedule Data Source

Extend `res://data/season_calendar.json` (introduced in Spec 009 REQ-009-010). Each season entry gains a `weekly_schedule` field:

```json
{
  "id": "spring_2026",
  "label": "Spring Series 2026",
  "kind": "spring_series",
  "window_start": "2026-01-01",
  "window_end": "2026-04-18",
  "weekly_schedule": {
    "timezone": "America/Indiana/Indianapolis",
    "days": [
      { "type": "women", "weekday": "friday",   "time": "20:00", "laps": 150 },
      { "type": "men",   "weekday": "saturday", "time": "20:00", "laps": 150 },
      { "type": "mixed", "weekday": "sunday",   "time": "15:00", "laps": 150 }
    ]
  }
}
```

- Server-side, a new `WeeklyScheduler` Lambda (EventBridge rule, tick every minute) reads this config, expands the recurring schedule into concrete race instances for the current week, and writes them to DynamoDB (REQ-012-005).
- A race instance is created 24 hours before its scheduled `starts_at`, so the client can show a "starts in 23h 42m" countdown.
- Instances created but never entered by any human player are left to run with an all-AI field (still persisted for leaderboard consistency); this keeps the leaderboard math clean even on empty weeks.

### REQ-012-005: Persistence — DynamoDB Schema

Three new tables (extending the set in [Spec 006 REQ-006-004](spec_006_aws_infrastructure.md)):

| Table | PK | SK | Purpose |
|---|---|---|---|
| `little-six-weekly-races` | `season_id` | `race_id` | One item per weekly race instance. |
| `little-six-weekly-results` | `race_id` | `finish_position` | Per-player finish row for a race. |
| `little-six-leaderboard-snapshots` | `leaderboard_key` | `snapshot_at` | Full leaderboard row-list frozen at a point in time, for delta computation. |

**`little-six-weekly-races` item:**
```json
{
  "season_id": "spring_2026",
  "race_id": "spring_2026:wk10:women",
  "week_number": 10,
  "race_type": "women | men | mixed",
  "scheduled_start": "2026-03-13T20:00:00-04:00",
  "actual_start":   "2026-03-13T20:00:12-04:00",
  "actual_end":     "2026-03-13T20:04:27-04:00",
  "status": "scheduled | live | finished | cancelled",
  "laps": 150,
  "room_id": "...",           // reference to Spec 005 room
  "created_at": "..."
}
```

**`little-six-weekly-results` item:**
```json
{
  "race_id": "spring_2026:wk10:women",
  "finish_position": 1,
  "player_id": "guest_abc123",
  "player_name": "Lila",
  "team_id": null,             // null in Phase 1 individual races
  "is_ai": false,
  "league": "women",
  "finish_time_ms": 267340,
  "laps_completed": 150,
  "cp_earned": 85,
  "elo_before": 1245,
  "elo_after":  1262,
  "momentum_earned": 1
}
```

GSI on `player_id` so a player's own weekly history is queryable without a table scan.

**`little-six-leaderboard-snapshots` item:**
```json
{
  "leaderboard_key": "spring_2026:women",   // or ":men" or ":mixed"
  "snapshot_at": "2026-03-13T20:10:00-04:00",
  "rank_rows": [
    { "rank": 1, "player_id": "...", "player_name": "Lila",  "points": 280, "wins": 3, "top3": 7 },
    { "rank": 2, "player_id": "...", "player_name": "Omar",  "points": 265, "wins": 2, "top3": 8 },
    /* ... top 100 ... */
  ]
}
```

- A snapshot is written **after every weekly race** (from the Race Results Lambda).
- Snapshots are retained for the full season (TTL = season end + 30 days). Finale-week has ~10 snapshots per leaderboard, enough for stable delta arrows and historical sparklines.
- For finale / combined season ladder deltas, add an additional `leaderboard_key = "spring_2026:season_ladder"` snapshot at the same cadence.

### REQ-012-006: Leaderboard Point Calculation (weekly)

Each weekly race awards **Weekly Points** to each finisher:

| Finish position | Weekly Points |
|---|---|
| 1st | 100 |
| 2nd | 70 |
| 3rd | 50 |
| 4th | 30 |
| 5th | 15 |
| 6th | 10 |
| DNF / race cancelled mid-run | 5 (if at least lap 30 completed) |

Weekly Points are **separate** from CP (Spec 009 REQ-009-002) and ELO (REQ-009-001). They exist only to order the weekly leaderboard. They reset at the start of each new season.

AI-filled slots **do not** contribute to or appear on any player-facing leaderboard. The weekly race results row for an AI racer is stored (for race-log completeness) but filtered out of snapshot `rank_rows`.

### REQ-012-007: Leaderboard Page (client)

`scenes/hub/Leaderboard.tscn` — extends the existing scene from Spec 009 REQ-009-005.

Tabs (in this order):
1. **This Week — Women's**  *(visible to Women's League + as read-only spectator to Men's League)*
2. **This Week — Men's**    *(visible to Men's League + as read-only spectator to Women's League)*
3. **This Week — Mixed**
4. **Season Ladder** *(unified ELO; from Spec 009)*
5. **Best Times**   *(from Spec 009)*
6. **My History**   *(this player's finishes, reverse-chrono)*

**Row rendering for tabs 1–3:**

```
┌───────────────────────────────────────────────────────────────┐
│ Rank │ Δ │ Player           │ League │ Points │ Wins │ Top 3  │
├───────────────────────────────────────────────────────────────┤
│   1  │ ▲2│ Lila             │ Women  │   280  │   3  │    7   │   ← moved up 2 places since last snapshot
│   2  │ — │ Omar             │ Men    │   265  │   2  │    8   │   ← unchanged
│   3  │ ▼1│ Priya            │ Women  │   250  │   3  │    6   │   ← dropped 1
│   4  │NEW│ Jesse            │ Mixed  │   220  │   2  │    4   │   ← first appearance this season
│   …                                                           │
└───────────────────────────────────────────────────────────────┘
```

Delta symbol rules:
- **▲N** (green) — rose N ranks since previous snapshot.
- **▼N** (red) — fell N ranks since previous snapshot.
- **—** (neutral) — rank unchanged.
- **NEW** (gold/accent) — player did not appear in the previous snapshot.

Delta is computed client-side by requesting the **current** and **previous** snapshot from the API and diffing `player_id` rank positions. Missing previous snapshot → all rows render as **NEW** (happens naturally in season week 1).

Sparkline column (optional in Phase 1): show a 5-point mini trend line per player over the last 5 snapshots. Deferred to Phase 2 if it costs first-paint time.

### REQ-012-008: Leaderboard API

Lambda under `infra/lambda/leaderboard/` adds these endpoints:

```
GET  /api/leaderboard/weekly?season={id}&type={women|men|mixed}
     → { snapshot_at, prev_snapshot_at, rank_rows[], prev_rank_rows[] }

GET  /api/leaderboard/history?season={id}&type=...&limit=5
     → { snapshots: [ { snapshot_at, rank_rows[] }, ... ] }   // for sparklines

GET  /api/leaderboard/player/{player_id}?season={id}
     → { weekly_history: [ ... ], season_totals: { ... } }
```

All three are cacheable for 60 seconds at CloudFront (`Cache-Control: public, max-age=60`). Leaderboards do not need to be real-time; they update at most ~3× per week per board.

### REQ-012-009: Weekly Race Card on Main Hub

Replace the existing "RACE NOW" card logic from Spec 002 REQ-002-007 with a **Weekly Schedule card**:

```
┌────────────────────────────────────────────┐
│  THIS WEEK                                 │
│  ─────────────                             │
│  Fri 8:00 PM ET  │  Women's Weekly   ←you  │
│  Sat 8:00 PM ET  │  Men's Weekly           │
│  Sun 3:00 PM ET  │  Mixed Weekly     ←you  │
│                                            │
│  [ NEXT RACE: 2 DAYS 14H ]                 │
│  [ SET REMINDER ]                          │
└────────────────────────────────────────────┘
```

- "← you" marker on rows the player is eligible for.
- When a race's `scheduled_start` is within 15 minutes, the card pulses and the "NEXT RACE" countdown becomes "STARTING IN 14:32" — tapping it enters the lobby.
- "SET REMINDER" toggles a browser Notification (permission-gated) 10 minutes before the scheduled start.
- A separate "Quickplay (AI only)" button remains for off-schedule play.

### REQ-012-010: Race Results → Leaderboard Snapshot Flow

After a weekly race finishes:

1. Game server (ECS task) posts `POST /api/rooms/{id}/finished` with the `race_id` and per-player results array.
2. **Race Results Lambda** does, in order:
   a. Writes rows to `little-six-weekly-results` (one per human + AI).
   b. Recomputes every affected player's season-to-date Weekly Points total (scan GSI on `player_id` within this season).
   c. Loads the current top-100 ranking for this leaderboard, compares to the most recent snapshot, and writes a new row to `little-six-leaderboard-snapshots`.
   d. Awards Race IQ bump + 1 Season Momentum token to each human finisher (see REQ-012-011).
   e. Emits a CloudWatch event `WeeklyLeaderboardUpdated` for future integrations.
3. The Main Hub leaderboard card, if currently displayed, refetches the leaderboard API (triggered by the `host_event_received` bridge from Spec 011 — the host forwards a `leaderboard_updated` WebSocket push).

### REQ-012-011: Season Momentum (transient stat)

Add to `RacerData` (Resource):

```gdscript
@export var season_momentum: int = 0     # 0–10, transient, resets on season end
@export var last_weekly_finished_at: String = ""   # ISO 8601
```

**Earning / decay rules (client-side computation, verified server-side on sync):**
- Finish any weekly race (human, any placement): **+1 Momentum**, cap 10.
- 7 days without finishing a weekly: **−1 Momentum**, floor 0. Decay check runs on login and at midnight local.
- Season end: Momentum resets to 0.

**Race effect (during finale and weekly races):**
- Each point of Momentum adds **+1%** to the rider's effective Cadence window width (i.e., the "power stroke" timing window; see [ADR 0003](../adr/0003-input-control-scheme.md)). At cap (10), the rider is 10% more forgiving on cadence timing.
- Each point of Momentum also grants **+0.3%** to the Race IQ-derived draft efficiency (negligible alone, meaningful stacked).
- Combined at cap, Momentum is roughly equivalent to ~2–3 ELO points of finale skill on average — enough to *tilt* close races toward weekly participants, not enough to overwhelm raw execution. This is the explicit ADR 0002 §6 commitment.

**UI:** a small "Momentum" badge on the Main Hub header shows `🔥 7 / 10` or similar. Tooltip: *"Keep racing weekly to keep your edge. Decays 1 per week you skip."*

### REQ-012-012: League-Aware Matchmaking

Extend the matchmaking Lambda from [Spec 005 / Spec 006 REQ-006-005](spec_006_aws_infrastructure.md):

```javascript
// Pseudocode
function findWeeklyRoom(player, weeklyRaceId) {
  const race = getRace(weeklyRaceId);
  if (!canEnterWeekly(player, race)) throw new Error('league_mismatch');
  const room = getOrCreateRoomForRace(race);
  if (room.player_count >= 6) throw new Error('race_full');
  addPlayerToRoom(player, room);
  return { server_url: room.server_url, room_id: room.id, join_token: issueToken(player, room) };
}
```

- Weekly races have exactly **one room per race instance**. Unlike Quickplay, there is no rolling matchmaking pool.
- When the room count of humans < 6 at `scheduled_start`, the server fills remaining slots with AI before starting.

### REQ-012-013: Finale Eligibility Does Not Depend on Weekly Participation

Explicitly: a player can enter the season finale with **zero** weekly races finished. They will race without Season Momentum (floor 0), which is a disadvantage but not a disqualifier. The finale matchmaker does not filter on league — the finale is a single combined field (ADR 0001 / ADR 0002 §4).

### REQ-012-014: Analytics Events (stub)

Emit the following through the analytics stub (Spec 011 REQ-011-009), tagged for future wiring:

```
weekly.registered     { race_id, race_type, league }
weekly.entered_lobby  { race_id, starts_in_seconds }
weekly.missed         { race_id, player_id }    // emitted when race finished without player entering
weekly.finished       { race_id, finish_position, laps, time_ms }
league.selected       { old_league?, new_league, reason: "create_racer" | "settings" }
leaderboard.viewed    { tab, season_id }
momentum.changed      { old, new, reason: "earned" | "decayed" | "season_reset" }
```

---

## Data Structures

See REQ-012-005 for DynamoDB items and REQ-012-011 for `RacerData` / `PlayerData` additions. No new client-side Resource classes beyond those fields.

---

## UI/Scene Hierarchy

### `scenes/hub/Leaderboard.tscn` (updated)

```
Leaderboard (Control)
├── TabBar (HBoxContainer)
│   ├── WomensTab (Button)
│   ├── MensTab (Button)
│   ├── MixedTab (Button)
│   ├── SeasonLadderTab (Button)
│   ├── BestTimesTab (Button)
│   └── MyHistoryTab (Button)
├── HeaderRow (HBoxContainer)
│   └── [labels: Rank, Δ, Player, League, Points, Wins, Top 3]
├── RowsScroll (ScrollContainer)
│   └── RowsContainer (VBoxContainer)
│       └── LeaderboardRow (PackedScene, instanced per entry)
│           ├── RankLabel
│           ├── DeltaBadge (sub-scene that renders ▲N / ▼N / — / NEW)
│           ├── PlayerNameLabel
│           ├── LeagueBadge
│           ├── PointsLabel
│           ├── WinsLabel
│           └── Top3Label
├── Footer
│   ├── SnapshotAtLabel ("as of Sat 2026-03-14 8:05 PM ET")
│   └── RefreshButton
└── EmptyState (shown when rank_rows = []; copy: "First weekly race hasn't run yet. Back here Friday 8 PM ET.")
```

### `scenes/ui/components/DeltaBadge.tscn` (new)

```
DeltaBadge (Control, 32×24)
├── BgRect (ColorRect; green/red/slate/gold via variant)
└── Label (text: "▲2" / "▼1" / "—" / "NEW", Press Start 2P 10px)

Script exposes: `set_delta(current_rank: int, previous_rank: int | null) -> void`
- previous_rank == null → "NEW", gold bg
- current < previous → "▲{diff}", green bg
- current > previous → "▼{diff}", red bg
- equal → "—", slate bg
```

---

## Signal Interface

### EventBus signals added

```
league_changed(old_league: String, new_league: String)
weekly_schedule_loaded(races: Array[Dictionary])
weekly_race_imminent(race_id: String, seconds_until_start: int)
weekly_race_entered(race_id: String)
weekly_race_finished(race_id: String, your_position: int, momentum_earned: int)
leaderboard_snapshot_updated(leaderboard_key: String)
momentum_changed(old: int, new: int)
```

### Listeners

- `MainHub` listens to `weekly_schedule_loaded`, `weekly_race_imminent`, `momentum_changed`.
- `Leaderboard` listens to `leaderboard_snapshot_updated` and refetches the current tab.
- `HostBridge` (Spec 001 REQ-001-012) forwards `weekly_race_finished` as an analytics `postMessage` to the web host.

---

## Acceptance Criteria

- [ ] Three weekly race instances are auto-created per season per week (women/men/mixed) by the `WeeklyScheduler` Lambda, visible in DynamoDB.
- [ ] A Women's-League player attempting to enter a Men's Weekly receives a 403 with `error: "league_mismatch"` and a friendly redirect message in the UI.
- [ ] A Women's-League player **can** enter a Mixed Weekly.
- [ ] Re-selecting league from Settings updates `PlayerData.league` and `league_selected_at`, and takes effect on the next scheduled race.
- [ ] A weekly race ends within ≤ 5 minutes of wall-clock, or freezes positions at 5:00 if the leader has not crossed the finish line.
- [ ] After a weekly race finishes, a new row is written to `little-six-leaderboard-snapshots` for the matching leaderboard key.
- [ ] Leaderboard page renders correct delta symbols: ▲ for rank increase, ▼ for decrease, — for unchanged, NEW for first appearance.
- [ ] When fewer than 2 human racers enter a scheduled weekly, the race still runs with AI fill and a valid snapshot is written.
- [ ] AI rows do not appear in leaderboard `rank_rows` but do appear in `weekly_results` for race-log completeness.
- [ ] Season Momentum increments by 1 on each weekly finish and is capped at 10.
- [ ] Season Momentum decays by 1 after 7 days of no weekly finishes (verified by advancing system clock in test harness).
- [ ] Season end resets all Season Momentum to 0.
- [ ] Main Hub Weekly Schedule card shows the three races with correct local-time conversion.
- [ ] "Set Reminder" button requests Notification permission and schedules a local notification 10 minutes before `scheduled_start`.
- [ ] A finale can be entered with `season_momentum = 0` and completes normally.
- [ ] Analytics stub receives the events listed in REQ-012-014 with correct payloads.

---

## Implementation Notes

1. **Start small on the dashboard.** Phase 1 ships only the Leaderboard tabs + delta badge. Sparklines, per-player trend charts, and notification-based reminders are Phase 1.5. Ship the core loop first.
2. **Snapshot storage is cheap.** At three races per week per season × four seasons × a top-100 payload, we're looking at ~5 MB/year in DynamoDB. No compression needed; TTL covers old seasons.
3. **Why points and not ELO for the weekly leaderboard.** Weekly Points are a *monotonic, non-zero-sum* cumulative count — ideal for a "this season" ranking where new players can catch up by attending. ELO is reserved for the Combined Season Ladder where we want two-way movement.
4. **Why Momentum tops out at 10.** Ten weekly finishes is roughly 3–4 weeks of consistent attendance. That's the "engaged player" threshold; we don't want to reward a single pre-season binge over sustained attendance, and we don't want runaway stacking that renders the finale pay-to-practice.
5. **Timezone presentation.** Always render the authoritative time (America/Indiana/Indianapolis) alongside the player's local conversion. Copy like *"Fri 8:00 PM ET (your time: 5:00 PM PT)"*. Avoid silent conversion that can confuse players who travel or change their device clock.
6. **Race results lambda idempotency.** Keyed on `race_id`. A retry from the game server must not double-write a snapshot or double-award Momentum; include the `race_id` in a conditional write.
