# Audience & Personas — Little Six

**Version:** 1.0
**Status:** Living document — revise when real-player data contradicts assumptions.
**Last Updated:** 2026-04-22

---

## Purpose

Little Six is a small indie cycling game. A small game can't be everything to everyone, and the product will drift toward whatever the team finds easiest unless we explicitly name **who we are building for**. This document enumerates the audiences that matter, ordered by product priority, with the behaviors and motivations that should guide design decisions.

When a product question is contested ("should we X?"), walk it back to this document: "Which persona does X serve? Is that persona prioritized above the persona X costs?"

---

## Priority Order

1. **P0 — The Little 500 Rider.** Current or former racer in the real IU Little 500. The reason this game exists in its current shape.
2. **P1 — The Little 500 Fan.** IU student, alum, Bloomington resident, or lifelong follower of the race who has never pedaled but lives for Race Weekend.
3. **P2 — The Mobile Arcade Gamer.** Casual phone gamer drawn by short sessions, arcade aesthetics, and "one more race" loops — no prior Little 500 context.
4. **P3 — The Tamagotchi Enjoyer.** Player who latches onto the daily training/care loop irrespective of the racing.

The team resolves conflicts in favor of the lower-numbered persona. A feature that delights P0 at the cost of P3 is a net win; the reverse is a loss.

---

## P0 — The Little 500 Rider (Primary)

**Archetype:** A current or recent IU Little 500 rider — men's or women's field. They spend January through April training on the cinder oval at Bill Armstrong Stadium. They know the feel of a 46x18 coaster-brake bike, the specific rhythm of exchange zones, and the phrase "the burn." Many continue to ride for years after graduating; alumni riders are a large share of this persona.

**What they know:**
- Exact mechanics of the real race: lap counts (200 men's / 100 women's), exchange zone rules, gearing, standardized bikes, cinder surface.
- Real teams, historic winners, famous exchanges, legendary crashes. They read *Indiana Daily Student* coverage. They watched *Breaking Away* a dozen times.
- Training calendar: quals in late March, track hours requirement, team dynamics.

**What they want from the game:**
- **Authenticity.** Anything the game gets wrong about the real race is grating. Small details (coaster-brake feel, exchange-zone timing, a 46x18 gear feeling different from a track bike) earn disproportionate trust.
- **Hype for Race Weekend.** A fun way to feel the anticipation building as the real race approaches. "My game season ends the week before the real race" is a feature, not a bug.
- **Banter with teammates.** Something to show teammates on the bus, in the pit, at watch parties.
- **A reason to keep coming back in the off-season.** The real race is one weekend a year; this persona is emotionally under-served for the other 51 weeks.

**What they don't want:**
- Fantasy-skinned cycling that dilutes the Little 500 vibe (no lasers, no power-ups, no dragons).
- A game that treats them as novices. No "learn what a peloton is" tutorial.
- A pay-to-win multiplayer where a whale beats a trained rider.

**Product implications:**
- **Calendar alignment.** Little Six's flagship season culminates **one week before** the real Little 500 race weekend; Little Six "Quals" run **one week before** real Little 500 Quals. See [ADR 0001](adr/0001-schedule-alignment-with-little-500.md).
- **Off-cycle seasons.** Between the aligned Spring season and next year's aligned season, run three additional quarterly seasons with their own fiction and events — so the daily loop never goes cold.
- **Mechanical fidelity.** Coaster brake, 46x18 feel, exchange zone as a tactical choke point, drafting physics, "the burn" as a real mechanic with trade-offs.
- **Fictional veneer without dilution.** The game is set at a fictional all-American college (working name: the "Little Six" university), running a 600-lap race — deliberately a spiritual successor, not a copy. Authenticity stays in the mechanics; the setting is generic enough that any college-cycling culture fan can graft their own identity onto it. See [GDD §2 — World & Setting](GDD.md).

**Reach channels:**
- IUSF rider Discord / GroupMe channels, team captains, the Cutters alumni network.
- *Indiana Daily Student* coverage around Quals Week and Race Week.
- Reddit r/IndianaUniversity, r/Bloomington.

---

## P1 — The Little 500 Fan (Strong Secondary)

**Archetype:** An IU student, alum, Bloomington townie, or family member of a rider. They have never ridden the cinder, but Race Weekend is a highlight of their year. They can name past winners and explain "the burn" to a friend.

