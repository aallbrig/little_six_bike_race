extends Node
class_name StartingGridController

# Starting Grid Generation Controller (Spec 010)

const START_POSITION = Vector3(-50.0, 0.0, 1.0)  # Track left edge at SF line
const RIDER_SPACING = 1.5  # meters between riders

func generate_starting_grid(qualifying_results: Array) -> Array[Vector3]:
    """
    Generate starting grid positions based on qualifying times.
    qualifying_results: Array of dicts with "racer_id" and "qualifying_time"
    Returns array of Vector3 positions.
    """
    if qualifying_results.size() == 0:
        return []

    # Sort by qualifying time (fastest first)
    var sorted_results = qualifying_results.duplicate()
    sorted_results.sort_custom(func(a, b):
        return a.get("qualifying_time", 999999.0) < b.get("qualifying_time", 999999.0)
    )

    var positions: Array[Vector3] = []

    # Single-file line before start/finish
    for i in range(sorted_results.size()):
        var pos = START_POSITION + Vector3(0, 0, i * RIDER_SPACING)
        positions.append(pos)

    return positions

func assign_grid_positions(riders: Array, qualifying_results: Array) -> void:
    """
    Assign starting positions to riders based on qualifying results.
    """
    var grid_positions = generate_starting_grid(qualifying_results)

    # Create mapping of racer_id to grid position
    var position_map = {}
    for i in range(min(qualifying_results.size(), grid_positions.size())):
        var racer_id = qualifying_results[i].get("racer_id", 0)
        position_map[racer_id] = grid_positions[i]

    # Position the riders
    for rider in riders:
        var racer_id = rider.get_meta("racer_id", 0)
        if racer_id in position_map:
            rider.global_position = position_map[racer_id]
            print("Rider ", racer_id, " starts at position ", position_map[racer_id])

func get_qualifying_results_for_testing() -> Array:
    """
    Generate mock qualifying results for testing.
    """
    return [
        {"racer_id": 0, "qualifying_time": 185.5},  # Fastest
        {"racer_id": 1, "qualifying_time": 187.2},
        {"racer_id": 2, "qualifying_time": 189.1},
        {"racer_id": 3, "qualifying_time": 191.8},
        {"racer_id": 4, "qualifying_time": 194.3},
        {"racer_id": 5, "qualifying_time": 196.7}   # Slowest
    ]