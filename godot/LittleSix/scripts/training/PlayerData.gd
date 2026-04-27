class_name PlayerData
extends Resource

@export var player_id: String = ""
@export var display_name: String = "Rider"
@export var is_guest: bool = true
@export var cred_points: int = 0
@export var elo_rating: int = 1000
@export var racer: RacerData = null
@export var current_season: SeasonData = null
@export var career_wins: int = 0
@export var career_races: int = 0
@export var unlocked_cosmetics: Array = []

func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"display_name": display_name,
		"is_guest": is_guest,
		"cred_points": cred_points,
		"elo_rating": elo_rating,
		"racer": racer.to_dict() if racer else (null as Variant),
		"current_season": current_season.to_dict() if current_season else (null as Variant),
		"career_wins": career_wins,
		"career_races": career_races,
		"unlocked_cosmetics": unlocked_cosmetics
	}

static func from_dict(d: Dictionary) -> PlayerData:
	var player = PlayerData.new()
	player.player_id = d.get("player_id", "")
	player.display_name = d.get("display_name", "Rider")
	player.is_guest = d.get("is_guest", true)
	player.cred_points = d.get("cred_points", 0)
	player.elo_rating = d.get("elo_rating", 1000)
	if d.get("racer"):
		player.racer = RacerData.from_dict(d.racer)
	if d.get("current_season"):
		player.current_season = SeasonData.from_dict(d.current_season)
	player.career_wins = d.get("career_wins", 0)
	player.career_races = d.get("career_races", 0)
	var cosmetics = d.get("unlocked_cosmetics", [])
	player.unlocked_cosmetics = cosmetics if cosmetics is Array else []
	return player