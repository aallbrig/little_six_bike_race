extends Node3D

# Basic player rider for testing camera system
# Moves along the track path

@onready var track_path: Path3D = get_parent().get_parent().get_node("TrackPath")

var progress: float = 0.0
var speed: float = 5.0

func _ready() -> void:
    if track_path:
        global_position = track_path.curve.get_point_position(0)

func _process(delta: float) -> void:
    if track_path:
        progress += speed * delta
        if progress > track_path.curve.get_baked_length():
            progress = 0.0

        global_position = track_path.curve.sample_baked(progress)

        # Look along the path
        var next_progress = min(progress + 1.0, track_path.curve.get_baked_length())
        var next_pos = track_path.curve.sample_baked(next_progress)
        look_at(next_pos, Vector3.UP)

func get_velocity() -> Vector3:
    # Return forward velocity for camera calculations
    return -global_transform.basis.z * speed