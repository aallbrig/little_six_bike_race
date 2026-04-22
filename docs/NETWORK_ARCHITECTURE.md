# Network Architecture — Little Six

**Version:** 1.0  
**Status:** Approved for Implementation  
**Last Updated:** 2026-04-10  

---

## 1. Overview

Little Six is a real-time multiplayer game that must work in mobile web browsers. This constrains the transport layer: only **WebSocket (WSS)** and **WebRTC** are available. We use WSS as the primary transport because:

- WebRTC requires signaling infrastructure; WSS is simpler
- WSS works through all common mobile NATs and corporate firewalls
- Godot 4.x has first-class `WebSocketMultiplayerPeer` support
- All modern mobile browsers (Safari iOS 13+, Chrome Android 75+) support WSS

The architecture has three tiers:

```
┌─────────────────────────────────────────────────────────────────┐
│  CLIENT TIER                                                     │
│  Godot Web (WASM) in mobile browser                             │
│  - Game rendering & input                                       │
│  - Client-side prediction                                       │
│  - State reconciliation                                         │
└────────────────────┬────────────────────────────────────────────┘
                     │ WSS (game state) + HTTPS (API)
┌────────────────────▼────────────────────────────────────────────┐
│  SERVER TIER                                                     │
│  Game Server: Godot Linux headless on ECS Fargate Spot          │
│  Matchmaking API: Node.js Lambda functions                      │
│  - Authoritative game simulation                                │
│  - Room management                                              │
│  - Score validation                                             │
└────────────────────┬────────────────────────────────────────────┘
                     │ DynamoDB + ElastiCache
┌────────────────────▼────────────────────────────────────────────┐
│  DATA TIER                                                       │
│  DynamoDB: Player data, sessions, leaderboards                  │
│  ElastiCache (Redis): Active game room state, rate limiting     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Deployment Topology

```
Internet
   │
   ├── CloudFront (CDN)
   │       └── S3 (static game files: index.html, game.wasm, assets)
   │
   ├── API Gateway (HTTPS)
   │       └── Lambda functions
   │               ├── POST /api/auth/guest        → DynamoDB
   │               ├── GET  /api/match?type=...    → Redis + DynamoDB
   │               ├── POST /api/player/save       → DynamoDB
   │               └── GET  /api/leaderboard       → DynamoDB
   │
   └── Application Load Balancer (WSS)
           └── Target Group: ECS Fargate Service
                   └── Task: little-six-server (Godot headless)
                           ├── Instance 1: Room AAAAAA (6 players)
                           ├── Instance 2: Room BBBBBB (3 players + 3 AI)
                           └── ...
```

---

## 3. Server Architecture

### 3.1 Game Server: Godot Headless

The game server is the same Godot codebase exported as a Linux server binary with `--headless` flag. Server-specific scenes are loaded (no rendering).

**Server startup:**
```bash
./little_six_server --headless \
  --room-id AAAAAA \
  --max-players 6 \
  --port 7777
```

**Server exports only:**
- `NetworkManager.gd` (server-mode branch)
- `RaceController.gd` (authoritative simulation)
- `RaceAI.gd` (AI racers for empty slots)
- No rendering nodes, no audio, no UI

**Per-container resources:**
- 1 vCPU, 512MB RAM per room
- AWS Fargate Spot pricing: ~$0.012/vCPU-hour, ~$0.0013/GB-hour
- 20-minute race = ~$0.004/room

### 3.2 Matchmaking API

Node.js Lambda functions handle matchmaking. Stateless. Room state in Redis.

**Lambda: GET /api/match**

```
Request: { type: "quick" | "private" | "season", room_code?: string }

Logic:
  1. Find an open room of requested type in Redis
  2. If none exists, create a new room entry in Redis + DynamoDB
  3. Trigger ECS task creation for new rooms (via ECS SDK)
  4. Return: { server_url, room_id, join_token }

