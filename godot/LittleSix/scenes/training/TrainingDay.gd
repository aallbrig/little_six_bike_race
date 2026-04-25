extends Control

var selected_slot = -1
var activity_buttons = []

func _ready() -> void:
    # Connect all activity cards
    activity_buttons = [
        $Activities/Activity1, $Activities/Activity2, $Activities/Activity3, $Activities/Activity4,
        $Activities/Activity5, $Activities/Activity6, $Activities/Activity7, $Activities/Activity8
    ]

    var activity_types = [
        TrainingActivity.SPRINT_INTERVALS,
        TrainingActivity.LONG_RIDE,
        TrainingActivity.STRENGTH_WORK,
        TrainingActivity.VIDEO_STUDY,
        TrainingActivity.TEAM_MEETING,
        TrainingActivity.NUTRITION_PLAN,
        TrainingActivity.RECOVERY_SPIN,
        TrainingActivity.REST_DAY
    ]

    for i in activity_buttons.size():
        var card = activity_buttons[i]
        card.activity_type = activity_types[i]
        card.card_tapped.connect(func(type): _on_activity_selected(i))

    $ConfirmButton.pressed.connect(_on_confirm_pressed)

    # Check if this is first training day for tutorial
    _check_tutorial_needed()

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

    # Update stat bars
    $StatsContainer/Speed.stat_name = "SPEED"
    $StatsContainer/Speed.value = racer.speed
    $StatsContainer/Endurance.stat_name = "ENDURANCE"
    $StatsContainer/Endurance.value = racer.endurance
    $StatsContainer/Recovery.stat_name = "RECOVERY"
    $StatsContainer/Recovery.value = racer.recovery
    $StatsContainer/Handling.stat_name = "HANDLING"
    $StatsContainer/Handling.value = racer.handling
    $StatsContainer/TeamChem.stat_name = "TEAM CHEM"
    $StatsContainer/TeamChem.value = racer.team_chem

    # Update fatigue arc
    $Header/FatigueArc.fatigue = racer.fatigue

    # Update confirm button
    $ConfirmButton.disabled = TrainingManager.selected_activities.is_empty()

func _on_activity_selected(index: int) -> void:
    var activity = activity_types[index]
    var _slot = TrainingManager.selected_activities.size()

    if TrainingManager.select_activity(activity, _slot):
        # Visual feedback - clear all selections first
        for card in activity_buttons:
            card.is_selected = false
        # Select the clicked card
        activity_buttons[index].is_selected = true

func _on_confirm_pressed() -> void:
    TrainingManager.confirm_training_day()

func _check_tutorial_needed() -> void:
    # Show tutorial for first-time players
    if SaveManager.player_data and SaveManager.player_data.current_season:
        var season = SaveManager.player_data.current_season
        # If this is week 1, day 1, show tutorial
        if season.current_week == 1 and season.current_day == 1:
            $TutorialOverlay.tutorial_active = true
            $TutorialOverlay.show_current_step()
        else:
            $TutorialOverlay.tutorial_active = false
            $TutorialOverlay.hide_tutorial()