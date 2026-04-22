# Little Six

A multiplayer browser-based cycling video game inspired by Indiana University's iconic "Little 500" bike race tradition. Built with Godot 4.6, targeting mobile web browsers, deployed on AWS.

## What Is Little Six?

Little Six puts you in the saddle for the greatest college cycling weekend. Train your rider Tamagotchi-style through a 6-week preseason, compete in qualifying time trials and sprint events, then race 50 laps around the cinder oval against up to 5 other teams in real-time multiplayer.

The game simulates the full spirit of the Little 500: standardized coaster-brake bikes, mandatory rider exchanges, pack drafting, "the burn" sprint maneuver, and the strategic chaos of exchange zone timing.

## Key Features

- **Tamagotchi Training** — Daily training choices with fatigue, over-training risk, and random events
- **Spring Series Events** — Individual Time Trials, Miss-N-Out elimination races, Team Pursuit
- **Real-Time Multiplayer Race** — 50-lap race with rider exchanges, drafting, and sprint mechanics
- **Mobile-First** — Designed for phone browsers; tilt/touch controls; portrait lobby, landscape racing
- **Attract Mode Loop** — Logo → Cinematic → Title Screen → Demo Race → repeat

## Documentation

| Document | Description |
|---|---|
| [Game Design Document](docs/GDD.md) | Full game design: mechanics, systems, flow |
| [Technical Design Document](docs/TDD.md) | Engine architecture, code organization, data models |
| [Art Bible](docs/ART_BIBLE.md) | Visual direction, style guide, asset specs |
| [Network Architecture](docs/NETWORK_ARCHITECTURE.md) | Multiplayer protocol, server design |
| [AWS Deployment](docs/AWS_DEPLOYMENT.md) | Infrastructure, cost model, deployment guide |
| [Sound Design](docs/SOUND_DESIGN.md) | Audio direction and implementation guide |
| [Level Design](docs/LEVEL_DESIGN.md) | Track layout, environment specs |
| [Spec Overview](docs/specs/SPEC_OVERVIEW.md) | Index of all implementation specs |
| [Future Ideas](docs/FUTURE_IDEAS.md) | Parked ideas not in current scope |

## Repository Structure

```
little_six_bike_race/
├── docs/                  # All design and architecture documents
│   └── specs/             # Spec-driven development implementation specs
├── godot/
│   └── LittleSix/         # Godot 4.6 project root
│       ├── assets/        # Audio, fonts, models, textures, UI
│       ├── scenes/        # Godot scene files (.tscn)
│       ├── scripts/       # GDScript files (.gd)
│       │   ├── autoloads/ # Global singletons
│       │   ├── race/      # Race simulation scripts
│       │   ├── training/  # Training system scripts
│       │   ├── ui/        # UI controller scripts
│       │   └── network/   # Networking layer scripts
│       └── addons/        # Third-party Godot plugins
└── infra/                 # AWS infrastructure (Terraform/CDK)
    ├── matchmaking/       # Lambda functions for matchmaking
    └── gameserver/        # EC2/ECS game server configuration
```

## Technology Stack

| Layer | Technology |
|---|---|
| Game Engine | Godot 4.6 |
| Game Client | HTML5/WebAssembly (web export) |
| Game Server | Godot 4.6 headless (Linux) |
| Matchmaking API | Node.js on AWS Lambda |
| Database | AWS DynamoDB |
| Static Hosting | AWS S3 + CloudFront |
| Game Servers | AWS ECS Fargate Spot |
| Networking | WebSocket (WSS) |

## Quick Start (Development)

```bash
# Open the Godot project
# 1. Install Godot 4.6
# 2. Open godot/LittleSix/project.godot

# Start the local dev server (matchmaking)
cd infra/matchmaking
npm install
npm run dev

# Run game server locally
./godot_headless --headless --path godot/LittleSix
```

## Implementation Roadmap

See [Spec Overview](docs/specs/SPEC_OVERVIEW.md) for the full implementation checklist.

**Phase 1 — Core Loop (MVP)**
- Godot project scaffolding
- Attract mode loop
- Training system
- Single-player race (AI opponents)

**Phase 2 — Multiplayer**
- WebSocket networking layer
- Matchmaking service
- Real-time race synchronization
- Rider exchange coordination

**Phase 3 — Season & Persistence**
- Player accounts (anonymous + guest)
- Season progression
- Leaderboards
- AWS deployment

## The Little 500 Tradition

Since 1951, Indiana University has hosted the Little 500 — a 200-lap, 50-mile relay bike race at Bill Armstrong Stadium. Teams of 4 riders race on identical coaster-brake bikes, exchanging at pit spots along the front straight. The event inspired the 1979 Academy Award-winning film *Breaking Away* and is billed as "The World's Greatest College Weekend." Little Six pays digital tribute to that tradition.
