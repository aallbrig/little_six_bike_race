extends Control

func _ready() -> void:
    _apply_safe_area()
    _load_current_settings()
    _connect_signals()

func _apply_safe_area() -> void:
    var safe = DisplayServer.get_display_safe_area()
    var screen_size = DisplayServer.window_get_size()

    if safe.size.x > 0 and safe.size.y > 0:
        var top_margin = safe.position.y
        var bottom_margin = screen_size.y - (safe.position.y + safe.size.y)
        var left_margin = safe.position.x
        var right_margin = screen_size.x - (safe.position.x + safe.size.x)

        $ScrollContainer.add_theme_constant_override("margin_top", top_margin + 8)
        $ScrollContainer.add_theme_constant_override("margin_bottom", bottom_margin + 8)
        $ScrollContainer.add_theme_constant_override("margin_left", left_margin + 8)
        $ScrollContainer.add_theme_constant_override("margin_right", right_margin + 8)

func _load_current_settings() -> void:
    # Load from SaveManager
    $ScrollContainer/VBoxContainer/AudioSection/VBoxContainer/MusicSlider/MusicValue.value = SaveManager.get_setting("music_volume", 0.8)
    $ScrollContainer/VBoxContainer/AudioSection/VBoxContainer/SFXSlider/SFXValue.value = SaveManager.get_setting("sfx_volume", 1.0)
    $ScrollContainer/VBoxContainer/ControlsSection/VBoxContainer/TiltToggle.button_pressed = SaveManager.get_setting("use_tilt_controls", true)
    $ScrollContainer/VBoxContainer/ControlsSection/VBoxContainer/TiltSensitivity/TiltSensSlider.value = SaveManager.get_setting("tilt_sensitivity", 1.0)
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/HighContrastToggle.button_pressed = SaveManager.get_setting("high_contrast", false)
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/ReduceMotionToggle.button_pressed = SaveManager.get_setting("reduce_motion", false)

    # Text scale buttons
    var text_scale = SaveManager.get_setting("text_scale", "M")
    _set_text_scale_button(text_scale)

    # Update tilt sensitivity visibility
    _on_tilt_toggle_toggled($ScrollContainer/VBoxContainer/ControlsSection/VBoxContainer/TiltToggle.button_pressed)

func _connect_signals() -> void:
    # Back button
    $ScrollContainer/VBoxContainer/Header/BackButton.pressed.connect(_on_back_pressed)

    # Audio
    $ScrollContainer/VBoxContainer/AudioSection/VBoxContainer/MusicSlider/MusicValue.value_changed.connect(_on_music_volume_changed)
    $ScrollContainer/VBoxContainer/AudioSection/VBoxContainer/SFXSlider/SFXValue.value_changed.connect(_on_sfx_volume_changed)
    $ScrollContainer/VBoxContainer/AudioSection/VBoxContainer/TestSFXButton.pressed.connect(_on_test_sfx_pressed)

    # Controls
    $ScrollContainer/VBoxContainer/ControlsSection/VBoxContainer/TiltToggle.toggled.connect(_on_tilt_toggle_toggled)
    $ScrollContainer/VBoxContainer/ControlsSection/VBoxContainer/TiltSensitivity/TiltSensSlider.value_changed.connect(_on_tilt_sensitivity_changed)
    $ScrollContainer/VBoxContainer/ControlsSection/VBoxContainer/TestTiltButton.pressed.connect(_on_test_tilt_pressed)

    # Display
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/TextScaleButtons/TextScaleHBox/TextScaleS.pressed.connect(_on_text_scale_selected.bind("S"))
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/TextScaleButtons/TextScaleHBox/TextScaleM.pressed.connect(_on_text_scale_selected.bind("M"))
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/TextScaleButtons/TextScaleHBox/TextScaleL.pressed.connect(_on_text_scale_selected.bind("L"))
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/HighContrastToggle.toggled.connect(_on_high_contrast_toggled)
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/ReduceMotionToggle.toggled.connect(_on_reduce_motion_toggled)

    # Account
    $ScrollContainer/VBoxContainer/AccountSection/VBoxContainer/SaveNameButton.pressed.connect(_on_save_name_pressed)
    $ScrollContainer/VBoxContainer/AccountSection/VBoxContainer/SignOutButton.pressed.connect(_on_sign_out_pressed)
    $ScrollContainer/VBoxContainer/AccountSection/VBoxContainer/DeleteAccountButton.pressed.connect(_on_delete_account_pressed)

    # About
    $ScrollContainer/VBoxContainer/AboutSection/VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)

func _on_back_pressed() -> void:
    GameManager.transition_to(GameManager.GameState.MAIN_HUB)

func _on_music_volume_changed(value: float) -> void:
    AudioManager.set_music_volume(value)
    SaveManager.set_setting("music_volume", value)

func _on_sfx_volume_changed(value: float) -> void:
    AudioManager.set_sfx_volume(value)
    SaveManager.set_setting("sfx_volume", value)

func _on_test_sfx_pressed() -> void:
    AudioManager.play_test_sfx()

func _on_tilt_toggle_toggled(enabled: bool) -> void:
    SaveManager.set_setting("use_tilt_controls", enabled)
    $ScrollContainer/VBoxContainer/ControlsSection/VBoxContainer/TiltSensitivity.visible = enabled

func _on_tilt_sensitivity_changed(value: float) -> void:
    SaveManager.set_setting("tilt_sensitivity", value)

func _on_test_tilt_pressed() -> void:
    # TODO: Show tilt test UI
    pass

func _set_text_scale_button(scale: String) -> void:
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/TextScaleButtons/TextScaleHBox/TextScaleS.button_pressed = (scale == "S")
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/TextScaleButtons/TextScaleHBox/TextScaleM.button_pressed = (scale == "M")
    $ScrollContainer/VBoxContainer/DisplaySection/VBoxContainer/TextScaleButtons/TextScaleHBox/TextScaleL.button_pressed = (scale == "L")

func _on_text_scale_selected(scale: String) -> void:
    SaveManager.set_setting("text_scale", scale)
    _set_text_scale_button(scale)

func _on_high_contrast_toggled(enabled: bool) -> void:
    SaveManager.set_setting("high_contrast", enabled)
    # TODO: Apply high contrast theme

func _on_reduce_motion_toggled(enabled: bool) -> void:
    SaveManager.set_setting("reduce_motion", enabled)
    # TODO: Disable animations

func _on_save_name_pressed() -> void:
    var new_name = $ScrollContainer/VBoxContainer/AccountSection/VBoxContainer/DisplayNameHBox/DisplayNameInput.text.strip_edges()
    if new_name.length() > 0:
        # TODO: Save display name
        pass

func _on_sign_out_pressed() -> void:
    # TODO: Show confirmation dialog
    pass

func _on_delete_account_pressed() -> void:
    # TODO: Show destructive confirmation dialog
    pass

func _on_credits_pressed() -> void:
    # TODO: Show credits screen
    pass