class_name RacerData
extends Resource

@export var racer_id: String = ""
@export var name: String = ""
@export var jersey_color_id: int = 0
@export var background: String = ""

# Permanent stats (0-100)
@export var speed: int = 50
@export var endurance: int = 50
@export var recovery: int = 50
@export var handling: int = 50
@export var team_chem: int = 50

# Transient (not saved between seasons)
@export var fatigue: int = 0
@export var morale: int = 50
@export var is_injured: bool = false
@export var injury_days_remaining: int = 0

func get_race_form() -> String:
	# Returns "HOT" / "WARM" / "COLD" based on recent training
	if fatigue > 70:
	    return "COLD"
	elif fatigue > 40:
	    return "WARM"
	else:
	    return "HOT"

func apply_training(activity: TrainingActivity.Type, fatigue_multiplier: float = 1.0) -> Dictionary:
	# Returns dict of stat changes
	var changes = {}
	var effects = TrainingActivity.EFFECTS.get(activity, {})

	for stat in effects:
	    var base_change = effects[stat]
	    var effective_change = base_change

	    # Apply fatigue multiplier only to positive gains, not fatigue cost
	    if stat != "fatigue" and base_change > 0:
	        effective_change = round(base_change * fatigue_multiplier)

	    # Apply soft cap: gains above 85 are halved, above 90 are quartered
	    var current_value = get(stat)
	    if stat in ["speed", "endurance", "recovery", "handling", "team_chem"]:
	        if current_value >= 85 and effective_change > 0:
	            var over_soft_cap = max(0, current_value + effective_change - 85)
	            effective_change = max(0, effective_change - over_soft_cap / 2)
	        if current_value >= 90 and effective_change > 0:
	            var over_hard_cap = max(0, current_value + effective_change - 90)
	            effective_change = max(0, effective_change - over_hard_cap * 3 / 4)

	    # Apply the change
	    match stat:
	        "speed":
	            speed = clamp(speed + effective_change, 0, 100)
	            changes[stat] = effective_change
	        "endurance":
	            endurance = clamp(endurance + effective_change, 0, 100)
	            changes[stat] = effective_change
	        "recovery":
	            recovery = clamp(recovery + effective_change, 0, 100)
	            changes[stat] = effective_change
	        "handling":
	            handling = clamp(handling + effective_change, 0, 100)
	            changes[stat] = effective_change
	        "team_chem":
	            team_chem = clamp(team_chem + effective_change, 0, 100)
	            changes[stat] = effective_change
	        "fatigue":
	            fatigue = clamp(fatigue + effective_change, 0, 100)
	            changes[stat] = effective_change
	        "morale":
	            morale = clamp(morale + effective_change, 0, 100)
	            changes[stat] = effective_change

	return changes

func apply_stat_change(stat_name: String, delta: int) -> void:
	match stat_name:
	    "speed":
	        speed = clamp(speed + delta, 0, 100)
	    "endurance":
	        endurance = clamp(endurance + delta, 0, 100)
	    "recovery":
	        recovery = clamp(recovery + delta, 0, 100)
	    "handling":
	        handling = clamp(handling + delta, 0, 100)
	    "team_chem":
	        team_chem = clamp(team_chem + delta, 0, 100)

func apply_injury(affected_stat: String, penalty: int, days: int) -> void:
	is_injured = true
	injury_days_remaining = days
	# Store the penalty for healing later
	set_meta("injury_stat", affected_stat)
	set_meta("injury_penalty", penalty)
	apply_stat_change(affected_stat, -penalty)

func to_dict() -> Dictionary:
	return {
	    "racer_id": racer_id,
	    "name": name,
	    "jersey_color_id": jersey_color_id,
	    "background": background,
	    "speed": speed,
	    "endurance": endurance,
	    "recovery": recovery,
	    "handling": handling,
	    "team_chem": team_chem,
	    "fatigue": fatigue,
	    "morale": morale,
	    "is_injured": is_injured,
	    "injury_days_remaining": injury_days_remaining
	}

static func from_dict(d: Dictionary) -> RacerData:
	var racer = RacerData.new()
	racer.racer_id = d.get("racer_id", "")
	racer.name = d.get("name", "")
	racer.jersey_color_id = d.get("jersey_color_id", 0)
	racer.background = d.get("background", "")
	racer.speed = d.get("speed", 50)
	racer.endurance = d.get("endurance", 50)
	racer.recovery = d.get("recovery", 50)
	racer.handling = d.get("handling", 50)
	racer.team_chem = d.get("team_chem", 50)
	racer.fatigue = d.get("fatigue", 0)
	racer.morale = d.get("morale", 50)
	racer.is_injured = d.get("is_injured", false)
	racer.injury_days_remaining = d.get("injury_days_remaining", 0)
	return racer