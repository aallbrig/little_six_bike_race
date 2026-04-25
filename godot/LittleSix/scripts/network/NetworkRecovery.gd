extends Node
class_name NetworkRecovery

# Network recovery system for Little Six (Spec 005)
# Handles connection drops, reconnections, and state recovery

signal recovery_started(reason: String)
signal recovery_completed()
signal recovery_failed(reason: String)
signal state_recovered(recovered_state: Dictionary)

enum RecoveryState {
	IDLE,
	RECONNECTING,
	RECOVERING_STATE,
	FAILED
}

var _recovery_state: RecoveryState = RecoveryState.IDLE
var _reconnect_attempts: int = 0
var _max_reconnect_attempts: int = 5
var _reconnect_delay: float = 1.0
var _last_connection_time: float = 0.0
var _recovery_timeout: float = 30.0
var _recovery_start_time: float = 0.0

var _saved_game_state: Dictionary = {}
var _network_manager: NetworkManager

func _ready() -> void:
	_network_manager = get_parent() if get_parent() is NetworkManager else null

	if _network_manager:
		_network_manager.connection_lost.connect(_on_connection_lost)
		_network_manager.connection_established.connect(_on_connection_established)

func _on_connection_lost(reason: String) -> void:
	"""Handle connection loss"""
	print("NetworkRecovery: Connection lost - ", reason)

	if _recovery_state == RecoveryState.IDLE:
		_start_recovery(reason)

func _on_connection_established() -> void:
	"""Handle successful reconnection"""
	print("NetworkRecovery: Reconnected successfully")

	if _recovery_state == RecoveryState.RECONNECTING:
		_recovery_state = RecoveryState.RECOVERING_STATE
		_recovery_start_time = Time.get_ticks_msec() / 1000.0
		recovery_completed.emit()

		# Start state recovery
		_recover_game_state()

func _start_recovery(reason: String) -> void:
	"""Start the recovery process"""
	_recovery_state = RecoveryState.RECONNECTING
	_reconnect_attempts = 0
	_recovery_start_time = Time.get_ticks_msec() / 1000.0

	recovery_started.emit(reason)
	print("NetworkRecovery: Starting recovery process")

	_attempt_reconnection()

func _attempt_reconnection() -> void:
	"""Attempt to reconnect to the server"""
	if _reconnect_attempts >= _max_reconnect_attempts:
		_recovery_failed("Max reconnection attempts exceeded")
		return

	_reconnect_attempts += 1
	print("NetworkRecovery: Reconnection attempt ", _reconnect_attempts, "/", _max_reconnect_attempts)

	# Wait before attempting
	await get_tree().create_timer(_reconnect_delay * _reconnect_attempts).timeout

	if _network_manager and _network_manager.get_connection_state() == NetworkMgr.ConnectionState.DISCONNECTED:
		var success = _network_manager.connect_to_server()
		if not success:
			# Try again with exponential backoff
			_attempt_reconnection()

func _recover_game_state() -> void:
	"""Recover game state after reconnection"""
	print("NetworkRecovery: Recovering game state")

	# Send current local state to server for validation
	if _network_manager:
		var current_state = _get_current_game_state()
		_network_manager.send_race_update({
			"type": "state_recovery",
			"client_state": current_state
		})

	# Set a timeout for recovery
	var recovery_timer = get_tree().create_timer(_recovery_timeout)
	recovery_timer.timeout.connect(func(): _recovery_failed("Recovery timeout"))

func _get_current_game_state() -> Dictionary:
	"""Get the current local game state for recovery"""
	var state = {
		"timestamp": Time.get_ticks_msec(),
		"game_mode": "unknown",
		"player_state": {}
	}

	# Get current scene and extract relevant state
	var current_scene = get_tree().current_scene
	if current_scene:
		if current_scene.name == "RaceTrack":
			state["game_mode"] = "racing"
			# Extract racing state
			var race_controller = current_scene.race_controller if current_scene.has_method("get") and current_scene.get("race_controller") else null
			if race_controller:
				state["race_state"] = {
					"lap": race_controller.rider_laps.get(0, 0),  # Local player
					"position": race_controller.rider_positions.get(0, 0),
					"progress": race_controller.rider_progress.get(0, 0.0)
				}
		elif current_scene.name == "Lobby":
			state["game_mode"] = "lobby"
			state["lobby_id"] = _network_manager.get_current_lobby_id()

	return state

func _on_state_recovery_response(server_state: Dictionary) -> void:
	"""Handle server response to state recovery"""
	print("NetworkRecovery: State recovery response received")

	# Apply any corrections from server
	if server_state.has("corrections"):
		_apply_state_corrections(server_state["corrections"])

	_recovery_state = RecoveryState.IDLE
	state_recovered.emit(server_state)

func _apply_state_corrections(corrections: Dictionary) -> void:
	"""Apply server corrections to local state"""
	# This would update local game objects based on server corrections
	print("NetworkRecovery: Applying state corrections: ", corrections)

func _recovery_failed(reason: String) -> void:
	"""Recovery process failed"""
	_recovery_state = RecoveryState.FAILED
	recovery_failed.emit(reason)
	print("NetworkRecovery: Recovery failed - ", reason)

	# Could show error dialog or return to main menu here

func save_game_state_for_recovery(state: Dictionary) -> void:
	"""Save current game state for potential recovery"""
	_saved_game_state = state.duplicate()
	_saved_game_state["timestamp"] = Time.get_ticks_msec()

func get_saved_game_state() -> Dictionary:
	"""Get the saved game state"""
	return _saved_game_state

func is_recovering() -> bool:
	"""Check if currently in recovery process"""
	return _recovery_state != RecoveryState.IDLE

func get_recovery_progress() -> Dictionary:
	"""Get recovery progress information"""
	return {
		"state": _recovery_state,
		"attempts": _reconnect_attempts,
		"max_attempts": _max_reconnect_attempts,
		"time_elapsed": Time.get_ticks_msec() / 1000.0 - _recovery_start_time
	}

func force_recovery_restart() -> void:
	"""Force restart the recovery process"""
	if _recovery_state != RecoveryState.IDLE:
		_recovery_state = RecoveryState.IDLE
		print("NetworkRecovery: Recovery process restarted")

func _process(delta: float) -> void:
	"""Monitor recovery timeouts"""
	if _recovery_state == RecoveryState.RECOVERING_STATE:
		var elapsed = Time.get_ticks_msec() / 1000.0 - _recovery_start_time
		if elapsed > _recovery_timeout:
			_recovery_failed("State recovery timeout")