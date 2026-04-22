## GameManager — Top-level game state machine.
## All scene transitions go through here.
## Access: GameManager.transition_to(state)
extends Node

enum GameState {
	LOGO,
	CINEMATIC,
	TITLE,
	DEMO,
	CREATE_RACER,
	MAIN_HUB,
	TRAINING_DAY,
	TRAINING_RESULTS,
	LOBBY,
	RACE_QUALIFYING,
	SPRING_EVENT,
	RACE_ACTIVE,
	RACE_RESULTS,
	SETTINGS,
}

const SCENE_MAP: Dictionary = {
	GameState.LOGO:             "res://scenes/logo/Logo.tscn",
	GameState.CINEMATIC:        "res://scenes/cinematic/IntroCinematic.tscn",
	GameState.TITLE:            "res://scenes/title/TitleScreen.tscn",
	GameState.DEMO:             "res://scenes/demo/DemoRace.tscn",
	GameState.CREATE_RACER:     "res://scenes/hub/CreateRacer.tscn",
	GameState.MAIN_HUB:         "res://scenes/hub/MainHub.tscn",
	GameState.TRAINING_DAY:     "res://scenes/training/TrainingDay.tscn",
	GameState.TRAINING_RESULTS: "res://scenes/training/TrainingResults.tscn",
	GameState.LOBBY:            "res://scenes/ui/Lobby.tscn",
	GameState.RACE_QUALIFYING:  "res://scenes/race/RaceTrack.tscn",
	GameState.SPRING_EVENT:     "res://scenes/race/RaceTrack.tscn",
	GameState.RACE_ACTIVE:      "res://scenes/race/RaceTrack.tscn",
	GameState.RACE_RESULTS:     "res://scenes/results/RaceResults.tscn",
	GameState.SETTINGS:         "res://scenes/hub/MainHub.tscn",  # Settings is a panel in hub
}

var current_state: GameState = GameState.LOGO
var previous_state: GameState = GameState.LOGO
var current_player = null  # PlayerData — set after CreateRacer or save load
var _transition_data: Dictionary = {}
var _loading: bool = false


func _ready() -> void:
	EventBus.network_message_received.connect(_on_network_message)
	# Start the game at LOGO state
	# Scenes are loaded by responding to game_state_changed signal
	# The initial scene is set in project.godot (Logo.tscn)


func transition_to(new_state: GameState, data: Dictionary = {}) -> void:
	if new_state == current_state:
		return
	if _loading:
		push_warning("GameManager: transition requested while loading, queuing: " + str(new_state))
		return

	_loading = true
	_transition_data = data
	previous_state = current_state
	current_state = new_state

	EventBus.game_state_changed.emit(new_state)
	_load_scene_for_state(new_state)


func _load_scene_for_state(state: GameState) -> void:
	var scene_path = SCENE_MAP.get(state, "")
	if scene_path == "":
		push_error("GameManager: no scene defined for state " + str(state))
		_loading = false
		return

	# Use deferred loading for non-blocking
	ResourceLoader.load_threaded_request(scene_path)
	_poll_loading(scene_path)


func _poll_loading(scene_path: String) -> void:
	var status = ResourceLoader.load_threaded_get_status(scene_path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(scene_path)

	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("GameManager: failed to load scene: " + scene_path)
		_loading = false
		return

	var packed_scene = ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if packed_scene == null:
		push_error("GameManager: scene is not a PackedScene: " + scene_path)
		_loading = false
		return

	get_tree().change_scene_to_packed(packed_scene)
	_loading = false


func get_transition_data() -> Dictionary:
	return _transition_data


func show_loading(message: String = "") -> void:
	# LoadingOverlay is expected as a child of root or as an autoloaded scene
	# Scenes can call this to show a loading spinner
	pass  # Implemented when UI layer is built (Spec 007)


func hide_loading() -> void:
	pass  # Implemented when UI layer is built (Spec 007)


func _on_network_message(msg_type: String, _payload: Dictionary) -> void:
	match msg_type:
		"RACE_START":
			if current_state == GameState.LOBBY:
				transition_to(GameState.RACE_ACTIVE)
		"RACE_FINISHED":
			if current_state == GameState.RACE_ACTIVE:
				transition_to(GameState.RACE_RESULTS, _payload)
