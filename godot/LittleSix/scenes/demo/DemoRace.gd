extends Control

var _demo_timer = 0.0
const DEMO_DURATION = 60.0

func _ready() -> void:
	EventBus.music_track_requested.emit("race_normal", 1.0)
	$TapToPlay.pressed.connect(_on_tap_to_play_pressed)
	$DemoLabel.text = "DEMO"

func _process(delta: float) -> void:
	_demo_timer += delta
	if _demo_timer >= DEMO_DURATION:
	    GameManager.transition_to(GameManager.GameState.CINEMATIC)

func _on_tap_to_play_pressed() -> void:
	if SaveManager.player_data == null:
	    GameManager.transition_to(GameManager.GameState.CREATE_RACER)
	else:
	    GameManager.transition_to(GameManager.GameState.MAIN_HUB)