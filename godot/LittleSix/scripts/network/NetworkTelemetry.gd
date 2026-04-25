extends Node
class_name NetworkTelemetry

# Network telemetry and debugging for Little Six (Spec 005)
# Tracks network performance, latency, and debugging information

signal telemetry_updated(telemetry_data: Dictionary)

const MAX_SAMPLES = 100
const TELEMETRY_UPDATE_INTERVAL = 1.0  # Seconds

var _ping_samples: Array[float] = []
var _latency_samples: Array[float] = []
var _packet_loss_samples: Array[int] = []
var _bytes_sent_samples: Array[int] = []
var _bytes_received_samples: Array[int] = []

var _last_ping_time: float = 0.0
var _last_telemetry_update: float = 0.0
var _ping_id: int = 0
var _pending_pings: Dictionary = {}

var _total_bytes_sent: int = 0
var _total_bytes_received: int = 0
var _packets_sent: int = 0
var _packets_received: int = 0

var _ws_client: WebSocketClient
var _network_manager: NetworkManager

func _ready() -> void:
	_network_manager = get_parent() if get_parent() is NetworkManager else null
	if _network_manager:
		_ws_client = _network_manager._ws_client
		_ws_client.message_received.connect(_on_message_received)

	# Start telemetry timer
	var timer = Timer.new()
	timer.wait_time = TELEMETRY_UPDATE_INTERVAL
	timer.timeout.connect(_update_telemetry)
	add_child(timer)
	timer.start()

func _process(delta: float) -> void:
	# Send periodic ping for latency measurement
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_ping_time > 5.0:  # Ping every 5 seconds
		_send_ping()

func _send_ping() -> void:
	"""Send a ping to measure latency"""
	if not _ws_client or not _ws_client.is_ws_connected():
		return

	_ping_id += 1
	_pending_pings[_ping_id] = Time.get_ticks_msec() / 1000.0
	_last_ping_time = Time.get_ticks_msec() / 1000.0

	_ws_client.send_message("ping", {"id": _ping_id})

func _on_message_received(type: String, payload: Dictionary) -> void:
	"""Handle incoming messages for telemetry"""
	if type == "pong":
		_on_pong_received(payload)
	elif type == "ping":
		# Respond to server ping
		_ws_client.send_message("pong", payload)

func _on_pong_received(payload: Dictionary) -> void:
	"""Handle pong response for latency calculation"""
	var ping_id = payload.get("id", 0)
	if _pending_pings.has(ping_id):
		var ping_time = _pending_pings[ping_id]
		var current_time = Time.get_ticks_msec() / 1000.0
		var latency = (current_time - ping_time) * 1000.0  # Convert to ms

		_add_latency_sample(latency)
		_pending_pings.erase(ping_id)

func _add_latency_sample(latency: float) -> void:
	"""Add a latency measurement to the samples"""
	_latency_samples.append(latency)
	if _latency_samples.size() > MAX_SAMPLES:
		_latency_samples.remove_at(0)

func _update_telemetry() -> void:
	"""Update and emit telemetry data"""
	var telemetry = {
		"connection": {
			"state": _network_manager.get_connection_state() if _network_manager else "unknown",
			"is_connected": _network_manager.is_network_connected() if _network_manager else false,
			"url": _ws_client.get_url() if _ws_client else ""
		},
		"latency": {
			"current": _get_current_latency(),
			"average": _get_average_latency(),
			"min": _get_min_latency(),
			"max": _get_max_latency()
		},
		"traffic": {
			"bytes_sent_total": _total_bytes_sent,
			"bytes_received_total": _total_bytes_received,
			"packets_sent": _packets_sent,
			"packets_received": _packets_received,
			"bytes_per_second": _calculate_bytes_per_second()
		},
		"lobby": {
			"in_lobby": _network_manager.is_in_lobby() if _network_manager else false,
			"lobby_id": _network_manager.get_current_lobby_id() if _network_manager else "",
			"is_host": _network_manager.is_lobby_host() if _network_manager else false
		},
		"race": {
			"in_race": _network_manager.is_in_race() if _network_manager else false
		},
		"debug": {
			"pending_pings": _pending_pings.size(),
			"latency_samples": _latency_samples.size()
		}
	}

	telemetry_updated.emit(telemetry)

func _get_current_latency() -> float:
	"""Get the most recent latency measurement"""
	return _latency_samples.back() if _latency_samples.size() > 0 else 0.0

func _get_average_latency() -> float:
	"""Calculate average latency"""
	if _latency_samples.size() == 0:
		return 0.0

	var sum = 0.0
	for latency in _latency_samples:
		sum += latency
	return sum / _latency_samples.size()

func _get_min_latency() -> float:
	"""Get minimum latency"""
	if _latency_samples.size() == 0:
		return 0.0

	var min_latency = _latency_samples[0]
	for latency in _latency_samples:
		min_latency = min(min_latency, latency)
	return min_latency

func _get_max_latency() -> float:
	"""Get maximum latency"""
	if _latency_samples.size() == 0:
		return 0.0

	var max_latency = _latency_samples[0]
	for latency in _latency_samples:
		max_latency = max(max_latency, latency)
	return max_latency

func _calculate_bytes_per_second() -> float:
	"""Calculate current bytes per second (simplified)"""
	# This would need proper tracking of bytes over time intervals
	return 0.0  # Placeholder

func record_bytes_sent(bytes: int) -> void:
	"""Record bytes sent for telemetry"""
	_total_bytes_sent += bytes
	_packets_sent += 1

func record_bytes_received(bytes: int) -> void:
	"""Record bytes received for telemetry"""
	_total_bytes_received += bytes
	_packets_received += 1

func get_telemetry_summary() -> String:
	"""Get a human-readable telemetry summary"""
	var summary = "=== Network Telemetry ===\n"
	summary += "Connection: " + str(_network_manager.get_connection_state()) + "\n"
	summary += "Latency: " + str(snapped(_get_average_latency(), 0.1)) + "ms avg\n"
	summary += "Traffic: " + str(_total_bytes_sent) + " sent, " + str(_total_bytes_received) + " received\n"
	summary += "Packets: " + str(_packets_sent) + " sent, " + str(_packets_received) + " received\n"

	if _network_manager.is_in_lobby():
		summary += "Lobby: " + _network_manager.get_current_lobby_id() + " ("
		summary += "host" if _network_manager.is_lobby_host() else "client"
		summary += ")\n"

	return summary

func reset_telemetry() -> void:
	"""Reset all telemetry data"""
	_ping_samples.clear()
	_latency_samples.clear()
	_packet_loss_samples.clear()
	_bytes_sent_samples.clear()
	_bytes_received_samples.clear()
	_pending_pings.clear()
	_total_bytes_sent = 0
	_total_bytes_received = 0
	_packets_sent = 0
	_packets_received = 0
	_ping_id = 0