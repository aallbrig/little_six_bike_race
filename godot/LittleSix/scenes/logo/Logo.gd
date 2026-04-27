extends Control

func _ready() -> void:
	# Start the logo animation
	$AnimationPlayer.play("show")

	# Wait for animation to complete then transition
	await $AnimationPlayer.animation_finished

	# Ensure GameManager is ready (autoloads initialize in order)
	await get_tree().process_frame
	if GameManager:
		GameManager.transition_to(GameManager.GameState.CINEMATIC)
	else:
		push_error("GameManager not found - autoload failed to initialize")