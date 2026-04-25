extends Node3D
class_name RaceCamera

# Dynamic camera system for Little Six racing
# Supports multiple camera modes with automatic switching during key moments

enum CameraMode {
    CHASE,      # Standard follow camera
    ACTION,     # Dynamic angles during sprints
    CINEMATIC,  # Dramatic shots for highlights
    POV,        # First-person view
    SPECTATOR,  # Overview of the pack
    MANUAL      # Player-controlled mode
}

signal camera_mode_changed(new_mode: CameraMode)

@export var target_rider: Node3D = null
@export var camera_mode: CameraMode = CameraMode.CHASE
@export var smooth_speed: float = 3.0
@export var look_ahead_distance: float = 5.0

# Camera mode configurations
@export_group("Chase Camera")
@export var chase_distance: float = 8.0
@export var chase_height: float = 4.0
@export var chase_angle: float = 15.0

@export_group("Action Camera")
@export var action_distance: float = 6.0
@export var action_height: float = 2.0
@export var action_angle: float = 10.0

@export_group("Cinematic Camera")
@export var cinematic_distance: float = 12.0
@export var cinematic_height: float = 8.0
@export var cinematic_angle: float = 25.0

@export_group("POV Camera")
@export var pov_offset: Vector3 = Vector3(0, 1.7, -0.5)

@export_group("Spectator Camera")
@export var spectator_distance: float = 20.0
@export var spectator_height: float = 15.0

var _camera: Camera3D
var _current_mode: CameraMode = CameraMode.CHASE
var _mode_timer: float = 0.0
var _auto_switch_timer: float = 0.0
var _target_position: Vector3
var _target_rotation: Vector3

# Camera priorities for automatic switching (higher = more important)
const CAMERA_PRIORITIES = {
    CameraMode.CINEMATIC: 100,
    CameraMode.ACTION: 80,
    CameraMode.POV: 60,
    CameraMode.CHASE: 40,
    CameraMode.SPECTATOR: 20,
    CameraMode.MANUAL: 0
}

func _ready() -> void:
    _camera = $Camera3D
    if not _camera:
        _camera = Camera3D.new()
        add_child(_camera)
        _camera.name = "Camera3D"

    # Connect to race events for automatic camera switching
    EventBus.race_started.connect(_on_race_started)
    EventBus.sprint_button_pressed.connect(_on_sprint_pressed)
    EventBus.lap_completed.connect(_on_lap_completed)
    EventBus.race_finished.connect(_on_race_finished)
    EventBus.bell_lap_triggered.connect(_on_bell_lap)
    EventBus.crash_occurred.connect(_on_crash_occurred)
    EventBus.exchange_button_tapped.connect(_on_exchange_tapped)

    _current_mode = camera_mode
    _update_camera_transform()

func _process(delta: float) -> void:
    if not target_rider:
        return

    _mode_timer -= delta
    _auto_switch_timer -= delta

    # Auto-switch back to chase camera after cinematic moments
    if _mode_timer <= 0 and _current_mode in [CameraMode.CINEMATIC, CameraMode.ACTION, CameraMode.POV]:
        if _auto_switch_timer <= 0:
            set_camera_mode(CameraMode.CHASE)

    # Smooth camera movement
    _update_camera_transform()
    _smooth_camera_movement(delta)

func set_camera_mode(new_mode: CameraMode, duration: float = 3.0) -> void:
    if new_mode == _current_mode:
        return

    # Check if new mode has higher priority
    if CAMERA_PRIORITIES[new_mode] <= CAMERA_PRIORITIES[_current_mode] and _current_mode != CameraMode.CHASE:
        return

    _current_mode = new_mode
    _mode_timer = duration
    _auto_switch_timer = duration + 2.0  # Extra time before auto-switch

    camera_mode_changed.emit(new_mode)
    _update_camera_transform()

func _update_camera_transform() -> void:
    if not target_rider:
        return

    var rider_pos = target_rider.global_position
    var rider_forward = target_rider.global_transform.basis.z.normalized()
    var rider_velocity = Vector3.ZERO

    # Try to get rider velocity if available
    if target_rider.has_method("get_velocity"):
        rider_velocity = target_rider.get_velocity()

    match _current_mode:
        CameraMode.CHASE:
            _target_position = rider_pos - rider_forward * chase_distance + Vector3.UP * chase_height
            _target_position += rider_forward * look_ahead_distance * rider_velocity.length() * 0.1
            look_at(rider_pos + rider_forward * 5.0)

        CameraMode.ACTION:
            _target_position = rider_pos - rider_forward * action_distance + Vector3.UP * action_height
            _target_position += rider_forward * look_ahead_distance * 1.5  # More aggressive look-ahead
            look_at(rider_pos + rider_forward * 8.0)

        CameraMode.CINEMATIC:
            _target_position = rider_pos - rider_forward * cinematic_distance + Vector3.UP * cinematic_height
            look_at(rider_pos + rider_forward * 3.0)

        CameraMode.POV:
            _target_position = rider_pos + pov_offset
            look_at(rider_pos + rider_forward * 10.0)

        CameraMode.SPECTATOR:
            _target_position = rider_pos + Vector3(0, spectator_height, -spectator_distance)
            look_at(rider_pos)

        CameraMode.MANUAL:
            # Don't update target position, allow manual control
            pass

func _smooth_camera_movement(delta: float) -> void:
    if _current_mode == CameraMode.MANUAL:
        return

    # Smooth position interpolation
    global_position = global_position.lerp(_target_position, smooth_speed * delta)

    # Smooth rotation interpolation
    var target_basis = Basis.looking_at((_target_position - global_position).normalized())
    transform.basis = transform.basis.slerp(target_basis, smooth_speed * delta)

# Event handlers for automatic camera switching
func _on_race_started() -> void:
    set_camera_mode(CameraMode.CINEMATIC, 5.0)  # Dramatic start

func _on_sprint_pressed(pressed: bool) -> void:
    if pressed:
        set_camera_mode(CameraMode.ACTION, 2.0)  # Exciting sprint view

func _on_lap_completed(racer_id: int, lap_number: int, lap_time: float) -> void:
    if lap_number >= 45:  # Final laps
        set_camera_mode(CameraMode.CINEMATIC, 3.0)

func _on_race_finished(results: Array) -> void:
    set_camera_mode(CameraMode.CINEMATIC, 8.0)  # Victory celebration

func _on_bell_lap() -> void:
    set_camera_mode(CameraMode.CINEMATIC, 4.0)  # Bell lap drama

func _on_crash_occurred(racer_id: int) -> void:
    if target_rider and target_rider.has_meta("racer_id") and target_rider.get_meta("racer_id") == racer_id:
        set_camera_mode(CameraMode.ACTION, 2.0)  # Show the crash

func _on_exchange_tapped() -> void:
    set_camera_mode(CameraMode.SPECTATOR, 3.0)  # Show the exchange from above

# Public API
func get_current_mode() -> CameraMode:
    return _current_mode

func set_target_rider(rider: Node3D) -> void:
    target_rider = rider

# Mobile touch controls for camera (if needed)
func _input(event: InputEvent) -> void:
    if event is InputEventScreenDrag and _current_mode == CameraMode.MANUAL:
        # Allow manual camera control on mobile
        var sensitivity = 0.01
        rotate_y(event.relative.x * sensitivity)
        rotate_x(event.relative.y * sensitivity)
        rotation.x = clamp(rotation.x, -PI/3, PI/3)