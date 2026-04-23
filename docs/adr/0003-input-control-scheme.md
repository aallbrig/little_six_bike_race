# ADR 0003 — Input Control Scheme (Four-Button Pedal + Steer)

**Status:** Accepted
**Date:** 2026-04-22
**Deciders:** Andrew (product), Claude (assist)
**Tags:** product, racing, input, mobile-ux

---

## Context

Earlier specs (Spec 004 REQ-004-005, Spec 007 REQ-007-006) assumed the bike **auto-accelerates** toward a stat-derived top speed, with the player only modulating **steering** (tilt or L/R touch), **brake**, **sprint**, and **exchange**. In that model, the player's primary skill expression is a corner-line and sprint-timing game.

We've since landed two product decisions that strain that model:

1. **Audience priority (ADR 0002, [AUDIENCE.md](../AUDIENCE.md))** — our P0 is a real Little 500 rider. Auto-accelerate feels too arcadey; real cyclists expect the bike to reflect their pedaling effort.
2. **Skill-vs-training balance.** We committed in [ADR 0002](0002-weekly-race-format-and-leagues.md) that weekly-race participants gain a modest training advantage but the finale must stay **a game of skill**. Auto-accelerate pushes too much of race performance onto stats. We need a skill surface the player can *practice* with, so stats become multipliers rather than the outcome itself.

The product directive is clear: *"maybe players have a button to pedal left, pedal right, and steer left, steer right."* This ADR formalizes that direction and settles the open variables (what pedals the bike, what stops it, what sprints, where those buttons live on a 375-px mobile viewport).

---

## Decision

### 1. The bike is thrust by **alternating pedal taps**, not auto-acceleration.

Two on-screen buttons on the **bottom of the landscape HUD**:

- **Pedal Left** (left thumb)
- **Pedal Right** (right thumb)

The player alternates: `L → R → L → R → …`. Each successful alternating tap delivers a **power stroke** to the bike. Tapping the same pedal twice in a row (`L → L`) is a **missed stroke** — no power delivered, small rhythm penalty.

**Power per stroke** depends on two things:
- **Timing quality.** Each stroke has a "power window" centered on the ideal cadence interval for the rider's current gear/speed. Strokes inside the window deliver full power; strokes early or late deliver scaled-down power.
- **Stat-derived ceiling.** The **Power** stat sets the maximum force per stroke; the **Cadence** stat sets the **width of the power window** (higher Cadence = more forgiveness on timing).

Combined effect: the player's rhythm produces speed; the racer's stats determine ceiling and forgiveness. A skilled novice with low Cadence can still beat a trained player with sloppy rhythm, but an equally-skilled, well-trained rider will always edge out an equally-skilled, untrained one.

**Rhythm-based, not rapid-tap.** Target cadence is ~80–100 pedal strokes per minute — roughly real-cycling tempo. We are **not** building a mash-as-fast-as-possible minigame; that cramps thumbs and rewards macros. The skill is *evenness*, not raw rate.

### 2. Steering is **hold-to-turn**, not tilt.

Two on-screen buttons near the top corners of the landscape HUD:

- **Steer Left**
- **Steer Right**

Hold to turn in that direction; release to let the bike track straight. Holding **both** does nothing (mutual cancel). Pressing left while right is held flips direction without re-press latency (the controller reads the most recently pressed).

**Tilt support is removed as a primary input** and relegated to an optional accessibility assist (see §4). Reasons:
- Tilt doesn't coexist with the pedal buttons — the player can't rock the device mid-cadence without disrupting their thumbs.
- Tilt accuracy on mobile Safari / Chrome Android is inconsistent and frequently blocked by user gesture policies.
- A pure-button scheme is **deterministic**, making the skill surface fair, replayable, and spectator-legible.

### 3. Braking is a dedicated button (coaster-brake framing retained).

A **Brake** button on the right-bottom cluster, reachable by the right thumb without leaving the Pedal-Right position (short sweep). Held brake decelerates the bike proportional to hold time.

Thematically, the bike is still a coaster-brake bike — "back-pedaling to brake" is preserved as the **cosmetic animation** of the rider when the brake button is held. The actual input is the button (discoverable, thumb-reachable on mobile) rather than a gesture.

### 4. Sprint and The Burn stay; they become **long-press modifiers** on pedal + exchange.

