# Spec 010: Event Telemetry Logger

## Overview
Create a comprehensive telemetry system that listens to ALL signals on the EventBus and produces rich console logs. This provides real-time visibility into game state transitions, player actions, training events, race mechanics, and system interactions.

## Requirements

### REQ-010-001: EventBus Signal Monitoring
- Create `EventTelemetryLogger.gd` that automatically connects to every signal defined in `EventBus.gd`
- Log format must include: `[TELEMETRY] SIGNAL_NAME(params...)` with timestamp
- Support both simple signals and complex signals with typed parameters
- Handle parameter serialization for complex types (dictionaries, custom objects)
- Log at appropriate verbosity levels (INFO for major events, DEBUG for frequent signals like input)

### REQ-010-002: Configurable Telemetry
- Enable/disable via SettingsData.telemetry_enabled (default: true in development)
- Configurable log level (NONE, ERROR, WARN, INFO, DEBUG)
- Option to filter specific signals or signal categories (Training, Race, UI, Network)
- Output to both Godot console and optional file (user://telemetry.log)

### REQ-010-003: Signal Coverage
Must monitor ALL signals from EventBus.gd including:
- Game state changes
- Training system events (activity chosen, resolved, random events, fatigue)
- Race events (lap completed, position changes, sprint, crashes)
- Input events (steer, sprint, brake, exchange)
- Audio and UI events
- Networking and host bridge events

### REQ-010-004: Performance
- Must not impact game performance (use lightweight logging)
- Batch similar rapid events (e.g. frequent steer_input_changed)
- Provide summary statistics (signals per second, most frequent signals)

### REQ-010-005: Integration
- Add as autoload in project.godot (after EventBus)
- Auto-connect in `_ready()` using reflection or explicit connections
- Graceful handling of signals added in future specs
- Include in GameManager initialization sequence

## Acceptance Criteria
- Running `make game` shows telemetry output for all major events
- Training activities, race progression, and state changes are clearly logged
- Can be toggled via settings without restarting
- No console spam during normal gameplay (configurable verbosity)
- All EventBus signals are accounted for in logs

## Implementation Notes
- Use `signal.get_name()` or explicit connection list
- Create helper to format complex parameters (JSON-like output)
- Consider using Godot's `print_rich()` for colored output
- Add to docs/specs/spec_010_event_telemetry.md

**Priority:** High
**Epic:** Telemetry & Observability
**Depends on:** Spec 001 (EventBus)

---
**Status:** [ ] Not Started
**Owner:** Next Agent
**Target Completion:** Before Spec 005 Networking implementation
