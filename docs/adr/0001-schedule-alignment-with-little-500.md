# ADR 0001 — Schedule Alignment with the Real IU Little 500

**Status:** Accepted
**Date:** 2026-04-22
**Deciders:** Andrew (product), Claude (assist)
**Tags:** product, scheduling, seasons, audience

---

## Context

Our primary audience (P0 in [AUDIENCE.md](../AUDIENCE.md)) is the real IU Little 500 rider, with the Little 500 fan (P1) a close secondary. Both are under-served for 51 weeks of the year: the real race is a single April weekend, after which the scene goes quiet until January training begins again.

Little Six is a Tamagotchi-style cycling game set at a fictional all-American college ("Little Six University"). The question: how should the game's calendar relate to the real race calendar?

**Forces on the decision:**

1. **Hype for Race Weekend.** P0 and P1 want the game to amplify the real event — not compete with it and not ignore it.
2. **Don't overshadow the real race.** The fictional race must **precede** the real race so that on the real Race Weekend, the player's emotional energy rolls forward into the real event (not back into a game they played after).
3. **Year-round retention for the Tamagotchi loop.** P3 — and the lifetime value of P0 — depend on the game having purpose outside the April crescendo. A single season per year is not enough.
4. **Authenticity without impersonation.** Little Six is a tribute, not a simulation of IU. The fictional-college framing gives license to bend specifics (600-lap race length, a single men+women combined field) while keeping the tribute legible.
5. **Real 2026 dates are now known:**
   - Little 500 Qualifications: **Saturday, March 28, 2026**
   - Women's Little 500 Race: **Friday, April 24, 2026 at 4:00 PM**
   - Men's Little 500 Race: **Saturday, April 25, 2026 at 2:00 PM**

---

## Decision

**1. Little Six's flagship "Spring Series" season is anchored one week earlier than the real Little 500 race.**

Using 2026 as the reference year:

| Event | Real Little 500 Date | Little Six Date |
|---|---|---|
| Qualifications | Sat 2026-03-28 | **Sat 2026-03-21** |
| Race Weekend — Women's | Fri 2026-04-24 | **Fri 2026-04-17** |
| Race Weekend — Men's / Combined | Sat 2026-04-25 | **Sat 2026-04-18** |

