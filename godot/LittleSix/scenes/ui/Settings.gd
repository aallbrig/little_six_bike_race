extends CanvasLayer
class_name Settings

# Settings UI management with persistence

@onready var music_slider: HSlider = $Panel/ScrollContainer/VBoxContainer/AudioSection/MusicVolume/MusicSlider
@onready var music_value: Label = $Panel/ScrollContainer/VBoxContainer/AudioSection/MusicVolume/MusicValue
@onready var sfx_slider: HSlider = $Panel/ScrollContainer/VBoxContainer/AudioSection/SFXVolume/SFXSlider
@onready var sfx_value: Label = $Panel/ScrollContainer/VBoxContainer/AudioSection/SFXVolume/SFXValue

@onready var tilt_checkbox: CheckBox = $Panel/ScrollContainer/VBoxContainer/ControlsSection/TiltControls/TiltCheckBox
@onready var sensitivity_slider: HSlider = $Panel/ScrollContainer/VBoxContainer/ControlsSection/TiltSensitivity/SensitivitySlider
@onready var sensitivity_value: Label = $Panel/ScrollContainer/VBoxContainer/ControlsSection/TiltSensitivity/SensitivityValue

@onready var scale_small_btn: Button = $Panel/ScrollContainer/VBoxContainer/DisplaySection/TextScale/ScaleSmallButton
@onready var scale_medium_btn: Button = $Panel/ScrollContainer/VBoxContainer/DisplaySection/TextScale/ScaleMediumButton
@onready var scale_large_btn: Button = $Panel/ScrollContainer/VBoxContainer/DisplaySection/TextScale/ScaleLargeButton
@onready var contrast_checkbox: CheckBox = $Panel/ScrollContainer/VBoxContainer/DisplaySection/HighContrast/ContrastCheckBox
@onready var motion_checkbox: CheckBox = $Panel/ScrollContainer/VBoxContainer/DisplaySection/ReduceMotion/MotionCheckBox

@onready var name_input: LineEdit = $Panel/ScrollContainer/VBoxContainer/AccountSection/DisplayName/NameInput
@onready var player_id_label: Label = $Panel/ScrollContainer/VBoxContainer/AccountSection/PlayerID/IDValue
@onready var version_label: Label = $Panel/ScrollContainer/VBoxContainer/AboutSection/Version/VersionValue

var current_text_scale: String = "medium"

func _ready() -> void:
	# Apply safe area margins for mobile (disabled for now)
	# if SafeAreaManager.is_safe_area_supported():
	# 	SafeAreaManager.apply_safe_area_to_container($Panel/ScrollContainer)

	# Load saved settings
	load_settings()

	# Update version from project
	version_label.text = ProjectSettings.get_setting("application/config/version", "1.0.0")

	# Generate player ID (simplified)
	player_id_label.text = generate_player_id()

	# Connect to SaveManager for persistence
	SaveManager.setting_changed.connect(_on_setting_changed)

func load_settings() -> void:
	# Audio settings
	var music_vol = SaveManager.get_setting("audio.music_volume", 0.7)
	music_slider.value = music_vol
	music_value.text = str(int(music_vol * 100)) + "%"

	var sfx_vol = SaveManager.get_setting("audio.sfx_volume", 0.8)
	sfx_slider.value = sfx_vol
	sfx_value.text = str(int(sfx_vol * 100)) + "%"

	# Control settings
	var use_tilt = SaveManager.get_setting("controls.use_tilt", true)
	tilt_checkbox.button_pressed = use_tilt
	sensitivity_slider.editable = use_tilt

	var tilt_sens = SaveManager.get_setting("controls.tilt_sensitivity", 1.0)
	sensitivity_slider.value = tilt_sens
	sensitivity_value.text = str(tilt_sens) + "×"

	# Display settings
	current_text_scale = SaveManager.get_setting("display.text_scale", "medium")
	update_text_scale_buttons()

	contrast_checkbox.button_pressed = SaveManager.get_setting("display.high_contrast", false)
	motion_checkbox.button_pressed = SaveManager.get_setting("display.reduce_motion", false)

	# Account settings
	name_input.text = SaveManager.get_setting("account.display_name", "")

func update_text_scale_buttons() -> void:
	scale_small_btn.button_pressed = (current_text_scale == "small")
	scale_medium_btn.button_pressed = (current_text_scale == "medium")
	scale_large_btn.button_pressed = (current_text_scale == "large")

