extends Node
class_name NetworkManagerSingleton

# High-level network coordinator for Little Six (Spec 005)
# Manages WebSocket connection, matchmaking, and game state sync

signal connection_established()
signal connection_lost(reason: String)
signal lobby_state_changed(lobby_data: Dictionary)
signal race_synchronized(race_state: Dictionary)
signal network_error(error_type: String, message: String)

enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	IN_LOBBY,
	IN_RACE
}

var _connection_state: ConnectionState = ConnectionState.DISCONNECTED
var _ws_client: WebSocketClient
var _matchmaking_api: MatchmakingAPI
var _server_url: String = "wss://api.littlesix.com/ws"  # Placeholder
var _auth_token: String = ""

# Race synchronization
var _client_prediction_enabled: bool = true
var _last_server_update: Dictionary = {}
var _prediction_errors: Array = []
var _max_prediction_errors: int = 10

func _ready() -> void:
	_initialize_networking()

func _initialize_networking() -> void:
	"""Initialize network components"""
	_ws_client = WebSocketClient.new()
	_matchmaking_api = MatchmakingAPI.new(_ws_client)

	# Connect signals
	_ws_client.connected.connect(_on_connected)
	_ws_client.disconnected.connect(_on_disconnected)
	_ws_client.connection_failed.connect(_on_connection_failed)
	_ws_client.message_received.connect(_on_message_received)

	_matchmaking_api.lobby_created.connect(_on_lobby_created)
	_matchmaking_api.lobby_joined.connect(_on_lobby_joined)
	_matchmaking_api.lobby_updated.connect(_on_lobby_updated)
	_matchmaking_api.lobby_destroyed.connect(_on_lobby_destroyed)
	_matchmaking_api.player_joined.connect(_on_player_joined)
	_matchmaking_api.player_left.connect(_on_player_left)
	_matchmaking_api.player_ready_changed.connect(_on_player_ready_changed)
	_matchmaking_api.race_starting.connect(_on_race_starting)
	_matchmaking_api.matchmaking_error.connect(_on_matchmaking_error)

func _process(delta: float) -> void:
	"""Poll network state every frame"""
	if _ws_client:
		_ws_client.poll()

func connect_to_server(server_url: String = "", auth_token: String = "") -> bool:
	"""Connect to the game server"""
	if server_url != "":
		_server_url = server_url
	if auth_token != "":
		_auth_token = auth_token

	if _connection_state != ConnectionState.DISCONNECTED:
		push_warning("NetworkManager: Already connected or connecting")
		return false

	_connection_state = ConnectionState.CONNECTING
	_ws_client.connect_to(_server_url, _auth_token)
	return true

func disconnect_from_server() -> void:
	"""Disconnect from the server"""
	_ws_client.disconnect_from_server()
	_connection_state = ConnectionState.DISCONNECTED

# Matchmaking API passthrough
func create_lobby(race_type: String, max_players: int = 8, is_private: bool = false) -> bool:
	return _matchmaking_api.create_lobby(race_type, max_players, is_private)

func join_lobby(lobby_id: String) -> bool:
	return _matchmaking_api.join_lobby(lobby_id)

func leave_lobby() -> bool:
	return _matchmaking_api.leave_lobby()

func set_player_ready(ready: bool) -> bool:
	return _matchmaking_api.set_player_ready(ready)

func start_race() -> bool:
	return _matchmaking_api.start_race()

func find_match(race_type: String) -> bool:
	return _matchmaking_api.find_match(race_type)

func cancel_matchmaking() -> bool:
	return _matchmaking_api.cancel_matchmaking()

# Race synchronization
func send_race_update(update_data: Dictionary) -> bool:
	"""Send race state update to server"""
	if _connection_state != ConnectionState.IN_RACE:
		return false

	var payload = {
		"timestamp": Time.get_ticks_msec(),
		"update": update_data
	}

	return _ws_client.send_message("race_update", payload)

func send_rider_position(racer_id: int, position: Vector3, velocity: Vector3) -> bool:
	"""Send rider position update for synchronization"""
	var update_data = {
		"racer_id": racer_id,
		"position": {"x": position.x, "y": position.y, "z": position.z},
		"velocity": {"x": velocity.x, "y": velocity.y, "z": velocity.z},
		"timestamp": Time.get_ticks_msec()
	}

	return send_race_update(update_data)

