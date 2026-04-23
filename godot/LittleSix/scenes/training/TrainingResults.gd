extends Control

func _ready() -> void:
    $ContinueButton.pressed.connect(_on_continue_pressed)
    
    # In full version this would display actual training summary from EventBus

func _on_continue_pressed() -> void:
    GameManager.transition_to(GameManager.GameState.MAIN_HUB)