extends Node
class_name CollisionController

# Collision Model Controller (Spec 010)
# Handles rider-to-rider and rider-to-wall collisions

const RIDER_COLLISION_DISTANCE = 0.6  # meters
const WALL_COLLISION_FORCE = 500.0   # Newtons
const RIDER_SEPARATION_FORCE = 50.0   # Newtons (gentle repulsion)

# Collision state
var rider_collision_areas: Dictionary = {}  # racer_id -> Area3D

func _ready() -> void:
    # Set up collision areas for all riders
    _setup_collision_detection()

func _setup_collision_detection() -> void:
    """Create collision detection areas for riders"""
    # This would be called after riders are instantiated
    # For now, collision is handled in RiderController._physics_process
    pass

func check_rider_collisions(rider: CharacterBody3D, all_riders: Array) -> void:
    """
    Check for rider-to-rider collisions and apply separation forces.
    Called from RiderController._physics_process.
    """
    var rider_pos = rider.global_position
    var rider_id = rider.get_meta("racer_id", 0)

    for other_rider in all_riders:
        if other_rider == rider:
            continue

        var other_pos = other_rider.global_position
        var distance = rider_pos.distance_to(other_pos)

        if distance < RIDER_COLLISION_DISTANCE:
            # Apply gentle separation force
            var separation_direction = (rider_pos - other_pos).normalized()
            var separation_force = separation_direction * RIDER_SEPARATION_FORCE

            # Apply to both riders (equal and opposite)
            rider.velocity += separation_force * get_physics_process_delta_time() / rider.get_meta("mass", 85.0)
            other_rider.velocity -= separation_force * get_physics_process_delta_time() / other_rider.get_meta("mass", 85.0)

            # Optional: emit collision event
            EventBus.rider_collision.emit(rider_id, other_rider.get_meta("racer_id", 0))

func check_wall_collisions(rider: CharacterBody3D, track_path: Path3D) -> void:
    """
    Check for rider-to-wall collisions using track boundaries.
    Called from RiderController._physics_process.
    """
    if not track_path or not track_path.curve:
        return

    var rider_pos = rider.global_position

    # Project rider position onto track
    var offset = track_path.curve.get_closest_offset(rider_pos)
    var track_pos = track_path.curve.sample_baked(offset)

    # Calculate distance from track centerline
    var distance_from_track = rider_pos.distance_to(track_pos)

    # Track width is 8m total (4m each side)
    const TRACK_HALF_WIDTH = 4.0

    if distance_from_track > TRACK_HALF_WIDTH:
        # Rider is outside track boundary
        var wall_normal = (track_pos - rider_pos).normalized()
        var wall_force = wall_normal * WALL_COLLISION_FORCE

        # Apply wall collision force
        rider.velocity += wall_force * get_physics_process_delta_time() / rider.get_meta("mass", 85.0)

        # Reduce speed on wall contact
        rider.velocity *= 0.8  # 20% speed reduction

        # Optional: emit wall collision event
        EventBus.wall_collision.emit(rider.get_meta("racer_id", 0), rider_pos)

func get_rider_at_position(position: Vector3, all_riders: Array, exclude_rider = null) -> CharacterBody3D:
    """
    Find the rider closest to a position (for collision detection).
    """
    var closest_rider = null
    var closest_distance = 999999.0

    for rider in all_riders:
        if rider == exclude_rider:
            continue

        var distance = position.distance_to(rider.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest_rider = rider

    return closest_rider

# Utility functions for crash detection
func is_corner_crash_speed(rider: CharacterBody3D, track_path: Path3D) -> bool:
    """
    Check if rider is going too fast for a corner (Spec 010).
    """
    if not track_path:
        return false

    var rider_speed = rider.velocity.length()
    var progress = track_path.curve.get_closest_offset(rider.global_position) / track_path.curve.get_baked_length()

    # Check if in turn zone
    var in_turn = false
    for zone in [Vector2(0.22, 0.38), Vector2(0.72, 0.88)]:  # Turn zones
        if progress >= zone.x and progress <= zone.y:
            in_turn = true
            break

    if in_turn:
        var corner_speed_limit = 8.0  # m/s (~18 mph) in corners
        return rider_speed > corner_speed_limit

    return false