- **Sprint** is activated by **holding both pedal buttons simultaneously for ≥ 200ms** (two-thumb commit). While held, the rider enters Sprint mode — higher top speed, faster cadence expectation, drains Sprint energy. Release either pedal to exit Sprint and return to alternating cadence.
- **The Burn** remains sprint-during-exchange-zone: executing the sprint hold while crossing the exchange zone and tapping the **Exchange** button produces the 0.3s Burn advantage, exactly as in [GDD §8](../GDD.md).

We chose "hold both pedals" for Sprint because it:
- Matches the real act of an out-of-saddle sprint (both legs firing).
- Doesn't require finding a fifth button on a crowded landscape HUD.
- Naturally rate-limits spam (you can't alternate while both are held, so you're paying a cadence cost).

### 5. Exchange stays a separate button (Phase 2 only).

In Phase 2 relay races (Spec 004 REQ-004-004+), the **Exchange** button appears at bottom-center only when the active rider enters the team's pit zone, exactly as previously specified. Tapping it triggers the rider handoff. Holding both pedals while tapping Exchange triggers The Burn.

### 6. HUD layout — landscape orientation

```
┌───────────────────────────────────────────────────────────────┐
│ [LAP 123/600]                [MINIMAP]              [SPRINT░░]│
│ [pos 3rd]                                            [bar]    │
│                                                               │
│ [◀ STEER L]                                       [STEER R ▶] │
│                                                               │
│                    (race world — 3D)                          │
│                                                               │
│                     [EXCHANGE]     (pit-zone only)            │
│                                                               │
│ [FATIGUE ☁]                                        [BRAKE ⬤]  │
│ [PEDAL L ▼]                                        [PEDAL R ▼]│
└───────────────────────────────────────────────────────────────┘
```

Specifics:
- **Steer L / Steer R**: anchored to the upper-inside corners, ~72 × 72 px, above the pedal buttons so both thumbs naturally find a comfortable left-pedal + left-steer rest position.
- **Pedal L / Pedal R**: anchored to the bottom-inside corners, ~96 × 96 px (larger; most-used input).
- **Brake**: bottom-right, above or beside Pedal R; ~72 × 72 px.
- **Exchange**: bottom-center, only visible in pit zone, ~88 × 88 px.
- **Fatigue arc**: bottom-left corner, non-interactive.
- **Sprint energy bar**: top-right corner, non-interactive.
- **Lap counter / minimap / position**: top strip, non-interactive.

All tappable targets ≥ 44 × 44 px (Spec 007 REQ-007-001). Safe-area insets respected (Spec 007 REQ-007-005).

### 7. Desktop input mirrors the mobile buttons.

| Mobile button | Default keyboard | Default gamepad |
|---|---|---|
| Pedal Left | `A` or `Left Shift` | Left Trigger |
| Pedal Right | `D` or `Right Shift` | Right Trigger |
| Steer Left | `Left Arrow` | Left Stick Left |
| Steer Right | `Right Arrow` | Left Stick Right |
| Brake | `Space` | `B` / Circle |
| Exchange | `E` | `A` / Cross |
| Sprint (hold both pedals) | `A + D` | LT + RT |

Desktop is a supported surface, not a primary one. Keyboard defaults are overridable from Settings.

### 8. Accessibility assists (opt-in, in Settings)

- **Auto-Cadence Assist.** A toggle that replaces alternating-pedal-taps with a single-button hold. The system maintains a floor cadence for the player; their in-race ceiling drops by ~10% to keep the skill floor honest. Intended for: first-time players, players with motor-control needs, parents racing with a kid.
- **Steering Assist.** Soft corrects steering toward the racing line when the player is not actively pressing a steer button. Reduces crash-on-corner risk. Small speed cost.
- **Tilt Assist (deprecated-primary).** Optional accelerometer-based steering for players who genuinely prefer tilt. Off by default. If enabled, the Steer L/R buttons remain present and always override.

All assists are **off** by default. None of them gate a player out of any leaderboard or achievement — assists are a ramp, not a penalty.

---

## Consequences

### Positive

- **True game of skill.** Race outcomes are driven by the player's rhythm and steering, modulated by stats. Matches the [ADR 0002](0002-weekly-race-format-and-leagues.md) commitment that weekly participation is an edge, not a replacement for skill.
- **Real-cycling feel for P0.** The pedal-alternation model will read as respectful to riders who know what real pedaling feels like. Cadence-as-skill is an earned, legible mechanic.
- **Deterministic + spectator-legible.** Buttons, not tilt. Every input produces the same outcome on every device. Replays and leaderboards are honest.
- **Clear training→race translation.** Stats have obvious, explainable effects (Power → force ceiling; Cadence → timing forgiveness; Endurance → fatigue drain). No "mystery stat" problem.
- **Fits the 5-minute weekly race** and the 15–20 minute finale equally well — the same inputs work at both scales.

