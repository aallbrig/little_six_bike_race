extends Control

func _ready() -> void:
    EventBus.music_track_requested.emit("hub", 1.0)
    $TrainButton.pressed.connect(_on_train_pressed)
    $RaceButton.pressed.connect(_on_race_pressed)

func _on_train_pressed() -> void:
    GameManager.transition_to(GameManager.GameState.TRAINING_DAY)

func _on_race_pressed() -> void:
    GameManager.transition_to(GameManager.GameState.LOBBY)