extends CharacterBody3D
class_name RiderController

# Physics constants from Spec 010
const MASS = 85.0  # kg (rider + bike)
const ACCEL = 5.0  # m/s² desired acceleration when pedaling
const COAST_DECEL = 0.05  # m/s² rolling resistance
const BRAKE_DECEL = 7.0   # m/s² coaster brake
const MAX_SPEED = 12.0    # m/s (~27 mph) - terminal velocity
const DRAFT_BONUS = 0.3   # 30% drag reduction when drafting

# State
var is_pedaling = true
var is_braking = false
var is_sprinting = false
var sprint_energy = 100.0
var is_drafting = false
var current_speed = 0.0
var track_progress = 0.0  # 0-1 around the track
var racer_id = 0
var is_ai = false

# References
var draft_detector: Area3D

func _ready() -> void:
    # Setup collision
    collision_layer = 1
    collision_mask = 1

    # Create draft detector
    draft_detector = Area3D.new()
    var collision_shape = CollisionShape3D.new()
    var sphere = SphereShape3D.new()
    sphere.radius = 8.0  # Draft zone ~2 bike lengths
    collision_shape.shape = sphere
    draft_detector.add_child(collision_shape)
    add_child(draft_detector)
    draft_detector.area_entered.connect(_on_draft_area_entered)
    draft_detector.area_exited.connect(_on_draft_area_exited)

func _physics_process(delta: float) -> void:
    # Calculate forces per Spec 010
    var pedal_force = 0.0
    if is_pedaling and not is_braking:
        pedal_force = MASS * ACCEL

    var drag = 0.3 * current_speed * current_speed
    if is_drafting:
        drag *= (1.0 - DRAFT_BONUS)

    var rolling_resistance = MASS * 9.8 * 0.005  # μ_r = 0.005 for cinder

    var brake_force = 0.0
    if is_braking:
        brake_force = MASS * 9.8 * 0.7  # μ_b = 0.7 for coaster brake

    # Net force
    var net_force = pedal_force - drag - rolling_resistance - brake_force

    # Update velocity
    var acceleration = net_force / MASS
    current_speed = clamp(current_speed + acceleration * delta, 0.0, MAX_SPEED)

    # Apply movement
    if is_ai:
        _ai_steering(delta)
    else:
        _player_steering(delta)

    # Sprint energy management
    if is_sprinting:
        sprint_energy = max(0.0, sprint_energy - 25.0 * delta)
        if sprint_energy <= 0:
            is_sprinting = false
            EventBus.sprint_exhausted.emit(racer_id)
    elif sprint_energy < 100.0:
        sprint_energy = min(100.0, sprint_energy + 15.0 * delta)

    # Update track progress (simplified)
    track_progress = fmod(track_progress + (current_speed * delta * 0.01), 1.0)

    # Emit position updates for networking
    if not is_ai:
        EventBus.racer_position_changed.emit(racer_id, int(track_progress * 100))

func _player_steering(delta: float) -> void:
    # Player uses input for steering (tilt or buttons)
    var turn = 0.0
    if Input.is_action_pressed("steer_left"):
        turn = -1.0
    elif Input.is_action_pressed("steer_right"):
        turn = 1.0

    rotate_y(turn * 2.0 * delta)

    # Forward movement along facing direction
    var direction = -transform.basis.z
    velocity = direction * current_speed
    move_and_slide()

func _ai_steering(delta: float) -> void:
    # AI follows simple path with some randomness
    var target_speed = MAX_SPEED * 0.85
    current_speed = lerp(current_speed, target_speed, 0.1)

    # Simple AI steering - would use PathFollow3D in full implementation
    velocity = -transform.basis.z * current_speed
    move_and_slide()

func _on_draft_area_entered(area: Area3D) -> void:
    is_drafting = true

func _on_draft_area_exited(area: Area3D) -> void:
    is_drafting = false

func activate_sprint() -> void:
    if sprint_energy > 30.0 and not is_sprinting:
        is_sprinting = true
        current_speed = min(current_speed * 1.4, MAX_SPEED * 1.2)
        EventBus.sprint_activated.emit(racer_id)

func apply_brake() -> void:
    is_braking = true
    is_pedaling = false

func release_brake() -> void:
    is_braking = false
    is_pedaling = true

func get_speed_mph() -> float:
    return current_speed * 2.237  # m/s to mph

func reset_for_new_lap() -> void:
    sprint_energy = 100.0
    is_sprinting = false
    is_braking = false