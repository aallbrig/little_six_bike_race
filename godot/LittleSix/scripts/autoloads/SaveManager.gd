extends Node

const SAVE_PATH = "user://save.json"

var player_data = null  # Will hold PlayerData dict for now
var settings_data = {
    "music_volume": 0.8,
    "sfx_volume": 1.0,
    "use_tilt_controls": true,
    "tilt_sensitivity": 1.0,
    "text_scale": "M",
    "high_contrast": false,
    "reduce_motion": false
}

func _ready() -> void:
    load_game()

func load_game() -> bool:
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        # No save file exists
        player_data = null
        return false

    var json_string = file.get_as_text()
    file.close()

    var json = JSON.new()
    var error = json.parse(json_string)
    if error != OK:
        push_error("Failed to parse save file: " + json.get_error_message())
        player_data = null
        return false

    var data = json.get_data()
    if data.has("player"):
        player_data = data.player  # Store as dict for now

    if data.has("settings"):
        settings_data = data.settings

    return player_data != null

func save_game() -> void:
    var data = {}

    if player_data:
        data["player"] = player_data  # Store as dict for now

    data["settings"] = settings_data

    var json_string = JSON.stringify(data, "\t")

    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(json_string)
        file.close()
    else:
        push_error("Failed to save game to: " + SAVE_PATH)

func wipe_save() -> void:
    var dir = DirAccess.open("user://")
    if dir.file_exists("save.json"):
        dir.remove("save.json")
    player_data = null

func get_setting(key: String, default = null):
    return settings_data.get(key, default)

func set_setting(key: String, value) -> void:
    settings_data[key] = value
    save_game()  # Auto-save settings