extends Control

var selected_slot = -1
var activity_buttons = []

func _ready() -> void:
    # Connect all activity buttons
    activity_buttons = [$Activities/Activity1, $Activities/Activity2, $Activities/Activity3, $Activities/Activity4]
    for i in activity_buttons.size():
        var button = activity_buttons[i]
        button.pressed.connect(func(): _on_activity_selected(i))
    
    $ConfirmButton.pressed.connect(_on_confirm_pressed)
    
    # Connect to training signals
    EventBus.training_day_started.connect(_on_training_day_started)
    EventBus.training_activity_chosen.connect(_on_training_activity_chosen)
    
    # Initialize with current racer data
    _update_ui()

func _on_training_day_started(week: int, day: int) -> void:
    $Header/WeekDay.text = "WEEK %d — DAY %d" % [week, day]
    _update_ui()

func _on_training_activity_chosen(activity: int, slot: int) -> void:
    _update_ui()

func _update_ui() -> void:
    var racer = TrainingManager._get_current_racer()
    if not racer:
        return
    
    # Update stat bars (simplified)
    $StatsContainer/Speed/Bar.value = racer.speed
    $StatsContainer/Speed/Value.text = str(racer.speed)
    $StatsContainer/Endurance/Bar.value = racer.endurance  
    $StatsContainer/Endurance/Value.text = str(racer.endurance)
    
    # Update fatigue
    var fatigue_label = TrainingManager.get_fatigue_label(racer.fatigue)
    $Header/FatigueLabel.text = "FATIGUE: " + fatigue_label
    
    # Update confirm button
    $ConfirmButton.disabled = TrainingManager.selected_activities.is_empty()

func _on_activity_selected(index: int) -> void:
    var activity_types = [
        TrainingActivity.SPRINT_INTERVALS,
        TrainingActivity.LONG_RIDE,
        TrainingActivity.RECOVERY_SPIN,
        TrainingActivity.REST_DAY
    ]
    
    var activity = activity_types[index]
    var slot = TrainingManager.selected_activities.size()
    
    if TrainingManager.select_activity(activity, slot):
        # Visual feedback
        for button in activity_buttons:
            button.add_theme_stylebox_override("normal", null)
        activity_buttons[index].add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

func _on_confirm_pressed() -> void:
    TrainingManager.confirm_training_day()