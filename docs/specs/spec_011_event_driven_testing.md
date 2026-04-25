# Spec 011: Event-Driven Testing Strategy with GUT

## Overview
Establish comprehensive testing strategy using Godot Unit Testing (GUT) framework focused on event-driven architecture. Create rubric for "good event-driven tests" and map game systems to specific test suites that exercise EventBus interactions.

## Rubric: What Constitutes Good Event-Driven Tests

### Core Principles (Must Meet All)
1. **Signal Verification**: Test both emission AND reception of signals
2. **Parameter Validation**: Assert exact parameter values and types
3. **Isolation**: Test individual systems with mocked dependencies
4. **State Transition Testing**: Verify system moves through correct states via events
5. **Integration Coverage**: Test system-to-system communication via EventBus
6. **Negative Testing**: Test error conditions and invalid events
7. **Performance Testing**: Ensure events don't cause performance regressions

### Test Structure Requirements
- **Given/When/Then** format with clear setup, action, assertion
- Use GUT's `watch_signals()` and `assert_signal_emitted()` 
- Mock EventBus connections where appropriate
- Test both direct method calls AND event-triggered paths
- Include timing tests for race conditions (using `await get_tree().create_timer()`)
- Document expected vs actual signal flow

### Coverage Requirements
- **Unit Tests**: Individual signal handlers (80%+ coverage)
- **Integration Tests**: Multi-system event flows (Training → UI → Save)
- **End-to-End Tests**: Complete user journeys via events only
- **Regression Tests**: Known edge cases and bugs

### Quality Metrics
- Each major signal must have at least 2 tests (emit + receive)
- Test names must describe the event flow (e.g. `test_training_activity_resolved_updates_stats_and_emits_event()`)
- All tests must run in < 2 seconds
- No direct node/scene dependencies in unit tests (use doubles)

## Game Systems to Test

### 1. Training System Tests (`test_training_*.gd`)
- Training day lifecycle (start, activity selection, resolution, completion)
- Fatigue and random event mechanics
- Stat progression and persistence via events
- UI feedback (ActivityCard, StatBar, FatigueArc updates)
- Edge cases: injury, overload, perfect training day

### 2. Race System Tests (`test_race_*.gd`)
- Race state machine (countdown, started, lap completed, finished)
- Rider physics and input events (steer, sprint, brake)
- Position tracking and leaderboard updates
- AI opponent behavior via simulated events
- Sprint mechanics and energy management
- Crash and recovery scenarios

### 3. UI Component Tests (`test_ui_*.gd`)
- Component response to events (StatBar value changes, FatigueArc color shifts)
- Touch input translation to EventBus signals
- Settings persistence and UI state synchronization
- Loading states and error banner display
- Component library integration tests

### 4. State Management Tests (`test_state_*.gd`)
- GameManager state transitions via EventBus.game_state_changed
- Scene loading/unloading coordination
- SaveManager persistence triggered by game events
- AudioManager music/SFX triggers

### 5. Telemetry & Observability Tests (`test_telemetry_*.gd`)
- EventTelemetryLogger correctly connects to all signals
- Log formatting and filtering work as expected
- Performance impact is within acceptable limits
- Configuration changes take effect immediately

## Implementation Requirements

### REQ-011-001: GUT Setup
- Add GUT plugin to Godot project (if not present)
- Create test/ directory structure matching game architecture
- Add `make test` command to run all GUT tests
- Configure GUT with appropriate double strategy for Godot nodes

### REQ-011-002: Test Implementation
- Implement tests for all major systems listed above
- Create base test class with common EventBus mocking utilities
- Ensure 85%+ coverage of event-driven code paths
- Include both happy path and error path tests

### REQ-011-003: Documentation
- Create `docs/testing/README.md` with test execution instructions
- Document test coverage goals and current status
- Maintain test-to-spec traceability matrix

## Acceptance Criteria
- All tests pass when running `make test`
- Telemetry logger itself is thoroughly tested
- Test coverage includes all EventBus signals
- Clear documentation of testing strategy in docs/
- New tests demonstrate the rubric in practice

## Success Metrics
- 50+ event-driven tests covering core gameplay
- Ability to run focused test suites (`gut -g training`)
- Test output clearly shows event flows being exercised
- Developers can quickly identify broken event flows

**Priority:** High
**Epic:** Quality & Observability
**Depends on:** Spec 010 (Event Telemetry), existing game systems

---
**Status:** [ ] Not Started
**Owner:** Next Agent  
**Target Completion:** Parallel with Spec 010 implementation
