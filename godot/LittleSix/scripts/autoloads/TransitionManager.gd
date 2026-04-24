extends Node

# Simple transition overlay for iris wipe effect
var _transition_overlay: ColorRect
var _is_transitioning: bool = false

func _ready() -> void:
    # Create transition overlay
    _transition_overlay = ColorRect.new()
    _transition_overlay.name = "TransitionOverlay"
    _transition_overlay.color = Color(0, 0, 0, 1)
    _transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

    # Add simple black material for now
    _transition_overlay.material = null

    # Add to root so it stays on top
    get_tree().root.add_child(_transition_overlay)
    _transition_overlay.z_index = 1000
    _transition_overlay.visible = false

# Transition out (fade out)
func transition_out(callback: Callable, duration: float = 0.3) -> void:
    if _is_transitioning:
        return
    _is_transitioning = true
    _transition_overlay.visible = true

    var tween: Tween = create_tween()
    tween.tween_property(_transition_overlay, "modulate:a", 1.0, duration)
    tween.finished.connect(_on_transition_out_finished.bind(callback))

# Transition in (fade in)
func transition_in(duration: float = 0.3) -> void:
    if not _transition_overlay.visible:
        return

    var tween: Tween = create_tween()
    tween.tween_property(_transition_overlay, "modulate:a", 0.0, duration)
    tween.finished.connect(_on_transition_in_finished)

func _on_transition_out_finished(callback: Callable) -> void:
    callback.call()
    _is_transitioning = false

func _on_transition_in_finished() -> void:
    _transition_overlay.visible = false
    _is_transitioning = false