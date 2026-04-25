# Little Six Development Handoff

**Date:** April 24, 2026
**Current Commit:** `f179264`
**Project Status:** Active Development - Core Foundation Complete

## 🎯 **Project Overview**

Little Six is a multiplayer browser-based cycling game inspired by Indiana University's Little 500 tradition. Built with Godot 4.6 for web deployment on AWS, targeting mobile-first gameplay with real-time multiplayer racing.

**Key Features:**
- Tamagotchi-style training system
- Real-time multiplayer racing (50 laps, rider exchanges, drafting)
- Mobile-first design with touch controls
- Attract mode with cinematic sequences
- AWS serverless backend

## ✅ **Completed Work**

### **Core Infrastructure (Spec 001)**
- ✅ Godot 4.6 project structure with Compatibility renderer
- ✅ Autoload system: GameManager, EventBus, SaveManager, AudioManager, NetworkManager, HostBridge, TransitionManager
- ✅ Data classes: PlayerData, RacerData, SeasonData, SettingsData
- ✅ Viewport configuration: 1080×1920 portrait, canvas_items stretch mode

### **Attract Mode (Spec 002)**
- ✅ Logo scene with fade transitions
- ✅ IntroCinematic with 30-second camera animation and 3D track background
- ✅ TitleScreen with pulsing "TAP TO START" and idle timer
- ✅ DemoRace scene with AI racing
- ✅ Iris-wipe transition system
- ✅ Game state machine managing attract loop

### **Mobile UI/UX (Spec 007)**
- ✅ Theme system (LittleSixTheme.tres) with mobile-optimized styles
- ✅ Component library: StatBar, FatigueArc, ActivityCard, PlayerSlot, SprintBar, Minimap
- ✅ Orientation management (portrait/landscape switching with rotate overlay)
- ✅ Touch input system (RaceInputOverlay with zone-based controls)
- ✅ Loading overlay with cycling puns
- ✅ Settings screen with audio, controls, display, account sections
- ✅ ConfirmDialog and ErrorBanner components
- ✅ Safe area handling for iOS notch

### **Marketing Website (Spec 011)**
- ✅ Bootstrap 5 responsive marketing site
- ✅ Game host page with postMessage integration
- ✅ Mobile optimization and asset placeholders
- ✅ Static site structure ready for AWS deployment

### **Development Workflow**
- ✅ Comprehensive shell script system in `scripts/` directory
- ✅ Makefile as primary development interface
- ✅ Portable, IDE-independent workflow
- ✅ Error checking and dependency validation in all scripts

## 🚧 **Current State**

### **Working Features**
- Attract mode loop runs successfully
- Godot project launches without errors
- Website serves correctly
- All development scripts execute properly
- Mobile UI components render correctly

### **Known Limitations**
- UI integration is partial (TrainingDay and HUD updated; Race and other scenes need component library integration)
- Audio system uses placeholders (missing .ogg files)
- AWS infrastructure and networking not implemented
- No GUT tests exist yet (Spec 011 will address this)
- Telemetry logger is implemented but may need configuration integration with SettingsData

## 🎯 **Next Development Priorities**

### **Recently Completed**
- **Spec 003 - Training System**: Full Tamagotchi implementation (activity selection, fatigue, random events, stat progression)
- **Spec 004 - Multiplayer Race**: Core racing mechanics (RaceController, RiderController, physics, AI opponents, lap tracking)
- **Spec 007 UI Components**: Integrated ActivityCard, StatBar, FatigueArc, SprintBar into TrainingDay and HUD scenes
- **EventTelemetryLogger**: Added (see Spec 010) - listens to ALL EventBus signals with rich console output

### **New Epics for Next Agent (Added per user request)**
**Epic 1: Event Telemetry & Observability (Spec 010)**
- Implement comprehensive EventBus signal monitoring
- Create `EventTelemetryLogger.gd` (already added as autoload)
- Configurable logging with filtering and statistics
- Console telemetry for training, racing, input, state changes
- See `docs/specs/spec_010_event_telemetry.md`

**Epic 2: Event-Driven Testing Strategy (Spec 011)**
- Establish GUT-based testing framework focused on events
- Document rubric for "good event-driven tests"
- Create test suites for Training, Race, UI, State Management, and Telemetry
- Ensure all major EventBus signals have dedicated tests
- See `docs/specs/spec_011_event_driven_testing.md` and `docs/testing/README.md`

### **Remaining Immediate Priorities**
1. **Complete Spec 007**: Full integration of components into ALL scenes + settings persistence
2. **Spec 008 - Audio System**: Implement missing music and sound effects
3. **Spec 005 - Networking Layer**: Real-time multiplayer infrastructure
4. **Spec 006 - AWS Infrastructure**: Cloud deployment setup

### **Medium-term Goals**
- Spec 009 - Enhanced Player Progression & Save System
- Spec 012 - Advanced Race Physics & Simulation
- Complete test coverage per Spec 011 (target 50+ event-driven tests)

## 🛠️ **Development Environment**

### **Prerequisites**
- **Godot 4.6** (Compatibility renderer mandatory)
- **Python 3** or **Node.js** (for website server)
- **Docker + Docker Compose** (for LocalStack)
- **AWS SAM CLI** (for deployment)
- **Make** (for running commands)

