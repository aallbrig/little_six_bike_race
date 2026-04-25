extends Node3D

var riders = []
var race_controller

func _ready() -> void:
    # Create race controller
    var RaceControllerScript = load("res://scripts/race/RaceController.gd")
    race_controller = RaceControllerScript.new()
    add_child(race_controller)

    # Spawn 6 riders (1 player, 5 AI)
    _spawn_riders()

    # Connect start/finish line
    $StartFinishLine.body_entered.connect(_on_start_finish_line_crossed)

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
        rider.set_meta("racer_id", i)
        rider.set_meta("is_ai", i > 0)
        rider.position = Vector3(i * 2.0 - 5.0, 0.5, -20 + i * 2.0)
        $Riders.add_child(rider)
        riders.append(rider)
        race_controller.add_rider(rider)

func _create_placeholder_riders() -> void:
    # Create simple CharacterBody3D riders for testing
    for i in range(6):
        var rider = CharacterBody3D.new()
        rider.name = "Rider" + str(i)
        rider.set_meta("racer_id", i)
        rider.set_meta("is_ai", i > 0)
        rider.position = Vector3(i * 2.0 - 5.0, 0.5, -20 + i * 2.0)

        var mesh = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(1, 1, 2)
        mesh.mesh = box
        rider.add_child(mesh)

        $Riders.add_child(rider)
        riders.append(rider)
        race_controller.add_rider(rider)

func _on_race_started() -> void:
    print("Race started - ", riders.size(), " riders on track")

var _rider_last_lap = {}  # Track last lap crossing to prevent multiple triggers

func _on_start_finish_line_crossed(body: Node3D) -> void:
    if not race_controller or not race_controller.race_started or race_controller.race_finished:
        return

    if not body is CharacterBody3D:
        return

    var racer_id = body.get_meta("racer_id", -1)
    if racer_id == -1:
        return

    # Check if this rider has already crossed this lap (prevent multiple triggers)
    var current_lap = race_controller.rider_laps.get(racer_id, 0)
    if _rider_last_lap.get(racer_id, -1) >= current_lap:
        return

    _rider_last_lap[racer_id] = current_lap

    # Calculate lap time
    var lap_time = race_controller.get_race_time()  # Simplified

    # Trigger lap completion
    EventBus.lap_completed.emit(racer_id, current_lap + 1, lap_time)

func _on_lap_completed(racer_id: int, lap_number: int, lap_time: float) -> void:
    # Race controller handles lap completion
    pass

# Called by GameManager when entering RACE_ACTIVE state
func start_race() -> void:
    race_controller.start_race()

    # Add HUD
    var hud_scene = load("res://scenes/ui/HUD.tscn")
    if hud_scene:
        var hud = hud_scene.instantiate()
        add_child(hud)

    # Start AI riders
    for rider in riders:
        if rider.get_meta("is_ai", false):
            rider.set_meta("is_pedaling", true)

    print("Race started with HUD and physics simulation")

func get_leader() -> Node:
    if riders.is_empty():
        return null
    return riders[0]  # Simplified - would calculate by track progress in full version