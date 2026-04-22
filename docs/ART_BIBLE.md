# Art Bible — Little Six

**Version:** 1.0  
**Status:** Approved for Implementation  
**Last Updated:** 2026-04-10  

---

## 1. Visual Direction

### 1.1 Core Aesthetic

**"Americana Arcade"**

Little Six blends two visual registers:
1. **Warm Midwestern Nostalgia** — The warm, golden-hour palette of an Indiana spring afternoon. Think late afternoon light on brick buildings, cream and crimson banners, cinder dust catching sunlight.
2. **Retro Arcade Energy** — Bold UI, outlined text, score-style numerals, neon accents on dark backgrounds. The game should feel like it belongs in a college arcade from 1990, upgraded with modern rendering.

The combination creates something that feels both timeless and specific to the Little 500 tradition.

### 1.2 Reference Pillars

| Reference | What to Take |
|---|---|
| *Breaking Away* (1979 film) | Color palette, collegiate atmosphere, track aesthetics |
| Mario Kart 8 | Clean readable 3D, bright team colors, cartoon collision effects |
| Stardew Valley | Pixel-style UI elements, warm palette, friendly iconography |
| Sprint (Midway, 1986) | Arcade feel, bold font, top-down racing energy |
| IU campus (real) | Limestone buildings, red brick, cream and crimson branding |

### 1.3 Tone

- **Not** dark, gritty, or hyper-realistic
- **Not** childish or overly cartoonish
- **Is** approachable, energetic, warmly nostalgic
- Characters read as college-age students, not action heroes

---

## 2. Color System

### 2.1 Primary Palette

| Name | Hex | Use |
|---|---|---|
| Crimson | `#B31B1B` | Primary CTA buttons, accents, P1 team color |
| Cream | `#FAF3E0` | Background surfaces, text on dark bg |
| Cinder Tan | `#C4A882` | Track surface, dirt textures |
| Indiana Gold | `#C28B3A` | Secondary accents, award iconography |
| Sky Blue | `#6BA3C5` | Skybox midtones, weather effects |

### 2.2 UI Functional Colors

| Name | Hex | Use |
|---|---|---|
| Amber | `#F59E0B` | Warning states, Sprint bar |
| Forest | `#16A34A` | Success states, Fresh fatigue |
| Charcoal | `#1C1C1E` | Card backgrounds, overlays |
| Near-black | `#0F0F0F` | App background |
| Off-white | `#F5F5F0` | Body text on dark |
| Slate | `#64748B` | Secondary/disabled text |

### 2.3 Team Colors (6 slots)

Each team gets a distinct pair: jersey color + accent color.

| Team | Jersey | Accent | Shape Icon |
|---|---|---|---|
| 1 | Crimson `#B31B1B` | Cream `#FAF3E0` | Circle |
| 2 | Navy `#1E3A5F` | Gold `#F59E0B` | Diamond |
| 3 | Forest `#166534` | White `#FFFFFF` | Triangle |
| 4 | Purple `#581C87` | Lavender `#C4B5FD` | Square |
| 5 | Charcoal `#374151` | Orange `#F97316` | Star |
| 6 | Teal `#0F766E` | Cream `#FAF3E0` | Hexagon |

**Color-blind support:** Every team identifier uses **both** color AND shape. Shape icons appear on the minimap, race position list, and HUD indicators.

---

## 3. Typography

### 3.1 Primary Font: Arcade-Style Display

- Font: **Press Start 2P** (Google Fonts, free for commercial use) or custom pixel font
- Use for: Game title, score displays, lap counters, position badges
- Sizes: 48px (title), 32px (header), 24px (sub-header), 16px (data label)
- Color: Cream on dark; Crimson on cream

### 3.2 Body Font: Clean Sans

- Font: **Nunito** (Google Fonts, rounded, friendly)
- Use for: Menu copy, training descriptions, tooltips, settings
- Sizes: 18px (primary body), 14px (secondary), 12px (caption)
- Weight: Regular (400) for body; SemiBold (600) for labels

### 3.3 HUD Font: Condensed

- Font: **Barlow Condensed** (numbers especially)
- Use for: Speed numerals, timer, position numbers, mini lap clock
- Condensed format saves space on mobile HUD

### 3.4 Font Scaling

Text scale setting (S/M/L) multiplies all font sizes:
- S: 0.85×
- M: 1.0× (default)
- L: 1.2×

---

## 4. 3D Art Style

### 4.1 Character Style

