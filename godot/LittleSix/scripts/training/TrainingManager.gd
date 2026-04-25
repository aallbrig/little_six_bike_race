extends Node

# Training day state
var current_week: int = 1
var current_day: int = 1
var selected_activities: Array[int] = []  # Array of TrainingActivity.Type

func _ready() -> void:
    EventBus.game_state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state: int) -> void:
    if new_state == GameManager.GameState.TRAINING_DAY:
        start_training_day()

func start_training_day() -> void:
    # Reset for new training day
    selected_activities.clear()
    EventBus.training_day_started.emit(current_week, current_day)

    # In full implementation this would load the TrainingDay scene
    print("Training Day ", current_week, "-", current_day, " started")

func select_activity(activity_type: int, slot: int) -> bool:
    # Validate selection rules from Spec 003
    if slot == 0 and selected_activities.size() > 0:
        # Can't change slot 1 after choosing slot 2
        return false

    if activity_type in selected_activities:
        # Can't choose same activity twice
        return false

    # Check fatigue gating and injury rules (simplified)
    var racer = _get_current_racer()
    if racer and racer.fatigue >= 80:
        var allowed = [TrainingActivity.Type.RECOVERY_SPIN, TrainingActivity.Type.REST_DAY, TrainingActivity.Type.NUTRITION_PLAN]
        if not activity_type in allowed:
            return false

    # Add to selected activities
    if slot < selected_activities.size():
        selected_activities[slot] = activity_type
    else:
        selected_activities.append(activity_type)

    EventBus.training_activity_chosen.emit(activity_type, slot)
    return true

func confirm_training_day() -> void:
    if selected_activities.is_empty():
        return

    var racer = _get_current_racer()
    if not racer:
        return

    var summary = {}

    # Apply each activity
    for activity in selected_activities:
        var fatigue_mult = get_fatigue_multiplier(racer.fatigue)
        var changes = racer.apply_training(activity, fatigue_mult)
        summary[str(activity)] = changes
        EventBus.training_activity_resolved.emit(activity, changes)

    # Roll for random event (simplified implementation)
    var base_probability = 0.25
    if current_week >= 4:
        base_probability = 0.35
    if racer.fatigue >= 71:
        base_probability += 0.10

    if randf() < base_probability:
        _apply_simple_random_event(racer, selected_activities)

    # Advance day
    current_day += 1
    if current_day > 3:
        current_day = 1
        current_week += 1

    EventBus.training_day_completed.emit(current_week, current_day, summary)
    SaveManager.save_game()

    # Transition to results
    GameManager.transition_to(GameManager.GameState.TRAINING_RESULTS)

func _get_current_racer() -> RacerData:
    if SaveManager.player_data and SaveManager.player_data.racer:
        return SaveManager.player_data.racer
    return null

func _apply_simple_random_event(racer: RacerData, activities: Array) -> void:
    # Simple random events for testing
    var events = [
        { "id": "coach_pep_talk", "desc": "+10 morale" },
        { "id": "minor_strain", "desc": "+3 fatigue, -1 random stat" },
        { "id": "rival_encounter", "desc": "+2 speed, +3 morale" },
        { "id": "good_weather", "desc": "-2 fatigue" }
    ]

    var event = events[randi() % events.size()]
    EventBus.training_random_event_fired.emit(event.id, { "description": event.desc })

    match event.id:
        "coach_pep_talk":
            racer.morale = clamp(racer.morale + 10, 0, 100)
        "minor_strain":
            racer.fatigue = clamp(racer.fatigue + 3, 0, 100)
            var stat = _get_random_stat()
            racer.apply_stat_change(stat, -1)
        "rival_encounter":
            racer.speed = clamp(racer.speed + 2, 0, 100)
            racer.morale = clamp(racer.morale + 3, 0, 100)
        "good_weather":
            racer.fatigue = clamp(racer.fatigue - 2, 0, 100)

func get_fatigue_label(fatigue: int) -> String:
    if fatigue <= 30: return "FRESH"
    elif fatigue <= 55: return "GOOD"
    elif fatigue <= 70: return "TIRED"
    elif fatigue <= 85: return "OVERLOADED"
    else: return "DANGER ZONE"

func get_fatigue_multiplier(fatigue: int) -> float:
    if fatigue <= 30: return 1.1
    elif fatigue <= 55: return 1.0
    elif fatigue <= 70: return 0.8
    elif fatigue <= 85: return 0.6
    else: return 0.4

func _get_most_trained_stat(activities: Array) -> String:
    var stat_counts = {}
    for activity in activities:
        var effects = TrainingActivity.EFFECTS.get(activity, {})
        for stat in effects:
            if effects[stat] > 0 and stat != "morale":  # Count positive stat gains
                stat_counts[stat] = stat_counts.get(stat, 0) + effects[stat]

    var max_stat = ""
    var max_count = 0
    for stat in stat_counts:
        if stat_counts[stat] > max_count:
            max_count = stat_counts[stat]
            max_stat = stat
    return max_stat

func _get_last_trained_stat(activities: Array) -> String:
    if activities.is_empty():
        return ""
    var last_activity = activities.back()
    var effects = TrainingActivity.EFFECTS.get(last_activity, {})
    for stat in ["speed", "endurance", "handling", "recovery", "team_chem"]:
        if effects.get(stat, 0) > 0:
            return stat
    return "endurance"  # fallback

func _get_random_stat() -> String:
    var stats = ["speed", "endurance", "handling", "recovery"]
    return stats[randi() % stats.size()]