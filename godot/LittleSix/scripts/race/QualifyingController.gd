extends Node
class_name QualifyingController

# Qualifying Time Trial Controller (Spec 010)

@export var qualifying_laps: int = 4
@export var is_qualifying: bool = false

# Qualifying state
var qual_start_time: float = 0.0
var lap_times: Array[float] = []
var ghost_data: Array = []  # Array of position data for ghost rider
var personal_best: float = 999999.0

# References
@onready var race_controller: RaceController = $".."
@onready var track_path: Path3D = $"../TrackPath"

func _ready() -> void:
    EventBus.lap_completed.connect(_on_lap_completed)
    # Load personal best from save
    personal_best = SaveManager.get_setting("qual_pb", 999999.0)

func start_qualifying() -> void:
    """Start a qualifying time trial"""
    is_qualifying = true
    qual_start_time = Time.get_ticks_msec() / 1000.0
    lap_times.clear()
    ghost_data.clear()

    race_controller.total_laps = qualifying_laps
    race_controller.start_race()

    print("Qualifying started - ", qualifying_laps, " laps")

func _on_lap_completed(racer_id: int, lap_number: int, lap_time: float) -> void:
    """Handle lap completion during qualifying"""
    if not is_qualifying or racer_id != 0:  # Only track player (racer_id 0)
        return

    lap_times.append(lap_time)

    print("Qualifying lap ", lap_number, " completed in ", snapped(lap_time, 0.01), "s")

    # Record ghost data for this lap segment
    _record_ghost_data()

    # Check if qualifying is complete
    if lap_times.size() >= qualifying_laps:
        _finish_qualifying()

func _record_ghost_data() -> void:
    """Record rider position data for ghost rider"""
    # Simplified: record position every 0.1 seconds for the last lap
    var current_time = Time.get_ticks_msec() / 1000.0 - qual_start_time
    var player_rider = race_controller._get_rider_by_id(0)

    if player_rider:
        var ghost_point = {
            "time": current_time,
            "position": player_rider.global_position,
            "progress": race_controller.rider_progress.get(0, 0.0)
        }
        ghost_data.append(ghost_point)

func _finish_qualifying() -> void:
    """Calculate qualifying time and save results"""
    is_qualifying = false

    # Qualifying time: laps 2+3+4 (lap 1 is flying start warmup)
    if lap_times.size() >= 4:
        var official_time = lap_times[1] + lap_times[2] + lap_times[3]

        print("Qualifying complete! Official time: ", snapped(official_time, 0.01), "s")

        # Check for personal best
        if official_time < personal_best:
            personal_best = official_time
            SaveManager.set_setting("qual_pb", personal_best)
            SaveManager.set_setting("qual_ghost_data", ghost_data)
            print("New personal best!")

        SaveManager.save_game()
        EventBus.game_state_changed.emit(GameManager.GameState.RACE_RESULTS)

    else:
        print("Qualifying incomplete - not enough laps")

func get_ghost_data() -> Array:
    """Get stored ghost rider data"""
    return SaveManager.get_setting("qual_ghost_data", [])

func reset_personal_best() -> void:
    """Reset qualifying personal best (for testing)"""
    personal_best = 999999.0
    SaveManager.set_setting("qual_pb", personal_best)
    SaveManager.set_setting("qual_ghost_data", [])
    SaveManager.save_game()