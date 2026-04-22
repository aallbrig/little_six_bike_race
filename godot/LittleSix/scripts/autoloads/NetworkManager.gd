## NetworkManager — WebSocket multiplayer peer management.
## Handles connection, matchmaking, message routing, and heartbeat.
extends Node

enum ConnectionState {
	DISCONNECTED,
	MATCHMAKING,
	CONNECTING,
	CONNECTED,
	IN_ROOM,
	IN_RACE,
}

# Server config — override in dev with environment config
const DEFAULT_API_BASE := "https://api.littlesix.gg"
const HEARTBEAT_INTERVAL := 1.0     # seconds
const INPUT_SEND_INTERVAL := 1.0 / 30.0  # 30 Hz

var state: ConnectionState = ConnectionState.DISCONNECTED
var local_player_id: int = -1
var current_room_id: String = ""
var ping_ms: int = 0

var _ws: WebSocketPeer = null
var _ws_state: WebSocketPeer.State = WebSocketPeer.STATE_CLOSED
var _seq: int = 0
var _heartbeat_timer: float = 0.0
var _input_send_timer: float = 0.0
var _last_heartbeat_seq: int = 0
var _last_heartbeat_ts: float = 0.0

# Current race input (set by RiderController)
var _steer: float = 0.0
var _is_braking: bool = false
var _is_sprinting: bool = false

# HTTP client for matchmaking API
var _http: HTTPRequest = null


func _ready() -> void:
	# Don't initialize on headless server
	if DisplayServer.get_name() == "headless":
		return
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_http_response)
	EventBus.race_started.connect(func(): state = ConnectionState.IN_RACE)
	EventBus.race_finished.connect(func(_r): state = ConnectionState.IN_ROOM)


func _process(delta: float) -> void:
	if _ws == null:
		return

	_ws.poll()
	var new_ws_state = _ws.get_ready_state()

	if new_ws_state != _ws_state:
		_ws_state = new_ws_state
		if _ws_state == WebSocketPeer.STATE_OPEN:
			state = ConnectionState.CONNECTED
			EventBus.connected_to_server.emit()
			_send_join_room()
		elif _ws_state == WebSocketPeer.STATE_CLOSED:
			var was_state = state
			state = ConnectionState.DISCONNECTED
			EventBus.disconnected_from_server.emit("connection_closed")
			if was_state == ConnectionState.IN_RACE:
				EventBus.race_abandoned.emit()

	# Read incoming messages
	while _ws.get_available_packet_count() > 0:
		var raw = _ws.get_packet()
		_parse_packet(raw)

	# Heartbeat
	if state == ConnectionState.IN_ROOM or state == ConnectionState.IN_RACE:
		_heartbeat_timer -= delta
		if _heartbeat_timer <= 0:
			_heartbeat_timer = HEARTBEAT_INTERVAL
			_send_heartbeat()

	# Input updates (only during race)
	if state == ConnectionState.IN_RACE:
		_input_send_timer -= delta
		if _input_send_timer <= 0:
			_input_send_timer = INPUT_SEND_INTERVAL
			_send_input_update()


# ── Public API ──────────────────────────────────────────────────────────────

func find_quick_match() -> void:
	if state != ConnectionState.DISCONNECTED:
		push_warning("NetworkManager: already connected or matching")
		return
	state = ConnectionState.MATCHMAKING
	var url = DEFAULT_API_BASE + "/api/match?type=quick"
	var headers = _get_auth_headers()
	_http.request(url, headers, HTTPClient.METHOD_GET)


func find_private_room(room_code: String) -> void:
	if state != ConnectionState.DISCONNECTED:
		return
	state = ConnectionState.MATCHMAKING
	var url = DEFAULT_API_BASE + "/api/match?type=private&room_code=" + room_code
	_http.request(url, _get_auth_headers(), HTTPClient.METHOD_GET)


func create_private_room() -> void:
	if state != ConnectionState.DISCONNECTED:
		return
	state = ConnectionState.MATCHMAKING
	var url = DEFAULT_API_BASE + "/api/match?type=private_create"
	_http.request(url, _get_auth_headers(), HTTPClient.METHOD_GET)


