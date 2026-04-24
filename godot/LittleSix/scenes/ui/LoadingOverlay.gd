extends CanvasLayer

const LOADING_PUNS = [
    "Pedaling to the server...",
    "Adjusting coaster brake...",
    "Finding the pack...",
    "Counting laps...",
    "Warming up the oval...",
    "Checking tire pressure...",
    "Finding the sweet spot...",
    "Coasting to victory..."
]

var _current_pun_index = 0
var _pun_timer: Timer

func _ready() -> void:
    visible = false
    _setup_pun_timer()
    # Ensure nodes are accessible
    if has_node("CenterContainer/VBoxContainer/LoadingLabel"):
        $CenterContainer/VBoxContainer/LoadingLabel.text = "Loading..."

func _setup_pun_timer() -> void:
    _pun_timer = Timer.new()
    _pun_timer.wait_time = 2.0
    _pun_timer.timeout.connect(_cycle_pun)
    add_child(_pun_timer)

func show_loading(message: String = "") -> void:
    if message.is_empty():
        _cycle_pun()
    else:
        $CenterContainer/VBoxContainer/LoadingLabel.text = message

    visible = true
    _pun_timer.start()

    # Animate spinner
    var tween = create_tween().set_loops()
    tween.tween_property($CenterContainer/VBoxContainer/Spinner, "rotation", TAU, 1.0)

func hide_loading() -> void:
    visible = false
    if _pun_timer:
        _pun_timer.stop()
    _current_pun_index = 0

func _cycle_pun() -> void:
    $CenterContainer/VBoxContainer/LoadingLabel.text = LOADING_PUNS[_current_pun_index]
    _current_pun_index = (_current_pun_index + 1) % LOADING_PUNS.size()