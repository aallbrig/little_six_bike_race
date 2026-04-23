# ADR 0002 — Weekly Race Format & League Selection

**Status:** Accepted
**Date:** 2026-04-22
**Deciders:** Andrew (product), Claude (assist)
**Tags:** product, racing, seasons, social, audience

---

## Context

The game has two scales of race already defined (see [GDD §8](../GDD.md) and [ADR 0001](0001-schedule-alignment-with-little-500.md)):
- **Season finale** — 600 laps, 15–20 minutes, the culmination of a Spring/Summer/Autumn/Winter season.
- **Spring Series events** inside a season — time trials, Miss-N-Out, Team Pursuit.

Missing from that structure is a **weekly heartbeat** that:
1. Gives lapsed players a low-friction reason to come back this week.
2. Introduces new players to the multiplayer race loop without demanding a 20-minute commitment.
3. Produces public, league-scoped results that feed a leaderboard so the scene feels alive between finale weekends.

The real Little 500 tradition runs the **women's race first** (Friday), then the **men's race** (Saturday). We want to preserve that framing *and* provide a way for players to race each other regardless of which sex-based field they chose. The idea of a **third, mixed race** — on the day after the men's — is the inclusive bolt-on.

The weekly race should not be a stand-in for the finale. It's a **drop-in event**, not mandatory, with light stakes, short runtime, and expectation that attendance is sparse.

---

## Decision

### 1. The weekly cadence is a three-day sequence.

Every week of every season (Spring, Summer, Autumn, Winter), the game runs **three scheduled races** on three consecutive days at a fixed time of day (leaning Fri/Sat/Sun; exact day anchor is configurable per season):

| Day | Race Name | Eligibility | Intent |
|---|---|---|---|
| **Day 1** | **Women's Weekly** | Players in the Women's League | Preserves the real Little 500 women's-first tradition. |
| **Day 2** | **Men's Weekly** | Players in the Men's League | Preserves the real Little 500 men's format. |
| **Day 3** | **Mixed Weekly** | *All* players (both leagues) | Always runs after the first two. The day the whole community can show up together. |

Rationale for ordering (women → men → mixed): it mirrors the real Little 500 (women's race Fri, men's Sat), then adds the mixed race as the social/inclusive capstone of the week. The mixed race never runs *before* the two league-gated races — it's framed as "the rematch where everyone lines up."

### 2. Weekly races last **no longer than 5 minutes**.

They are short-format by design. Target lap count: **~150 laps** at the game's standard 1.5–2.0 sec/lap pacing. Spec 004 / Spec 012 encode the exact lap count; this ADR only commits to the ≤ 5 minute ceiling.

This is a fundamentally different shape than the 600-lap, 15–20 minute season finale (see [ADR 0001](0001-schedule-alignment-with-little-500.md)). That difference is intentional — the finale is an *event*, the weekly is a *drop-in*.

### 3. Weekly races happen at scheduled times and do not require a full field.

- Races are **scheduled** (configured in `season_calendar.json`-adjacent data; see Spec 012) — e.g., "Fri 8:00 PM ET, Sat 8:00 PM ET, Sun 3:00 PM ET."
- At race time, **whoever is in the lobby races**. AI fills empty slots up to the 6-rider cap, exactly as in quickplay.
- **Attendance is not expected to be complete.** Two human players and four AI is a valid weekly race. So is six humans. So is one human and five AI. The system does not cancel or delay due to low turnout.
- **No entry fee, no loss penalty.** The weekly is a free swing. You cannot lose rating or CP by showing up and placing last.

### 4. League selection is self-chosen and cosmetic-adjacent.

At account creation (or later, in Settings), the player picks one of:
- **Women's League**
- **Men's League**

This choice **only** determines which of the three weekly days the player is eligible to race on:

| League | Day 1 (Women's) | Day 2 (Men's) | Day 3 (Mixed) |
|---|---|---|---|
| Women's League | ✅ Eligible | ❌ Not eligible | ✅ Eligible |
| Men's League | ❌ Not eligible | ✅ Eligible | ✅ Eligible |

It has **no** effect on:
- Racer stats, training options, or gear.
- Match quality in the mixed race or in any non-weekly mode.
- Anything in the season finale (finales run as a single combined field).

League choice is **re-selectable** from Settings. There is no gatekeeping beyond the self-declared choice. Leaderboards partition by league for the weekly races (see Spec 012); the final season leaderboard is unified.

### 5. Weekly race results feed a persistent, league-scoped leaderboard.

Every weekly race result is persisted (see Spec 012 for the DynamoDB schema) and rolls up into:
- **Women's Weekly leaderboard** — results from all Women's Weekly races this season.
- **Men's Weekly leaderboard** — results from all Men's Weekly races this season.
- **Mixed Weekly leaderboard** — results from all Mixed Weekly races this season.
- **Combined Season Ladder** — ELO ladder across all race types (see Spec 009).

Each leaderboard exposes **rank-change deltas** between successive snapshots (▲ / ▼ / — / NEW), so a returning player immediately sees who moved this week.

### 6. Participating in weekly races grants a modest, accumulating advantage for the season finale.

