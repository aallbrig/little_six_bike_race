extends CanvasLayer
class_name Lobby

# Lobby screen for Little Six multiplayer (Spec 005)
# Manages player slots, ready states, and race start

@onready var lobby_id_label: Label = $Panel/VBoxContainer/Header/LobbyIdLabel
@onready var race_type_label: Label = $Panel/VBoxContainer/RaceTypeLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var ready_button: Button = $Panel/VBoxContainer/Controls/ReadyButton
@onready var start_button: Button = $Panel/VBoxContainer/Controls/StartButton
@onready var player_slots: Array = [
	$Panel/VBoxContainer/PlayerList/PlayerSlot1,
	$Panel/VBoxContainer/PlayerList/PlayerSlot2,
	$Panel/VBoxContainer/PlayerList/PlayerSlot3,
	$Panel/VBoxContainer/PlayerList/PlayerSlot4,
	$Panel/VBoxContainer/PlayerList/PlayerSlot5,
	$Panel/VBoxContainer/PlayerList/PlayerSlot6,
	$Panel/VBoxContainer/PlayerList/PlayerSlot7,
	$Panel/VBoxContainer/PlayerList/PlayerSlot8
]

var _lobby_data: Dictionary = {}
var _is_ready: bool = false
var _is_host: bool = false

func _ready() -> void:
	# Connect to network events
	NetworkMgr.lobby_state_changed.connect(_on_lobby_state_changed)
	NetworkMgr.race_starting.connect(_on_race_starting)

	# Initialize player slots
	for slot in player_slots:
		slot.set_player_data("", false, false)  # Empty slot

func update_lobby_info(lobby_data: Dictionary) -> void:
	"""Update lobby display with new data"""
	_lobby_data = lobby_data
	_is_host = lobby_data.get("is_host", false)

	# Update labels
	var lobby_id = lobby_data.get("lobby_id", "UNKNOWN")
	lobby_id_label.text = "ID: " + lobby_id.substr(lobby_id.length() - 6)  # Last 6 chars

	var race_type = lobby_data.get("race_type", "Unknown")
	race_type_label.text = "Race: " + race_type

	# Update player slots
	var players = lobby_data.get("players", [])
	for i in range(player_slots.size()):
		if i < players.size():
			var player = players[i]
			var is_local = player.get("is_local", false)
			var is_ready = player.get("ready", false)
			player_slots[i].set_player_data(player.get("name", "Player"), is_ready, is_local)
		else:
			player_slots[i].set_player_data("", false, false)  # Empty

	# Update controls
	_update_controls(lobby_data)

func _update_controls(lobby_data: Dictionary) -> void:
	"""Update control buttons based on lobby state"""
	var players = lobby_data.get("players", [])
	var ready_count = 0
	var total_players = 0

	for player in players:
		total_players += 1
		if player.get("ready", false):
			ready_count += 1

	# Ready button
	ready_button.text = "READY" if not _is_ready else "NOT READY"
	ready_button.disabled = false

	# Start button (host only)
	start_button.visible = _is_host
	if _is_host:
		var all_ready = ready_count >= total_players and total_players >= 2
		start_button.disabled = not all_ready
		start_button.text = "START RACE" if all_ready else "WAITING..."

	# Status
	if _is_host:
		status_label.text = "You are the host. " + str(ready_count) + "/" + str(total_players) + " ready"
	else:
		status_label.text = str(ready_count) + "/" + str(total_players) + " players ready"

func _on_lobby_state_changed(lobby_data: Dictionary) -> void:
	"""Handle lobby state updates"""
	update_lobby_info(lobby_data)

func _on_race_starting(lobby_id: String, race_config: Dictionary) -> void:
	"""Handle race starting"""
	hide()
	# Transition to race scene would happen here

func _on_ready_pressed() -> void:
	"""Toggle ready state"""
	_is_ready = not _is_ready
	NetworkMgr.set_player_ready(_is_ready)

	# Update button text immediately for responsiveness
	ready_button.text = "READY" if not _is_ready else "NOT READY"

func _on_leave_pressed() -> void:
	"""Leave the lobby"""
	NetworkMgr.leave_lobby()
	hide()
	# Return to main menu

func _on_start_pressed() -> void:
	"""Start the race (host only)"""
	if _is_host:
		NetworkMgr.start_race()

func show_lobby(lobby_data: Dictionary) -> void:
	"""Show the lobby with initial data"""
	update_lobby_info(lobby_data)
	show()

func hide_lobby() -> void:
	"""Hide the lobby"""
	hide()