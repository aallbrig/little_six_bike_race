extends Node

# NetworkManager — High-Level Integration (Spec 005)

enum ConnectionState {
	DISCONNECTED,
	MATCHMAKING,
	CONNECTING,
	CONNECTED,
	IN_ROOM,
	IN_RACE
}

var state: ConnectionState = ConnectionState.DISCONNECTED
var local_player_id: int = -1
var ws_client: WebSocketClient
var matchmaking_client: MatchmakingClient

# Input sync
var _current_steer: float = 0.0
var _current_is_braking: bool = false
var _current_is_sprinting: bool = false
var _input_send_timer: float = 0.0

func _ready() -> void:
	ws_client = WebSocketClient.new()
	matchmaking_client = MatchmakingClient.new()
	ws_client.message_received.connect(_on_ws_message)
	matchmaking_client.match_found.connect(_on_match_found)
	matchmaking_client.match_error.connect(_on_matchmaking_error)

func _process(delta: float) -> void:
	ws_client.poll()

	if state == ConnectionState.IN_RACE:
		_input_send_timer -= delta
		if _input_send_timer <= 0:
			_input_send_timer = 1.0 / 30.0  # 30 Hz
			ws_client.send("INPUT_UPDATE", {
				"steer": _current_steer,
				"is_braking": _current_is_braking,
				"is_sprinting": _current_is_sprinting,
			})

func find_match(type: String) -> void:
	state = ConnectionState.MATCHMAKING
	matchmaking_client.find_match(type)

func join_private_room(room_code: String) -> void:
	state = ConnectionState.MATCHMAKING
	matchmaking_client.find_private_room(room_code)

func report_input(steer: float, is_braking: bool, is_sprinting: bool) -> void:
	_current_steer = steer
	_current_is_braking = is_braking
	_current_is_sprinting = is_sprinting

func _on_match_found(server_url: String, room_id: String, join_token: String, player_count: int) -> void:
	state = ConnectionState.CONNECTING
	ws_client.connect_to(server_url, join_token)

func _on_matchmaking_error(error: String) -> void:
	state = ConnectionState.DISCONNECTED
	EventBus.disconnected_from_server.emit("matchmaking_failed")

func _on_ws_message(type: String, payload: Dictionary) -> void:
	EventBus.network_message_received.emit(type, payload)
	match type:
		"JOIN_ACK":
			local_player_id = payload.get("your_player_id", -1)
			state = ConnectionState.IN_ROOM
			EventBus.player_joined_room.emit(local_player_id, SaveManager.player_data.display_name)
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
			var ping_ms = int((Time.get_unix_time_from_system() - payload.get("ping_ts", 0.0)) * 1000)
			EventBus.latency_updated.emit(ping_ms)
		"ERROR":
			push_warning("Server error: " + str(payload))
