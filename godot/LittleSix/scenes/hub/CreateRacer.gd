extends Control

var current_step = 1
var racer_name = "My Racer"
var selected_background = 0
var selected_jersey = 0

func _ready() -> void:
    $BackButton.pressed.connect(_on_back_pressed)
    $Content/BeginButton.pressed.connect(_on_begin_pressed)
    
    # For demo purposes, auto-complete after a delay
    await get_tree().create_timer(3.0).timeout
    _complete_creation()

func _on_back_pressed() -> void:
    GameManager.transition_to(GameManager.GameState.TITLE)

func _on_begin_pressed() -> void:
    # In full version this would advance through 5 steps
    _complete_creation()

func _complete_creation() -> void:
    # Create player data
    var player = PlayerData.new()
    player.display_name = racer_name
    player.is_guest = true
    player.racer = RacerData.new()
    player.racer.name = racer_name
    player.current_season = SeasonData.new()
    
    SaveManager.player_data = player
    SaveManager.save_game()
    
    # Transition to main hub
    GameManager.transition_to(GameManager.GameState.MAIN_HUB)