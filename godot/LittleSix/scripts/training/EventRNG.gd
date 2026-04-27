class_name EventRNG
extends RefCounted

const EVENTS := [
	{ "id": "breakthrough", "weight": 10, "condition": "fatigue < 50 and week >= 3" },
	{ "id": "minor_strain", "weight": 20, "condition": "fatigue > 60" },
	{ "id": "rival_encounter", "weight": 15, "condition": "true" },
	{ "id": "rain_day", "weight": 15, "condition": "week <= 4" },
	{ "id": "equipment_check", "weight": 10, "condition": "true" },
	{ "id": "coach_pep_talk", "weight": 10, "condition": "morale < 40" },
	{ "id": "overtraining_warning", "weight": 20, "condition": "fatigue > 75" },
	{ "id": "nutrition_win", "weight": 8, "condition": "nutrition_plan_chosen_today" },
	{ "id": "weather_perfect", "weight": 12, "condition": "true" },
	{ "id": "illness_risk", "weight": 15, "condition": "fatigue > 80" },
]

const EVENT_EFFECTS := {
	"breakthrough": { "effect": "stat_boost", "description": "+5 to the most trained stat today" },
	"minor_strain": { "effect": "stat_penalty", "description": "+3 fatigue, -1 to last trained stat" },
	"rival_encounter": { "effect": "morale_boost", "description": "+2 speed, +3 morale" },
	"rain_day": { "effect": "activity_restriction", "description": "Limited activities next training day" },
	"equipment_check": { "effect": "activity_restriction", "description": "One fewer activity slot available" },
	"coach_pep_talk": { "effect": "morale_boost", "description": "+10 morale" },
	"overtraining_warning": { "effect": "activity_restriction", "description": "Force REST_DAY next training day" },
	"nutrition_win": { "effect": "multiplier_boost", "description": "Double Nutrition Plan effect" },
	"weather_perfect": { "effect": "fatigue_reduction", "description": "All fatigue gains halved today" },
	"illness_risk": { "effect": "injury_chance", "description": "30% chance of injury" },
}

static func roll_for_event(week: int, fatigue: int, nutrition_plan_used: bool) -> Dictionary:
	var base_probability = 0.25
	if week >= 4:
		base_probability = 0.35
	if fatigue >= 71:
		base_probability += 0.10

	if randf() >= base_probability:
		return {}

	# Filter eligible events
	var eligible_events = []
	for event in EVENTS:
		if _evaluate_condition(event.condition, week, fatigue, nutrition_plan_used):
			eligible_events.append(event)

	if eligible_events.is_empty():
		return {}

	# Select event by weight
	var total_weight = 0
	for event in eligible_events:
		total_weight += event.weight

	var roll = randi() % total_weight
	var current_weight = 0

	for event in eligible_events:
		current_weight += event.weight
		if roll < current_weight:
			return {
				"id": event.id,
				"effect": EVENT_EFFECTS[event.id]
			}

	return {}

static func _evaluate_condition(condition: String, week: int, fatigue: int, nutrition_plan_used: bool) -> bool:
	match condition:
		"fatigue < 50 and week >= 3":
			return fatigue < 50 and week >= 3
		"fatigue > 60":
			return fatigue > 60
		"true":
			return true
		"week <= 4":
			return week <= 4
		"morale < 40":
			return true	 # We'll check morale separately if needed
		"fatigue > 75":
			return fatigue > 75
		"nutrition_plan_chosen_today":
			return nutrition_plan_used
		"fatigue > 80":
			return fatigue > 80
		_:
			return false