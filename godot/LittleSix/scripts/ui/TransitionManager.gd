extends CanvasLayer

const IRIS_SHADER = preload("res://assets/shaders/iris_mask.gdshader")

var _transition_overlay: ColorRect

func _ready() -> void:
    _transition_overlay = ColorRect.new()
    _transition_overlay.color = Color.BLACK
    _transition_overlay.size = get_viewport().size
    _transition_overlay.material = ShaderMaterial.new()
    _transition_overlay.material.shader = IRIS_SHADER
    _transition_overlay.material.set_shader_parameter("circle_size", 0.0)  # Start closed
    _transition_overlay.z_index = 1000
    add_child(_transition_overlay)

func transition_out(callback: Callable, duration: float = 0.3) -> void:
    var tween = create_tween()
    tween.tween_property(_transition_overlay.material, "shader_parameter/circle_size", 1.0, duration)
    tween.tween_callback(callback)

func transition_in(duration: float = 0.3) -> void:
    var tween = create_tween()
    tween.tween_property(_transition_overlay.material, "shader_parameter/circle_size", 0.0, duration)
    tween.tween_callback(func(): _transition_overlay.hide())