func send_message(msg_type: String, payload: Dictionary) -> void:
	if _ws == null or _ws_state != WebSocketPeer.STATE_OPEN:
		return
	_seq += 1
	var msg = {
		"type": msg_type,
		"seq": _seq,
		"ts": Time.get_unix_time_from_system(),
		"payload": payload,
	}
	_ws.send_text(JSON.stringify(msg))


func report_input(steer: float, is_braking: bool, is_sprinting: bool) -> void:
	_steer = steer
	_is_braking = is_braking
	_is_sprinting = is_sprinting


func disconnect_gracefully() -> void:
	if _ws and _ws_state == WebSocketPeer.STATE_OPEN:
		_ws.close(1000, "graceful")
	state = ConnectionState.DISCONNECTED
	current_room_id = ""


func is_online() -> bool:
	return state != ConnectionState.DISCONNECTED


# ── Private ──────────────────────────────────────────────────────────────────

func _connect_to_server(url: String, token: String) -> void:
	state = ConnectionState.CONNECTING
	_ws = WebSocketPeer.new()
	var headers = PackedStringArray(["Authorization: Bearer " + token])
	var err = _ws.connect_to_url(url, TLSOptions.client_unsafe(), headers)
	if err != OK:
		state = ConnectionState.DISCONNECTED
		EventBus.disconnected_from_server.emit("connect_failed")


func _send_join_room() -> void:
	var racer_stats = {}
	if GameManager.current_player and GameManager.current_player.racer:
		var r = GameManager.current_player.racer
		racer_stats = {
			"speed": r.speed,
			"endurance": r.endurance,
			"jersey_color_id": r.jersey_color_id,
		}
	send_message("JOIN_ROOM", {
		"player_name": GameManager.current_player.display_name if GameManager.current_player else "Rider",
		"racer_stats": racer_stats,
	})


func _send_heartbeat() -> void:
	_last_heartbeat_seq = _seq + 1
	_last_heartbeat_ts = Time.get_unix_time_from_system()
	send_message("HEARTBEAT", {"ping_seq": _last_heartbeat_seq})


func _send_input_update() -> void:
	send_message("INPUT_UPDATE", {
		"steer": _steer,
		"is_braking": _is_braking,
		"is_sprinting": _is_sprinting,
	})


func _parse_packet(raw: PackedByteArray) -> void:
	var text = raw.get_string_from_utf8()
	var result = JSON.parse_string(text)
	if result == null or not result.has("type"):
		return

	var msg_type: String = result["type"]
	var payload: Dictionary = result.get("payload", {})

	# Route common messages
	match msg_type:
		"JOIN_ACK":
			local_player_id = payload.get("your_player_id", -1)
			state = ConnectionState.IN_ROOM
			EventBus.race_room_joined.emit(current_room_id, payload.get("room_state", {}))
		"PLAYER_JOINED":
			EventBus.player_joined_room.emit(payload.get("player_id", -1), payload.get("player_name", "?"))
		"PLAYER_LEFT":
			EventBus.player_left_room.emit(payload.get("player_id", -1))
		"HEARTBEAT_ACK":
			var now = Time.get_unix_time_from_system()
			ping_ms = int((now - _last_heartbeat_ts) * 1000.0)
			EventBus.latency_updated.emit(ping_ms)
		"ERROR":
			push_warning("NetworkManager: server error: " + str(payload))

	# Always forward to EventBus for scene-level listeners
	EventBus.network_message_received.emit(msg_type, payload)


func _on_http_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		state = ConnectionState.DISCONNECTED
		EventBus.disconnected_from_server.emit("offline")
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null:
		state = ConnectionState.DISCONNECTED
		EventBus.disconnected_from_server.emit("invalid_response")
		return

	current_room_id = data.get("room_id", "")
	var server_url = data.get("server_url", "")
	var token = data.get("join_token", "")
	_connect_to_server(server_url, token)


func _get_auth_headers() -> PackedStringArray:
	var token = SaveManager.get_setting("auth_token", "") if SaveManager else ""
	if token != "":
		return PackedStringArray(["Authorization: Bearer " + token, "Content-Type: application/json"])
	return PackedStringArray(["Content-Type: application/json"])
