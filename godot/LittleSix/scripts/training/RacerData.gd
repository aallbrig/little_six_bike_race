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

func apply_training(activity: TrainingActivity) -> Dictionary:
    # Returns dict of stat changes
    var changes = {}
    var effects = TrainingActivity.EFFECTS.get(activity, {})

    for stat in effects:
        var change = effects[stat]
        match stat:
            "speed":
                speed = clamp(speed + change, 0, 100)
                changes[stat] = change
            "endurance":
                endurance = clamp(endurance + change, 0, 100)
                changes[stat] = change
            "recovery":
                recovery = clamp(recovery + change, 0, 100)
                changes[stat] = change
            "handling":
                handling = clamp(handling + change, 0, 100)
                changes[stat] = change
            "team_chem":
                team_chem = clamp(team_chem + change, 0, 100)
                changes[stat] = change
            "fatigue":
                fatigue = clamp(fatigue + change, 0, 100)
                changes[stat] = change
            "morale":
                morale = clamp(morale + change, 0, 100)
                changes[stat] = change

    return changes

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