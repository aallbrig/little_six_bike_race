# Sound Design Document — Little Six

**Version:** 1.0  
**Last Updated:** 2026-04-10  

---

## 1. Audio Philosophy

Sound in Little Six serves three roles:
1. **Feedback** — Every meaningful input or game event has an audio response. Players never wonder if their action registered.
2. **Atmosphere** — The soundscape of a spring college race day: crowd, outdoor ambiance, mechanical bike sounds.
3. **Emotional Amplification** — Music adapts to race tension. The bell lap should feel like the climax it is.

**Constraint:** Mobile browsers have strict autoplay policies. No audio plays until the user's first tap (handled by playing a silent buffer on first touch, then enabling all audio).

---

## 2. Audio Bus Layout

```
Master
├── Music (stereo, streaming OGG)
│   ├── Layer A (main track)
│   └── Layer B (crossfade target)
├── SFX (stereo, 22kHz WAV)
├── Crowd (positional, attenuated by camera distance)
└── UI (non-positional, always full volume)
```

---

## 3. Music Tracks

All music is original composition or royalty-free licensed. Upbeat, collegiate, accessible.

| Track ID | File | Scene | Style | Loop? |
|---|---|---|---|---|
| `logo` | logo.ogg | Logo screen | Brief orchestral sting (3s) | No |
| `attract` | attract.ogg | Cinematic + Title | Mellow indie-rock instrumental | Yes |
| `hub` | hub.ogg | Main Hub | Lo-fi hip-hop with cycling percussion | Yes |
| `training` | training.ogg | Training Day | Chill acoustic guitar + ambient | Yes |
| `lobby` | lobby.ogg | Lobby | Upbeat pop-electronic | Yes |
| `race_normal` | race_normal.ogg | Race (normal) | Driving rock, 120 BPM | Yes |
| `race_intense` | race_intense.ogg | Race (bell lap) | Elevated version of race_normal, fuller mix | Yes |
| `results_win` | results_win.ogg | Results (1st–3rd) | Triumphant fanfare + crowd | No |
| `results_loss` | results_loss.ogg | Results (4th–6th) | Bittersweet resolution | No |
| `spring_event` | spring_event.ogg | Spring Series | Energetic, shorter, punchy | Yes |

### 3.1 Dynamic Music Transitions

**Race music intensity:**
- Laps 1–39: `race_normal` plays
- Lap 40: Begin crossfading toward `race_intense` over 4 seconds
- Lap 49 (bell lap): Hard cut + 1-beat silence + `race_intense` resumes from downbeat
- Race end: Hard cut → `results_win` or `results_loss` based on placement

**Crossfade implementation (AudioManager.gd):**
- Uses two `AudioStreamPlayer` nodes (Layer A and B)
- Fade: Layer A volume fades to -80dB, Layer B fades from -80dB to 0dB over `fade_time`
- Beat-synced transitions where possible (track metadata stores BPM for sync)

---

## 4. Sound Effects Catalog

### 4.1 Bike & Racing SFX

| SFX ID | File | Trigger | Notes |
|---|---|---|---|
| `bike_pedal_loop` | bike_pedal.wav | While pedaling (looped) | Mechanical chain/gear sound; pitch scales with speed |
| `bike_sprint` | bike_sprint.wav | Sprint activated | Short whoosh + mechanical "click" |
| `bike_brake` | bike_brake.wav | Brake held | Coaster brake scrape sound |
| `the_burn_skid` | burn_skid.wav | Burn execution | Long skid + cinder spray |
| `draft_whoosh` | draft_whoosh.wav | Slingshot break | Quick air whoosh |
| `crash_impact` | crash.wav | Crash | Bike clatter + body slide |
| `exchange_click` | exchange.wav | Exchange complete | Satisfying metal "clunk" of bike handoff |
| `bell_lap` | bell_lap.wav | Lap 49 crossing | Classic race bell, resonant |

### 4.2 Race Events SFX

| SFX ID | File | Trigger |
|---|---|---|
| `race_start_horn` | start_horn.wav | Race countdown end |
| `lap_whoosh` | lap_whoosh.wav | Each lap complete (local rider) |
| `position_up` | pos_up.wav | Moving up in position |
| `position_down` | pos_down.wav | Losing position |
| `burn_announce` | burn_announce.wav | Burn! opportunity window opens |

### 4.3 Training SFX

| SFX ID | File | Trigger |
|---|---|---|
| `stat_increase` | stat_up.wav | Stat increases during resolution |
| `stat_decrease` | stat_down.wav | Stat decreases |
| `fatigue_warning` | fatigue_warn.wav | Fatigue crosses into Overloaded |
| `injury_event` | injury.wav | Injury random event fires |
| `event_positive` | event_good.wav | Positive random event |
| `event_negative` | event_bad.wav | Negative random event |

### 4.4 UI SFX

| SFX ID | File | Trigger |
|---|---|---|
| `button_tap` | tap.wav | Any button press |
| `back_nav` | back.wav | Back navigation |
| `screen_appear` | appear.wav | Screen slides in |
| `unlock` | unlock.wav | Cosmetic unlocked / stat cap reached |
| `notification` | notify.wav | New season event available |
| `countdown_tick` | tick.wav | Countdown 3-2-1 each number |
| `countdown_go` | go.wav | "GO!" on race start |

### 4.5 Ambient / Crowd SFX

| SFX ID | File | Type |
|---|---|---|
| `crowd_idle` | crowd_idle.wav | Looping ambient crowd murmur |
| `crowd_cheer` | crowd_cheer.wav | Short burst cheer (position changes, the burn) |
| `crowd_gasp` | crowd_gasp.wav | Crash, near-miss |
| `crowd_eruption` | crowd_eruption.wav | Bell lap, winner finishes |
| `wind_ambient` | wind.wav | Outdoor background wind (looped, quiet) |

---

## 5. Audio Implementation Notes

### 5.1 Mobile Autoplay

```gdscript
# AudioManager.gd - must call this on first user interaction
func unlock_audio() -> void:
    var silent := AudioStreamPlayer.new()
    silent.stream = _create_silent_stream()
    silent.play()
    add_child(silent)
    await get_tree().process_frame
    silent.queue_free()
    _audio_unlocked = true
```

### 5.2 Bike Pedal Pitch Scaling

```gdscript
# Pitch scales with current speed
func _update_pedal_audio(speed: float) -> void:
    var normalized = speed / MAX_SPEED  # 0.0 to 1.0
    pedal_player.pitch_scale = lerp(0.7, 1.4, normalized)
    pedal_player.volume_db = lerp(-12.0, 0.0, normalized)
```

### 5.3 Positional Audio

Crowd sounds use Godot `AudioStreamPlayer3D` positioned at the grandstands. Volume falls off with distance (inverse square). During race, the crowd gets louder as the camera zooms out (more crowd in view = more perceived volume).

### 5.4 File Specs

| Type | Format | Sample Rate | Channels | Notes |
|---|---|---|---|---|
| Music | OGG Vorbis q5 | 44.1kHz | Stereo | Streaming; do not preload |
| SFX (short) | WAV PCM | 22kHz | Mono | Preloaded in memory |
| Ambient loops | OGG Vorbis q3 | 22kHz | Mono | Streaming |
| Logo sting | OGG Vorbis q6 | 44.1kHz | Stereo | Preloaded |
