## SaveManager — Local JSON save/load. Mirrors to server when online.
extends Node

const SAVE_PATH := "user://save.json"
const SCHEMA_VERSION := 1

var player_data = null   # PlayerData resource
var settings_data = null # SettingsData resource

# Default settings
const DEFAULT_SETTINGS := {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"use_tilt": true,
	"tilt_sensitivity": 1.0,
	"text_scale": "M",
	"high_contrast": false,
	"reduce_motion": false,
	"auth_token": "",
	"last_play_date": "",
	"qual_pb": 999999.0,
}

var _settings: Dictionary = {}
var _save_dirty: bool = false


func _ready() -> void:
	_settings = DEFAULT_SETTINGS.duplicate()
	load_game()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot open save file")
		return false

	var text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if data == null:
		push_error("SaveManager: invalid save JSON")
		return false

	# Load settings
	if data.has("settings"):
		for key in data["settings"]:
			_settings[key] = data["settings"][key]

	# Load player data
	if data.has("player") and data.has("racer"):
		player_data = _parse_player(data)
		if player_data:
			GameManager.current_player = player_data

	return player_data != null


func save_game() -> void:
	var data := {
		"schema_version": SCHEMA_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"settings": _settings,
	}

	if player_data != null:
		data["player"] = _serialize_player(player_data)
		if player_data.racer:
			data["racer"] = _serialize_racer(player_data.racer)
		if player_data.current_season:
			data["season"] = _serialize_season(player_data.current_season)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write save file")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_save_dirty = false


func wipe_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	player_data = null
	_settings = DEFAULT_SETTINGS.duplicate()
	GameManager.current_player = null


func get_setting(key: String, default: Variant = null) -> Variant:
	return _settings.get(key, default if default != null else DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	save_game()  # Auto-save settings immediately


func export_save_json() -> String:
	var data := {
		"schema_version": SCHEMA_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
	}
	if player_data != null:
		data["player"] = _serialize_player(player_data)
		if player_data.racer:
			data["racer"] = _serialize_racer(player_data.racer)
	return JSON.stringify(data)


# ── Serialization helpers ─────────────────────────────────────────────────

func _serialize_player(p) -> Dictionary:
	return {
		"player_id": p.player_id,
		"display_name": p.display_name,
		"is_guest": p.is_guest,
		"cred_points": p.cred_points,
		"elo_rating": p.elo_rating,
		"career_wins": p.career_wins,
		"career_races": p.career_races,
		"unlocked_cosmetics": p.unlocked_cosmetics,
	}


func _serialize_racer(r) -> Dictionary:
	return {
		"name": r.name,
		"jersey_color_id": r.jersey_color_id,
		"background": r.background,
		"speed": r.speed,
		"endurance": r.endurance,
		"recovery": r.recovery,
		"handling": r.handling,
		"team_chem": r.team_chem,
		"fatigue": r.fatigue,
		"morale": r.morale,
		"is_injured": r.is_injured,
		"injury_days_remaining": r.injury_days_remaining,
	}


func _serialize_season(s) -> Dictionary:
	return {
		"season_id": s.season_id,
		"current_week": s.current_week,
		"current_day": s.current_day,
		"is_race_week": s.is_race_week,
		"qualifying_time": s.qualifying_time,
		"qualifying_position": s.qualifying_position,
	}


func _parse_player(data: Dictionary):
	# Returns a PlayerData-like dictionary (full Resource class added in Spec 003)
	# For now, returns a plain Dictionary that GameManager can use
	# TODO: Replace with proper PlayerData.from_dict() when Resource classes exist
	var p = {
		"player_id": data["player"].get("player_id", ""),
		"display_name": data["player"].get("display_name", "Rider"),
		"is_guest": data["player"].get("is_guest", true),
		"cred_points": data["player"].get("cred_points", 0),
		"elo_rating": data["player"].get("elo_rating", 1000),
		"career_wins": data["player"].get("career_wins", 0),
		"career_races": data["player"].get("career_races", 0),
		"unlocked_cosmetics": data["player"].get("unlocked_cosmetics", []),
	}
	return p
