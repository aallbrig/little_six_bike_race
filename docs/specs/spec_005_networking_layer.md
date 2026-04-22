# Spec 005 — Networking Layer

**Depends on:** Spec 004  
**Last Updated:** 2026-04-10  

---

## Overview

Implement the complete multiplayer networking layer: WebSocket client in Godot, matchmaking API integration, lobby system, real-time race synchronization (client-side prediction + server reconciliation), and graceful offline handling.

---

## Requirements

### REQ-005-001: WebSocket Client (Godot)
`scripts/network/WebSocketClient.gd` — low-level WebSocket management.

```gdscript
class_name WebSocketClient
extends RefCounted

signal message_received(type: String, payload: Dictionary)
signal connected()
signal disconnected(reason: String)
signal connection_failed(error: String)

var _ws: WebSocketPeer = null
var _state: WebSocketPeer.State = WebSocketPeer.STATE_CLOSED
var _url: String = ""
var _seq: int = 0

func connect_to(url: String, token: String) -> void:
    _url = url
    _ws = WebSocketPeer.new()
    var headers = ["Authorization: Bearer " + token]
    var err = _ws.connect_to_url(url, TLSOptions.client_unsafe(), headers)
    if err != OK:
        connection_failed.emit("Failed to connect: " + str(err))

func poll() -> void:
    # Called every frame from NetworkManager._process
    if _ws == null: return
    _ws.poll()
    var new_state = _ws.get_ready_state()
    if new_state != _state:
        _state = new_state
        if _state == WebSocketPeer.STATE_OPEN:
            connected.emit()
        elif _state == WebSocketPeer.STATE_CLOSED:
            disconnected.emit("Connection closed")
    while _ws.get_available_packet_count() > 0:
        var raw = _ws.get_packet()
        _parse_packet(raw)

func send(type: String, payload: Dictionary) -> void:
    if _ws == null or _state != WebSocketPeer.STATE_OPEN: return
    _seq += 1
    var msg = {
        "type": type,
        "seq": _seq,
        "ts": Time.get_unix_time_from_system(),
        "payload": payload
    }
    _ws.send_text(JSON.stringify(msg))

func close() -> void:
    if _ws and _state == WebSocketPeer.STATE_OPEN:
        _ws.close(1000, "graceful")

func _parse_packet(raw: PackedByteArray) -> void:
    var text = raw.get_string_from_utf8()
    var result = JSON.parse_string(text)
    if result == null: return
    if not result.has("type"): return
    message_received.emit(result["type"], result.get("payload", {}))
```

### REQ-005-002: Matchmaking Client
`scripts/network/MatchmakingClient.gd` — REST API client for matchmaking.

```gdscript
class_name MatchmakingClient
extends RefCounted

signal match_found(server_url: String, room_id: String, join_token: String, player_count: int)
signal match_error(error: String)
signal save_synced()
signal save_sync_error(error: String)

const BASE_URL := "https://api.littlesix.gg"  # Override in dev via env/config

func find_match(type: String) -> void:
    var url = BASE_URL + "/api/match?type=" + type
    var headers = ["Content-Type: application/json"]
    if _has_auth_token():
        headers.append("Authorization: Bearer " + _get_auth_token())
    
    var request = HTTPRequest.new()
    # Must add to scene tree
    GameManager.add_child(request)
    request.request_completed.connect(_on_match_found.bind(request))
    request.request(url, headers, HTTPClient.METHOD_GET)

func find_private_room(room_code: String) -> void:
    var url = BASE_URL + "/api/match?type=private&room_code=" + room_code
    # ... same pattern

func sync_save(save_json: String) -> void:
    var url = BASE_URL + "/api/player/save"
    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " + _get_auth_token()
    ]
    # POST save_json body

func _on_match_found(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest) -> void:
    request.queue_free()
    if response_code != 200:
        match_error.emit("Server error: " + str(response_code))
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if data == null:
        match_error.emit("Invalid server response")
        return
    match_found.emit(data["server_url"], data["room_id"], data["join_token"], data.get("player_count", 0))
```

### REQ-005-003: NetworkManager — High-Level Integration
`scripts/autoloads/NetworkManager.gd` (from Spec 001) — integrates WebSocketClient and MatchmakingClient.

Full state machine:
```
DISCONNECTED → MATCHMAKING (find_match called)
MATCHMAKING → CONNECTING (match found, connecting WSS)
CONNECTING → CONNECTED (WebSocket open)
CONNECTED → IN_ROOM (JOIN_ACK received)
IN_ROOM → IN_RACE (RACE_START received)
IN_RACE → IN_ROOM (race finished) OR DISCONNECTED (error)
Any state → DISCONNECTED (disconnect)
```

