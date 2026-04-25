extends RefCounted
class_name WebSocketClient

# Low-level WebSocket client for Little Six networking (Spec 005)

signal message_received(type: String, payload: Dictionary)
signal connected()
signal disconnected(reason: String)
signal connection_failed(error: String)

var _ws: WebSocketPeer = null
var _state: WebSocketPeer.State = WebSocketPeer.STATE_CLOSED
var _url: String = ""
var _seq: int = 0
var _last_poll_time: float = 0.0
var _connection_timeout: float = 10.0
var _connect_start_time: float = 0.0

func connect_to(url: String, token: String = "") -> void:
	"""Connect to WebSocket server with optional authentication token"""
	_url = url
	_ws = WebSocketPeer.new()

	var headers = PackedStringArray()
	if token != "":
		headers.append("Authorization: Bearer " + token)

	var err = _ws.connect_to_url(url, TLSOptions.client_unsafe(), headers)
	if err != OK:
		connection_failed.emit("Failed to initiate connection: " + str(err))
		return

	_state = WebSocketPeer.STATE_CONNECTING
	_connect_start_time = Time.get_ticks_msec() / 1000.0
	print("WebSocket: Connecting to ", url)

func disconnect_from_server() -> void:
	"""Disconnect from WebSocket server"""
	if _ws:
		_ws.close()
		_ws = null
	_state = WebSocketPeer.STATE_CLOSED
	print("WebSocket: Disconnected")

func poll() -> void:
	"""Poll WebSocket for new messages and state changes. Call this every frame."""
	if _ws == null:
		return

	_ws.poll()
	var new_state = _ws.get_ready_state()

	# Check for connection timeout
	if new_state == WebSocketPeer.STATE_CONNECTING:
		var elapsed = Time.get_ticks_msec() / 1000.0 - _connect_start_time
		if elapsed > _connection_timeout:
			connection_failed.emit("Connection timeout")
			disconnect_from_server()
			return

	# Handle state changes
	if new_state != _state:
		_state = new_state
		match _state:
			WebSocketPeer.STATE_OPEN:
				connected.emit()
				print("WebSocket: Connected successfully")
			WebSocketPeer.STATE_CLOSED:
				var close_code = _ws.get_close_code()
				var close_reason = _ws.get_close_reason()
				disconnected.emit(close_reason)
				print("WebSocket: Disconnected - Code: ", close_code, ", Reason: ", close_reason)

	# Process incoming messages
	while _ws.get_ready_state() == WebSocketPeer.STATE_OPEN and _ws.get_available_packet_count() > 0:
		var packet = _ws.get_packet()
		var message_text = packet.get_string_from_utf8()

		if _parse_incoming_message(message_text):
			pass  # Message processed successfully
		else:
			push_warning("WebSocket: Failed to parse message: " + message_text)

func send_message(type: String, payload: Dictionary) -> bool:
	"""Send a message to the server. Returns true if sent successfully."""
	if _ws == null or _state != WebSocketPeer.STATE_OPEN:
		return false

	_seq += 1

	var message = {
		"type": type,
		"seq": _seq,
		"timestamp": Time.get_ticks_msec(),
		"payload": payload
	}

	var json_text = JSON.stringify(message)
	var err = _ws.send_text(json_text)

	if err == OK:
		return true
	else:
		push_error("WebSocket: Failed to send message: " + str(err))
		return false

func _parse_incoming_message(json_text: String) -> bool:
	"""Parse incoming JSON message and emit appropriate signals"""
	var json = JSON.new()
	var err = json.parse(json_text)

	if err != OK:
		push_error("WebSocket: Invalid JSON received: " + json_text)
		return false

	var message = json.get_data()
	if not message is Dictionary:
		push_error("WebSocket: Message is not a dictionary: " + json_text)
		return false

	# Validate message structure
	if not message.has("type"):
		push_error("WebSocket: Message missing 'type' field: " + json_text)
		return false

	var type = message["type"]
	var payload = message.get("payload", {})

	# Emit the message received signal
	message_received.emit(type, payload)
	return true

# Public getters
func is_connected() -> bool:
	return _state == WebSocketPeer.STATE_OPEN

func get_connection_state() -> WebSocketPeer.State:
	return _state

func get_sequence_number() -> int:
	return _seq

func get_url() -> String:
	return _url

func get_last_message_time() -> float:
	return _last_poll_time

# Configuration
func set_connection_timeout(timeout_seconds: float) -> void:
	_connection_timeout = timeout_seconds