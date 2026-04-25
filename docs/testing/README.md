# Event-Driven Testing Strategy

## Rubric for Good Event-Driven Tests

**Core Criteria (All Must Pass):**
1. **Signal Verification**: Tests both `.emit()` and `.connect()` paths using GUT's `watch_signals()` + `assert_signal_emitted()`
2. **Parameter Validation**: Asserts exact values, types, and data structure of all signal parameters
3. **Isolation**: Uses doubles/mocks for dependencies; never tests multiple systems in one unit test
4. **State Transition Testing**: Verifies system correctly responds to events by checking resulting state
5. **Bidirectional Testing**: Tests both "system emits event" and "system receives event" scenarios
6. **Negative Cases**: Tests invalid parameters, error conditions, and edge cases
7. **Performance**: Tests run quickly (< 500ms) and don't create real nodes unless testing UI components

**Test Structure Template:**
```gdscript
func test_training_activity_resolved_updates_stats_and_emits_event():
    # Given
    var training_manager = TrainingManager.new()
    watch_signals(EventBus)
    var test_activity = TrainingActivity.Type.ENDURANCE
    
    # When
    training_manager._resolve_activity(test_activity, {"endurance": 15})
    
    # Then
    assert_signal_emitted(EventBus, "training_activity_resolved")
    assert_eq(player_data.racer.endurance, expected_value)
    assert_signal_emitted_with_parameters(...)
```

## Test Organization

### Core Test Suites

**1. test_training/** 
- `test_training_manager.gd` - Training day lifecycle, fatigue, random events
- `test_activity_card.gd` - UI component event responses
- `test_training_stats.gd` - StatBar and FatigueArc updates via events

**2. test_race/**
- `test_race_controller.gd` - Race state machine via events
- `test_rider_controller.gd` - Input events (steer, sprint, brake) 
- `test_race_hud.gd` - HUD updates from lap/position/sprint events
- `test_race_ai.gd` - AI behavior simulation via event injection

**3. test_ui/**
- `test_components.gd` - All component library behavior
- `test_input_overlay.gd` - Touch zone to EventBus signal mapping
- `test_settings.gd` - Settings persistence and UI sync

**4. test_core/**
- `test_game_manager.gd` - State transitions via EventBus
- `test_event_bus.gd` - Signal catalog and connection integrity
- `test_telemetry_logger.gd` - EventTelemetryLogger correctness and performance

**5. test_integration/**
- End-to-end flows using simulated event sequences
- Training → Results → Hub → Race progression
- Save/load triggered by game events

## Implementation Status
- [ ] GUT framework added to project
- [ ] Base test utilities created (EventBus mocking, signal helpers)
- [ ] Training system tests (high priority)
- [ ] Race system tests
- [ ] Telemetry logger tests (validates Spec 010)

## Running Tests
```bash
make test                    # Run all tests
make test-training          # Run only training tests  
make test-race              # Run race-related tests
```

**Last Updated:** 2026-04-24
**Owner:** Testing Agent
**Related Specs:** spec_011_event_driven_testing.md, spec_010_event_telemetry.md
