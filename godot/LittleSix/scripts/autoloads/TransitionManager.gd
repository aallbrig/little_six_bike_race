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

	# Create iris wipe shader material
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;

	uniform float progress : hint_range(0.0, 1.0) = 0.0;
	uniform bool reverse = false;

	void fragment() {
	    vec2 center = vec2(0.5, 0.5);
	    vec2 uv = UV;
	    float dist = distance(uv, center);

	    float radius = reverse ? (1.0 - progress) : progress;
	    float alpha = smoothstep(radius - 0.01, radius + 0.01, dist);

	    COLOR = vec4(0.0, 0.0, 0.0, alpha);
	}
	"""
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("progress", 0.0)
	material.set_shader_parameter("reverse", false)

	_transition_overlay.material = material

	# Add to root so it stays on top (deferred to avoid setup conflicts)
	get_tree().root.call_deferred("add_child", _transition_overlay)
	_transition_overlay.z_index = 1000
	_transition_overlay.visible = false

# Transition out (iris closes)
func transition_out(callback: Callable, duration: float = 0.3) -> void:
	if _is_transitioning:
	    return
	_is_transitioning = true
	_transition_overlay.visible = true

	var material = _transition_overlay.material as ShaderMaterial
	material.set_shader_parameter("reverse", false)
	material.set_shader_parameter("progress", 0.0)

	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, duration)
	tween.finished.connect(_on_transition_out_finished.bind(callback))

# Transition in (iris opens)
func transition_in(duration: float = 0.3) -> void:
	if not _transition_overlay.visible:
	    return

	var material = _transition_overlay.material as ShaderMaterial
	material.set_shader_parameter("reverse", true)
	material.set_shader_parameter("progress", 1.0)

	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 1.0, 0.0, duration)
	tween.finished.connect(_on_transition_in_finished)

func _set_progress(value: float) -> void:
	var material = _transition_overlay.material as ShaderMaterial
	material.set_shader_parameter("progress", value)

func _on_transition_out_finished(callback: Callable) -> void:
	callback.call()
	_is_transitioning = false

func _on_transition_in_finished() -> void:
	_transition_overlay.visible = false
	_is_transitioning = false