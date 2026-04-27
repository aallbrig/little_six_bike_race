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
	var err = _ws.connect_to_url(url, headers)
	if err != OK:
		connection_failed.emit("Failed to connect: " + str(err))

func poll() -> void:
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