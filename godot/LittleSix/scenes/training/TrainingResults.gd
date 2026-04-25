extends Control

var _training_summary = {}
var _random_event = {}

func _ready() -> void:
    $ContinueButton.pressed.connect(_on_continue_pressed)

    # Listen for training completion
    EventBus.training_day_completed.connect(_on_training_day_completed)
    EventBus.training_random_event_fired.connect(_on_random_event_fired)

func _on_training_day_completed(week: int, day: int, summary: Dictionary) -> void:
    _training_summary = summary
    _update_display(week, day)

func _on_random_event_fired(event_id: String, effects: Dictionary) -> void:
    _random_event = { "id": event_id, "effects": effects }

func _update_display(week: int, day: int) -> void:
    var racer = TrainingManager._get_current_racer()
    if not racer:
        return

    var summary_text = "WEEK %d, DAY %d COMPLETE\n\n" % [week, day]

    # Show stat changes
    var stat_names = ["speed", "endurance", "recovery", "handling", "team_chem", "fatigue", "morale"]
    for stat in stat_names:
        var total_change = 0
        for activity_summary in _training_summary.values():
            total_change += activity_summary.get(stat, 0)

        if total_change != 0:
            var sign = "+" if total_change > 0 else ""
            var current_value = racer.get(stat)
            summary_text += "%s: %s%d (%d)\n" % [stat.capitalize(), sign, total_change, current_value]

    # Show random event if any
    if not _random_event.is_empty():
        summary_text += "\nRandom Event: %s\n%s" % [
            _random_event.id.capitalize().replace("_", " "),
            _random_event.effects.get("description", "")
        ]

    # Show race form
    summary_text += "\n\nRace Form: %s" % racer.get_race_form()

    $Summary.text = summary_text

func _on_continue_pressed() -> void:
    GameManager.transition_to(GameManager.GameState.MAIN_HUB)