extends Control

var player_slots = []

func _ready() -> void:
	player_slots = $PlayerSlots.get_children()
	$ReadyButton.pressed.connect(_on_ready_pressed)
	$BackButton.pressed.connect(_on_back_pressed)

	EventBus.player_joined_room.connect(_on_player_joined)
	EventBus.player_left_room.connect(_on_player_left)

	# Send JOIN_ROOM
	NetworkMgr.ws_client.send("JOIN_ROOM", {})

func _on_player_joined(player_id: int, player_name: String) -> void:
	for i in player_slots.size():
		if player_slots[i].player_id == -1:
			player_slots[i].set_player(player_id, player_name)
			break

func _on_player_left(player_id: int) -> void:
	for slot in player_slots:
		if slot.player_id == player_id:
			slot.clear_player()
			break

func _on_ready_pressed() -> void:
	NetworkMgr.ws_client.send("PLAYER_READY", {"ready": true})
	$ReadyButton.text = "Waiting..."

func _on_back_pressed() -> void:
	GameManager.transition_to(GameManager.GameState.MAIN_HUB)