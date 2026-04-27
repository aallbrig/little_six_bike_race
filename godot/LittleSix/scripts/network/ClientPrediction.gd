extends Node
class_name ClientPrediction

# Client-side prediction system for Little Six multiplayer (Spec 005)
# Predicts player movement locally while waiting for server confirmation

signal prediction_error_detected(error_data: Dictionary)
signal prediction_corrected(correction_data: Dictionary)

const PREDICTION_BUFFER_SIZE = 60  # 1 second at 60 FPS
const MAX_CORRECTION_DISTANCE = 5.0	 # Meters before snapping
const SMOOTHING_FACTOR = 0.1  # How aggressively to correct predictions

var _prediction_buffer: Array[Dictionary] = []
var _last_server_state: Dictionary = {}
var _prediction_enabled: bool = true
var _rider_controller: RiderController = null

func _ready() -> void:
	# Connect to network events
	NetworkMgr.race_synchronized.connect(_on_server_correction)

func set_rider_controller(rider: RiderController) -> void:
	"""Set the rider controller to predict for"""
	_rider_controller = rider

func enable_prediction(enabled: bool) -> void:
	"""Enable or disable client prediction"""
	_prediction_enabled = enabled
	if not enabled:
		_prediction_buffer.clear()

func predict_movement(input_state: Dictionary, delta: float) -> Dictionary:
	"""Generate predicted movement based on current input"""
	if not _prediction_enabled or not _rider_controller:
		return {}

	# Store current state for later correction
	var current_state = {
		"timestamp": Time.get_ticks_msec(),
		"position": _rider_controller.global_position,
		"velocity": _rider_controller.velocity,
		"input": input_state.duplicate()
	}

	_prediction_buffer.append(current_state)

	# Limit buffer size
	if _prediction_buffer.size() > PREDICTION_BUFFER_SIZE:
		_prediction_buffer.remove_at(0)

	# Calculate predicted movement
	var prediction = _calculate_prediction(input_state, delta)

	return prediction

func _calculate_prediction(input_state: Dictionary, delta: float) -> Dictionary:
	"""Calculate predicted position/velocity based on input"""
	if not _rider_controller:
		return {}

	var predicted_velocity = _rider_controller.velocity
	var predicted_position = _rider_controller.global_position

	# Apply input-based acceleration
	if input_state.get("accelerating", false):
		predicted_velocity += _rider_controller.transform.basis.z * _rider_controller.bike_physics.ACCEL * delta
	elif input_state.get("braking", false):
		predicted_velocity -= _rider_controller.transform.basis.z * _rider_controller.bike_physics.BRAKE_DECEL * delta

	# Apply drag
	var speed = predicted_velocity.length()
	if speed > 0:
		var drag_force = _rider_controller.bike_physics.calculate_drag_force(speed)
		var drag_decel = drag_force / _rider_controller.bike_physics.MASS
		predicted_velocity -= predicted_velocity.normalized() * drag_decel * delta

	# Apply rolling resistance
	var rolling_force = _rider_controller.bike_physics.calculate_rolling_force()
	var rolling_decel = rolling_force / _rider_controller.bike_physics.MASS
	predicted_velocity -= predicted_velocity.normalized() * rolling_decel * delta

	# Update position
	predicted_position += predicted_velocity * delta

	return {
		"position": predicted_position,
		"velocity": predicted_velocity,
		"timestamp": Time.get_ticks_msec()
	}

func _on_server_correction(server_state: Dictionary) -> void:
	"""Handle server correction of client prediction"""
	if not _prediction_enabled or _prediction_buffer.size() == 0:
		return

	_last_server_state = server_state

	# Find the closest prediction to the server timestamp
	var server_timestamp = server_state.get("timestamp", 0)
	var closest_prediction = _find_closest_prediction(server_timestamp)

	if closest_prediction.size() > 0:
		var error = _calculate_prediction_error(closest_prediction, server_state)
		if error > 0.01:  # Small threshold to avoid jitter
			_apply_correction(error, server_state)
			prediction_error_detected.emit({
				"error": error,
				"server_state": server_state,
				"predicted_state": closest_prediction
			})

func _find_closest_prediction(server_timestamp: int) -> Dictionary:
	"""Find the prediction closest to the server timestamp"""
	var closest = {}
	var smallest_diff = 999999

	for prediction in _prediction_buffer:
		var diff = abs(prediction["timestamp"] - server_timestamp)
		if diff < smallest_diff:
			smallest_diff = diff
			closest = prediction

	return closest

func _calculate_prediction_error(predicted: Dictionary, actual: Dictionary) -> float:
	"""Calculate the error between predicted and actual state"""
	var predicted_pos = predicted.get("position", Vector3.ZERO)
	var actual_pos = Vector3(
		actual.get("position", {}).get("x", 0.0),
		actual.get("position", {}).get("y", 0.0),
		actual.get("position", {}).get("z", 0.0)
	)

	return predicted_pos.distance_to(actual_pos)

func _apply_correction(error: float, server_state: Dictionary) -> void:
	"""Apply server correction to local state"""
	if not _rider_controller:
		return

	var server_pos = Vector3(
		server_state.get("position", {}).get("x", 0.0),
		server_state.get("position", {}).get("y", 0.0),
		server_state.get("position", {}).get("z", 0.0)
	)

	var server_velocity = Vector3(
		server_state.get("velocity", {}).get("x", 0.0),
		server_state.get("velocity", {}).get("y", 0.0),
		server_state.get("velocity", {}).get("z", 0.0)
	)

	if error > MAX_CORRECTION_DISTANCE:
		# Large error - snap to correct position
		_rider_controller.global_position = server_pos
		_rider_controller.velocity = server_velocity
	else:
		# Small error - smoothly interpolate
		_rider_controller.global_position = _rider_controller.global_position.lerp(server_pos, SMOOTHING_FACTOR)
		_rider_controller.velocity = _rider_controller.velocity.lerp(server_velocity, SMOOTHING_FACTOR)

	prediction_corrected.emit({
		"error": error,
		"corrected_position": _rider_controller.global_position,
		"corrected_velocity": _rider_controller.velocity
	})

func get_prediction_buffer_size() -> int:
	"""Get current prediction buffer size (for debugging)"""
	return _prediction_buffer.size()

func clear_prediction_buffer() -> void:
	"""Clear the prediction buffer (e.g., on race start)"""
	_prediction_buffer.clear()

func get_average_prediction_error() -> float:
	"""Get average prediction error over recent corrections"""
	if NetworkMgr.get_prediction_error_count() == 0:
		return 0.0

	# This would need to be implemented in NetworkManager
	# For now, return a placeholder
	return 0.0