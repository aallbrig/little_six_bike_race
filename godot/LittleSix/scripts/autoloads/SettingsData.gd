class_name SettingsData
extends Resource

@export var music_volume: float = 0.8	   # 0.0–1.0
@export var sfx_volume: float = 1.0
@export var use_tilt_controls: bool = true
@export var tilt_sensitivity: float = 1.0	# 0.5–2.0
@export var text_scale: String = "M"		# "S", "M", "L"
@export var high_contrast: bool = false
@export var reduce_motion: bool = false
@export var display_name: String = ""		# Player's display name

func to_dict() -> Dictionary:
	return {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"use_tilt_controls": use_tilt_controls,
		"tilt_sensitivity": tilt_sensitivity,
		"text_scale": text_scale,
		"high_contrast": high_contrast,
		"reduce_motion": reduce_motion,
		"display_name": display_name
	}

func from_dict(d: Dictionary) -> void:
	music_volume = d.get("music_volume", 0.8)
	sfx_volume = d.get("sfx_volume", 1.0)
	use_tilt_controls = d.get("use_tilt_controls", true)
	tilt_sensitivity = d.get("tilt_sensitivity", 1.0)
	text_scale = d.get("text_scale", "M")
	high_contrast = d.get("high_contrast", false)
	reduce_motion = d.get("reduce_motion", false)
	display_name = d.get("display_name", "")