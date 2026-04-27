extends Control

func _ready() -> void:
	$Options/QuickRace.pressed.connect(_on_quick_race_pressed)
	$Options/PrivateRoom.pressed.connect(_on_private_room_pressed)
	$Options/SeasonMatch.pressed.connect(_on_season_match_pressed)
	$BackButton.pressed.connect(_on_back_pressed)

	EventBus.disconnected_from_server.connect(_on_matchmaking_error)

func _on_quick_race_pressed() -> void:
	NetworkMgr.find_match("quick")
	GameManager.show_loading("Finding a race...")

func _on_private_room_pressed() -> void:
	# Show private room dialog - simplified
	var room_code = "ABCD12"  # Would be user input
	NetworkMgr.join_private_room(room_code)
	GameManager.show_loading("Joining private room...")

func _on_season_match_pressed() -> void:
	NetworkMgr.find_match("season")
	GameManager.show_loading("Finding ranked match...")

func _on_back_pressed() -> void:
	GameManager.transition_to(GameManager.GameState.MAIN_HUB)

func _on_matchmaking_error(reason: String) -> void:
	GameManager.hide_loading()
	GameManager.show_error("Failed to find match: " + reason)