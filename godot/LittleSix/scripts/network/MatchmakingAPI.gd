extends RefCounted
class_name MatchmakingAPI

# Matchmaking API for Little Six (Spec 005)
# Handles lobby creation, joining, and race matchmaking

signal lobby_created(lobby_id: String, lobby_data: Dictionary)
signal lobby_joined(lobby_id: String, lobby_data: Dictionary)
signal lobby_updated(lobby_data: Dictionary)
signal lobby_destroyed(lobby_id: String)
signal player_joined(player_id: String, player_data: Dictionary)
signal player_left(player_id: String)
signal player_ready_changed(player_id: String, ready: bool)
signal race_starting(lobby_id: String, race_config: Dictionary)
signal matchmaking_error(error_type: String, message: String)

var _ws_client: WebSocketClient
var _current_lobby_id: String = ""
var _is_host: bool = false

func _init(ws_client: WebSocketClient) -> void:
	_ws_client = ws_client
	_ws_client.message_received.connect(_on_message_received)

func create_lobby(race_type: String, max_players: int = 8, is_private: bool = false) -> bool:
	"""Create a new lobby for matchmaking"""
	var payload = {
		"race_type": race_type,
		"max_players": max_players,
		"is_private": is_private
	}

	return _ws_client.send_message("create_lobby", payload)

func join_lobby(lobby_id: String) -> bool:
	"""Join an existing lobby"""
	var payload = {
		"lobby_id": lobby_id
	}

	return _ws_client.send_message("join_lobby", payload)

func leave_lobby() -> bool:
	"""Leave the current lobby"""
	if _current_lobby_id == "":
		return false

	var payload = {
		"lobby_id": _current_lobby_id
	}

	var success = _ws_client.send_message("leave_lobby", payload)
	if success:
		_current_lobby_id = ""
		_is_host = false

	return success

func set_player_ready(ready: bool) -> bool:
	"""Set player's ready status"""
	if _current_lobby_id == "":
		return false

	var payload = {
		"lobby_id": _current_lobby_id,
		"ready": ready
	}

	return _ws_client.send_message("set_ready", payload)

func start_race() -> bool:
	"""Start the race (host only)"""
	if _current_lobby_id == "" or not _is_host:
		return false

	var payload = {
		"lobby_id": _current_lobby_id
	}

	return _ws_client.send_message("start_race", payload)

func find_match(race_type: String) -> bool:
	"""Find a match for the specified race type"""
	var payload = {
		"race_type": race_type
	}

	return _ws_client.send_message("find_match", payload)

func cancel_matchmaking() -> bool:
	"""Cancel matchmaking"""
	return _ws_client.send_message("cancel_matchmaking", {})

func _on_message_received(type: String, payload: Dictionary) -> void:
	"""Handle incoming matchmaking messages"""
	match type:
		"lobby_created":
			_on_lobby_created(payload)
		"lobby_joined":
			_on_lobby_joined(payload)
		"lobby_updated":
			lobby_updated.emit(payload)
		"lobby_destroyed":
			_on_lobby_destroyed(payload)
		"player_joined":
			player_joined.emit(payload.get("player_id", ""), payload)
		"player_left":
			player_left.emit(payload.get("player_id", ""))
		"player_ready_changed":
			player_ready_changed.emit(payload.get("player_id", ""), payload.get("ready", false))
		"race_starting":
			race_starting.emit(payload.get("lobby_id", ""), payload.get("race_config", {}))
		"match_found":
			_on_match_found(payload)
		"matchmaking_cancelled":
			print("Matchmaking cancelled")
		"error":
			_on_error(payload)

func _on_lobby_created(payload: Dictionary) -> void:
	_current_lobby_id = payload.get("lobby_id", "")
	_is_host = true
	lobby_created.emit(_current_lobby_id, payload)

func _on_lobby_joined(payload: Dictionary) -> void:
	_current_lobby_id = payload.get("lobby_id", "")
	_is_host = false
	lobby_joined.emit(_current_lobby_id, payload)

func _on_lobby_destroyed(payload: Dictionary) -> void:
	var lobby_id = payload.get("lobby_id", "")
	if lobby_id == _current_lobby_id:
		_current_lobby_id = ""
		_is_host = false
	lobby_destroyed.emit(lobby_id)

func _on_match_found(payload: Dictionary) -> void:
	# Automatically join the found lobby
	var lobby_id = payload.get("lobby_id", "")
	if lobby_id != "":
		join_lobby(lobby_id)

func _on_error(payload: Dictionary) -> void:
	var error_type = payload.get("error_type", "unknown")
	var message = payload.get("message", "Unknown error")
	matchmaking_error.emit(error_type, message)

# Public getters
func get_current_lobby_id() -> String:
	return _current_lobby_id

func is_host() -> bool:
	return _is_host

func is_in_lobby() -> bool:
	return _current_lobby_id != ""