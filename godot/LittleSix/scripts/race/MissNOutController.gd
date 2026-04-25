extends Node
class_name MissNOutController

# Miss-N-Out Event Controller (Spec 010)
# 8 riders start, last rider eliminated each lap, final 2 compete head-to-head

@export var total_riders: int = 8
@export var is_miss_n_out: bool = false

# Elimination state
var eliminated_riders: Array[int] = []
var last_lap_elimination_checked: Dictionary = {}  # lap -> already checked

# References
@onready var race_controller: RaceController = $"../race_controller"

func _ready() -> void:
	EventBus.lap_completed.connect(_on_lap_completed)

func start_miss_n_out() -> void:
	"""Start a Miss-N-Out race event"""
	is_miss_n_out = true
	eliminated_riders.clear()
	last_lap_elimination_checked.clear()

	race_controller.total_laps = 50  # Standard race length
	race_controller.start_race()

	print("Miss-N-Out started with ", total_riders, " riders")

func _on_lap_completed(racer_id: int, lap_number: int, lap_time: float) -> void:
	"""Check for eliminations after each lap"""
	if not is_miss_n_out:
	    return

	# Only check elimination once per lap
	if last_lap_elimination_checked.get(lap_number, false):
	    return
	last_lap_elimination_checked[lap_number] = true

	# Don't eliminate if 2 or fewer riders remain
	var active_riders = race_controller.riders.filter(func(rider):
	    return not (rider.get_meta("racer_id", 0) in eliminated_riders)
	)

	if active_riders.size() <= 2:
	    if active_riders.size() == 2:
	        _start_head_to_head()
	    return

	# Find the last-place rider(s)
	var sorted_positions = _get_sorted_positions(active_riders)

	if sorted_positions.size() == 0:
	    return

	var last_rider = sorted_positions.back()
	var second_last_rider = sorted_positions[sorted_positions.size() - 2] if sorted_positions.size() > 1 else null

	# Double save check: within 0.3 seconds
	var should_eliminate = true
	if second_last_rider:
	    var last_time = race_controller.rider_laps.get(last_rider.get_meta("racer_id", 0), 0) * 45.0  # Rough estimate
	    var second_last_time = race_controller.rider_laps.get(second_last_rider.get_meta("racer_id", 0), 0) * 45.0
	    var time_gap = abs(last_time - second_last_time)

	    if time_gap < 0.3:
	        print("Double save! Riders within ", snapped(time_gap, 0.01), "s")
	        should_eliminate = false

	if should_eliminate:
	    _eliminate_rider(last_rider, lap_number)

func _get_sorted_positions(active_riders: Array) -> Array:
	"""Get riders sorted by race position (laps desc, progress desc)"""
	var sorted = active_riders.duplicate()
	sorted.sort_custom(func(a, b):
	    var a_id = a.get_meta("racer_id", 0)
	    var b_id = b.get_meta("racer_id", 0)

	    var a_laps = race_controller.rider_laps.get(a_id, 0)
	    var b_laps = race_controller.rider_laps.get(b_id, 0)

	    if a_laps != b_laps:
	        return a_laps > b_laps

	    var a_progress = race_controller.rider_progress.get(a_id, 0.0)
	    var b_progress = race_controller.rider_progress.get(b_id, 0.0)
	    return a_progress > b_progress
	)
	return sorted

func _eliminate_rider(rider: Node3D, lap_number: int) -> void:
	"""Eliminate a rider from the race"""
	var racer_id = rider.get_meta("racer_id", 0)
	eliminated_riders.append(racer_id)

	# Visual elimination effect
	rider.visible = false  # Simple fade out

	# Update HUD
	var remaining = race_controller.riders.size() - eliminated_riders.size()
	print("Rider ", racer_id, " eliminated on lap ", lap_number, "! ", remaining, " riders remain")

	# Check if head-to-head should start
	var active_count = race_controller.riders.size() - eliminated_riders.size()
	if active_count == 2:
	    _start_head_to_head()

func _start_head_to_head() -> void:
	"""Start the final head-to-head phase"""
	print("Head-to-head final! All sprint bars refilled!")

	# Refill sprint energy for remaining riders
	for rider in race_controller.riders:
	    var racer_id = rider.get_meta("racer_id", 0)
	    if not (racer_id in eliminated_riders) and rider.has_method("reset_for_new_lap"):
	        rider.reset_for_new_lap()

func is_rider_eliminated(racer_id: int) -> bool:
	"""Check if a rider has been eliminated"""
	return racer_id in eliminated_riders

func get_remaining_riders() -> int:
	"""Get count of remaining active riders"""
	return race_controller.riders.size() - eliminated_riders.size()