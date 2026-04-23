extends Control

func _ready() -> void:
    # Start pulsing animation for "TAP TO START"
    $PulseTimer.timeout.connect(_on_pulse_timer_timeout)
    $IdleTimer.timeout.connect(_on_idle_timer_timeout)
    
    # Initial pulse
    _pulse_tap_label()
    
    # Connect input for any tap
    gui_input.connect(_on_gui_input)
    
    # Start music
    EventBus.music_track_requested.emit("attract", 0.5)

func _on_pulse_timer_timeout() -> void:
    _pulse_tap_label()

func _pulse_tap_label() -> void:
    var tween = create_tween()
    tween.tween_property($TapLabel, "modulate:a", 0.3, 0.6)
    tween.tween_property($TapLabel, "modulate:a", 1.0, 0.6)

func _on_idle_timer_timeout() -> void:
    # Auto advance to demo after 10 seconds of no input
    GameManager.transition_to(GameManager.GameState.DEMO)

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        _start_game()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        _start_game()

func _start_game() -> void:
    $IdleTimer.stop()
    if SaveManager.player_data == null:
        GameManager.transition_to(GameManager.GameState.CREATE_RACER)
    else:
        GameManager.transition_to(GameManager.GameState.MAIN_HUB)