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
var finish_order: Array = []

# Bell lap
const BELL_LAP = 49  # Lap 49 out of 50
var bell_lap_triggered: bool = false

func _ready() -> void:
    EventBus.race_started.connect(_on_race_started)
    EventBus.lap_completed.connect(_on_lap_completed)

func _process(delta: float) -> void:
    if race_started and not race_finished:
        current_race_time += delta

        # Check time cap
        if time_cap_sec > 0 and current_race_time >= time_cap_sec:
            _finish_race_early()

func start_race() -> void:
    race_started = true
    race_start_time = Time.get_ticks_msec() / 1000.0
    current_race_time = 0.0

    # Initialize rider tracking
    for rider in riders:
        var racer_id = rider.get_meta("racer_id", 0)
        rider_laps[racer_id] = 0
        rider_positions[racer_id] = 0

    EventBus.race_started.emit()
    print("Race started with ", riders.size(), " riders")

func add_rider(rider: Node3D) -> void:
    riders.append(rider)

func _on_race_started() -> void:
    print("Race controller: Race started!")

func _on_lap_completed(racer_id: int, lap_number: int, lap_time: float) -> void:
    if not race_started or race_finished:
        return

    rider_laps[racer_id] = lap_number
    rider_positions[racer_id] = lap_number  # Simplified - would calculate by track position

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
        result.fastest_lap = 45.0 + randf() * 10.0  # Placeholder
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