Message routing (incoming):
```gdscript
func _on_ws_message(type: String, payload: Dictionary) -> void:
    EventBus.network_message_received.emit(type, payload)
    match type:
        "JOIN_ACK":
            _local_player_id = payload.get("your_player_id", -1)
            state = ConnectionState.IN_ROOM
            EventBus.player_joined_room.emit(_local_player_id, SaveManager.player_data.display_name)
        "PLAYER_JOINED":
            EventBus.player_joined_room.emit(payload["player_id"], payload["player_name"])
        "PLAYER_LEFT":
            EventBus.player_left_room.emit(payload["player_id"])
        "RACE_START":
            state = ConnectionState.IN_RACE
            EventBus.race_started.emit()
        "RACE_FINISHED":
            state = ConnectionState.IN_ROOM
            # Parse results and emit race_finished
        "HEARTBEAT_ACK":
            ping_ms = int((Time.get_unix_time_from_system() - payload.get("ping_ts", 0.0)) * 1000)
            EventBus.latency_updated.emit(ping_ms)
        "ERROR":
            push_warning("Server error: " + str(payload))
```

### REQ-005-004: Input Synchronization (Client → Server)
`NetworkManager` must send `INPUT_UPDATE` messages at 30Hz during races.

```gdscript
# NetworkManager._process (when IN_RACE)
_input_send_timer -= delta
if _input_send_timer <= 0:
    _input_send_timer = 1.0 / 30.0  # 30 Hz
    ws_client.send("INPUT_UPDATE", {
        "steer": _current_steer,
        "is_braking": _current_is_braking,
        "is_sprinting": _current_is_sprinting,
    })
```

NetworkManager exposes:
```gdscript
func report_input(steer: float, is_braking: bool, is_sprinting: bool) -> void:
    _current_steer = steer
    _current_is_braking = is_braking
    _current_is_sprinting = is_sprinting
```

Called by `RiderController` every frame with current input values.

### REQ-005-005: World State Reconciliation (Server → Client)
On receiving `WORLD_STATE` message (from server at 20Hz):

```gdscript
# In race scene or dedicated RaceNetSync node
func _on_world_state(payload: Dictionary) -> void:
    var server_ts: float = payload["timestamp"]
    for racer_data in payload["racers"]:
        var racer_id = racer_data["id"]
        var server_pos = Vector3(
            racer_data["pos"][0],
            racer_data["pos"][1],
            racer_data["pos"][2]
        )
        var server_speed = racer_data["speed"]
        var server_laps = racer_data["laps"]
        
        if racer_id == NetworkManager.local_player_id:
            # Reconcile local rider
            var local_rider = _get_rider(racer_id)
            var delta_pos = (local_rider.global_position - server_pos).length()
            if delta_pos > RECONCILE_THRESHOLD:  # 0.5m
                # Smoothly correct over 200ms
                local_rider.start_reconcile(server_pos, 0.2)
            # Always accept server lap count
            if server_laps > local_rider.laps_completed:
                local_rider.laps_completed = server_laps
        else:
            # Interpolate remote rider toward server position
            var remote_rider = _get_rider(racer_id)
            if remote_rider:
                remote_rider.add_interpolation_target(server_pos, server_ts)
```

Reconciliation in `RiderController`:
```gdscript
var _reconcile_target: Vector3
var _reconcile_time_remaining: float = 0.0

func start_reconcile(target: Vector3, duration: float) -> void:
    _reconcile_target = target
    _reconcile_time_remaining = duration

func _apply_reconcile(delta: float) -> void:
    if _reconcile_time_remaining <= 0: return
    var t = delta / _reconcile_time_remaining
    global_position = global_position.lerp(_reconcile_target, t)
    _reconcile_time_remaining = max(0.0, _reconcile_time_remaining - delta)
```

### REQ-005-006: Lobby Scene
`scenes/ui/Lobby.tscn` — shows players joining before race starts.

**Elements:**
- Room code display (6-character code, large, copyable)
- Player slots (6): each slot shows "Waiting..." or player name + jersey color swatch
- Racer preview: mini stat bars for each joined player (Speed, Endurance)
- "READY" button → sends PLAYER_READY to server
- Host "START RACE" button (only visible if you created the room) → active when ≥2 players ready
- Auto-start timer: "Race starts in Xs" countdown (when room has ≥2 human players and all are ready, or 30s timeout with AI fill)
- Latency indicator: your connection ping displayed

**Flow:**
1. Matchmaking resolves → Lobby opens with found room
2. `JOIN_ROOM` message sent automatically on WSS connect
3. `JOIN_ACK` received → room code shown, player slot filled
4. `PLAYER_JOINED` events fill remaining slots
5. Player taps "READY" → `PLAYER_READY` sent
6. `RACE_COUNTDOWN` received → countdown overlay (3-2-1)
7. `RACE_START` received → transition to race scene

