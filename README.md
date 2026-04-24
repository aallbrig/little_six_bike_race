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

## Current Status

Little Six is in active development with spec-driven implementation. Core project structure, attract mode, and marketing website are complete and playable.

### Completed Specs
- **Spec 001** — Godot Project Structure: All autoloads, data classes, and core architecture implemented
- **Spec 002** — Attract Mode & Game Flow: Logo, cinematic, title screen, demo race with iris transitions
- **Spec 011** — Static Marketing Website: Bootstrap 5 site with game host, mobile responsive design

### Next Priorities
- Spec 003 — Training System (Tamagotchi mechanics)
- Spec 007 — Mobile UI/UX (touch controls, responsive layouts)
- Spec 004 — Multiplayer Race (core racing mechanics)

## Development

Little Six uses **Make** as the primary interface for development tasks. All commands delegate to shell scripts in the `scripts/` directory for portability and maintainability.

### Quick Start

```bash
# Start development environment
make dev-setup

# Or start components individually
make website      # Start marketing site server
make localstack   # Start local AWS simulation
make matchmaking  # Start matchmaking service
```

### Available Commands

| Command | Description |
|---|---|
| `make help` | Show all available commands |
| `make website` | Start marketing website server (http://localhost:8000) |
| `make game` | Run the Godot game |
| `make editor` | Open Godot editor |
| `make localstack` | Start LocalStack for AWS testing |
| `make matchmaking` | Run matchmaking service locally |
| `make sam-build` | Build SAM application |
| `make sam-api` | Start SAM local API (http://localhost:3000) |
| `make sam-deploy` | Deploy to AWS |
| `make build-site` | Build static website |
| `make export-web` | Export Godot game for web |
| `make deploy` | Full deployment pipeline |
| `make dev-setup` | Start website + LocalStack together |

### Development Workflow

1. **Setup**: Run `make dev-setup` to start all local services
2. **Develop**: Use `make editor` to work on the game, `make website` to preview the site
3. **Test**: Use `make sam-api` for backend testing with LocalStack
4. **Deploy**: Use `make deploy` for full AWS deployment

### Prerequisites

- **Godot 4.6** - For game development
- **Python 3** or **Node.js** - For website server
- **Docker + Docker Compose** - For LocalStack
- **AWS SAM CLI** - For AWS deployment (optional)
- **Make** - For running commands

## Documentation

| Document | Description |
|---|---|
| [Audience & Personas](docs/AUDIENCE.md) | Who we are (and aren't) building for |
| [ADRs](docs/adr/README.md) | Architecture Decision Records |
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

### Prerequisites
- Godot 4.6
- Node.js 20+
- Docker (for LocalStack)

### Using JetBrains IDE Run Configurations (Recommended)
If using Rider or IntelliJ IDEA 2026.1+, open the project and use the pre-configured run configurations:
- **Full Local Dev Stack**: Launches LocalStack, matchmaking server, and web dev server simultaneously
- **Godot Editor**: Opens the Godot project editor
- **Matchmaking Dev**: Runs the Node.js matchmaking server
- **LocalStack**: Starts AWS LocalStack for local DynamoDB/Lambda testing
- **Website Dev Server**: Serves the static marketing site

### Manual Setup
```bash
# Open the Godot project
godot --path godot/LittleSix --editor

# Start LocalStack
docker compose -f infra/localstack/docker-compose.yml up

# Start the matchmaking dev server
cd infra/matchmaking
npm install
npm run dev

# Serve the website (in another terminal)
cd web
python3 -m http.server 8080

# Run game server locally
godot --path godot/LittleSix --headless
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
