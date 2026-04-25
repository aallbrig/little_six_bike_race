# Sprint 3 Planning Document

**Sprint Name:** Polish & Engagement  
**Date:** April 24, 2026  
**Version:** 0.3.0  
**Duration:** 2 weeks  
**Focus:** Transform functional prototype into engaging game experience

## Executive Summary

The current Little Six implementation has solid technical foundations but falls short of delivering an engaging cycling game experience that would satisfy its core audience. While the training system, race mechanics, and mobile UI components work, the game lacks the "game feel," visual polish, audio feedback, and compelling progression that makes cycling games addictive.

**Core Problem:** The software plays like a simulation with good mechanics but lacks the soul, feedback, and engagement that makes games fun.

## Audience Evaluation

### Core Audience
- **Primary:** Indiana University students/alumni familiar with Little 500 tradition
- **Secondary:** Competitive cyclists, mobile racing game enthusiasts, fitness gamers
- **Demographics:** 18-35 years old, mobile-first players, value authenticity and competition

### Current Game Experience Assessment

**✅ What Works:**
- **Mobile Controls:** RaceInputOverlay provides intuitive touch zones (steer left/right, sprint top-right, brake bottom-right)
- **Training Depth:** Tamagotchi-style progression with fatigue management, random events, and stat building feels authentic to cycling training
- **Technical Foundation:** EventBus architecture, telemetry logging, component-based UI, and GUT testing framework are professional-grade
- **Attract Mode:** Logo → Cinematic → Title → Demo loop demonstrates the game's visual identity

**❌ What Doesn't Work (Audience Perspective):**

**1. "Does it play like a game?" - Partially**
- The training system feels like a management sim rather than an engaging cycling experience
- Race mechanics exist but lack the excitement of actual racing (no drafting visualization, limited rider personality)
- Demo race is too passive - audience wants to feel like they're racing

**2. Start Screen & Onboarding - Weak**
- Title screen exists but lacks compelling "Play Now" flow
- No tutorial for training mechanics or race controls
- CreateRacer scene auto-completes without meaningful player investment

**3. Engagement Level - Low**
- Training activities are abstract (clicking cards) rather than interactive cycling experiences
- No meaningful progression feedback or "level up" moments
- Missing dopamine hits from successful sprints, race wins, or training breakthroughs

**4. User Interface Support - Mixed**
- Component library (ActivityCard, StatBar, FatigueArc, SprintBar) is well-designed
- However, the UI doesn't tell a compelling story or create emotional connection
- Settings screen exists but core gameplay UI lacks polish

**5. Camera Work - Basic**
- Race camera follows rider but doesn't do "interesting things"
- No dynamic camera angles during sprints, crashes, or exchanges
- Missing cinematic moments that make cycling races exciting

**6. Controls - Functional but not Intuitive**
- Touch zones make sense technically but players may not discover them naturally
- No visual feedback showing active control zones
- Sprint/brake feel disconnected from actual cycling experience

**7. Graphics & Visuals - Placeholder Level**
- Current graphics are extremely basic (simple 3D models, no textures, basic lighting)
- No rider customization or personality
- Training activities lack visual representation (no animations of cyclists training)

## Observations from Core Audience Perspective

**"This feels like a cycling management game, not a racing game."**
The training system is the strongest part but feels more like Tamagotchi than cycling. The race system has good physics but lacks the visceral thrill of actual bike racing.

**"I don't feel like I'm racing."**
The demo race shows AI opponents but players can't participate meaningfully. The camera is functional but doesn't create excitement or drama.

**"The UI is clean but doesn't excite me."**
Components are well-coded but lack the personality and feedback that makes mobile games addictive. No sound means no satisfying "whoosh" on sprints or crowd cheers on race wins.

**"Controls make sense once you know them."**
Zone-based touch controls are clever but discovery is poor. No visual indicators for control zones during gameplay.

## Brainstorm: How to Make This Better Software

### High-Impact Ideas (Must Do)
1. **Audio Implementation (Spec 008)** - Critical for engagement. Sound effects for pedaling, sprints, crashes, crowd cheers, training feedback
2. **Dynamic Camera System** - Multiple camera modes (chase, cinematic, action) that switch during key moments
3. **Visual Polish Pass** - Better textures, particle effects, rider animations, environmental details
4. **Onboarding & Tutorial System** - Guided first training day and race with visual instruction
5. **Reward & Progression Feedback** - Level-up animations, achievement unlocks, visual stat growth