- **Poly budget:** Medium-low. Target 3,000–5,000 tris per rider (LOD0); 800 tris (LOD1 at distance)
- **Proportion:** Slightly stylized proportions (larger head ~1.2× realistic ratio, simplified hands)
- **Detail level:** Readable at thumbnail size. Jersey number and team color must be distinguishable at 50m
- **Face:** Minimal detail (dot eyes, basic nose/mouth). Helmet covers most of face
- **Animation rig:** Simple skeleton — spine, shoulders, arms, legs. No finger rigging

### 4.2 Bike Style

The bike is standardized (46×18, coaster brake). One base mesh; visual skins swap texture only.

- **Poly budget:** 1,500 tris
- **Details to model:** Frame, handlebars, wheels with spokes, coaster hub, flat pedals
- **Wheels:** Spinning wheel texture (not actual spoke rotation — cheaper)
- **Skins:** 5 levels (Freshman → Legend) achieved via albedo texture swap + metallic variation

### 4.3 Track & Environment

**Track surface:**
- Cinder material: rough, granular texture in Cinder Tan tones
- Slightly dark in the racing groove (where tires have worn)
- Tire marks texture overlay on straights
- Subtle chalk line at start/finish, exchange zone markings

**Infield:**
- Short grass (green, #4A7C59)
- Simple geometry only (no complex foliage)
- Optional: scoreboard sprite in background

**Grandstands:**
- Stylized concrete structure
- Crowd: Billboard sprites (2D images on 3D planes), randomly tinted per team
- Multiple crowd density presets (empty / half-full / packed)
- Crowd "wave" animation: simple offset-animation across billboards

**Sky:**
- Time: Late afternoon (the race is traditionally late afternoon)
- Sky gradient: Deep blue to warm amber near horizon
- Clouds: Simple billboard sprites, very slow drift
- Sun: Directional light, warm yellow-orange color `#FFD085`

### 4.4 Lighting

| Source | Type | Color | Intensity |
|---|---|---|---|
| Sun (primary) | DirectionalLight3D | `#FFD085` | 1.2 |
| Sky fill | Environment ambient | `#87CEEB` | 0.3 |
| Shadow | Directional shadow | — | Soft edges (PCF5) |
| Grandstand ambient | No dynamic lights (baked) | — | — |

**Shadow maps:** 1024px for track objects; grandstands use baked lightmap.  
**Dynamic lights:** None during race (performance). Only used in cinematic scenes.

---

## 5. UI/UX Art Direction

### 5.1 UI Component Language

**Cards:**
- Background: Charcoal `#1C1C1E`
- Border: 1px solid `#374151`
- Border-radius: 12px
- Drop shadow: 0 4px 16px `rgba(0,0,0,0.4)`

**Buttons (primary):**
- Background: Crimson `#B31B1B`
- Text: Cream `#FAF3E0`, Press Start 2P
- Height: 56px (mobile touch target)
- Width: Full-width in mobile, auto on desktop
- States: default / hover / pressed (`scale(0.97)` + `brightness(1.2)`) / disabled (30% opacity)

**Buttons (secondary):**
- Background: transparent
- Border: 2px solid Cream
- Text: Cream

**Stat bars:**
- Track: `#374151`, h=12px, rounded
- Fill: Color-coded (green → amber → red based on value)
- Animated: values change with a 0.4s ease-out slide + particle burst on significant increase

**Progress indicators:**
- Sprint bar: Vertical, amber, right side of HUD
- Fatigue indicator: Arc gauge (not bar), color-shifts green→red
- Lap counter: Large press-start numerals top-left

### 5.2 Iconography

All icons are SVG, exported to PNG at @1x, @2x, @3x.

| Icon | Meaning | Notes |
|---|---|---|
| Lightning bolt | Sprint / Speed stat | Filled = active, outline = inactive |
| Heart | Recovery stat | Pulse animation when value improves |
| Bicycle wheel | Handling stat | Spokes visible |
| Fire | Hot form / The Burn | Animated in attract mode |
| Zzz | Fatigue high | Animated |
| Bandage | Injured | Red cross on white |
| Trophy | Race win / ranking | Gold/silver/bronze |
| Clock | Time trial | Stopwatch style |
| Team shield | Team identity | Each team's shape integrated |

### 5.3 Transition Effects

| Transition | Style | Duration |
|---|---|---|
| Scene change | Iris wipe (circular, camera shutter) | 0.3s |
| Training result reveal | Stats slide up from bottom with stagger | 0.5s total |
| Race position change | Number badge slides to new position | 0.2s |
| Lap complete | Quick screen edge flash (team color) | 0.15s |
| Burn execution | White flash + screen shake | 0.1s |
| Bell lap | Full screen tint + crowd VFX | 0.3s |
| Result screen | Confetti particle drop from top | 1.0s |

### 5.4 Screen Orientation Handling

**Portrait (all non-race screens):**
- Max content width: 390px (iPhone 14 width)
- Content centered, side padding: 16px
- Bottom safe area respected (iOS home indicator)

**Landscape (race screen):**
- Full-width 3D view
- HUD elements in corner zones (corners are thumb-reachable on most phones)
- Safe area margins respected on all edges

---

## 6. Attract Mode Cinematic — Art Direction

### 6.1 Shot Breakdown

The cinematic is 30 seconds. Can be real-time rendered in Godot using the main race scene assets.

| Shot | Camera | Content | Duration | Audio |
|---|---|---|---|---|
| 1 | Aerial pullback | Oval track at golden hour, empty | 2s | Ambient wind |
| 2 | Ground-level | Closeup of spinning coaster-brake wheel, sunlight refracting through spokes | 2s | Wheel hum |
| 3 | Wide angle | Crowd filling grandstands, banners waving | 3s | Crowd murmur builds |
| 4 | Tracking shot | 4 riders in matching jerseys riding warm-up laps | 3s | Pedaling sounds, crowd grows |
| 5 | Pit zone level | "The burn" — rider sprints to pit, hard-brakes, hands off bike | 5s | Dramatic skid SFX + crowd gasp |
| 6 | Finish line | Lead rider crosses, team floods track, confetti | 3s | Crowd eruption |
| 7 | Crane shot up | Camera tilts to sky; LITTLE SIX title card drops with impact | 4s | Title music sting |
| 8 | Static | Subtitle fades in: "The World's Greatest College Weekend" | 3s | Music resolves |
| 9 | Fade | Fade to black | 2s | — |

### 6.2 Cinematic Implementation

Implemented as a Godot `AnimationPlayer` sequence in `IntroCinematic.tscn`:
- Camera path: `Path3D` with `PathFollow3D` for smooth camera movement
- `AnimationPlayer` controls camera, spot positions, UI overlay timing
- The 3D content is the race scene partially loaded (no game logic active)

---

## 7. Character Design

### 7.1 Racer Archetypes

Four starting backgrounds, each with a default appearance:

| Background | Build | Helmet | Face | Jersey Default |
|---|---|---|---|---|
| Weekend Warrior | Average build | Casual lid helmet | Friendly smile, slight sunburn | Crimson/Cream |
| Ex-Track Star | Athletic, tall | Aero track helmet | Focused, intense | Navy/Gold |
| Distance Rider | Lean, compact | Vented road helmet | Calm, steady gaze | Forest/White |
| Complete Newbie | Varied | Borrowed-looking helmet (sticker on it) | Eager, slightly uncertain | Charcoal/Orange |

### 7.2 Jersey Design

Base jersey shape: short-sleeve cycling jersey, race bib shorts.

**Customizable elements:**
- Jersey body color (preset palette of 20 colors)
- Accent stripe color (preset palette)
- Number on back: player-assigned or auto-assigned
- Socks color: unlockable
- Helmet skins: unlockable

---

## 8. VFX

| Effect | Method | When |
|---|---|---|
| Sprint trail | GPU particles (small, fast-moving dots, team color) | Sprint held |
| Crash impact | GPU particles (grey dust + stars) | On crash |
| The burn skid | Particle strip on ground (smoke/dust) | Burn execution |
| Exchange flash | Screen-space flash + ring effect around exchange zone | Exchange complete |
| Bell lap | Particles from start/finish line | Lap 49 crossing |
| Confetti | GPU particles from top of screen | Race win |
| Crowd wave | Billboard shader animation offset | Bell lap + race end |
| Drafting indicator | Subtle green shimmer around drafting rider | While drafting |

---

## 9. Asset Specifications Summary

| Asset Type | Format | Max Size | Notes |
|---|---|---|---|
| Textures | WebP | 512×512px (1024 for track) | Power-of-2 required |
| Models | GLTF 2.0 | < 5MB per model | No embedded textures |
| Music | OGG Vorbis | < 8MB per track | Streaming |
| SFX | WAV (mono, 22kHz) | < 500KB per file | In-memory |
| Fonts | TTF/OTF | < 500KB | Subset to needed glyphs |
| UI icons | PNG @3x | < 50KB each | Also provide SVG source |
| Cinematic | Real-time (Godot) | — | No pre-rendered video |

---

## 10. Accessibility Checklist

- All text meets WCAG AA contrast ratio (4.5:1 minimum)
- Team identifiers use color + shape (not color alone)
- Animation can be reduced via settings (removes particles, crowd wave)
- Font can be scaled S/M/L
- High-contrast mode: switches to pure black/white for UI backgrounds
- All interactive elements 44×44px minimum touch target
- Critical game states announced via screen-reader-compatible ARIA (where browser allows)
