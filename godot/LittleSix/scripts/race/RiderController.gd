extends CharacterBody3D
class_name RiderController

# Physics constants from Spec 010
const MAX_SPEED = 12.0    # m/s (~27 mph) - terminal velocity
const DRAFT_BONUS = 0.3   # 30% drag reduction when drafting

# State
var is_pedaling = true
var is_braking = false
var is_sprinting = false
var sprint_energy = 100.0
var is_drafting = false
var track_progress = 0.0  # 0-1 around the track
var racer_id = 0
var is_ai = false

# Physics system
var bike_physics: BikePhysics

# References
var draft_detector: Area3D
var collision_controller: CollisionController

func _ready() -> void:
    # Setup collision
    collision_layer = 1
    collision_mask = 1
    add_to_group("riders")

    # Get collision controller reference
    collision_controller = get_parent().get_node_or_null("CollisionController")

    # Initialize bike physics
    bike_physics = BikePhysics.new()
    add_child(bike_physics)

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
    # Update bike physics state
    bike_physics.is_pedaling = is_pedaling
    bike_physics.is_braking = is_braking

    # Apply drafting bonus to physics
    if is_drafting:
        # Temporarily reduce drag coefficient for drafting
        bike_physics.DRAG_COEFFICIENT = 0.3 * (1.0 - DRAFT_BONUS)
    else:
        bike_physics.DRAG_COEFFICIENT = 0.3

    # Update physics
    bike_physics.update_velocity(delta)
    current_speed = bike_physics.velocity

    # Clamp to max speed
    current_speed = min(current_speed, MAX_SPEED)

    # Apply movement
    if is_ai:
        _ai_steering(delta)
    else:
        _player_steering(delta)

    # Forward movement along facing direction
    var direction = -transform.basis.z
    velocity = direction * current_speed

    # Apply collision detection
    if collision_controller:
        var all_riders = get_tree().get_nodes_in_group("riders")
        collision_controller.check_rider_collisions(self, all_riders)
        collision_controller.check_wall_collisions(self, get_parent().get_node_or_null("TrackPath"))

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
    return bike_physics.get_speed_mph()

func reset_for_new_lap() -> void:
    sprint_energy = 100.0
    is_sprinting = false
    is_braking = false
    bike_physics.reset()