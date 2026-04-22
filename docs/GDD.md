# Game Design Document — Little Six

**Version:** 1.0  
**Status:** Approved for Implementation  
**Last Updated:** 2026-04-10  

---

## Table of Contents

1. [Game Overview](#1-game-overview)
2. [Core Philosophy](#2-core-philosophy)
3. [Attract Mode & Game Flow](#3-attract-mode--game-flow)
4. [Player Onboarding](#4-player-onboarding)
5. [Racer Creation & Stats](#5-racer-creation--stats)
6. [Training System](#6-training-system)
7. [Spring Series Events](#7-spring-series-events)
8. [The Main Race](#8-the-main-race)
9. [Multiplayer Architecture](#9-multiplayer-architecture)
10. [Controls](#10-controls)
11. [UI/UX Overview](#11-uiux-overview)
12. [Progression & Persistence](#12-progression--persistence)
13. [Audio Direction](#13-audio-direction)
14. [Monetization](#14-monetization)

---

## 1. Game Overview

| Field | Value |
|---|---|
| **Title** | Little Six |
| **Subtitle** | The World's Greatest College Weekend |
| **Genre** | Multiplayer Arcade Racing / Social Simulation |
| **Platform** | Web browser (mobile-first; desktop supported) |
| **Engine** | Godot 4.6 |
| **Target Audience** | Ages 16–30; college students, cycling fans, casual gamers |
| **Players** | 1–6 concurrent (one race room) |
| **Session Length** | 5–20 minutes per race; 2–5 minutes training per day |

### High-Concept Pitch

> *Train your rider like a Tamagotchi. Race 50 laps around the cinder oval. Execute "the burn" in the pit. Be the last team standing when the bell lap drops.*

Little Six is a two-layer game: a **daily training simulator** where the player nurtures their racer's stats through careful choices (without over-training!), and a **real-time multiplayer race** where those investments pay off. The game compresses a full collegiate cycling season into tight, phone-friendly play sessions.

### Inspiration

- **Primary:** Indiana University's Little 500 bike race (est. 1951)
- **Training Loop:** Tamagotchi, Pokémon training mechanics
- **Racing:** Mario Kart (arcade feel), Sprint (Midway arcade)
- **Aesthetic:** Americana college town, late-spring golden hour

---

## 2. Core Philosophy

### Design Pillars

**1. Authentic to the Tradition**  
Every mechanic traces back to a real Little 500 rule or cultural element. Coaster brakes, exchange zones, standardized bikes, "the burn" — players should feel they're engaging with something real.

**2. Mobile-First, Frictionless**  
Every screen is designed for a 390×844 px phone. One thumb should handle 80% of training interactions. Racing uses simple two-thumb controls. No required keyboard or mouse.

**3. Short Sessions, Long Engagement**  
Each play session is 5–20 minutes. But the season loop — training for 6 weeks then racing — provides weeks of engagement. Players dip in daily to train, then gather for race events.

**4. Event-Driven Architecture**  
Every significant action emits an event. No system polls for state; everything reacts to signals. This keeps the code decoupled and easy to extend.

**5. Approachable Depth**  
Casual players can mash through training and still have fun racing. Competitive players study stat synergies, optimize training sequences, and master exchange timing. The skill ceiling is high; the skill floor is low.

---

## 3. Attract Mode & Game Flow

### 3.1 Attract Mode Loop

The game runs in an attract mode loop when no player is active. This loop cycles continuously:

```
┌─────────────────────────────────────────────────────────┐
│                    ATTRACT MODE LOOP                     │
│                                                         │
│  [1] LOGO SCREEN        (3 seconds, fade in/out)        │
│       ↓                                                 │
│  [2] INTRO CINEMATIC    (30 seconds, skippable)         │
│       ↓                                                 │
│  [3] TITLE SCREEN       (10 seconds, tap to enter)      │
│       ↓                                                 │
│  [4] DEMO RACE          (60 seconds of AI gameplay)     │
│       ↓                                                 │
│  ─── loops back to [2] ────────────────────────────────  │
└─────────────────────────────────────────────────────────┘
```

**Tap anywhere on Title Screen → Exit attract mode → Player Onboarding or Main Hub**

### 3.2 Logo Screen

- Black background
- Studio/publisher logo fades in with a subtle sound sting
- 3 seconds total, then fades to black
- Not skippable (brand requirement)

### 3.3 Intro Cinematic

Pre-rendered (or real-time animated) sequence:
- Shot 1: Aerial pullback from a cinder oval track at golden hour (2s)
- Shot 2: Close-up of coaster-brake wheel spinning (2s)
- Shot 3: Crowd filling the stands — pennants, cheering (3s)
- Shot 4: Four riders warming up in matching jerseys (3s)
- Shot 5: "THE BURN" — rider sprints, brakes hard, hands off bike (5s)
- Shot 6: Finish line, confetti, team celebrating (3s)
- Shot 7: Camera tilts up to sky, LITTLE SIX title card drops in with hit (4s)
- Shot 8: Subtitle: *"The World's Greatest College Weekend"* (3s)
- Fade to black (2s)
- Skippable via tap after 5 seconds

### 3.4 Title Screen

- Animated background: slow-moving camera above the empty track at dusk
- "LITTLE SIX" title with retro arcade font, slight neon glow
- "TAP TO START" pulsing text
- Crowd ambiance audio loop
- Idle for 10 seconds → automatically transitions to Demo Race

### 3.5 Demo Race

- Full race scene with AI-controlled riders (6 teams, 4 riders each)
- Camera follows the lead rider
- "DEMO" watermark in corner
- "TAP TO PLAY" always visible
- No HUD elements (clean cinematic view)
- Plays for 60 seconds then returns to Intro Cinematic

### 3.6 Full Game Flow (after attract mode)

```
ATTRACT MODE
    ↓ (tap)
ONBOARDING / MAIN HUB
    ├── NEW PLAYER → CREATE RACER → TUTORIAL → MAIN HUB
    └── RETURNING → MAIN HUB
           │
           ├── MY RACER ──→ TRAINING DAY ──→ TRAINING RESULTS ──┐
           │                                                      │
           ├── RACE NOW ──→ MATCHMAKING LOBBY ──→ RACE ──────────┤
           │                                                      │
           ├── SEASON ───→ SEASON HUB ──→ WEEK VIEW ──→ EVENT ──┤
           │                                                      │
           └── LEADERBOARD / SETTINGS                            │
                                                                  ↓
                                                          RESULTS SCREEN
                                                                  ↓
                                                          BACK TO MAIN HUB
```

---

## 4. Player Onboarding

### 4.1 First-Run Flow

1. **Welcome screen** — brief flavor text about the tradition ("Since 1951, the cinder oval has decided glory.")
2. **Choose a Racer Background** — determines starting stat spread (not locked in, just a starting point)
3. **Name Your Racer** — text input, 16-char max
4. **Customize Jersey** — choose from 8 preset color combinations (crimson/cream default)
5. **Brief tutorial** — introduces training and the controls (can be skipped)

### 4.2 Racer Backgrounds

| Background | Speed | Endurance | Recovery | Handling | TeamChem | Flavor |
|---|---|---|---|---|---|---|
| Weekend Warrior | 45 | 50 | 55 | 50 | 60 | "You ride for fun on weekends. Balanced and friendly." |
| Ex-Track Star | 70 | 40 | 45 | 65 | 40 | "Fast but brittle. High ceiling if you manage fatigue." |
| Distance Rider | 35 | 75 | 60 | 45 | 50 | "Built for the long haul. Steady wins the race." |
| Complete Newbie | 30 | 35 | 65 | 35 | 70 | "Most room to grow. Training pays off faster." |

---

## 5. Racer Creation & Stats

### 5.1 Permanent Stats (0–100 scale)

| Stat | Effect in Race | Effect in Training |
|---|---|---|
| **Speed** | Top sprint velocity; "burn" effectiveness | Determines max training load before diminishing returns |
| **Endurance** | Laps before fatigue penalty kicks in; sustain speed in pack | Training sessions scale based on base endurance |
| **Recovery** | How fast fatigue drops between exchanges | Reduces rest-day requirement; faster bounce-back |
| **Handling** | Corner speed (turn 1 & 2); pack avoidance; exchange precision | Affects "Video Study" training yield |
| **TeamChem** | Speed bonus when within 2 bike-lengths of a teammate | Improves with Team Meeting training |

### 5.2 Transient Stats (reset between races/seasons)

| Stat | Range | Description |
|---|---|---|
| **Fatigue** | 0–100 | Accumulates from training. High fatigue penalizes all race performance. Resets fully at race day. |
| **Morale** | 0–100 | Improves race performance across the board. Starts at 50. |
| **Race Form** | 0–100 | Hidden stat. Combination of recent training consistency and rest. Shown as "HOT / WARM / COLD" indicator. |

### 5.3 Stat Caps and Soft Caps

- Hard cap: 100 for all stats
- Soft cap at 85: training gains above 85 are halved
- Diminishing returns above 90: gains quartered
- Fatigue above 70: all training gains reduced 30%
- Fatigue above 85: risk of **injury event** each training session (15% chance)

### 5.4 Injury System

When injured:
- 2–3 forced rest days (no training choices)
- Affected stat reduced by 5–10 points temporarily
- Recovery stat determines how quickly temp reduction heals
- Visual: racer icon shows bandage, "INJURED" status badge

---

## 6. Training System

### 6.1 Season Structure

A full season consists of:
- **6 Training Weeks** (before the final race)
- Each week: **3 Training Days** + **1 Spring Series Event**
- Final week: Qualifying + Main Race

```
Week 1: [Train][Train][Train][ITT Event]
Week 2: [Train][Train][Train][Miss-N-Out Event]
Week 3: [Train][Train][Train][Team Pursuit Event]
Week 4: [Train][Train][Train][ITT Event (ranked)]
Week 5: [Train][Train][Train][Miss-N-Out (ranked)]
Week 6: [Train][Train][Train][Qualifying Time Trial]
Race Week: [Qualifying][Qualifying][RACE DAY]
```

### 6.2 Training Day

Each training day, the player selects **2 activities** from the available list. Activities execute sequentially and stats update with animations.

After selection:
1. Activity 1 animates (racer icon performs activity)
2. Stat bars update with +/- indicators
3. Activity 2 animates
4. Stat bars update
5. Random event may fire (see 6.4)
6. Day summary shown: "Day Complete. Next: [Day X of Week Y]"

### 6.3 Training Activities

| Activity | Speed Δ | Endurance Δ | Recovery Δ | Handling Δ | TeamChem Δ | Fatigue Δ | Morale Δ |
|---|---|---|---|---|---|---|---|
| Sprint Intervals | +3 | 0 | 0 | 0 | 0 | +4 | +1 |
| Long Ride | 0 | +4 | 0 | +1 | 0 | +3 | +1 |
| Recovery Spin | 0 | 0 | +3 | 0 | 0 | -4 | +2 |
| Rest Day | 0 | 0 | +1 | 0 | 0 | -7 | +3 |
| Strength Work | +2 | +2 | 0 | 0 | 0 | +5 | 0 |
| Video Study | 0 | 0 | 0 | +4 | 0 | 0 | +1 |
| Team Meeting | 0 | 0 | 0 | 0 | +5 | 0 | +4 |
| Nutrition Plan | 0 | +2 | +1 | 0 | 0 | -3 | +1 |

**Rules:**
- "Rest Day" cannot be combined with any other activity (it consumes both slots)
- Same activity cannot be chosen twice in one day
- If Fatigue ≥ 80, only Rest Day, Recovery Spin, and Nutrition Plan are available

### 6.4 Random Training Events

Probability: 25% chance per training day. One event fires after both activities resolve. Events are weighted by current stats/season week.

| Event | Trigger Weight | Effect | Flavor Text |
|---|---|---|---|
| Breakthrough Session | Fatigue < 50, Week ≥ 3 | +5 to highest trained stat | *"Something clicked today. You feel unstoppable."* |
| Minor Strain | Fatigue > 60 | +3 Fatigue, -1 Speed | *"Pushed a little too hard. Your legs are talking to you."* |
| Rival Encounter | Any | +2 Speed, +3 Morale | *"You traded pace lines with a top-ranked team. Motivating."* |
| Rain Day | Weeks 1–4 | Only indoor options available today | *"A spring storm rolls through. Adapt or rest."* |
| Equipment Check | Any | 0 effect, but miss 1 activity slot | *"The pit crew flagged an issue. Lost a training slot but avoided a race problem."* |
| Coach's Pep Talk | Morale < 40 | +10 Morale | *"Your coach pulls you aside. 'Believe in the process.'"* |
| Overtraining Warning | Fatigue > 75 | Force Rest Day next session | *"Your body is waving a red flag. Tomorrow: mandatory rest."* |
| Nutrition Win | Nutrition Plan chosen | Double the Nutrition Plan effect | *"Meal prep paid off. Body is running clean."* |
| Weather Perfect | Any | All fatigue gains halved today | *"Crisp 65°F, zero wind. Perfect training conditions."* |
| Illness Risk | Fatigue > 80 | 30% chance: -5 Endurance, +5 Fatigue, 2-day injury | *"You wake up rough. Hope it's just allergies."* |

### 6.5 Over-Training System

The over-training system is the central tension of the training loop.

**Fatigue Thresholds:**

| Fatigue Level | Label | Training Effect | Visual Indicator |
|---|---|---|---|
| 0–30 | Fresh | +10% to all gains | Green racer face, energetic |
| 31–55 | Good | Normal gains | Neutral face |
| 56–70 | Tired | -20% to all gains | Yawning face |
| 71–85 | Overloaded | -40% to all gains, Morale -1/day | Red face, slumped |
| 86–100 | Danger Zone | -60% gains, injury risk 15%/session | Skull warning, slumped |

**Recovery rates** (per Rest Day / Recovery Spin):
- Rest Day: -7 Fatigue base, +Recovery Stat × 0.05 bonus
- Recovery Spin: -4 Fatigue base, +Recovery Stat × 0.03 bonus

**Designer Intent:** Players who push hard all 6 weeks will arrive at race day over-trained and underperform. The optimal path requires 1–2 rest periods across the season.

---

## 7. Spring Series Events

Spring Series events occur once per week. They serve two purposes:
1. Practice the race controls in a lower-stakes setting
2. Earn **Cred Points** and improve Race Form stat

### 7.1 Individual Time Trial (ITT)

**Format:** Solo 4-lap time attack around the full track.  
**Control feel:** Same as main race. No other racers on track.  
**Scoring:** Fastest lap time. Posted to seasonal leaderboard.  
**Reward:** Cred Points based on rank vs. other online players' times.

### 7.2 Miss-N-Out

**Format:** 8 riders start. After each lap, the last-place rider is eliminated. Final 2 riders race head-to-head.  
**Multiplayer:** Matchmade with real players when available; AI fill for empty slots.  
**Special rule:** If two riders are within 0.3 seconds at the line, neither is eliminated ("double save").  
**Reward:** Cred Points per lap survived. Bonus for winning.

### 7.3 Team Pursuit

**Format:** Two teams of 2 riders each start on opposite sides of the track. First team to catch the other (or complete 10 laps) wins.  
**Mechanic:** Requires synchronizing pace with a teammate — the ghost of your teammate's position is shown.  
**Reward:** Cred Points for each lap the gap closes.

### 7.4 Qualifying Time Trial

**Format:** 4-lap solo time trial. Sets your starting grid position for the main race.  
**Stakes:** Starting position matters — front rows draft advantage at race start; back rows fight through traffic.  
**Grid format:** 6 columns of variable rows depending on entrant count.

---

## 8. The Main Race

### 8.1 Overview

The Little Six main race is a 50-lap relay race on a quarter-mile cinder oval. Up to 6 teams of up to 4 riders compete. Only one rider per team is on the track at any time; teammates wait at the team's pit spot and can exchange on any lap.

### 8.2 Track Layout

```
        ┌──────── BACK STRAIGHT ─────────┐
        │                                 │
   TURN 2                             TURN 1
        │                                 │
        └──── FRONT STRAIGHT (PITS) ─────┘
                    ↑ START/FINISH
        ← PIT SPOTS (each 16ft, assigned by qual position) →
```

- **Track shape:** Symmetrical oval; cinder surface texture
- **Turn radius:** Tight (140° sweep); must brake slightly or drift through
- **Front straight:** Contains all pit spots + start/finish line
- **Pit spots:** One per team, assigned by qualifying position (fastest qualifier = closest to start/finish)
- **Pack density:** Up to 24 riders on track at once (6 teams × 4, but only active rider per team = 6 max on track simultaneously in Phase 1 MVP)

### 8.3 Race Phase (MVP — Individual Riders)

In Phase 1, each player controls their single racer for the full race duration. No exchanges are required. This simplifies the multiplayer sync problem.

- 6 players per race room
- Each player rides their trained racer
- Racer stats affect in-race performance
- 50 laps to complete
- Winner: first to complete lap 50

### 8.4 Race Phase (Full — Team Relay, Phase 2)

In Phase 2, teams of 2–4 riders compete as a unit:

- 2–6 teams, 2–4 riders per team
- Only the "active" rider is on track
- Others wait at pit spot
- Exchange: active rider rides into the 16-foot exchange zone; tap the Exchange button; the next rider takes over (instant, simulated handoff)
- **Minimum exchanges:** 5 exchanges required; penalty lap added if not met by lap 40
- **The Burn:** If the player presses Sprint + Exchange simultaneously in the exchange zone, the exchange is faster (0.3s advantage) and the outgoing rider visually sprints and brakes hard

### 8.5 Race Mechanics

**Drafting**
- Riding within 1 bike-length behind another rider: -20% fatigue drain, +3% speed
- Riding within 2 bike-lengths: -10% fatigue drain, +1% speed
- "Slingshot" opportunity: break out of draft for +8% speed burst for 2 seconds

**Coaster Brake**
- The game simulates coaster-brake physics: the bike builds momentum and only slows via brake input
- Brake button (right thumb area on mobile): applies progressive braking
- Releasing the pedal (letting go of accelerate) does not brake; it coasts
- Maximum brake at corners prevents crashes; under-braking causes wide turns

**Race Fatigue**
- Racer's in-race fatigue starts at 0, rises with effort
- At 50% fatigue: -5% top speed
- At 75% fatigue: -15% top speed, -10% corner speed
- At 100% fatigue: -30% top speed; risk of crash if cornering above 60% speed
- Fatigue drains slowly while coasting/drafting
- Pre-race training fatigue carries a penalty: race-day fatigue starts at `training_fatigue × 0.3`

**Sprint Mechanic**
- Sprint bar: 100 units; refills at 10/sec when not sprinting
- Sprint held: drains 25/sec; +15% speed
- Empty sprint bar: 3-second sprint lockout (exhaustion animation plays)

**Crashes**
- Probability on corners scales with speed × (100 − Handling) / 100
- Crash: 2-second animation, resume at 60% speed
- Cannot crash in straight sections unless colliding directly with another rider

**Bell Lap**
- Lap 50 is the bell lap
- Audio: bell rings, crowd noise increases dramatically
- All sprint bars fully refill for lap 50 (the "final sprint")
- All drafting effects are removed (pure speed contest)

### 8.6 Race HUD

On mobile (landscape orientation):
- Top-left: Lap counter (CURRENT / 50) + position badge (e.g., "3rd")
- Top-center: Minimap (oval; team dots colored)
- Top-right: Sprint bar (vertical gauge)
- Bottom-left: Fatigue indicator (colored arc: green → yellow → red)
- Bottom-right: Brake button (large circle)
- Bottom-center: Exchange button (only visible in pit zone; pulses when racer enters zone)
- "BURN" indicator: appears briefly when Sprint+Exchange combo window is available

### 8.7 Post-Race Results

1. Podium animation (top 3 riders on platform)
2. Full race breakdown:
   - Final positions (1st–6th)
   - Total time
   - Fastest lap
   - Number of exchanges (team mode)
   - Sprint uses
3. Cred Points awarded
4. Season standings update
5. "Race Again" or "Return to Hub"

---

## 9. Multiplayer Architecture

See [Network Architecture Document](NETWORK_ARCHITECTURE.md) for full technical detail.

### 9.1 Room Types

| Room Type | Description | Max Players |
|---|---|---|
| Quick Race | Random matchmaking; fill with AI bots | 6 |
| Friends Room | Private; share a 6-character room code | 6 |
| Season Match | ELO-matchmade; part of seasonal ranking | 6 |
| Demo AI | Local-only, no server needed | 0 (AI only) |

### 9.2 Lobby Flow

```
Player taps "Race Now"
    ↓
Select room type
    ↓
Matchmaking spinner (if Quick Race / Season Match)
    ↓
Lobby screen: player slots fill in, racer names/stats previewed
    ↓
Host taps "Start Race" (or auto-starts when full)
    ↓
Loading screen → Qualifying results display → Race countdown → RACE
```

### 9.3 Player Count Handling

- Game always starts with 6 slots
- Empty slots are filled with AI racers (difficulty scales to average player ELO)
- If a human player disconnects mid-race, their racer becomes AI-controlled

---

## 10. Controls

### 10.1 Mobile (Primary)

**Racing (Landscape):**

| Action | Input |
|---|---|
| Steer left | Tilt device left OR tap left half of screen |
| Steer right | Tilt device right OR tap right half of screen |
| Accelerate (pedal) | Automatic (always pedaling unless braking) |
| Sprint | Hold Sprint button (right side, above brake) |
| Brake | Hold Brake button (right side, lower) |
| Exchange | Tap Exchange button (center bottom, only in pit zone) |
| The Burn | Tap Sprint + Exchange simultaneously |

**Steering sensitivity:** Configurable in settings. Default: 25° tilt = max steer.  
**Tilt fallback:** If gyroscope unavailable, tap-only mode activates automatically.

**Menus (Portrait):**

| Action | Input |
|---|---|
| Confirm / Select | Tap |
| Back | Swipe right or tap Back button |
| Scroll | Swipe up/down |
| Long press | 600ms hold (context actions) |

### 10.2 Desktop / Keyboard (Secondary)

| Action | Key |
|---|---|
| Steer left | A or ← |
| Steer right | D or → |
| Sprint | Space (hold) |
| Brake | S or ↓ |
| Exchange | E |
| Pause | Esc |

### 10.3 Accessibility

- High-contrast mode (settings toggle)
- Text scale: S/M/L options (default M)
- Reduce motion mode (disables crowd animations, particle effects)
- Color-blind friendly team color assignments (uses both color + shape icons)
- Tilt sensitivity adjustment (0.5× to 2.0×)

---

## 11. UI/UX Overview

### 11.1 Screen Hierarchy

```
ATTRACT MODE (passive)
└── Title Screen
    └── Main Hub (post-login)
        ├── My Racer
        │   ├── Training Day
        │   │   └── Training Results
        │   └── Racer Stats (detailed view)
        ├── Race Now
        │   ├── Room Type Select
        │   ├── Matchmaking / Lobby
        │   └── Race → Results
        ├── Season
        │   ├── Season Overview
        │   ├── Week Detail
        │   └── Spring Event → Results
        ├── Leaderboard
        └── Settings
```

### 11.2 Design Principles

- **Minimum tap target:** 44×44 px (Apple HIG standard)
- **Primary actions:** Bottom 40% of screen (thumb reach zone)
- **Landscape for racing:** All race HUD elements are in corner zones
- **Portrait for everything else:** Menus, training, lobby
- **Loading states:** Every async operation shows an animated spinner with a cycling pun ("Pedaling to the server...")
- **Error states:** Friendly copy; never raw error codes

### 11.3 Color Palette (see Art Bible for full spec)

- Primary: Crimson (#B31B1B)
- Secondary: Cream (#FAF3E0)
- Accent: Amber (#F59E0B)
- Success: Green (#16A34A)
- Warning: Orange (#EA580C)
- Background: Near-black (#0F0F0F)

---

## 12. Progression & Persistence

### 12.1 Account System

- **Guest play:** No account required; local save only
- **Anonymous account:** Auto-created on first multiplayer game; persists data serverside
- **Named account:** Optional email + username for leaderboards and friend rooms

### 12.2 Seasons

- A season is 7 weeks (6 training + race week)
- Seasons reset globally on a schedule (or when the player completes their current season)
- Career stats accumulate across seasons

### 12.3 Cred Points (CP)

| Source | Amount |
|---|---|
| Complete a training day | 10 CP |
| Spring Series event (participation) | 25 CP |
| Spring Series event (top 3) | 50–100 CP |
| Main race (participation) | 75 CP |
| Main race (1st place) | 300 CP |
| Personal best time (any event) | 25 CP bonus |

### 12.4 Cosmetic Unlocks

CP can be spent on cosmetics (no pay-to-win):
- Jersey color presets: 8 base, 12 unlockable
- Bike skins: 5 tiers (Freshman, Sophomore, Junior, Senior, Legend)
- Rider accessories: helmet styles, glasses, socks
- Celebration animations: 6 post-win dances/gestures

### 12.5 Seasons Ladder

ELO-style rating tracks competitive performance:
- Season resets to 1000 ELO
- Win: +25–50 (scaled by opponent strength)
- Loss: -10–25
- Ladder divisions: Bronze, Silver, Gold, Crimson, Legend

---

## 13. Audio Direction

See [Sound Design Document](SOUND_DESIGN.md) for full spec.

### 13.1 Music Approach

- Attract mode: mellow indie college-rock instrumental
- Main hub: upbeat lo-fi with cycling rhythms
- Training: chill acoustic / ambient
- Race: driving rock/electronic hybrid with dynamic layers (intensifies at bell lap)
- Results: triumphant fanfare (win) or bittersweet melody (loss)

### 13.2 Key Sound Effects

- The burn: dramatic bike skid + crowd gasp
- Bell lap: iconic bell + crowd eruption
- Exchange: satisfying clunk/click of bike handoff
- Sprint activation: mechanical gear whir
- Crash: crunch + crowd "ooh"
- Drafting: audio whoosh when slingshot triggered
- Level up stat: ascending arpeggio

---

## 14. Monetization

Little Six is free-to-play with no pay-to-win elements.

**Revenue (if any):**
- Cosmetic season passes (purely visual; no stat effect)
- One-time "Supporter Pack" for players who want to back the project
- No ads (degrades mobile experience fatally)
- No loot boxes

**Cost reduction priority over revenue maximization** — the game is first a tribute to a beloved tradition, second a commercial product.
