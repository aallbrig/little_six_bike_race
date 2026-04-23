extends Control

var _skipped = false

func _ready() -> void:
    # Start music
    EventBus.music_track_requested.emit("attract", 1.0)
    
    # Connect skip timer
    $SkipTimer.timeout.connect(_on_skip_timer_timeout)
    
    # Connect input for skip
    gui_input.connect(_on_gui_input)

func _on_skip_timer_timeout() -> void:
    $SkipLabel.visible = true
    $AnimationPlayer.play("show_skip")

func _on_gui_input(event: InputEvent) -> void:
    if $SkipLabel.visible and event is InputEventMouseButton and event.pressed:
        _skip_to_title()

func _skip_to_title() -> void:
    if not _skipped:
        _skipped = true
        GameManager.transition_to(GameManager.GameState.TITLE)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and $SkipLabel.visible:
        _skip_to_title()

# Called when cinematic should end (would be triggered by AnimationPlayer in full version)
func _on_cinematic_complete() -> void:
    if not _skipped:
        GameManager.transition_to(GameManager.GameState.TITLE)