extends Control

func _ready() -> void:
    # Start the logo animation
    $AnimationPlayer.play("show")

    # Wait for animation to complete then transition
    await $AnimationPlayer.animation_finished
    GameManager.transition_to(GameManager.GameState.CINEMATIC)