**What they want:**
- A way to participate in Race Weekend even if they're not on a team — especially if they graduated and moved away.
- Something to play during the actual race broadcast / livestream.
- To share with friends who "just don't get it" as a low-friction way to explain the culture.

**What they don't want:**
- A training grind so deep it locks them out of the fun parts. They'll train less than P0.
- Niche references to riders/teams they don't recognize (they know the headlines, not the roster).

**Product implications:**
- The **multiplayer race must be approachable.** Quickplay with AI fill (Phase 1) is their primary on-ramp; deep ranked ladders are secondary.
- **Watch-along-friendly.** Short race length (15–20 minute format, 600 laps compressed) so a race fits between commercial breaks of the real broadcast.
- **Marketing site** (Spec 011) leads with the Little 500 tribute framing. Hero copy ("The World's Greatest College Weekend") speaks directly to this persona.

**Reach channels:**
- IU Alumni Association newsletters, Bloomington local press, nostalgia-driven social media (especially around Race Weekend).

---

## P2 — The Mobile Arcade Gamer (Tertiary)

**Archetype:** A phone gamer who sees a trailer, doesn't know or care about IU, and tries the game because the loop looks fun. Plays in 5–10 minute bursts on a bus, in a waiting room, before bed.

**What they want:**
- Immediate fun. The game must be comprehensible within 30 seconds of opening `/play`.
- Controls that feel right on a phone (tilt + touch).
- Short, satisfying race sessions.

**What they don't want:**
- A 20-minute first-run tutorial about a college tradition they've never heard of.
- Deep training systems gated behind lore.

**Product implications:**
- The attract-mode loop (Logo → Cinematic → Title → Demo) must sell the game **mechanically**, not just culturally. The cinematic shows pack racing, exchange chaos, and a finish-line sprint — not a history lesson.
- Single-player race-vs-AI must be a top-level action from the Main Hub, available without account creation.
- The training system must be **optional**. P2 can race without training; training rewards the engaged player rather than gating the casual one.

**Reach channels:**
- App store browsing (web app / PWA), word-of-mouth, short-form video (trailer clips on TikTok / Reels).

---

## P3 — The Tamagotchi Enjoyer (Niche)

**Archetype:** A player who, regardless of the sport, loves daily-care games: Nintendogs, Neopets, Habitica, original Tamagotchi. They'll open the game every day to do a training session, even if they only race once a week.

**What they want:**
- A rewarding daily check-in loop. Visible stat progression. Consequence for skipping days (but not a punishing grudge).
- Customization: jersey, rider name, maybe bike skins.
- A reason to care about "their" racer as a character.

**What they don't want:**
- A hardcore PvP ladder that makes their carefully-raised racer feel underpowered against tryhards.
- Energy timers that feel predatory.

**Product implications:**
- The Tamagotchi training loop is a first-class feature, not a bolt-on — 8 activities, fatigue, over-training risk, random events (see [GDD §5](GDD.md)).
- Off-cycle quarterly seasons (see ADR 0001) are largely in service of this persona: the game must have purpose on any given Tuesday in August.
- Customization surface (jersey colors, rider name, later: unlockable cosmetics) is meaningful.
- No pay-to-win. Timers are for pacing, not for monetization pressure.

**Reach channels:**
- r/Tamagotchi, r/incremental_games, cozy-game social media communities.

---

## Anti-Personas (Explicitly Not Targeting)

Naming who we're **not** for is as important as naming who we are for. Features that only serve these groups should be deprioritized or declined.

- **The hardcore cycling sim player.** Someone looking for Zwift, BKool, or a UCI-licensed road sim. Little Six is arcade-authentic, not simulation-authentic.
- **The esports competitor.** Someone expecting ranked ladders, anti-cheat arms races, tournament prize pools. Possible future, but not now.
- **The loot-box whale.** Someone looking for a gacha bike collection. Cosmetics only; no power progression behind paywalls.
- **The gambling / sportsbook user.** The Little 500 has a long tradition of being *about the race*, not *about betting on the race*. Little Six stays on that side of the line.

---

## How to Use This Document

1. **Before adding a feature:** name the persona it serves. If you can't, the feature is probably not for Little Six.
2. **When prioritizing:** the lower-numbered persona wins conflicts.
3. **When writing copy (marketing site, in-game text):** write for P0 first, P1 second. P2 and P3 will follow if P0 and P1 feel right; the reverse is not true.
4. **When reviewing specs:** if a requirement serves no listed persona, question it.

This document lives in the product-decisions layer. Specs implement; this frames.
