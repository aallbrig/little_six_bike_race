# Level Design Document — Little Six

**Version:** 1.0  
**Last Updated:** 2026-04-10  

---

## 1. The Track

### 1.1 Overview

The Little Six track is a symmetrical oval (velodrome-style), inspired by the real quarter-mile cinder track at Bill Armstrong Stadium. The track is the game's only environment; all events take place on or around it.

**Track specifications:**
- **Total length per lap:** ~400 meters (quarter-mile equivalent)
- **Surface:** Cinder (granular, slightly rough — affects physics feel, not mechanics)
- **Shape:** Elongated oval with two gentle turns and two straights
- **Banking:** Slight banking on turns (5°) for visual authenticity; no gameplay effect in Phase 1
- **Width:** 8 meters (allows 3 riders side-by-side)
- **Pit lane:** On inside of front straight, 16m per team slot × 6 teams = 96m of pit area

### 1.2 Track Layout (Top-Down)

```
         ─────────────── BACK STRAIGHT (100m) ───────────────
        /                                                       \
       /  TURN 2                                    TURN 1       \
      (   (40m radius)                          (40m radius)      )
       \                                                         /
        \                                                       /
         ─── FRONT STRAIGHT WITH PIT LANE (100m total) ───────
                              ↑
                       START / FINISH LINE
         
         [PIT1][PIT2][PIT3][PIT4][PIT5][PIT6]   ← 16m each
         [TEAM1][TEAM2][TEAM3][TEAM4][TEAM5][TEAM6]

         Pit assignment order: fastest qualifier → slot 1 (closest to S/F)
```

### 1.3 Key Zones

| Zone | Length | Purpose |
|---|---|---|
| Start/Finish Line | Point | Lap counting trigger; bell lap trigger |
| Exchange Zone (per team) | 16m × 6 | Rider exchange; activates Exchange button |
| Sprint Zone | Front straight | No special effect; visual cue for players to sprint |
| Turn 1 | 40m arc | Corner requiring slight brake; crash risk at max speed |
| Back Straight | 100m | Drafting opportunity; pack forms here |
| Turn 2 | 40m arc | Same as Turn 1 |

### 1.4 Track Physics Properties

- **Straight speed multiplier:** 1.0× (baseline)
- **Corner speed cap:** 85% of current max speed; above 85% on corners = crash probability rises
- **Cinder texture:** No gameplay effect; pure visual (mud/slick would require wet-weather mechanic which is out of scope Phase 1)

---

## 2. Environment

### 2.1 Grandstands

Located on the outside of the back straight and both turns. Not on pit-side (front straight).

- **Structure:** Concrete bleachers, 15 rows high, ~200m wide across back straight
- **Capacity (visual):** ~2,000 crowd billboards
- **Animation:** Simple billboard offset wave on bell lap and race end
- **Density states:** 
  - Attract mode / Demo: Half-full
  - Spring Series events: Quarter-full
  - Main race: Packed (all billboards active)

### 2.2 Infield

The inside of the oval. Visible but inaccessible.

- **Short grass** (well-manicured, IU grounds crew)
- **Scoreboard billboard** (back of infield, shows current leader and lap)
- **Sponsor banners** (fictional college sponsors for flavor)
- **No gameplay elements** inside the oval

### 2.3 Skybox

- **Time of day:** Late afternoon (4:00–6:00 PM)
- **Sun position:** Low in western sky; long shadows toward the east
- **Sky color:** Gradient from warm amber near horizon to deep blue at zenith
- **Clouds:** 4–6 billboard cloud sprites, very slow drift (no weather effect)

### 2.4 Pit Lane Area

The outside edge of the front straight. Teams stand here waiting to exchange.

- **Team markers:** Colored flags/banners at each team's 16m pit spot
- **Waiting riders:** 3D rider models (stationary, idle animation) at each pit; become "active" during exchange
- **Pit zone activation:** Visual pulse (colored ring on ground) when a rider enters the 16m zone

