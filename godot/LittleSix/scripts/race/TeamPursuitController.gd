extends Node
class_name TeamPursuitController

# Team Pursuit Event Controller (Spec 010)
# Two teams of 2 riders each, alternating laps, catch to win

@export var is_team_pursuit: bool = false
@export var team_size: int = 2  # Riders per team

# Team state
var teams = {
	1: {"riders": [0, 1], "current_rider": 0},  # Team 1: riders 0,1
	2: {"riders": [2, 3], "current_rider": 0}   # Team 2: riders 2,3
}

# References
@onready var race_controller: RaceController = $"../race_controller"

func _ready() -> void:
	EventBus.lap_completed.connect(_on_lap_completed)

func start_team_pursuit() -> void:
	"""Start a Team Pursuit race event"""
	is_team_pursuit = true

	# Position teams at starting locations
	_setup_starting_positions()

	race_controller.total_laps = 10  # Team pursuit is 10 laps
	race_controller.start_race()

	print("Team Pursuit started - Team 1 vs Team 2")

func _setup_starting_positions() -> void:
	"""Position teams at opposite sides of track"""
	# Team 1 starts at start/finish (progress 0.0)
	# Team 2 starts at opposite side (progress 0.5)

	for rider in race_controller.riders:
	    var racer_id = rider.get_meta("racer_id", 0)

	    if racer_id in teams[1]["riders"]:
	        # Team 1: start at beginning
	        rider.global_position = Vector3(-50, 0, 0)
	        race_controller.rider_progress[racer_id] = 0.0
	    elif racer_id in teams[2]["riders"]:
	        # Team 2: start at opposite side (mid-back-straight)
	        rider.global_position = Vector3(0, 0, -80)  # Mid-track position
	        race_controller.rider_progress[racer_id] = 0.5

func _on_lap_completed(racer_id: int, lap_number: int, lap_time: float) -> void:
	"""Handle team relay exchanges"""
	if not is_team_pursuit:
	    return

	var team_id = _get_team_for_rider(racer_id)
	if team_id == 0:
	    return

	# Switch to next rider in team
	var team = teams[team_id]
	team["current_rider"] = (team["current_rider"] + 1) % team_size

	var next_rider_id = team["riders"][team["current_rider"]]
	print("Team ", team_id, " switches to rider ", next_rider_id, " on lap ", lap_number)

	# Check for catch condition every lap
	_check_catch_condition()

	# Check win condition (10 laps)
	if lap_number >= 10:
	    _determine_winner()

func _get_team_for_rider(racer_id: int) -> int:
	"""Get team ID for a rider"""
	for team_id in teams:
	    if racer_id in teams[team_id]["riders"]:
	        return team_id
	return 0

func _check_catch_condition() -> void:
	"""Check if one team has caught the other"""
	var team1_progress = _get_team_progress(1)
	var team2_progress = _get_team_progress(2)

	var progress_diff = abs(team1_progress - team2_progress)

	# Catch condition: any rider from team A passes any rider from team B
	if progress_diff < 0.01:  # Very close (within 1% of track)
	    var winning_team = 1 if team1_progress > team2_progress else 2
	    _team_wins(winning_team, "catch")
	    return

	# Update gap display (would show in HUD)
	var gap = abs(team1_progress - team2_progress) * 400  # Rough meters
	print("Team gap: ", snapped(gap, 0.1), "m")

func _get_team_progress(team_id: int) -> float:
	"""Get the progress of the lead rider for a team"""
	var team = teams[team_id]
	var current_rider_id = team["riders"][team["current_rider"]]

	return race_controller.rider_progress.get(current_rider_id, 0.0)

func _determine_winner() -> void:
	"""Determine winner after 10 laps"""
	var team1_progress = _get_team_progress(1)
	var team2_progress = _get_team_progress(2)

	var winning_team = 1 if team1_progress > team2_progress else 2
	var margin = abs(team1_progress - team2_progress) * 400  # meters

	_team_wins(winning_team, "laps", margin)

func _team_wins(team_id: int, reason: String, margin: float = 0.0) -> void:
	"""Handle team victory"""
	if reason == "catch":
	    print("Team ", team_id, " wins by catch!")
	else:
	    print("Team ", team_id, " wins after 10 laps by ", snapped(margin, 0.1), "m!")

	race_controller.race_finished = true
	EventBus.race_finished.emit([])  # Would include proper results

func get_team_gap() -> Dictionary:
	"""Get current team gap information for HUD"""
	return {
	    "team1_progress": _get_team_progress(1),
	    "team2_progress": _get_team_progress(2),
	    "gap_meters": abs(_get_team_progress(1) - _get_team_progress(2)) * 400
	}