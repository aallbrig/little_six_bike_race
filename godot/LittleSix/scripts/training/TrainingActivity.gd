## TrainingActivity — Enum and effect data for all training activities.
## Static class — do not instantiate.
class_name TrainingActivity
extends RefCounted

enum Type {
	SPRINT_INTERVALS,
	LONG_RIDE,
	RECOVERY_SPIN,
	REST_DAY,
	STRENGTH_WORK,
	VIDEO_STUDY,
	TEAM_MEETING,
	NUTRITION_PLAN,
}

## Effect dictionaries: stat_name → delta
## Positive fatigue means fatigue increases; negative means it decreases.
const EFFECTS: Dictionary = {
	Type.SPRINT_INTERVALS: { "speed": 3,    "fatigue": 4,  "morale": 1 },
	Type.LONG_RIDE:        { "endurance": 4, "handling": 1, "fatigue": 3,  "morale": 1 },
	Type.RECOVERY_SPIN:    { "recovery": 3,  "fatigue": -4, "morale": 2 },
	Type.REST_DAY:         { "recovery": 1,  "fatigue": -7, "morale": 3 },
	Type.STRENGTH_WORK:    { "speed": 2,     "endurance": 2,"fatigue": 5 },
	Type.VIDEO_STUDY:      { "handling": 4,  "morale": 1 },
	Type.TEAM_MEETING:     { "team_chem": 5, "morale": 4 },
	Type.NUTRITION_PLAN:   { "endurance": 2, "recovery": 1, "fatigue": -3, "morale": 1 },
}

const DISPLAY_NAMES: Dictionary = {
	Type.SPRINT_INTERVALS: "Sprint Intervals",
	Type.LONG_RIDE:        "Long Ride",
	Type.RECOVERY_SPIN:    "Recovery Spin",
	Type.REST_DAY:         "Rest Day",
	Type.STRENGTH_WORK:    "Strength Work",
	Type.VIDEO_STUDY:      "Video Study",
	Type.TEAM_MEETING:     "Team Meeting",
	Type.NUTRITION_PLAN:   "Nutrition Plan",
}

const DESCRIPTIONS: Dictionary = {
	Type.SPRINT_INTERVALS: "+Speed   +Fatigue",
	Type.LONG_RIDE:        "+Endurance +Handling   +Fatigue",
	Type.RECOVERY_SPIN:    "+Recovery   -Fatigue",
	Type.REST_DAY:         "-Fatigue   +Morale  (uses both slots)",
	Type.STRENGTH_WORK:    "+Speed +Endurance   ++Fatigue",
	Type.VIDEO_STUDY:      "+Handling  (no fatigue cost)",
	Type.TEAM_MEETING:     "+TeamChem  +Morale",
	Type.NUTRITION_PLAN:   "+Endurance +Recovery   -Fatigue",
}

## Activities only available when fatigue < 80
const RECOVERY_ONLY_ACTIVITIES: Array[Type] = [
	Type.REST_DAY,
	Type.RECOVERY_SPIN,
	Type.NUTRITION_PLAN,
]

static func get_effects(activity: Type) -> Dictionary:
	return EFFECTS.get(activity, {})

static func get_name(activity: Type) -> String:
	return DISPLAY_NAMES.get(activity, "Unknown")

static func get_description(activity: Type) -> String:
	return DESCRIPTIONS.get(activity, "")

static func is_available_at_fatigue(activity: Type, fatigue: int) -> bool:
	if fatigue < 80:
		return true
	return activity in RECOVERY_ONLY_ACTIVITIES

static func consumes_both_slots(activity: Type) -> bool:
	return activity == Type.REST_DAY
