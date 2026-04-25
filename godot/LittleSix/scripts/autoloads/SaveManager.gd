extends Node

const SAVE_PATH := "user://save.json"

var player_data: PlayerData = null
var settings_data: SettingsData = null

func _ready() -> void:
    settings_data = SettingsData.new()  # Always initialize with defaults
    player_data = PlayerData.new()  # Always have a player data instance
    load_game()

func load_game() -> bool:
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        # No save file exists - keep the default player_data
        return false

    var json_string = file.get_as_text()
    file.close()

    var json = JSON.new()
    var error = json.parse(json_string)
    if error != OK:
        push_error("Failed to parse save file: " + json.get_error_message())
        # Keep the default player_data on parse error
        return false

    var data = json.get_data()
    if data.has("player"):
        # Deserialize PlayerData from dict
        player_data = PlayerData.from_dict(data.player)

    if data.has("settings"):
        # Deserialize SettingsData from dict
        settings_data.from_dict(data.settings)
    else:
        # Use defaults
        settings_data = SettingsData.new()

    return player_data != null

func save_game() -> void:
    var data = {}

    if player_data:
        data["player"] = player_data.to_dict()

    data["settings"] = settings_data.to_dict()

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

func get_setting(key: String, default: Variant = null) -> Variant:
    if settings_data:
        match key:
            "music_volume": return settings_data.music_volume
            "sfx_volume": return settings_data.sfx_volume
            "use_tilt_controls": return settings_data.use_tilt_controls
            "tilt_sensitivity": return settings_data.tilt_sensitivity
            "text_scale": return settings_data.text_scale
            "high_contrast": return settings_data.high_contrast
            "reduce_motion": return settings_data.reduce_motion
            "display_name": return settings_data.display_name
    return default

func set_setting(key: String, value: Variant) -> void:
    if settings_data:
        match key:
            "music_volume": settings_data.music_volume = value
            "sfx_volume": settings_data.sfx_volume = value
            "use_tilt_controls": settings_data.use_tilt_controls = value
            "tilt_sensitivity": settings_data.tilt_sensitivity = value
            "text_scale": settings_data.text_scale = value
            "high_contrast": settings_data.high_contrast = value
            "reduce_motion": settings_data.reduce_motion = value
        save_game()  # Auto-save settings

func export_save_json() -> String:
    var data = {}
    if player_data:
        data["player"] = player_data.to_dict()
    data["settings"] = settings_data.to_dict()
    return JSON.stringify(data)

func import_save_json(json: String) -> void:
    var json_parser = JSON.new()
    var error = json_parser.parse(json)
    if error != OK:
        push_error("Failed to parse imported save: " + json_parser.get_error_message())
        return

    var data = json_parser.get_data()
    if data.has("player"):
        player_data = PlayerData.from_dict(data.player)
    if data.has("settings"):
        settings_data.from_dict(data.settings)
    save_game()