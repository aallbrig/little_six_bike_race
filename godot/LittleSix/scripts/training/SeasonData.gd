class_name SeasonData
extends Resource

@export var season_id: String = ""
@export var current_week: int = 1
@export var current_day: int = 1  # 1-3 per week
@export var is_race_week: bool = false
@export var qualifying_time: float = 0.0
@export var qualifying_position: int = 0
@export var weeks_completed: Array = []  # Array of WeekData
@export var spring_series_results: Array = []  # Array of EventResult