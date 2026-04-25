extends Node

# ── Game State ──────────────────────────────────────────
signal game_state_changed(new_state)
signal scene_transition_requested(target_scene, data)

# ── Player / Account ────────────────────────────────────
signal player_logged_in(player_data)
signal player_logged_out()
signal racer_created(racer)
signal racer_stat_changed(stat, old_value, new_value)

# ── Training ─────────────────────────────────────────────
signal training_day_started(week, day)
signal training_activity_chosen(activity, slot)
signal training_activity_resolved(activity, changes)
signal training_random_event_fired(event_id, effects)
signal training_day_completed(week, day, summary)
signal fatigue_threshold_crossed(old_level, new_level)
signal injury_occurred(stat_affected, duration_days)

# ── Race ──────────────────────────────────────────────────
# TODO: Uncomment when Spec 004 is implemented
# signal race_room_joined(room_id: String, room_data: Dictionary)
# signal race_countdown_started(seconds: int)
signal race_started()
signal lap_completed(racer_id: int, lap_number: int, lap_time: float)
signal racer_position_changed(racer_id: int, new_position: int)
signal pit_zone_entered(racer_id: int)
signal pit_zone_exited(racer_id: int)
signal exchange_executed(team_id: int, outgoing_rider: int, incoming_rider: int, is_burn: bool)
signal sprint_activated(racer_id: int)
signal sprint_exhausted(racer_id: int)
signal crash_occurred(racer_id: int)
signal riders_position_update(rider_positions)
signal settings_closed()
signal rider_collision(rider_a_id: int, rider_b_id: int)
signal wall_collision(racer_id, position)
signal bell_lap_triggered()
signal race_finished(results: Array)
# signal race_abandoned()

# ── Networking ────────────────────────────────────────────
# TODO: Uncomment when Spec 005 is implemented
# signal connected_to_server()
# signal disconnected_from_server(reason: String)
# signal player_joined_room(player_id: int, player_name: String)
# signal player_left_room(player_id: int)
# signal network_message_received(msg_type: String, payload: Dictionary)
# signal latency_updated(ms: int)

# ── Audio ─────────────────────────────────────────────────
signal music_track_requested(track_id, fade_time)
signal sfx_requested(sfx_id, position)

# ── Host Bridge ───────────────────────────────────────────
signal host_event_sent(type, payload)
signal host_event_received(type, payload)

# ── Race Input ────────────────────────────────────────────
signal steer_input_changed(value: float)
signal sprint_button_pressed(pressed: bool)
signal brake_button_pressed(pressed: bool)
signal exchange_button_tapped()