---

## 3. Camera System

### 3.1 Race Camera Modes

**Default — Follow Cam (3rd person)**  
Primary camera for human-controlled rider.

- Position: 3m behind rider, 1.5m above
- FOV: 75° (slight wide-angle for mobile)
- Look-at: 2m ahead of rider in direction of travel
- Smooth follow: position lerps at 8.0 (responsive but not jarring)
- Banking: camera rolls slightly with turns (5° max) for immersion

**Corner Anticipation**  
When entering a corner, the camera pans slightly toward the apex (predictive look-ahead).

**The Burn Camera**  
On burn execution: 0.5s of slow-motion (time_scale 0.3), wide zoom-out, then snap back. Camera shakes briefly.

### 3.2 Cinematic / Demo Camera

Used in attract mode demo and intro cinematic. Follows a pre-defined `Path3D` using `PathFollow3D`.

**Cinematic camera paths:**
1. **Aerial sweep**: Above track, slow counter-clockwise orbit, tilted down 45°
2. **Pit alley**: Low angle, tracking along pit lane as riders wait
3. **Pack chase**: Follows the lead pack at ground level, 10m behind
4. **Hero shot**: Low angle, looking up as rider passes overhead

### 3.3 Minimap Camera

Orthographic top-down camera rendering to a `SubViewport`. Resolution: 256×256px.
- Scale: Shows the full track
- Team dots: Colored circles for each active rider
- Refreshes at 10 FPS (not 60 — saves performance)

---

## 4. Starting Grid

6 teams, positions 1–6. Grid is single-file (track width doesn't support side-by-side starts for all teams).

```
START ORDER:
[6] [5] [4] [3] [2] [1]   ← back to front
                    ↑
             fastest qualifier

Spacing: 1.5m between riders
```

At race start:
- Camera zooms out to show full grid
- 3-2-1 countdown with tick SFX
- "GO!" fires and riders begin

---

## 5. Time-of-Day Lighting

The game uses static (baked) lighting except for the directional sun light. No real-time global illumination.

| Element | Setting |
|---|---|
| Sun angle | 20° above horizon, coming from west |
| Shadow length | Long (late afternoon) |
| Shadow direction | East (away from camera on front straight) |
| Ambient color | Warm fill `#FFB74D` at low intensity |
| Sky contribution | Light blue fill from above |
| Baked lightmap | Applied to grandstands, infield, pit lane walls |

---

## 6. Scene Budget (Performance)

Target: 60 FPS on mid-range 2022 Android (e.g., Pixel 6a).

| Asset | Triangle Count | Notes |
|---|---|---|
| Track mesh | 800 tris | Simple oval, low detail |
| Turn banking mesh | 200 tris | 2 turns |
| Pit lane walls | 400 tris | Simple geometry |
| Grandstands | 600 tris | Low-poly structure |
| Crowd (each billboard) | 2 tris | Quad | Max 200 billboards active |
| Riders (LOD0) | 4,000 tris × 6 | LOD1 at >20m: 800 tris |
| Bikes (LOD0) | 1,500 tris × 6 | LOD1 at >20m: 300 tris |
| Infield (grass) | 100 tris | Flat plane + texture |
| Scoreboard | 50 tris | Billboard plane |
| **Total (max)** | ~35,000 tris | Well within mobile budget |

Draw calls target: < 50 per frame (use MultiMesh for crowd billboards).

---

## 7. Race Scene Load Strategy

The `RaceTrack.tscn` scene is large. Loading strategy:

1. Show loading screen immediately on scene transition
2. Load scene via `ResourceLoader.load_threaded_request`
3. Stream crowd billboards in after initial frame (not blocking)
4. Play `race_normal` music 0.5s after scene appears (before riders are placed)
5. Reveal scene with iris wipe transition when ready
6. Countdown starts only after scene is fully visible