func apply_server_correction(server_state: Dictionary) -> void:
	"""Apply server reconciliation to correct client prediction errors"""
	if not _client_prediction_enabled:
		return

	_last_server_update = server_state

	# Calculate prediction error (simplified)
	# In a full implementation, this would compare predicted vs actual state
	_prediction_errors.append(server_state)

	# Limit error history
	if _prediction_errors.size() > _max_prediction_errors:
		_prediction_errors.remove_at(0)

	# Apply corrections to local game state
	_apply_state_correction(server_state)

func _apply_state_correction(server_state: Dictionary) -> void:
	"""Apply server state corrections to local game objects"""
	# This would update rider positions, velocities, etc.
	# For now, just emit the synchronized state
	race_synchronized.emit(server_state)

func get_prediction_error_count() -> int:
	"""Get number of recent prediction errors (for debugging)"""
	return _prediction_errors.size()

func enable_client_prediction(enabled: bool) -> void:
	"""Enable or disable client-side prediction"""
	_client_prediction_enabled = enabled

# Message handlers
func _on_message_received(type: String, payload: Dictionary) -> void:
	"""Handle incoming network messages"""
	match type:
		"race_state_update":
			apply_server_correction(payload)
		"ping":
			# Respond to ping with pong
			_ws_client.send_message("pong", {})
		"server_info":
			_on_server_info(payload)

func _on_connected() -> void:
	_connection_state = ConnectionState.CONNECTED
	connection_established.emit()
	print("NetworkManager: Connected to server")

func _on_disconnected(reason: String) -> void:
	_connection_state = ConnectionState.DISCONNECTED
	connection_lost.emit(reason)
	print("NetworkManager: Disconnected - ", reason)

func _on_connection_failed(error: String) -> void:
	_connection_state = ConnectionState.DISCONNECTED
	network_error.emit("connection_failed", error)
	print("NetworkManager: Connection failed - ", error)

func _on_server_info(payload: Dictionary) -> void:
	"""Handle server information message"""
	var server_version = payload.get("version", "unknown")
	var features = payload.get("features", [])
	print("NetworkManager: Connected to server v", server_version, " with features: ", features)

# Matchmaking event handlers
func _on_lobby_created(lobby_id: String, lobby_data: Dictionary) -> void:
	_connection_state = ConnectionState.IN_LOBBY
	lobby_state_changed.emit(lobby_data)

func _on_lobby_joined(lobby_id: String, lobby_data: Dictionary) -> void:
	_connection_state = ConnectionState.IN_LOBBY
	lobby_state_changed.emit(lobby_data)

func _on_lobby_updated(lobby_data: Dictionary) -> void:
	lobby_state_changed.emit(lobby_data)

func _on_lobby_destroyed(lobby_id: String) -> void:
	if _connection_state == ConnectionState.IN_LOBBY:
		_connection_state = ConnectionState.CONNECTED

func _on_player_joined(player_id: String, player_data: Dictionary) -> void:
	# Update lobby state
	pass

func _on_player_left(player_id: String) -> void:
	# Update lobby state
	pass

func _on_player_ready_changed(player_id: String, ready: bool) -> void:
	# Update lobby state
	pass

func _on_race_starting(lobby_id: String, race_config: Dictionary) -> void:
	_connection_state = ConnectionState.IN_RACE
	print("NetworkManager: Race starting with config: ", race_config)

func _on_matchmaking_error(error_type: String, message: String) -> void:
	network_error.emit(error_type, message)

# Public getters
func get_connection_state() -> ConnectionState:
	return _connection_state

func is_network_connected() -> bool:
	return _connection_state != ConnectionState.DISCONNECTED

func is_in_lobby() -> bool:
	return _connection_state == ConnectionState.IN_LOBBY

func is_in_race() -> bool:
	return _connection_state == ConnectionState.IN_RACE

func get_current_lobby_id() -> String:
	return _matchmaking_api.get_current_lobby_id()

func is_lobby_host() -> bool:
	return _matchmaking_api.is_host()