This is how we honor "racers who participate in weekly races should have an advantage over players who only show up for the final race," without letting training dwarf skill. Specifically:

- Each weekly race the player finishes (any placement, including last) grants a small **Race IQ** bump and one **Season Momentum** token.
- **Season Momentum** is a transient stat that decays if you skip weekly races. It caps at a ceiling high enough to matter but low enough that a skilled no-weekly player can still win the finale with clean execution.
- Concrete numbers are in the stats framework (GDD §5 and Spec 012 REQ-012-011). This ADR only commits to: *finale entry with zero weekly participation is a disadvantage, but not a disqualifier.*

---

## Consequences

### Positive

- **Weekly retention loop** for lapsed players ("Did I miss this week's Women's?") without a 20-minute commitment.
- **Preserves the real Little 500 format** in-game (women's → men's sequence) while fixing the co-play gap with the mixed race — directly serves P0 and P1 from [AUDIENCE.md](../AUDIENCE.md).
- **Inclusive by default.** Every player races at least twice per week (one league day + mixed day); the league choice never locks anyone out of social play.
- **Light ops.** Three scheduled races per week per season is a cron config, not a live-ops team.
- **Finale stakes intact.** Weekly races feed rankings but do not replace the season finale's payoff.

### Negative / Costs

- **Data volume.** ~12 weekly races per month per shard + leaderboard snapshots. Still tiny in absolute terms; DynamoDB on-demand handles it trivially.
- **Time-zone ambiguity.** A "Friday 8:00 PM" race is 8:00 PM *where*? We pin Spring Series weeklies to America/Indiana/Indianapolis (home of the Little 500). Off-cycle seasons use the same anchor to avoid a second rule. Players outside Eastern time see converted local time on the schedule card.
- **Sparse weeks.** Some weeklies will run with 1 human and 5 AI. That's fine by design, but the leaderboard delta chart will be noisy in the first weeks of each season until the field depth grows.
- **"Why can't I race Men's Weekly?" friction.** A Women's-League player who wants to race the men's field will bounce off the eligibility check. Mitigation: the mixed race is always the next day; Settings offers a re-select. UI messaging in Spec 012 must make this friction gentle and informative, not gatekeeping.

### Follow-ups Required

1. [ ] Draft [Spec 012 — Weekly Races, Leagues & Leaderboards](../specs/spec_012_weekly_races_and_leaderboards.md): data model, scheduling, UI, delta computation.
2. [ ] Update [Spec 004](../specs/spec_004_multiplayer_race.md) with the weekly-format lap count (~150) vs. finale-format (600) and ensure the race controller reads format config.
3. [ ] Update [Spec 009](../specs/spec_009_player_progression.md) or spec 012 (TBD) to define **Season Momentum** as a transient stat alongside Fatigue/Morale/Race Form.
4. [ ] Update [GDD §5 Stats](../GDD.md) with the Race IQ / Season Momentum additions (deferred to the stats-proposal task, not this ADR).
5. [ ] Marketing site (Spec 011) FAQ should include "What's the weekly race? / What's the mixed race? / Can I change leagues?"

---

## Alternatives Considered

### A. One weekly race per week, no league split.
Simplest. Rejected because it erases the women's/men's framing that's core to the Little 500 tribute and to our P0 audience's emotional connection.

### B. Two weeklies (women's + men's), no mixed race.
Preserves tradition, cuts the mixed-play opportunity. Rejected because it locks players into racing only their league-mates every week — missing the point of "whole community shows up" social energy.

### C. Mixed race runs *first*, then league-gated races.
Rejected on narrative grounds: the mixed race works as a capstone (rematch, everyone's back), not as an opener. Also matches the real Little 500 by keeping women's race first in the sequence.

### D. Daily weekly races (7 per week).
Too demanding. The whole point of the ≤ 5 minute cap is to stay drop-in-friendly. Seven scheduled touchpoints pushes it from "habit" to "chore" — hostile to P2 and the tail of P0.

### E. Gated league selection (e.g., tied to account gender field).
Explicitly rejected. League is a self-declared scheduling preference, full stop. No verification, no lock-in, no binary-gender assumption baked into the product. A player can re-select at any time from Settings.

### F. Weekly participation grants no finale advantage (pure schedule event).
Rejected because it deletes the engagement loop's reward structure. A modest, bounded advantage (Race IQ + Season Momentum) gives weekly participants a sense of investment without tilting the finale into pay-to-practice.

### G. Weekly participation grants massive stat gains.
Rejected as the mirror risk. If skipping weeklies is fatal to finale success, the ≤ 5 minute "drop-in" framing becomes a lie. The bounded Race IQ/Momentum cap is the compromise.

---

## References

- [ADR 0001 — Schedule alignment with the real IU Little 500](0001-schedule-alignment-with-little-500.md)
- [AUDIENCE.md](../AUDIENCE.md) — P0 (Little 500 riders) is the primary reason for the women's-first ordering.
- [GDD §6 Training / §7 Spring Series / §8 The Main Race](../GDD.md)
- [Spec 012 — Weekly Races, Leagues & Leaderboards](../specs/spec_012_weekly_races_and_leaderboards.md) *(to be authored as a follow-up to this ADR)*
