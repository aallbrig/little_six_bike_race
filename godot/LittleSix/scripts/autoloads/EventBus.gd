extends Node

# ── Game State ──────────────────────────────────────────
signal game_state_changed(new_state: int)
signal scene_transition_requested(target_scene: String, data: Dictionary)

# ── Player / Account ────────────────────────────────────
signal player_logged_in(player_data: Resource)
signal player_logged_out()
signal racer_created(racer: Resource)
signal racer_stat_changed(stat: String, old_value: int, new_value: int)

# ── Training ─────────────────────────────────────────────
signal training_day_started(week: int, day: int)
signal training_activity_chosen(activity: Resource, slot: int)
signal training_activity_resolved(activity: Resource, changes: Dictionary)
signal training_random_event_fired(event: Dictionary)
signal training_day_completed(week: int, day: int, summary: Dictionary)
signal fatigue_threshold_crossed(old_level: String, new_level: String)
signal injury_occurred(stat_affected: String, duration_days: int)

# ── Race ──────────────────────────────────────────────────
signal race_room_joined(room_id: String, room_data: Dictionary)
signal race_countdown_started(seconds: int)
signal race_started()
signal lap_completed(racer_id: int, lap_number: int, lap_time: float)
signal racer_position_changed(racer_id: int, new_position: int)
signal pit_zone_entered(racer_id: int)
signal pit_zone_exited(racer_id: int)
signal exchange_executed(team_id: int, outgoing_rider: int, incoming_rider: int, is_burn: bool)
signal sprint_activated(racer_id: int)
signal sprint_exhausted(racer_id: int)
signal crash_occurred(racer_id: int)
signal bell_lap_triggered()
signal race_finished(results: Array)
signal race_abandoned()

# ── Networking ────────────────────────────────────────────
signal connected_to_server()
signal disconnected_from_server(reason: String)
signal player_joined_room(player_id: int, player_name: String)
signal player_left_room(player_id: int)
signal network_message_received(msg_type: String, payload: Dictionary)
signal latency_updated(ms: int)

# ── Audio ─────────────────────────────────────────────────
signal music_track_requested(track_id: String, fade_time: float)
signal sfx_requested(sfx_id: String, position: Vector3)

# ── Host Communication ────────────────────────────────────
signal host_event_sent(type: String, payload: Dictionary)
signal host_event_received(type: String, payload: Dictionary)