Every subsequent year, the Little Six Spring Series recomputes its dates from the published IU Little 500 dates with the same `-7 days` offset. (If IU's schedule ever splits oddly, fall back to "Saturday before IU Quals" for our Quals and "weekend before IU Race Weekend" for our Race.)

**2. Little Six's race format is 600 laps, targeting 15–20 minutes of real time.**

The real race is 200 laps (men's) / 100 laps (women's) on a quarter-mile cinder oval. Our 600-lap figure is deliberately a spiritual successor — bigger, faster, clearly fictional, and compressed to fit a mobile play session. Lap pacing averages roughly 1.5–2.0 seconds per lap in game time to hit the target run-time.

**3. The game runs four quarterly seasons per year; only one of the four is Little 500-aligned.**

| Season | Calendar window (approx.) | Fictional theme | Alignment |
|---|---|---|---|
| **Spring Series** | Jan 1 → IU Race Weekend − 1 week | Little Six's canonical season. Qualifications, ITT, Miss-N-Out, Team Pursuit, Race Weekend. | **Aligned** to the real Little 500. |
| **Summer Circuit** | IU Race Weekend − 1 week + 1 day → Jun 30 | Off-season criterium series at fictional venues. Shorter events, aggressive sprint meta. | Off-cycle. |
| **Autumn Invitational** | Jul 1 → Sep 30 | Invitational cup format at fictional rival campuses. | Off-cycle. |
| **Winter Trials** | Oct 1 → Dec 31 | Indoor training-emphasis season. Time-trial focused; preps the racer for next Spring. | Off-cycle; sets up the next Spring Series. |

Each quarterly season has its own narrative framing, its own leaderboard, and its own cosmetic reward track. Spring Series alone is tied to real-world dates.

**4. The daily/semi-daily Tamagotchi loop is continuous across seasons.**

Training activities, fatigue, over-training risk, and "race form" persist between seasons. A dropped racer loses condition exactly as they would in the real sport. The loop gives players a reason to open the game on a random Tuesday — the central value proposition for P3 and a retention anchor for P0.

---

## Consequences

### Positive

- **P0/P1 hype delivery:** When the real Little 500 arrives, our players have just finished an emotional in-game season. They walk into Race Weekend *warmed up*. This is the explicit goal of the schedule offset.
- **Year-round retention:** Four seasons means the daily loop always has stakes. No more than ~13 weeks between end-of-season moments.
- **Clean brand separation:** Because we're set at a fictional college with a fictional 600-lap distance, we can reference the Little 500 in marketing without claiming to *be* the Little 500. Reduces IP/legal risk and avoids accusations of impersonation.
- **Simple scheduling rule** (`−7 days from published IU dates`) that can be automated once IU publishes each year's calendar.

### Negative / Costs

- **Dependency on an external calendar.** Each year someone has to pull the IU dates and propagate them into the game config. This is a small manual ops task (see Spec 009 follow-up).
- **Off-cycle season narratives must be invented.** Summer Circuit, Autumn Invitational, Winter Trials all need enough flavor to feel distinct. Not a huge cost, but not free.
- **Possible confusion on first encounter.** Players who only check the game during real Little 500 weekend may find the Spring Series already over. Marketing site copy must set the expectation clearly ("Our finals line up one week before the real Little 500").
- **Locks Spring Series length to IU's cadence.** If IU ever moves the race dramatically (pandemic year redux), our flagship season warps with it.

### Follow-ups Required

1. [ ] Update [GDD.md](../GDD.md): 600-lap race length; fictional college setting; quarterly season structure.
2. [ ] Update [Spec 009 — Player Progression & Persistence](../specs/spec_009_player_progression.md) to encode the season calendar as data-driven config and add a rule for `spring_series_dates_from_little_500(year)`.
3. [ ] Pick a canonical fictional-college name. Working placeholder: **Little Six University** (deliberately on-the-nose). Alternatives worth considering: *Midland State*, *Heartland College*, *Sixth Street College*, *Hoosier State University* (probably too close). Park until a naming pass.
4. [ ] Marketing site (Spec 011) home page FAQ should include: "How does Little Six line up with the real Little 500?" with the `-1 week` answer.
5. [ ] An annual ops checklist: "When IUSF publishes next year's race dates, bump Spring Series config." Minor — one line in a runbook once we have runbooks.

---

## Alternatives Considered

### A. No schedule alignment (game calendar floats freely)
Simplest. Rejected because it forfeits the P0/P1 hype-amplifier that motivated this ADR in the first place.

### B. Align *exactly* with the real Little 500 (same day)
Rejected because it creates direct competition with the real event. On Race Weekend, P0 is at Bill Armstrong Stadium, not on their phone. The game should finish its crescendo *before* the real one begins.

### C. Align *after* the real Little 500 (one week later)
Rejected because it inverts the emotional trajectory. The point is to ramp *into* Race Weekend; running our finals after deflates real-race energy rather than building on it.

### D. One long season per year instead of four quarterlies
Rejected because it leaves 8+ months with no in-game stakes, which is fatal to the Tamagotchi loop and to P3 engagement. Also wastes the retention benefit of Little Six being a year-round product, not just a seasonal tie-in.

### E. Lap count = 500 (to match "Little 500" naming)
Rejected because 500 is the *distance in miles* analog of the real race name, not a lap count (the men's race is 200 laps / 50 miles). 600 is chosen as a deliberate spiritual-successor bump (`5 → 6` in both the name and the lap headline), reinforcing the "Little Six" framing without claiming to be the Little 500.

### F. Match real race length (200 laps)
Rejected because 200 laps at arcade pacing would run ~5–7 minutes — too short to build race drama, and too short to justify exchange-zone strategy. 600 laps at ~1.5–2 sec/lap gives us the 15–20 minute target.

---

## References

- [AUDIENCE.md](../AUDIENCE.md) — personas this decision serves.
- [GDD.md](../GDD.md) — game-design implications (season structure, lap count).
- [Spec 009 — Player Progression & Persistence](../specs/spec_009_player_progression.md) — where the season calendar lives as data.
- [2026 IU Little 500 dates — IU Student Foundation](https://iusf.bloomington.iu.edu/little500/index.html)
- [Indiana Daily Student — 2026 Men's Quals coverage (Mar 28)](https://www.idsnews.com/article/2026/03/mens-little-500-qualifications-cutters-fastest-time)
