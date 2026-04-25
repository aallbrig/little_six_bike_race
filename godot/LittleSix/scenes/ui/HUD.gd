extends Control

var current_lap = 1
var total_laps = 50
var current_position = 3
var current_speed = 28
var sprint_energy = 85.0
var in_exchange_zone = false

func _ready() -> void:
    # Apply safe area handling for mobile devices
    _apply_safe_area_margins()

    EventBus.lap_completed.connect(_on_lap_completed)
    EventBus.racer_position_changed.connect(_on_position_changed)
    EventBus.sprint_activated.connect(_on_sprint_activated)
    EventBus.sprint_exhausted.connect(_on_sprint_exhausted)
    EventBus.pit_zone_entered.connect(_on_pit_zone_entered)
    EventBus.pit_zone_exited.connect(_on_pit_zone_exited)
    EventBus.riders_position_update.connect(_on_riders_position_update)

func _process(_delta: float) -> void:
    # Update speedometer from rider (simplified)
    $Speedometer.text = str(current_speed) + "\nMPH"

    # Update sprint bar
    $SprintBar.sprint_energy = sprint_energy

    # Update lap counter
    $TopBar/LapCounter.text = "LAP " + str(current_lap) + "/" + str(total_laps)

    # Update position
    $TopBar/Position.text = str(current_position) + ("rd" if current_position == 3 else "th")

func _on_lap_completed(_racer_id: int, lap_number: int, _lap_time: float) -> void:
    current_lap = lap_number

func _on_position_changed(_racer_id: int, new_position: int) -> void:
    current_position = new_position

func _on_sprint_activated(_racer_id: int) -> void:
    sprint_energy = 60.0  # Visual feedback

func _on_sprint_exhausted(_racer_id: int) -> void:
    sprint_energy = 0.0

func _on_pit_zone_entered(_racer_id: int) -> void:
    if _racer_id == 0:  # Local player
        $ExchangeZone.visible = true
        in_exchange_zone = true

func _on_pit_zone_exited(_racer_id: int) -> void:
    if _racer_id == 0:
        $ExchangeZone.visible = false
        in_exchange_zone = false

func _on_riders_position_update(rider_positions: Array) -> void:
    $Minimap.update_rider_positions(rider_positions)

# Called from input handler
func update_speed(speed_mph: float) -> void:
    current_speed = int(speed_mph)

func set_sprint_energy(energy: float) -> void:
    sprint_energy = energy

func _apply_safe_area_margins() -> void:
    # Safe area handling disabled for now to avoid autoload issues
    # if not SafeAreaManager.is_safe_area_supported():
    #     return
    #
    # var margins = SafeAreaManager.get_safe_margins()
    #
    # # For landscape race HUD, adjust right margin for notch
    # $RaceHUD.add_theme_constant_override("margin_right", margins.right + 8)
    #
    # # Position elements to avoid safe area
    # if margins.right > 0:
    #     # Move speedometer and minimap left to avoid right notch
    #     $RaceHUD/Speedometer.position.x -= margins.right * 0.5
    #     $RaceHUD/Minimap.position.x -= margins.right
    pass