func generate_player_id() -> String:
	# Generate a simple 6-character player ID
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var id = ""
	for i in range(6):
		id += chars[randi() % chars.length()]
	return id

# Audio handlers
func _on_music_volume_changed(value: float) -> void:
	music_value.text = str(int(value * 100)) + "%"
	SaveManager.set_setting("audio.music_volume", value)
	AudioManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	sfx_value.text = str(int(value * 100)) + "%"
	SaveManager.set_setting("audio.sfx_volume", value)
	AudioManager.set_sfx_volume(value)

func _on_test_sfx_pressed() -> void:
	AudioManager.play_sfx("ui_click")

# Control handlers
func _on_tilt_controls_toggled(enabled: bool) -> void:
	SaveManager.set_setting("controls.use_tilt", enabled)
	sensitivity_slider.editable = enabled

func _on_tilt_sensitivity_changed(value: float) -> void:
	sensitivity_value.text = str(value) + "×"
	SaveManager.set_setting("controls.tilt_sensitivity", value)

func _on_test_tilt_pressed() -> void:
	# Show current device tilt (simplified)
	var accel = Input.get_accelerometer()
	if accel.length() > 0:
		var tilt_x = rad_to_deg(atan2(accel.x, accel.y))
		var tilt_y = rad_to_deg(atan2(accel.z, accel.y))
		print("Current tilt: X=", tilt_x, "°, Y=", tilt_y, "°")
	else:
		print("Accelerometer not available")

# Display handlers
func _on_text_scale_selected(scale: String) -> void:
	current_text_scale = scale
	SaveManager.set_setting("display.text_scale", scale)
	update_text_scale_buttons()

func _on_high_contrast_toggled(enabled: bool) -> void:
	SaveManager.set_setting("display.high_contrast", enabled)

func _on_reduce_motion_toggled(enabled: bool) -> void:
	SaveManager.set_setting("display.reduce_motion", enabled)

# Account handlers
func _on_display_name_changed(new_name: String) -> void:
	SaveManager.set_setting("account.display_name", new_name)

func _on_save_name_pressed() -> void:
	var name = name_input.text.strip_edges()
	if name.length() > 0:
		SaveManager.set_setting("account.display_name", name)
		# Show success feedback
		print("Display name saved: ", name)
	else:
		print("Display name cannot be empty")

func _on_sign_out_pressed() -> void:
	# Show confirmation dialog
	var confirm = preload("res://scenes/ui/components/ConfirmDialog.tscn").instantiate()
	confirm.title = "Sign Out"
	confirm.message = "You'll lose access to your cloud progress. Continue?"
	confirm.confirmed.connect(_do_sign_out)
	add_child(confirm)

func _do_sign_out() -> void:
	# Clear cloud data (simplified)
	SaveManager.set_setting("account.signed_in", false)
	print("Signed out successfully")

func _on_delete_account_pressed() -> void:
	# Show destructive confirmation
	var confirm = preload("res://scenes/ui/components/ConfirmDialog.tscn").instantiate()
	confirm.title = "Delete Account"
	confirm.message = "This will permanently delete all your progress. This action cannot be undone."
	confirm.confirm_text = "DELETE ACCOUNT"
	confirm.confirmed.connect(_do_delete_account)
	add_child(confirm)

func _do_delete_account() -> void:
	# Wipe all save data
	SaveManager.reset_to_defaults()
	print("Account deleted - all data wiped")

# About handlers
func _on_credits_pressed() -> void:
	# Open credits scene or show credits dialog
	print("Credits: Little Six - A tribute to the Little 500 bicycle race tradition")

# Bottom button handlers
func _on_close_pressed() -> void:
	hide()
	EventBus.settings_closed.emit()

func _on_reset_pressed() -> void:
	var confirm = preload("res://scenes/ui/components/ConfirmDialog.tscn").instantiate()
	confirm.title = "Reset Settings"
	confirm.message = "Reset all settings to defaults?"
	confirm.confirmed.connect(_do_reset)
	add_child(confirm)

func _do_reset() -> void:
	SaveManager.reset_to_defaults()
	load_settings()
	print("Settings reset to defaults")

func _on_setting_changed(key: String, value) -> void:
	# React to external setting changes if needed
	pass

# Public API
func show_settings() -> void:
	show()
	load_settings()  # Refresh in case settings changed elsewhere

func hide_settings() -> void:
	hide()