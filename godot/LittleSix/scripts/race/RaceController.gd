extends Node
class_name RaceController

# Race configuration
@export var total_laps: int = 50
@export var time_cap_sec: int = 0  # 0 = no time cap

# Race state
var race_started: bool = false
var race_finished: bool = false
var race_start_time: float = 0.0
var current_race_time: float = 0.0

# Rider tracking
var riders: Array = []
var rider_laps: Dictionary = {}
var rider_positions: Dictionary = {}
var rider_progress: Dictionary = {}	 # Track progress 0.0-1.0
var rider_prev_progress: Dictionary = {}  # For lap detection
var finish_order: Array = []

# Track zones (from Spec 010)
const TURN_ZONES = [
	[0.22, 0.38],	# Turn 1 (25% - 38% of lap)
	[0.72, 0.88],	# Turn 2 (72% - 88% of lap)
]

# Track reference
@onready var track_path: Path3D = $"../TrackPath"

# Bell lap
const BELL_LAP = 49	 # Lap 49 out of 50
var bell_lap_triggered: bool = false

# Crowd audio
var _crowd_player: AudioStreamPlayer
var _crowd_target_volume: float = -6.0

func _ready() -> void:
	EventBus.race_started.connect(_on_race_started)
	EventBus.lap_completed.connect(_on_lap_completed)
	EventBus.network_message_received.connect(_on_network_message)

	# Crowd audio setup
	_crowd_player = AudioStreamPlayer.new()
	_crowd_player.bus = "Crowd"
	_crowd_player.stream = load("res://assets/audio/sfx/crowd_idle.wav")
	add_child(_crowd_player)
	_crowd_player.play()

	EventBus.bell_lap_triggered.connect(_on_bell_lap)
	EventBus.racer_position_changed.connect(_on_position_change)
	EventBus.race_finished.connect(_on_race_finish)

	# Validate track path exists
	if not track_path:
		push_error("RaceController: TrackPath not found!")
		return

func _process(delta: float) -> void:
	if race_started and not race_finished:
		current_race_time += delta

		# Update rider progress and positions (every 0.5 seconds as per Spec 010)
		if fmod(current_race_time, 0.5) < delta:
			_update_all_rider_progress()
			update_race_positions()

		# Check time cap
		if time_cap_sec > 0 and current_race_time >= time_cap_sec:
			_finish_race_early()

	# Smoothly move crowd volume toward target
	_crowd_player.volume_db = move_toward(
		_crowd_player.volume_db, _crowd_target_volume, 3.0 * delta)

func start_race() -> void:
	race_started = true
	race_start_time = Time.get_ticks_msec() / 1000.0
	current_race_time = 0.0
	EventBus.race_started.emit()

	# Initialize rider tracking
	for rider in riders:
		var racer_id = rider.get_meta("racer_id", 0)
		rider_laps[racer_id] = 0
		rider_positions[racer_id] = 0
		rider_progress[racer_id] = 0.0
		rider_prev_progress[racer_id] = 0.0

	EventBus.race_started.emit()
	print("Race started with ", riders.size(), " riders")

func add_rider(rider: Node3D) -> void:
	riders.append(rider)

func _update_all_rider_progress() -> void:
	"""Update track progress for all riders"""
	for rider in riders:
		update_rider_progress(rider)

func _on_race_started() -> void:
	print("Race controller: Race started!")

func _on_lap_completed(racer_id: int, lap_number: int, _lap_time: float) -> void:
	if not race_started or race_finished:
		return

	rider_laps[racer_id] = lap_number
	rider_positions[racer_id] = lap_number	# Simplified - would calculate by track position

	# Check for bell lap
	if lap_number == BELL_LAP and not bell_lap_triggered:
		_trigger_bell_lap()

	# Check for race finish
	if lap_number >= total_laps:
		_finish_racer(racer_id)

func _trigger_bell_lap() -> void:
	bell_lap_triggered = true

	# Refill all sprint bars
	for rider in riders:
		if rider.has_method("reset_for_new_lap"):
			rider.reset_for_new_lap()

	EventBus.bell_lap_triggered.emit()
	print("Bell lap triggered - all sprint bars refilled!")

func _finish_racer(racer_id: int) -> void:
	if racer_id in finish_order:
		return

	finish_order.append(racer_id)

	if finish_order.size() >= riders.size():
		_finish_race()

func _finish_race() -> void:
	race_finished = true

	# Create race results
	var results = []
	for i in range(finish_order.size()):
		var racer_id = finish_order[i]
		var result = RaceResult.new()
		result.racer_id = racer_id
		result.position = i + 1
		result.total_time = current_race_time
		result.fastest_lap = 45.0 + randf() * 10.0	# Placeholder
		results.append(result)

	EventBus.race_finished.emit(results)
	print("Race finished! Results: ", results)

