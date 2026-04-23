extends Node3D

var riders = []
var lap_count = 0
const TOTAL_LAPS = 50

func _ready() -> void:
    # Spawn 6 riders (1 player, 5 AI)
    _spawn_riders()
    
    EventBus.race_started.connect(_on_race_started)
    EventBus.lap_completed.connect(_on_lap_completed)

func _spawn_riders() -> void:
    var rider_scene = load("res://scenes/race/Rider.tscn")
    if not rider_scene:
        # Create placeholder rider if scene doesn't exist yet
        _create_placeholder_riders()
        return
    
    for i in range(6):
        var rider = rider_scene.instantiate()
        rider.racer_id = i
        rider.is_ai = (i > 0)
        rider.position = Vector3(i * 2.0 - 5.0, 0.5, -20 + i * 2.0)
        $Riders.add_child(rider)
        riders.append(rider)

func _create_placeholder_riders() -> void:
    # Create simple CharacterBody3D riders for testing
    for i in range(6):
        var rider = CharacterBody3D.new()
        rider.name = "Rider" + str(i)
        rider.racer_id = i
        rider.is_ai = (i > 0)
        rider.position = Vector3(i * 2.0 - 5.0, 0.5, -20 + i * 2.0)
        
        var mesh = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(1, 1, 2)
        mesh.mesh = box
        rider.add_child(mesh)
        
        $Riders.add_child(rider)
        riders.append(rider)

func _on_race_started() -> void:
    lap_count = 0
    print("Race started - ", riders.size(), " riders on track")

func _on_lap_completed(racer_id: int, lap_number: int, lap_time: float) -> void:
    if lap_number > lap_count:
        lap_count = lap_number
        if lap_count >= TOTAL_LAPS:
            _finish_race()

func _finish_race() -> void:
    var results = []
    for rider in riders:
        var result = RaceResult.new()
        result.racer_id = rider.racer_id
        result.position = randi() % 6 + 1
        result.total_time = 180.0 + randf() * 30.0
        results.append(result)
    
    results.sort_custom(func(a, b): return a.position < b.position)
    EventBus.race_finished.emit(results)

# Called by GameManager when entering RACE_ACTIVE state
func start_race() -> void:
    EventBus.race_started.emit()
    
    # Add HUD
    var hud_scene = load("res://scenes/ui/HUD.tscn")
    if hud_scene:
        var hud = hud_scene.instantiate()
        add_child(hud)
    
    # Start AI riders
    for rider in riders:
        if rider.is_ai:
            rider.is_pedaling = true
    
    print("Race started with HUD and physics simulation")

func get_leader() -> Node:
    if riders.is_empty():
        return null
    return riders[0]  # Simplified - would calculate by track progress in full version