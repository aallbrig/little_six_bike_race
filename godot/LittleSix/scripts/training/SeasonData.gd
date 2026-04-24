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

func to_dict() -> Dictionary:
    return {
        "season_id": season_id,
        "current_week": current_week,
        "current_day": current_day,
        "is_race_week": is_race_week,
        "qualifying_time": qualifying_time,
        "qualifying_position": qualifying_position,
        "weeks_completed": weeks_completed,
        "spring_series_results": spring_series_results
    }

static func from_dict(d: Dictionary) -> SeasonData:
    var season = SeasonData.new()
    season.season_id = d.get("season_id", "")
    season.current_week = d.get("current_week", 1)
    season.current_day = d.get("current_day", 1)
    season.is_race_week = d.get("is_race_week", false)
    season.qualifying_time = d.get("qualifying_time", 0.0)
    season.qualifying_position = d.get("qualifying_position", 0)
    season.weeks_completed = d.get("weeks_completed", [])
    season.spring_series_results = d.get("spring_series_results", [])
    return season