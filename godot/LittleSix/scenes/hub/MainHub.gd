extends Control

func _ready() -> void:
    EventBus.music_track_requested.emit("hub", 1.0)
    $TrainButton.pressed.connect(_on_train_pressed)
    $RaceButton.pressed.connect(_on_race_pressed)

func _on_train_pressed() -> void:
    GameManager.transition_to(GameManager.GameState.TRAINING_DAY)

func _on_race_pressed() -> void:
    # Use matchmaking instead of direct lobby
    var matchmaking = load("res://scripts/network/MatchmakingClient.gd").new()
    add_child(matchmaking)
    matchmaking.quick_match()