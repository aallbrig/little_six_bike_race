class_name PlayerData
extends Resource

@export var player_id: String = ""
@export var display_name: String = "Rider"
@export var is_guest: bool = true
@export var cred_points: int = 0
@export var elo_rating: int = 1000
@export var racer: Resource = null  # RacerData
@export var current_season: Resource = null  # SeasonData
@export var career_wins: int = 0
@export var career_races: int = 0
@export var unlocked_cosmetics: Array[String] = []