### REQ-005-007: Room Selection Scene
`scenes/ui/RoomSelect.tscn` — room type chooser before matchmaking.

Options:
1. **Quick Race** — "Find a game now. Empty slots filled with AI." — primary button
2. **Private Room** — "Play with friends. Share a code." — secondary button
   - Sub-flow: "Create Room" → show room code to share; "Join Room" → enter 6-char code
3. **Season Match** — "Ranked. ELO-matched opponents." — secondary button (disabled if no season in progress)

Each option shows estimated wait time (pulled from server or estimated locally):
- Quick Race: "~10s wait"
- Season Match: "~30s wait" (smaller matchmaking pool)

### REQ-005-008: Offline Mode Handling
When `NetworkManager` cannot reach the API or WSS:

```gdscript
func _on_matchmaking_error(error: String) -> void:
    EventBus.disconnected_from_server.emit("offline")
    # GameManager routes to offline race mode

# In GameManager:
func _on_disconnected(reason: String) -> void:
    if reason == "offline":
        # Show "Playing Offline" indicator in hub
        # Race Now → local race with AI only
        # Leaderboard → show "offline" state
```

Offline mode features:
- Training: fully functional (local save)
- Quick Race: replaced with "Local Race" (5 AI opponents, no server required)
- Spring Series: AI only
- Results: still save to local file; sync to server when connection returns

### REQ-005-009: Connection Indicator
In MainHub and during Lobby, show a persistent connection indicator:
- Green dot: online, connected
- Amber dot: reconnecting
- Gray dot with strikethrough: offline mode

Implemented as a small overlay node in MainHub scene; also visible in race scene top-right.

---

## Data Structures

### Lobby Player Slot
```gdscript
class LobbySlot:
    var player_id: int = -1
    var player_name: String = "..."
    var jersey_color: Color = Color.GRAY
    var is_ready: bool = false
    var is_ai: bool = false
    var racer_stats: Dictionary = {}  # Speed, Endurance only shown
```

---

## Signal Interface

### NetworkManager emits via EventBus:
```
connected_to_server()
disconnected_from_server(reason: String)
player_joined_room(player_id, player_name)
player_left_room(player_id)
network_message_received(msg_type, payload)
latency_updated(ms)
```

### Listens to:
```
EventBus.race_started → begin sending INPUT_UPDATE
EventBus.race_finished → stop sending INPUT_UPDATE
EventBus.exchange_executed → send EXCHANGE_REQUEST to server
```

### RiderController listens to:
```
EventBus.network_message_received("WORLD_STATE") → reconcile
```

---

## Acceptance Criteria

- [ ] WebSocketClient connects to WSS server successfully
- [ ] `JOIN_ROOM` sent on WSS open; `JOIN_ACK` received within 5s
- [ ] `PLAYER_JOINED` updates lobby UI in real-time
- [ ] `RACE_COUNTDOWN` shows 3-2-1 overlay
- [ ] `RACE_START` transitions to race scene
- [ ] `INPUT_UPDATE` messages sent at 30Hz during race
- [ ] `WORLD_STATE` received at 20Hz; remote riders interpolate smoothly
- [ ] Local rider reconciliation: position correction < 200ms
- [ ] `HEARTBEAT` / `HEARTBEAT_ACK` cycle: ping_ms calculated correctly
- [ ] Disconnecting mid-race: rider becomes AI-controlled (server-side)
- [ ] API unreachable: offline mode activates, local race available
- [ ] Private room code: create code → share → friend can join with code
- [ ] All 6 player slots visible in lobby; empty slots show "AI" after timeout
- [ ] "START RACE" button only visible for room creator
- [ ] Connection indicator correct color for each state

---

## Implementation Notes

1. **TLS in web export:** Use `TLSOptions.client_unsafe()` for development. For production, use proper TLS. Godot web exports can handle WSS without extra configuration.
2. **Input update buffering:** NetworkManager buffers the latest input values; RiderController calls `report_input()` every frame; NetworkManager sends at 30Hz (not every frame).
3. **Message sequence gaps:** If `seq` is not monotonically increasing (packet arrived out of order), drop older messages silently. Don't reorder — just use the latest.
4. **Reconnection:** If WSS closes unexpectedly during race, attempt reconnect once with 2-second delay. If fails, fall back to AI control.
5. **Server URL config:** The server URL (`BASE_URL`) must be configurable via a project setting or autoloaded config file, not hardcoded. This allows dev/staging/prod pointing.
