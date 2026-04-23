extends Node

# Simple transition overlay for iris wipe effect
var _transition_overlay: ColorRect
var _is_transitioning = false

func _ready() -> void:
    # Create transition overlay
    _transition_overlay = ColorRect.new()
    _transition_overlay.name = "TransitionOverlay"
    _transition_overlay.color = Color(0, 0, 0, 1)
    _transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    
    # Add shader for circular mask (iris wipe)
    var shader_material = ShaderMaterial.new()
    var shader = Shader.new()
    shader.code = """
    shader_type canvas_item;
    
    uniform float circle_radius : hint_range(0.0, 2.0) = 0.0;
    uniform vec2 circle_center = vec2(0.5, 0.5);
    
    void fragment() {
        float dist = distance(UV, circle_center);
        float alpha = smoothstep(circle_radius - 0.1, circle_radius + 0.1, dist);
        COLOR = vec4(0.0, 0.0, 0.0, alpha);
    }
    """
    shader_material.shader = shader
    _transition_overlay.material = shader_material
    
    # Add to root so it stays on top
    get_tree().root.add_child(_transition_overlay)
    _transition_overlay.z_index = 1000
    _transition_overlay.visible = false

# Transition out (iris closes)
func transition_out(callback: Callable, duration: float = 0.3) -> void:
    if _is_transitioning:
        return
    _is_transitioning = true
    _transition_overlay.visible = true
    
    var material = _transition_overlay.material as ShaderMaterial
    var tween = create_tween()
    tween.tween_method(func(r): material.set_shader_parameter("circle_radius", r), 2.0, 0.0, duration)
    tween.finished.connect(func():
        callback.call()
        _is_transitioning = false
    )

# Transition in (iris opens)  
func transition_in(duration: float = 0.3) -> void:
    if not _transition_overlay.visible:
        return
        
    var material = _transition_overlay.material as ShaderMaterial
    var tween = create_tween()
    tween.tween_method(func(r): material.set_shader_parameter("circle_radius", r), 0.0, 2.0, duration)
    tween.finished.connect(func():
        _transition_overlay.visible = false
        _is_transitioning = false
    )