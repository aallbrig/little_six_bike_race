extends Control

var current_lap = 1
var total_laps = 50
var current_position = 3
var current_speed = 28
var sprint_energy = 85.0
var in_exchange_zone = false

func _ready() -> void:
    EventBus.lap_completed.connect(_on_lap_completed)
    EventBus.racer_position_changed.connect(_on_position_changed)
    EventBus.sprint_activated.connect(_on_sprint_activated)
    EventBus.sprint_exhausted.connect(_on_sprint_exhausted)
    EventBus.pit_zone_entered.connect(_on_pit_zone_entered)
    EventBus.pit_zone_exited.connect(_on_pit_zone_exited)

func _process(_delta: float) -> void:
    # Update speedometer from rider (simplified)
    $Speedometer.text = str(current_speed) + "\nMPH"

    # Update sprint bar
    $SprintBar.value = sprint_energy

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

# Called from input handler
func update_speed(speed_mph: float) -> void:
    current_speed = int(speed_mph)

func set_sprint_energy(energy: float) -> void:
    sprint_energy = energy