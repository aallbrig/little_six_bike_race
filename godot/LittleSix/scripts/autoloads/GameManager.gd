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
    RACE_ACTIVE,
    RACE_RESULTS,
    SPRING_EVENT,
    SETTINGS,
    QUIT,  # Terminal state for quitting to host
}

var current_state: GameState = GameState.LOGO
var current_player: Resource = null  # PlayerData

func _ready() -> void:
    # Connect to EventBus for network-driven state changes
    EventBus.network_message_received.connect(_on_network_message_received)

func transition_to(state: GameState, data: Dictionary = {}) -> void:
    if state == current_state:
        return

    _exit_state(current_state)
    current_state = state
    EventBus.game_state_changed.emit(state)
    _enter_state(state, data)

func _enter_state(state: GameState, data: Dictionary) -> void:
    match state:
        GameState.LOGO:
            _load_scene("res://scenes/logo/Logo.tscn")
        GameState.CINEMATIC:
            _load_scene("res://scenes/cinematic/IntroCinematic.tscn")
        GameState.TITLE:
            _load_scene("res://scenes/title/TitleScreen.tscn")
        GameState.DEMO:
            _load_scene("res://scenes/demo/DemoRace.tscn")
        GameState.CREATE_RACER:
            _load_scene("res://scenes/hub/CreateRacer.tscn")
        GameState.MAIN_HUB:
            _load_scene("res://scenes/hub/MainHub.tscn")
        GameState.TRAINING_DAY:
            _load_scene("res://scenes/training/TrainingDay.tscn", data)
        GameState.TRAINING_RESULTS:
            _load_scene("res://scenes/training/TrainingResults.tscn", data)
        GameState.LOBBY:
            _load_scene("res://scenes/ui/Lobby.tscn")
        GameState.RACE_ACTIVE:
            _load_scene("res://scenes/race/RaceTrack.tscn", data)
        GameState.RACE_RESULTS:
            _load_scene("res://scenes/results/RaceResults.tscn", data)
        GameState.SETTINGS:
            _load_scene("res://scenes/ui/Settings.tscn")
        GameState.QUIT:
            quit_to_host()
        _:
            push_error("Unknown game state: " + str(state))

func _exit_state(state: GameState) -> void:
    # Clean up state-specific resources if needed
    pass

func _load_scene(scene_path: String, data: Dictionary = {}) -> void:
    # Use SceneTree to change scenes with transition support
    var current_scene = get_tree().current_scene
    if current_scene and current_scene.name != "Logo":
        # For now, just change scene. TransitionManager will be added in full Spec 002
        get_tree().change_scene_to_file(scene_path)
    else:
        get_tree().change_scene_to_file(scene_path)

func quit_to_host(reason: String = "player_exit") -> void:
    HostBridge.emit_to_host("quit", { "reason": reason })
    transition_to(GameState.QUIT)

func _on_network_message_received(msg_type: String, payload: Dictionary) -> void:
    # Handle server-driven state changes
    match msg_type:
        "RACE_START":
            transition_to(GameState.RACE_ACTIVE, payload)
        "RACE_FINISHED":
            transition_to(GameState.RACE_RESULTS, payload)
        _:
            pass  # Other messages handled by other systems