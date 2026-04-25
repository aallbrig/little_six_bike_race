extends Node3D
class_name RaceTrack

# Manages the race track, camera, and riders

@onready var race_camera: RaceCamera = $RaceCamera
@onready var riders_container: Node3D = $Riders

var player_rider: Node3D = null

func _ready() -> void:
    # Find the player rider
    for child in riders_container.get_children():
        if child.has_meta("is_player") and child.get_meta("is_player"):
            player_rider = child
            break

    # Set camera target if we found the player
    if player_rider and race_camera:
        race_camera.set_target_rider(player_rider)

    # Connect to race events
    EventBus.race_started.connect(_on_race_started)

func _on_race_started() -> void:
    # Ensure camera is properly initialized
    if race_camera and player_rider:
        race_camera.set_target_rider(player_rider)

# Public API for external control
func get_race_camera() -> RaceCamera:
    return race_camera

func set_camera_mode(mode: RaceCamera.CameraMode, duration: float = 3.0) -> void:
    if race_camera:
        race_camera.set_camera_mode(mode, duration)