Response: {
  server_url: "wss://game.littlesix.gg/room/AAAAAA",
  room_id: "AAAAAA",
  join_token: "jwt...",
  player_count: 2
}
```

**Lambda: POST /api/rooms/{id}/server-ready**

Called by the game server when it's ready to accept connections.

---

## 4. Message Protocol

### 4.1 Envelope

All messages (client→server and server→client) use JSON over WebSocket text frames:

```json
{
  "type": "MSG_TYPE",
  "seq": 1234,
  "ts": 1713820800.123,
  "payload": {}
}
```

- `seq`: Monotonically increasing sequence number per sender
- `ts`: Sender's local timestamp (seconds since epoch, float)
- Used for latency calculation and ordering

### 4.2 Client → Server Messages

| Type | Payload | Frequency | Description |
|---|---|---|---|
| `JOIN_ROOM` | `{ token, player_name, racer_stats }` | Once | Initial join after WSS connect |
| `INPUT_UPDATE` | `{ steer, is_braking, is_sprinting }` | 30/s | Rider input snapshot |
| `EXCHANGE_REQUEST` | `{ team_id, rider_out, rider_in, is_burn }` | On action | Pit exchange request |
| `PLAYER_READY` | `{}` | Once per race | Player confirmed ready in lobby |
| `HEARTBEAT` | `{ ping_seq }` | 1/s | Keep-alive + latency measurement |
| `LEAVE_ROOM` | `{}` | On exit | Graceful disconnect |

**INPUT_UPDATE payload detail:**
```json
{
  "steer": 0.75,        // -1.0 (left) to 1.0 (right)
  "is_braking": false,
  "is_sprinting": true
}
```

### 4.3 Server → Client Messages

| Type | Payload | Frequency | Description |
|---|---|---|---|
| `JOIN_ACK` | `{ room_state, your_player_id }` | Once | Acknowledge join; send room state |
| `PLAYER_JOINED` | `{ player_id, player_name, slot }` | On join | Another player joined |
| `PLAYER_LEFT` | `{ player_id, reason }` | On leave | Player disconnected |
| `RACE_COUNTDOWN` | `{ seconds }` | 3 times | 3-2-1 countdown |
| `RACE_START` | `{ start_positions, racer_data[] }` | Once | Race begins |
| `WORLD_STATE` | `{ racers[], timestamp }` | 20/s | Authoritative positions |
| `LAP_COMPLETE` | `{ racer_id, lap, lap_time, positions[] }` | Per lap | Lap milestone |
| `EXCHANGE_ACK` | `{ team_id, rider_in, is_burn, time_bonus }` | On exchange | Exchange confirmed |
| `BELL_LAP` | `{}` | Once | Lap 49 crossed by leader |
| `RACE_FINISHED` | `{ results[] }` | Once | Race over, final results |
| `HEARTBEAT_ACK` | `{ ping_seq, server_ts }` | 1/s | Response to heartbeat |
| `ERROR` | `{ code, message }` | On error | Server error |

**WORLD_STATE payload detail:**
```json
{
  "timestamp": 1713820800.123,
  "racers": [
    {
      "id": 1,
      "pos": [12.3, 0.0, -5.7],
      "rot_y": 1.57,
      "speed": 8.2,
      "laps": 12,
      "race_fatigue": 35,
      "sprint_energy": 78,
      "is_active": true
    }
  ]
}
```

### 4.4 Error Codes

| Code | Meaning |
|---|---|
| 1001 | Invalid join token |
| 1002 | Room full |
| 1003 | Room not found |
| 1004 | Race already in progress |
| 2001 | Invalid exchange (not in pit zone) |
| 2002 | Invalid exchange (minimum exchanges met) |
| 3001 | Server internal error |

---

## 5. Client-Side Prediction & Reconciliation

### 5.1 Prediction Loop

```
Frame N:
  1. Apply local input to local rider (immediate response)
  2. Render frame
  3. Send INPUT_UPDATE to server

Server (50ms later):
  4. Server processes input, simulates, sends WORLD_STATE

Frame N+3 (after WORLD_STATE arrives):
  5. Compare server position vs predicted position
  6. If delta > RECONCILE_THRESHOLD (0.5m):
     → Interpolate toward server position over 200ms
  7. Else: accept local prediction
