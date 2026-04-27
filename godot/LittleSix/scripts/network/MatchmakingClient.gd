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
	var headers = ["Content-Type: application/json"]
	if _has_auth_token():
		headers.append("Authorization: Bearer " + _get_auth_token())

	var request = HTTPRequest.new()
	GameManager.add_child(request)
	request.request_completed.connect(_on_private_match_found.bind(request))
	request.request(url, headers, HTTPClient.METHOD_GET)

func sync_save(save_json: String) -> void:
	var url = BASE_URL + "/api/player/save"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + _get_auth_token()
	]
	var request = HTTPRequest.new()
	GameManager.add_child(request)
	request.request_completed.connect(_on_save_synced.bind(request))
	request.request(url, headers, HTTPClient.METHOD_POST, save_json)

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

func _on_private_match_found(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest) -> void:
	request.queue_free()
	if response_code != 200:
		match_error.emit("Private room not found or error: " + str(response_code))
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null:
		match_error.emit("Invalid server response")
		return
	match_found.emit(data["server_url"], data["room_id"], data["join_token"], data.get("player_count", 0))

func _on_save_synced(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest) -> void:
	request.queue_free()
	if response_code == 200:
		save_synced.emit()
	else:
		save_sync_error.emit("Save sync failed: " + str(response_code))

func _has_auth_token() -> bool:
	# Placeholder - implement based on auth system
	return false

func _get_auth_token() -> String:
	# Placeholder - implement based on auth system
	return ""