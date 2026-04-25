extends Node
class_name ServerReconciliation

# Server reconciliation system for Little Six multiplayer (Spec 005)
# Ensures client and server game states stay synchronized

signal reconciliation_applied(correction_data: Dictionary)
signal desync_detected(desync_data: Dictionary)

const RECONCILIATION_BUFFER_SIZE = 30
const MAX_DESYNC_DISTANCE = 10.0  # Meters
const RECONCILIATION_TIMEOUT = 5.0  # Seconds

var _reconciliation_buffer: Array[Dictionary] = []
var _last_reconciliation_time: float = 0.0
var _desync_count: int = 0
var _rider_controllers: Dictionary = {}  # racer_id -> RiderController

func _ready() -> void:
	NetworkMgr.race_synchronized.connect(_on_server_update)

func register_rider(racer_id: int, rider_controller: RiderController) -> void:
	"""Register a rider for reconciliation"""
	_rider_controllers[racer_id] = rider_controller

func unregister_rider(racer_id: int) -> void:
	"""Unregister a rider from reconciliation"""
	_rider_controllers.erase(racer_id)

func _on_server_update(server_state: Dictionary) -> void:
	"""Handle incoming server state update"""
	var timestamp = Time.get_ticks_msec() / 1000.0
	_last_reconciliation_time = timestamp

	# Store server state for reconciliation
	_reconciliation_buffer.append({
		"timestamp": timestamp,
		"server_state": server_state
	})

	# Limit buffer size
	if _reconciliation_buffer.size() > RECONCILIATION_BUFFER_SIZE:
		_reconciliation_buffer.remove_at(0)

	# Apply reconciliation
	_apply_reconciliation(server_state)

func _apply_reconciliation(server_state: Dictionary) -> void:
	"""Apply server state to correct client-side predictions"""
	var corrections_applied = 0

	# Update each rider's state
	for racer_id in server_state.get("riders", {}).keys():
		var rider_state = server_state["riders"][racer_id]
		var rider_controller = _rider_controllers.get(racer_id)

		if rider_controller:
			var correction = _reconcile_rider_state(rider_controller, rider_state)
			if correction["corrected"]:
				corrections_applied += 1

				reconciliation_applied.emit({
					"racer_id": racer_id,
					"correction": correction
				})

	if corrections_applied > 0:
		print("ServerReconciliation: Applied ", corrections_applied, " corrections")

func _reconcile_rider_state(rider: RiderController, server_state: Dictionary) -> Dictionary:
	"""Reconcile a single rider's state with server"""
	var client_pos = rider.global_position
	var server_pos = Vector3(
		server_state.get("position", {}).get("x", 0.0),
		server_state.get("position", {}).get("y", 0.0),
		server_state.get("position", {}).get("z", 0.0)
	)

	var distance = client_pos.distance_to(server_pos)

	if distance > MAX_DESYNC_DISTANCE:
		# Major desync - snap to correct position
		rider.global_position = server_pos
		rider.velocity = Vector3(
			server_state.get("velocity", {}).get("x", 0.0),
			server_state.get("velocity", {}).get("y", 0.0),
			server_state.get("velocity", {}).get("z", 0.0)
		)

		_desync_count += 1
		desync_detected.emit({
			"racer_id": rider.racer_id,
			"distance": distance,
			"client_pos": client_pos,
			"server_pos": server_pos
		})

		return {
			"corrected": true,
			"method": "snap",
			"distance": distance
		}
	elif distance > 0.1:
		# Minor desync - interpolate smoothly
		var smoothing_factor = 0.2
		rider.global_position = client_pos.lerp(server_pos, smoothing_factor)

		return {
			"corrected": true,
			"method": "interpolate",
			"distance": distance
		}

	return {"corrected": false, "distance": distance}

func send_client_state() -> void:
	"""Send current client state to server for reconciliation"""
	if not NetworkMgr.is_in_race():
		return

	var client_state = {
		"timestamp": Time.get_ticks_msec(),
		"riders": {}
	}

	# Collect state from all registered riders
	for racer_id in _rider_controllers:
		var rider = _rider_controllers[racer_id]
		client_state["riders"][racer_id] = {
			"position": {
				"x": rider.global_position.x,
				"y": rider.global_position.y,
				"z": rider.global_position.z
			},
			"velocity": {
				"x": rider.velocity.x,
				"y": rider.velocity.y,
				"z": rider.velocity.z
			},
			"speed": rider.current_speed
		}

	NetworkMgr.send_race_update(client_state)

func check_reconciliation_timeout() -> void:
	"""Check if reconciliation has timed out (server not responding)"""
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last_reconciliation = current_time - _last_reconciliation_time

	if time_since_last_reconciliation > RECONCILIATION_TIMEOUT:
		print("ServerReconciliation: Reconciliation timeout - ", time_since_last_reconciliation, "s since last update")
		# Could emit a timeout signal here

func _process(delta: float) -> void:
	"""Periodic reconciliation checks"""
	check_reconciliation_timeout()

func get_desync_count() -> int:
	"""Get total number of desync corrections applied"""
	return _desync_count

func reset_desync_count() -> void:
	"""Reset the desync counter"""
	_desync_count = 0

func get_reconciliation_health() -> Dictionary:
	"""Get reconciliation system health metrics"""
	var avg_reconciliation_delay = 0.0
	if _reconciliation_buffer.size() > 1:
		var total_delay = 0.0
		for i in range(1, _reconciliation_buffer.size()):
			var delay = _reconciliation_buffer[i]["timestamp"] - _reconciliation_buffer[i-1]["timestamp"]
			total_delay += delay
		avg_reconciliation_delay = total_delay / (_reconciliation_buffer.size() - 1)

	return {
		"buffer_size": _reconciliation_buffer.size(),
		"desync_count": _desync_count,
		"avg_reconciliation_delay": avg_reconciliation_delay,
		"time_since_last_update": Time.get_ticks_msec() / 1000.0 - _last_reconciliation_time
	}