### Medium-Impact Ideas (Should Do)
6. **Interactive Training Mini-Games** - Instead of clicking cards, make training activities interactive (timing-based pedaling, route selection)
7. **Rider Personality & Customization** - Rider models with different kits, simple customization options
8. **Better HUD Feedback** - Dynamic race information, drafting indicators, energy management visuals
9. **Social Elements** - Simple leaderboards, rival system, shareable training results

### Lower-Priority Ideas (Could Do)
10. **Advanced Physics** - More realistic drafting, cornering, bike handling
11. **Multiplayer Integration** - Real-time races (after networking layer)
12. **Story/Season Mode** - Narrative campaign around Little 500
13. **Accessibility Options** - Alternative control schemes, color blindness support

## Triage & Prioritization

**MVP Sprint 3 Goals (Next 2 Weeks):**
1. **Audio System** (Highest priority - transforms game feel)
2. **Camera System** (Makes racing exciting)
3. **Visual Polish Pass** (Makes game look intentional)
4. **Onboarding Improvements** (Reduces learning curve)
5. **Feedback & Reward Systems** (Increases engagement)

**Technical Debt to Address:**
- Fix remaining GUT path issues for reliable testing
- Complete UI component integration across all scenes (Spec 007)
- Integrate telemetry logger with SettingsData for user control

## New Specifications

### Spec 012: Audio System Implementation
**Status:** Not Started  
**Priority:** Critical  
**Dependencies:** Spec 001, Spec 008 placeholder assets

**Key Requirements:**
- Implement all EventBus audio signals (`music_track_requested`, `sfx_requested`)
- Create audio asset placeholders with realistic cycling sounds
- Add audio settings persistence
- Dynamic music based on game state (training vs racing)
- Spatial audio for race effects

**Success Criteria:** Game has satisfying sound design that enhances rather than distracts from gameplay.

### Spec 013: Dynamic Camera System
**Status:** Not Started  
**Priority:** High  
**Dependencies:** Spec 004 (Race system)

**Key Requirements:**
- Multiple camera modes (chase, cinematic, action cam)
- Automatic camera switching during key moments (sprints, exchanges, crashes)
- Smooth transitions between camera states
- Camera behaviors that tell the racing story
- Mobile-optimized camera controls

**Success Criteria:** Camera work makes races feel dynamic and cinematic rather than static.

### Spec 014: Visual Polish & Feedback Systems
**Status:** Not Started  
**Priority:** High  
**Dependencies:** Spec 007 (UI components)

**Key Requirements:**
- Particle effects for sprints, drafting, crashes
- Improved rider and bike visuals with basic animations
- Enhanced UI feedback (success indicators, combo multipliers)
- Reward animations for training achievements and race wins
- Environmental details that make the track feel alive

**Success Criteria:** Game looks and feels intentional rather than placeholder.

### Spec 015: Onboarding & Player Engagement
**Status:** Not Started  
**Priority:** Medium  
**Dependencies:** Spec 009 (Progression)

**Key Requirements:**
- Interactive tutorial for first training day
- Progressive difficulty in training activities
- Achievement system with visual rewards
- Better progression visualization (season goals, rival comparisons)
- Social proof elements (leaderboards, "beat your friends")

**Success Criteria:** New players understand game quickly and feel motivated to continue playing.

## Sprint Success Metrics

**Technical:**
- All new specs have corresponding test coverage
- No new telemetry spam or performance regressions
- GUT test suite passes 90%+ of test cases

**User Experience:**
- Playtesters rate engagement 7/10 or higher
- Audio enhances rather than distracts from gameplay
- Camera work creates "wow" moments during races
- New players can complete first training day without confusion

**Business:**
- Game feels like a real Little 500 experience
- Core loop (Train → Race → Progress) is compelling
- Visual and audio polish makes game shareable

---

**Next Steps:**
1. Implement Spec 012 (Audio) first - highest impact
2. Follow with Spec 013 (Camera) - transforms racing feel
3. Complete visual polish pass
4. Add onboarding improvements

This sprint focuses on transforming "functional prototype" into "engaging game" while maintaining the strong technical foundation already built.