### Negative / Costs

- **Learning curve.** First-time players won't instantly get alternating cadence. Tutorial + Auto-Cadence Assist must absorb the onboarding hit.
- **Thumb fatigue over long races.** 15–20 minutes of pedal alternation is fine for real cyclists but harsh for casuals. Mitigation: drafting is a *resting* mechanic — in a good draft, your cadence demand drops; the game explicitly rewards choosing to rest.
- **Spec rework.** Spec 004 REQ-004-005 (tilt-primary steering) and the REQ-004-006 auto-accelerate physics are both replaced. Spec 007 REQ-007-006 (touch zones) is replaced. Non-trivial re-implementation.
- **Screenshot discoverability suffers.** A tilt-steered bike is intuitive in a marketing screenshot; a four-button HUD looks busy. The trailer will need to show the rhythm in motion to communicate the skill loop.

### Follow-ups Required

1. [ ] Rewrite [Spec 004 REQ-004-005 (input)](../specs/spec_004_multiplayer_race.md) — four-button scheme; pedal cadence simulation; replace auto-accelerate with stroke-based thrust.
2. [ ] Rewrite [Spec 007 REQ-007-006 (touch)](../specs/spec_007_mobile_ui_ux.md) — new HUD layout, button zones, safe-area positioning.
3. [ ] Add Settings entries (Spec 007 REQ-007-008) for Auto-Cadence, Steering Assist, Tilt Assist.
4. [ ] Update [GDD §5 Stats](../GDD.md) — introduce **Cadence** stat (new), rename Speed → **Power** to match the new mechanic, define effect formulas.
5. [ ] Tutorial flow (future spec): first-run walkthrough of alternating cadence on a straight track before entering a full race.
6. [ ] Art/animation: rider's legs must visibly match the cadence input. This is a visible fidelity promise to P0.

---

## Alternatives Considered

### A. Keep the auto-accelerate + tilt model.
Simplest. Rejected because it flunks the "game of skill" commitment from ADR 0002 and feels disrespectful to P0 (no relationship between the player's effort and the bike's speed).

### B. Single-pedal hold-to-accelerate (like most racing games).
Middle ground. Rejected because it loses the real-cycling rhythm that's the whole differentiator. Also leaves Sprint without a natural long-press home.

### C. Rapid-tap both pedals as fast as possible (QWOP-adjacent).
Rejected for ergonomics (cramped thumbs over a 20-minute race), spam macros, and it's the wrong *kind* of skill — it rewards raw tap speed rather than rhythm.

### D. Gesture-based steering (swipe left/right).
Rejected because gesture recognition conflicts with taps in the same region and is unreliable on edge cases (near edges, near the pedal buttons).

### E. Virtual joystick for steering.
Rejected because it occupies too much HUD real estate on a phone and produces analog output the game doesn't need — binary hold is fine for a quarter-mile oval with two turns.

### F. Put Sprint on a fifth dedicated button.
Rejected for HUD crowding. Five interactive buttons on a 375-px-wide landscape viewport leaves no room for fatigue/minimap/lap chrome. "Hold both pedals" gets Sprint for free.

### G. Auto-Cadence on by default, manual cadence opt-in.
Rejected because it reverses our commitment. The default play experience should *be* the rhythm game; Auto-Cadence is a ramp for onboarding and accessibility, not the headline product.

---

## References

- [ADR 0002 — Weekly Race Format & League Selection](0002-weekly-race-format-and-leagues.md) — the skill-vs-training bargain this ADR settles.
- [AUDIENCE.md](../AUDIENCE.md) — P0 expects real-cycling feel.
- [GDD §8 — The Main Race](../GDD.md) — existing drafting, burn, coaster-brake framing.
- [Spec 004 — Multiplayer Race](../specs/spec_004_multiplayer_race.md) — REQ-004-005/006/007 to be rewritten per this ADR.
- [Spec 007 — Mobile UI/UX](../specs/spec_007_mobile_ui_ux.md) — REQ-007-006 touch model to be rewritten per this ADR.