```

### 5.2 Remote Rider Interpolation

Remote riders (not locally controlled) use interpolation:
- Buffer last 3 WORLD_STATE packets
- Render at `now - 100ms` using linear interpolation between buffered states
- Smooth despite network jitter

### 5.3 Latency Measurement

Client sends `HEARTBEAT` every second. Server responds with `HEARTBEAT_ACK` including server timestamp. Client calculates:

```
ping = (local_receive_ts - local_send_ts) * 1000  // ms
clock_offset = server_ts - (local_send_ts + ping/2)
```

Displayed as latency indicator in lobby and top-right during race.

---

## 6. Room Lifecycle

```
WAITING     → READY  (all players confirmed ready, or 15s timeout auto-fills with AI)
READY       → COUNTING (server starts 3-2-1 countdown)
COUNTING    → RACING (race begins)
RACING      → FINISHED (all 50 laps completed)
FINISHED    → CLEANUP (results sent, room destroyed after 30s)

If any state times out:
WAITING     → CLEANUP if no players join within 60s
RACING      → CLEANUP if all human players disconnect
```

### 6.1 Room State (Redis key: `room:{id}`)

```json
{
  "room_id": "AAAAAA",
  "type": "quick",
  "state": "WAITING",
  "server_url": "wss://game.littlesix.gg/room/AAAAAA",
  "created_at": 1713820800,
  "max_players": 6,
  "players": [
    { "player_id": "p1", "slot": 0, "state": "CONNECTED" },
    { "player_id": "p2", "slot": 1, "state": "READY" }
  ],
  "expires_at": 1713827400
}
```

---

## 7. AI Racer Handling

When a room has fewer than 6 human players, AI racers fill empty slots. AI runs server-side only.

- AI racer states are included in every `WORLD_STATE` broadcast (clients render them normally)
- If a human player disconnects mid-race, their racer becomes AI-controlled (server-side)
- AI decision loop runs at game server tick rate (20Hz)
- AI does NOT send `INPUT_UPDATE` messages (it's internal to server)

---

## 8. Security

### 8.1 Join Token

- JWT, signed with server secret
- Payload: `{ player_id, room_id, exp (5 min) }`
- Server validates on `JOIN_ROOM`
- Prevents joining a room without going through matchmaking

### 8.2 Input Validation (Server-Side)

All client inputs validated on server:
- `steer`: clamp to [-1.0, 1.0]
- `is_braking`, `is_sprinting`: boolean only
- `EXCHANGE_REQUEST`: verify player is in pit zone (server-side position check)
- Rate limiting: max 60 `INPUT_UPDATE` messages/second per client (drop excess)

### 8.3 Anti-Cheat (Lightweight)

- Server is authoritative: client never submits positions, only inputs
- Server validates that reported lap times are physically possible (min 12s/lap)
- Leaderboard times flagged if > 3σ below average

---

## 9. Scalability

### 9.1 Capacity

| Metric | Value | Notes |
|---|---|---|
| Players per room | 6 | Hard limit |
| Rooms per ECS task | 1 | One container per room |
| Concurrent rooms | Auto-scales | ECS Fargate, 0→N |
| Max concurrent players | ~600 (soft) | 100 rooms × 6; ECS limit |
| Scale-to-zero | Yes | 0 tasks when no active rooms |

### 9.2 Cost Model

**At idle (no players):**
- CloudFront + S3: ~$0.50/month
- DynamoDB: ~$0.25/month (on-demand, minimal reads)
- Lambda: Free tier (~$0/month)
- ECS: $0 (scale to zero)
- **Total: ~$1–2/month**

**At moderate load (50 concurrent players = ~8–9 rooms):**
- ECS Fargate Spot (9 tasks × 1vCPU × $0.012/hr × 730hr): ~$79/month → but races are ~20min so actual uptime much less
- More realistic: 8 rooms/hour × 0.33hr × $0.012 × 730hr/month: ~$23/month
- Plus data transfer, API calls: ~$5/month
- **Total: ~$25–35/month**

**Viral scenario (500 concurrent players = ~83 rooms):**
- ECS: ~$200/month
- Data transfer: ~$30/month
- Lambda: ~$5/month
- **Total: ~$235/month**

CloudFront + S3 scales gracefully regardless of player count (static files).

---

## 10. Offline / Single-Player Mode

When the server is unreachable (offline play), the game falls back gracefully:
- Training system: fully local (no sync until online)
- Quick Race: replaced by "Local Race" with 5 AI opponents (no server)
- Spring Series events: local AI only
- Leaderboards: disabled, show "offline" indicator
- Local save continues to accumulate changes; syncs when online

The `NetworkManager` autoload detects offline state and emits `EventBus.disconnected_from_server` with reason `"offline"`. `GameManager` routes to offline-compatible modes.
