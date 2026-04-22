## RacerData — Persistent racer stats and transient race/training state.
class_name RacerData
extends Resource

@export var racer_id: String = ""
@export var name: String = "My Racer"
@export var jersey_color_id: int = 0
@export var background: String = "weekend_warrior"

# ── Permanent stats (0–100) ───────────────────────────────────────────��──────
## Top sprint velocity; "burn" effectiveness
@export var speed: int = 50
## Laps before fatigue penalty kicks in
@export var endurance: int = 50
## How fast fatigue drops between exchanges / after rest
@export var recovery: int = 50
## Corner speed, pack navigation, exchange precision
@export var handling: int = 50
## Speed bonus near teammates; improves with Team Meeting
@export var team_chem: int = 50

# ── Transient (season-scoped; NOT saved between seasons) ────────────────────
## 0–100; accumulates from training; higher = worse performance
@export var fatigue: int = 0
## 0–100; general morale; improves race performance
@export var morale: int = 50
## Currently injured (forces rest days)
@export var is_injured: bool = false
## Days of injury remaining (decrements each training day)
@export var injury_days_remaining: int = 0
## Temporary stat penalty during injury (restored on heal)
@export var injury_stat: String = ""
@export var injury_delta: int = 0


func get_race_form() -> String:
	## HOT / WARM / COLD — summary of training readiness
	var form_score = _calculate_race_form()
	if form_score > 70:
		return "HOT"
	elif form_score >= 40:
		return "WARM"
	return "COLD"


func _calculate_race_form() -> float:
	## Composite of recent training consistency, morale, and fatigue
	## Morale weight: 20%, Fatigue penalty weight: 20%, Base: 60%
	var base: float = 60.0
	var morale_component: float = (morale / 100.0) * 20.0
	var fatigue_component: float = ((100 - fatigue) / 100.0) * 20.0
	return base + morale_component + fatigue_component


func apply_changes(changes: Dictionary) -> void:
	## Apply a dict of stat_name → delta values, respecting bounds.
	for stat_name in changes:
		var delta: int = changes[stat_name]
		match stat_name:
			"speed":     speed     = clampi(speed     + delta, 0, 100)
			"endurance": endurance = clampi(endurance + delta, 0, 100)
			"recovery":  recovery  = clampi(recovery  + delta, 0, 100)
			"handling":  handling  = clampi(handling  + delta, 0, 100)
			"team_chem": team_chem = clampi(team_chem + delta, 0, 100)
			"fatigue":   fatigue   = clampi(fatigue   + delta, 0, 100)
			"morale":    morale    = clampi(morale    + delta, 0, 100)


func get_stat(stat_name: String) -> int:
	match stat_name:
		"speed":     return speed
		"endurance": return endurance
		"recovery":  return recovery
		"handling":  return handling
		"team_chem": return team_chem
		"fatigue":   return fatigue
		"morale":    return morale
	return 0


static func from_background(bg: String) -> RacerData:
	var r = RacerData.new()
	r.background = bg
	match bg:
		"weekend_warrior":
			r.speed = 45; r.endurance = 50; r.recovery = 55; r.handling = 50; r.team_chem = 60
		"ex_track_star":
			r.speed = 70; r.endurance = 40; r.recovery = 45; r.handling = 65; r.team_chem = 40
		"distance_rider":
			r.speed = 35; r.endurance = 75; r.recovery = 60; r.handling = 45; r.team_chem = 50
		"complete_newbie":
			r.speed = 30; r.endurance = 35; r.recovery = 65; r.handling = 35; r.team_chem = 70
	return r