func _finish_race_early() -> void:
	# Time cap reached - freeze positions
	race_finished = true

	var results = []
	# Sort by current position
	var sorted_riders = riders.duplicate()
	sorted_riders.sort_custom(func(a, b): return rider_positions.get(a.get_meta("racer_id", 0), 0) > rider_positions.get(b.get_meta("racer_id", 0), 0))

	for i in range(sorted_riders.size()):
		var rider = sorted_riders[i]
		var racer_id = rider.get_meta("racer_id", 0)
		var result = RaceResult.new()
		result.racer_id = racer_id
		result.position = i + 1
		result.total_time = time_cap_sec
		result.fastest_lap = 45.0 + randf() * 10.0
		results.append(result)

	EventBus.race_finished.emit(results)
	print("Race finished early due to time cap! Results: ", results)

func get_racer_position(racer_id: int) -> int:
	return rider_positions.get(racer_id, 0)

func get_race_time() -> float:
	return current_race_time

# Track zone detection (Spec 010)
func is_in_turn(progress_ratio: float) -> bool:
	"""Check if a rider is currently in a turn zone"""
	for zone in TURN_ZONES:
		if progress_ratio >= zone[0] and progress_ratio <= zone[1]:
			return true
	return false

# Rider progress tracking (Spec 010)
func update_rider_progress(rider: Node3D) -> void:
	"""Update a rider's track progress using Path3D projection"""
	if not track_path or not track_path.curve:
		return

	var racer_id = rider.get_meta("racer_id", 0)
	var prev_progress = rider_progress.get(racer_id, 0.0)

	# Project rider position onto track path
	var offset = track_path.curve.get_closest_offset(rider.global_position)
	var total_length = track_path.curve.get_baked_length()
	var current_progress = offset / total_length

	# Store progress
	rider_progress[racer_id] = current_progress
	rider_prev_progress[racer_id] = prev_progress

	# Check for lap completion
	if race_started:
		_check_lap_completion(racer_id, prev_progress, current_progress)

func _check_lap_completion(racer_id: int, prev_progress: float, current_progress: float) -> void:
	"""Detect lap completion using progress crossing (Spec 010)"""
	# Detect crossing the start/finish line (0.0 threshold)
	# Going forward: prev > 0.9 and current < 0.1
	if prev_progress > 0.9 and current_progress < 0.1:
		_complete_lap(racer_id)
	# Going backwards (crash recovery) - do not count
	elif prev_progress < 0.1 and current_progress > 0.9:
		pass  # Ignore backward crossing

func _complete_lap(racer_id: int) -> void:
	"""Handle lap completion for a rider"""
	var current_lap = rider_laps.get(racer_id, 0) + 1
	rider_laps[racer_id] = current_lap

	# Calculate lap time (simplified)
	var lap_time = 45.0 + randf() * 10.0  # Placeholder timing

	EventBus.lap_completed.emit(racer_id, current_lap, lap_time)

	# Reset sprint energy for new lap
	var rider = _get_rider_by_id(racer_id)
	if rider and rider.has_method("reset_for_new_lap"):
		rider.reset_for_new_lap()

func _get_rider_by_id(racer_id: int) -> Node3D:
	"""Find rider node by racer ID"""
	for rider in riders:
		if rider.get_meta("racer_id", -1) == racer_id:
			return rider
	return null

func update_race_positions() -> void:
	"""Update race positions based on laps + track progress (Spec 010)"""
	if riders.size() == 0:
		return

	# Sort by: laps_completed DESC, track_progress DESC
	var sorted_riders = riders.duplicate()
	sorted_riders.sort_custom(func(a, b):
		var a_id = a.get_meta("racer_id", 0)
		var b_id = b.get_meta("racer_id", 0)

		var a_laps = rider_laps.get(a_id, 0)
		var b_laps = rider_laps.get(b_id, 0)

		if a_laps != b_laps:
			return a_laps > b_laps

		var a_progress = rider_progress.get(a_id, 0.0)
		var b_progress = rider_progress.get(b_id, 0.0)
		return a_progress > b_progress
	)

	# Update positions
	for i in range(sorted_riders.size()):
		var rider = sorted_riders[i]
		var racer_id = rider.get_meta("racer_id", 0)
		var new_position = i + 1

		if rider_positions.get(racer_id, -1) != new_position:
			rider_positions[racer_id] = new_position
			EventBus.racer_position_changed.emit(racer_id, new_position)

func _on_bell_lap() -> void:
	_crowd_target_volume = 6.0  # Crowd LOUD on bell lap

func _on_position_change(racer_id: int, new_pos: int) -> void:
	if racer_id == NetworkMgr.local_player_id:
		if new_pos == 1:
			AudioManager.play_sfx("crowd_cheer")
			_crowd_target_volume = 0.0
		elif new_pos > 3:
			_crowd_target_volume = -9.0

func _on_race_finish(_results) -> void:
	AudioManager.play_sfx("crowd_eruption")
	_crowd_target_volume = -3.0

func _on_network_message(type: String, payload: Dictionary) -> void:
	if type == "WORLD_STATE":
		_on_world_state(payload)