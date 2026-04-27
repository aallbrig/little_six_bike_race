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

const EFFECTS: Dictionary = {
	Type.SPRINT_INTERVALS: { "speed": 3, "fatigue": 4, "morale": 1 },
	Type.LONG_RIDE:		   { "endurance": 4, "handling": 1, "fatigue": 3, "morale": 1 },
	Type.RECOVERY_SPIN:	   { "recovery": 3, "fatigue": -4, "morale": 2 },
	Type.REST_DAY:		   { "recovery": 1, "fatigue": -7, "morale": 3 },
	Type.STRENGTH_WORK:	   { "speed": 2, "endurance": 2, "fatigue": 5 },
	Type.VIDEO_STUDY:	   { "handling": 4, "morale": 1 },
	Type.TEAM_MEETING:	   { "team_chem": 5, "morale": 4 },
	Type.NUTRITION_PLAN:   { "endurance": 2, "recovery": 1, "fatigue": -3, "morale": 1 },
}

static func get_activity_name(type: Type) -> String:
	match type:
		Type.SPRINT_INTERVALS: return "Sprint Intervals"
		Type.LONG_RIDE: return "Long Ride"
		Type.RECOVERY_SPIN: return "Recovery Spin"
		Type.REST_DAY: return "Rest Day"
		Type.STRENGTH_WORK: return "Strength Work"
		Type.VIDEO_STUDY: return "Video Study"
		Type.TEAM_MEETING: return "Team Meeting"
		Type.NUTRITION_PLAN: return "Nutrition Plan"
		_: return "Unknown Activity"

static func get_activity_description(type: Type) -> String:
	match type:
		Type.SPRINT_INTERVALS: return "High-intensity sprint training to build speed."
		Type.LONG_RIDE: return "Endurance-building long distance ride."
		Type.RECOVERY_SPIN: return "Light spinning to aid recovery."
		Type.REST_DAY: return "Complete rest to recover from fatigue."
		Type.STRENGTH_WORK: return "Weight training for overall strength."
		Type.VIDEO_STUDY: return "Study race footage to improve handling."
		Type.TEAM_MEETING: return "Team bonding and strategy discussion."
		Type.NUTRITION_PLAN: return "Optimize diet for better performance."
		_: return "Unknown activity."