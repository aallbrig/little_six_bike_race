extends Node

var _skipped = false

func _ready() -> void:
    # Start music
    EventBus.music_track_requested.emit("attract", 1.0)

    # Connect timers
    $SkipTimer.timeout.connect(_on_skip_timer_timeout)
    $CinematicTimer.timeout.connect(_on_cinematic_complete)

    # Start cinematic animations
    $AnimationPlayer.play("cinematic_timeline")
    $AnimationPlayer.play("fov_timeline")

func _on_skip_timer_timeout() -> void:
    $UI/SkipLabel.visible = true
    $AnimationPlayer.play("show_skip")

func _skip_to_title() -> void:
    if not _skipped:
        _skipped = true
        $AnimationPlayer.stop()
        $CinematicTimer.stop()
        $SkipTimer.stop()
        GameManager.transition_to(GameManager.GameState.TITLE)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and $UI/SkipLabel.visible:
        _skip_to_title()

func _on_cinematic_complete() -> void:
    if not _skipped:
        GameManager.transition_to(GameManager.GameState.TITLE)