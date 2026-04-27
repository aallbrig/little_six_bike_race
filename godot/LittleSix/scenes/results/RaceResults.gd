extends CanvasLayer
class_name RaceResults

# Race Results screen for Little Six
# Shows final race standings and player stats

var results_data: Array = []

func _ready() -> void:
	# Get results from scene parameters
	if get_tree().current_scene.has_meta("results"):
		results_data = get_tree().current_scene.get_meta("results")
		display_results(results_data)

func display_results(results: Array) -> void:
	"""Display race results"""
	print("Displaying race results for ", results.size(), " racers")

	# Update title
	$Panel/VBoxContainer/TitleLabel.text = "RACE COMPLETE"

	# Display top positions (simplified - only showing 2 for now)
	if results.size() >= 1:
		var first = results[0]
		$Panel/VBoxContainer/ResultsContainer/Position1/NameLabel.text = "Racer " + str(first.racer_id)
		$Panel/VBoxContainer/ResultsContainer/Position1/TimeLabel.text = format_time(first.total_time)

	if results.size() >= 2:
		var second = results[1]
		$Panel/VBoxContainer/ResultsContainer/Position2/NameLabel2.text = "Racer " + str(second.racer_id)
		$Panel/VBoxContainer/ResultsContainer/Position2/TimeLabel2.text = format_time(second.total_time)

	# Update player stats (mock data for now)
	update_player_stats()

func update_player_stats() -> void:
	"""Update player performance stats"""
	# Mock performance data - in real implementation this would come from race data
	$Panel/VBoxContainer/StatsContainer/SpeedStat.value = randi_range(60, 90)
	$Panel/VBoxContainer/StatsContainer/SprintStat.value = randi_range(40, 80)
	$Panel/VBoxContainer/StatsContainer/DraftingStat.value = randi_range(30, 70)

func format_time(total_seconds: float) -> String:
	"""Format time as MM:SS.mmm"""
	var minutes = int(total_seconds / 60)
	var seconds = int(total_seconds) % 60
	var milliseconds = int((total_seconds - int(total_seconds)) * 1000)

	return "%d:%02d.%03d" % [minutes, seconds, milliseconds]

func _on_replay_pressed() -> void:
	"""Race again - go back to lobby or start new race"""
	# For now, just go back to main hub
	GameManager.transition_to(GameManager.GameState.MAIN_HUB)

func _on_menu_pressed() -> void:
	"""Return to main menu"""
	GameManager.transition_to(GameManager.GameState.MAIN_HUB)