### **Quick Start**
```bash
# Clone and setup
git clone <repo>
cd little-six-bike-race

# Start development environment
make dev-setup

# Or run individual components
make website     # Marketing site on http://localhost:8000
make editor      # Open Godot editor
make localstack  # AWS simulation
```

### **Key Commands**
```bash
make help        # Show all available commands
make game        # Run the game
make build-site  # Build website
make deploy      # Full AWS deployment
```

## 🏗️ **Architecture Decisions**

### **Tech Stack**
- **Frontend**: Godot 4.6 HTML5 export (WebGL 2.0 Compatibility)
- **Backend**: AWS Lambda + API Gateway + DynamoDB
- **Hosting**: S3 + CloudFront
- **Development**: Shell scripts + Makefile (IDE-independent)

### **Design Principles**
- **Mobile-First**: All UI designed for 375px-430px viewports
- **Event-Driven**: All inter-system communication via EventBus signals
- **Spec-Driven**: Development follows detailed specification documents
- **Web-Native**: Designed for browser deployment from day one

### **Key Constraints**
- Must work on mobile browsers (Safari iOS 15+, Chrome Android 90+)
- WebGL 2.0 compatibility (Compatibility renderer only)
- Touch controls mandatory, mouse optional
- Offline-capable single-player features

## 📋 **Implementation Notes**

### **Godot Project Structure**
```
godot/LittleSix/
├── assets/ui/          # UI assets and themes
├── scenes/             # All game scenes
│   ├── ui/components/  # Reusable UI components
│   ├── logo/          # Attract mode scenes
│   ├── cinematic/
│   ├── title/
│   └── demo/
├── scripts/           # GDScript files
│   ├── autoloads/     # Global singletons
│   └── ui/           # UI controllers
└── project.godot      # Godot configuration
```

### **Web Structure**
```
web/
├── index.html         # Marketing homepage
├── play/index.html    # Game host page
├── assets/           # CSS, JS, images
└── game/             # Godot web export (generated)
```

### **Development Scripts**
```
scripts/              # All development tasks
├── *-website.sh      # Web server management
├── *-godot-*.sh      # Godot operations
├── sam-*.sh          # AWS operations
├── build-site.sh     # Website building
└── deploy.sh         # Full deployment
```

## 🚨 **Known Issues & Considerations**

### **Current Limitations**
- Attract mode is complete but remaining game content is placeholder
- No audio implementation yet
- AWS infrastructure specs exist but not deployed
- Some EventBus signals commented out pending future specs

### **Technical Debt**
- Theme system uses placeholder fonts (Nunito, Press Start 2P need actual files)
- Some UI components reference future data types
- Loading states not fully integrated with actual async operations

### **Browser Compatibility**
- Tested on modern browsers but may need polyfills for older mobile devices
- Orientation API may not work on all browsers (fallback implemented)
- Touch events require careful testing across devices

## 📚 **Documentation Resources**

### **Specifications**
- `docs/specs/SPEC_OVERVIEW.md` - Index of all specs (updated with new epics)
- `docs/specs/spec_001_godot_project_structure.md` - Project foundation
- `docs/specs/spec_002_attract_mode_flow.md` - Current implementation
- `docs/specs/spec_003_training_tamagotchi.md` - Training system (implemented)
- `docs/specs/spec_004_multiplayer_race.md` - Race system (implemented)
- `docs/specs/spec_007_mobile_ui_ux.md` - UI/UX system (partially implemented)
- `docs/specs/spec_010_event_telemetry.md` - **NEW** - EventBus telemetry logger
- `docs/specs/spec_011_event_driven_testing.md` - **NEW** - GUT event-driven testing strategy

### **Testing & Observability**
- `docs/testing/README.md` - Event-driven testing rubric and strategy
- `docs/specs/spec_010_event_telemetry.md` - Telemetry implementation guide

### **Design Documents**
- `docs/GDD.md` - Game Design Document
- `docs/TDD.md` - Technical Design Document
- `docs/ART_BIBLE.md` - Visual design guidelines

### **Development**
- `README.md` - Project overview and setup
- `Makefile` - Development commands
- `scripts/README.md` - Script documentation

## 🎯 **Next Agent Guidance**

### **Immediate Tasks**
1. **Review current state**: Run `make dev-setup` to verify everything works
2. **Study specs**: Read Spec 003 and Spec 004 for next implementation priorities
3. **Test attract mode**: Verify the complete Logo → Cinematic → Title → Demo loop

### **Development Workflow**
- Use `make` commands for all development tasks
- Follow existing code patterns (mobile-first, event-driven)
- Test on actual mobile devices, not just desktop
- Commit regularly with clear messages

### **Quality Standards**
- All UI must work on 375px viewport width
- Touch targets minimum 44px
- No crashes or errors in attract mode
- Follow existing naming and structure conventions

## 📞 **Support & Resources**

### **Getting Help**
- Check `docs/` for detailed specifications
- Review existing code for patterns and conventions
- Test on multiple devices/browsers early

### **Key Contacts**
- Original specifications in `docs/specs/`
- Game design vision in `docs/GDD.md`
- Technical architecture in `docs/TDD.md`

---

**Handoff Complete** ✅

This handoff provides everything needed to continue Little Six development. The foundation is solid, the development environment is established, and the next steps are clearly defined. Good luck with the training system and racing mechanics! 🚴‍♂️