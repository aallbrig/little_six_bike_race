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
    RACE_ACTIVE,
    RACE_RESULTS,
    SETTINGS,
    QUIT
}

var _loading_overlay: CanvasLayer

var current_state: GameState = GameState.LOGO
var current_player: PlayerData = null
var current_season: SeasonData = null

func _ready() -> void:
    # Connect to EventBus for network-driven state changes
    # TODO: Uncomment when Spec 005 is implemented
    # EventBus.network_message_received.connect(_on_network_message_received)

    # Initialize loading overlay
    _loading_overlay = preload("res://scenes/ui/LoadingOverlay.tscn").instantiate()
    get_tree().root.call_deferred("add_child", _loading_overlay)
    _loading_overlay.call_deferred("hide_loading")

func transition_to(state: GameState, data: Dictionary = {}) -> void:
    if state == current_state:
        return

    _exit_state(current_state)
    current_state = state
    EventBus.game_state_changed.emit(state)
    _enter_state(state, data)

func get_current_scene() -> Node:
    return get_tree().current_scene

func _on_scene_loaded(scene: Node) -> void:
    pass  # Override in subclasses if needed

func _enter_state(state: GameState, data: Dictionary) -> void:
    # Handle orientation changes
    _update_orientation_for_state(state)

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

func _update_orientation_for_state(state: GameState) -> void:
    # Orientation locking is handled by the rotate overlay and host page
    # For now, just ensure we're in the right mode when entering race
    match state:
        GameState.RACE_ACTIVE:
            # Request landscape via host bridge for mobile web
            HostBridge.emit_to_host("orientation_request", { "orientation": "landscape" })
        _:
            # Portrait for all other states
            HostBridge.emit_to_host("orientation_request", { "orientation": "portrait" })

func _exit_state(state: GameState) -> void:
    # Clean up state-specific resources if needed
    pass

func _load_scene(scene_path: String, data: Dictionary = {}) -> void:
    # Use TransitionManager for smooth iris-wipe transitions
    TransitionManager.transition_out(func():
        get_tree().change_scene_to_file(scene_path)
        # Transition back in after scene loads
        await get_tree().process_frame
        TransitionManager.transition_in()
    , 0.4)

func show_loading(message: String = "") -> void:
    _loading_overlay.show_loading(message)

func hide_loading() -> void:
    _loading_overlay.hide_loading()

func quit_to_host(reason: String = "player_exit") -> void:
    HostBridge.emit_to_host("quit", { "reason": reason })
    transition_to(GameState.QUIT)

# TODO: Uncomment when Spec 005 is implemented
# func _on_network_message_received(msg_type: String, payload: Dictionary) -> void:
#     # Handle server-driven state changes
#     match msg_type:
#         "RACE_START":
#             transition_to(GameState.RACE_ACTIVE, payload)
#         "RACE_FINISHED":
#             transition_to(GameState.RACE_RESULTS, payload)
#         _:
#             pass  # Other messages handled by other systems