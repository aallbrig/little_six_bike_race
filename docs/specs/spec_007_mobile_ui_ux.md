# Spec 007 — Mobile UI/UX

**Depends on:** Spec 001, Spec 002  
**Last Updated:** 2026-04-10  

---

## Overview

Define the mobile-specific UI/UX implementation: responsive layouts, touch handling, orientation management, theme system, component library, accessibility, and the settings screen. All UX must work on phones from 375px to 430px viewport width.

---

## Requirements

### REQ-007-001: Viewport and Scaling
`project.godot` display settings:
```
viewport_width = 1080
viewport_height = 1920
stretch_mode = "canvas_items"
stretch_aspect = "expand"
```

This means:
- The designed viewport is 1080×1920 (portrait)
- It scales to fit any screen size while maintaining aspect ratio
- UI elements are anchored using Godot's anchor system (not pixel positions)
- All `Control` nodes use `ANCHOR_` constants, not hardcoded positions

### REQ-007-002: Portrait/Landscape Orientation

**Portrait mode:** All non-race scenes
- Lock orientation to portrait on mobile (done via HTML5 `screen.orientation.lock("portrait")` called from JavaScript, or via Godot's `DisplayServer.screen_set_orientation`)
- Fallback: if lock fails (some browsers restrict this), detect landscape and show "Rotate your phone" overlay

**Landscape mode:** Race scene only
- When transitioning to race scene: call `DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)`
- When leaving race scene: revert to portrait
- On desktops: both orientations work; no lock enforced

**Rotate overlay:**
```
If currently in portrait mode and race scene is active:
    Show: "Rotate your phone sideways to race!"
    [Icon: phone rotation animation]
    Do not start race countdown until landscape detected
```

### REQ-007-003: Theme System
Create a Godot `Theme` resource at `assets/ui/LittleSixTheme.tres`:

```
Font settings:
  Default font: Nunito Regular
  Bold font: Nunito SemiBold
  Monospace/display font: Press Start 2P

Color settings (all controls default):
  font_color: #F5F5F0 (cream/off-white)
  font_disabled_color: #64748B (slate)
  font_placeholder_color: #9CA3AF

Button default:
  normal:  bg_color = #B31B1B (crimson), text_color = #FAF3E0
  hover:   bg_color = #C42020
  pressed: bg_color = #8B1515
  disabled: bg_color = #374151, opacity = 0.5
  border_radius = 12
  font: Press Start 2P at 18px
  minimum_size: Vector2(0, 56)   ← 56px height for touch targets

Button secondary (via StyleBoxFlat):
  normal:  bg = transparent, border = 2px #FAF3E0
  hover:   bg = #FAF3E0 at 10% opacity
  
PanelContainer default:
  bg_color = #1C1C1E
  border_radius = 12
  border = 1px #374151

ProgressBar fill: #16A34A (Green) → overridden per use case
Label font: Nunito 18px
```

Apply this theme globally to all `Control` nodes via `project.godot`:
```
gui/theme/custom = "res://assets/ui/LittleSixTheme.tres"
```

### REQ-007-004: Component Library
Create reusable scenes for common components:

**`scenes/ui/components/StatBar.tscn`**
```
StatBar (HBoxContainer)
├── Label (stat name, 14px, slate color, min_width=100)
├── ProgressBar (fill height=12px, border-radius=6px, expands)
└── ValueLabel (numeric value, 14px, Press Start 2P, min_width=36)

Script: StatBar.gd
  @export var stat_name: String
  @export var value: int : set = _set_value  # Animates bar on set
  @export var bar_color: Color
  
  func _set_value(v: int) -> void:
    var old = value
    value = v
    # Animate progress bar from old to new over 0.4s
    var tween = create_tween()
    tween.tween_property(progress_bar, "value", v, 0.4).set_ease(Tween.EASE_OUT)
    # Show floating +N or -N label
    _show_delta(v - old)
```

**`scenes/ui/components/FatigueArc.tscn`**
```
FatigueArc (Control, custom draw)
  @export var fatigue: int  # 0-100
  # _draw() draws an arc with dynamic color
  # Green at 0-30, Amber at 31-70, Red at 71+
  # Label in center: "FRESH" / "TIRED" / "OVERLOADED"
```

**`scenes/ui/components/ActivityCard.tscn`**
```
ActivityCard (PanelContainer)
├── VBoxContainer
│   ├── IconRect (TextureRect, 48×48)
│   ├── NameLabel (Label, 16px)
│   └── EffectLabel (Label, 12px, slate, "+Speed +Fatigue")
└── [script: ActivityCard.gd]
    @export var activity: TrainingActivity.Type
    @export var is_selected: bool : set  # Toggles crimson border
    @export var is_disabled: bool : set  # Grays out card
    signal card_tapped(activity_type)
```

**`scenes/ui/components/PlayerSlot.tscn`** (lobby use)
```
PlayerSlot (HBoxContainer)
├── ColorSwatchRect (ColorRect, 32×32, rounded)
├── NameLabel (Label, "Waiting..." or player name)
├── StatMiniBar (speed + endurance, tiny)
└── ReadyBadge (Label, "READY", hidden until ready)
```

**`scenes/ui/components/SprintBar.tscn`** (race HUD)
```
SprintBar (VBoxContainer)
├── Label ("SPRINT", 10px, center)
└── ProgressBar (vertical, amber fill, height=180px)
    [Update via EventBus.sprint_energy_changed]
```

**`scenes/ui/components/Minimap.tscn`**
```
Minimap (Control)
└── SubViewportContainer (128×128, custom material: no AA)
    └── SubViewport
        └── MinimapCamera (Camera3D, orthographic, top-down)
            [Renders the race scene from above]
    MinimapOverlay (CanvasLayer above SubViewport)
        RiderDots (6× ColorRect circles, positioned by script)
```

### REQ-007-005: Safe Area Handling (iOS Notch / Home Indicator)

For iPhone X+, the UI must respect safe area insets.

```gdscript
# In base scene script for all portrait screens
func _ready() -> void:
    var safe = DisplayServer.get_display_safe_area()
    # safe: Rect2i with origin = top-left inset, size = safe area size
    var screen_size = DisplayServer.window_get_size()
    
    var top_margin = safe.position.y
    var bottom_margin = screen_size.y - (safe.position.y + safe.size.y)
    
    $ScrollContainer.add_theme_constant_override("margin_top", top_margin + 8)
    $BottomNav.add_theme_constant_override("margin_bottom", bottom_margin + 8)
```

Race HUD safe areas:
- Landscape: right side may have notch area (iPhone). Respect safe area for sprint/brake buttons.
- Use `DisplayServer.get_display_safe_area()` to offset buttons.

### REQ-007-006: Touch Input Handling

**General touch (menus):**
- Godot's `_input(event: InputEvent)` handles `InputEventScreenTouch`
- No need for custom touch handling — Godot's `Button` and `Control` nodes handle touch natively
- Minimum tap target enforced via theme minimum_size

**Race touch (custom):**
- `RaceInputOverlay.tscn` (CanvasLayer): transparent Control covering full screen
- Registers touch zones for steer left/right, sprint, brake, exchange
- Send input state to `RiderController` via direct call (same scene) or EventBus signal

```gdscript
# RaceInputOverlay.gd
var _left_touch_id: int = -1
var _right_touch_id: int = -1
var _brake_touch_id: int = -1
var _sprint_touch_id: int = -1

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _register_touch(event.index, event.position)
        else:
            _release_touch(event.index)

func _register_touch(id: int, pos: Vector2) -> void:
    var screen_width = get_viewport().size.x
    var screen_height = get_viewport().size.y
    
    # Sprint button: top-right quadrant
    if _is_in_sprint_zone(pos):
        _sprint_touch_id = id
    # Brake button: bottom-right
    elif _is_in_brake_zone(pos):
        _brake_touch_id = id
    # Exchange: center-bottom (only if visible)
    elif _is_in_exchange_zone(pos) and _exchange_visible:
        EventBus.exchange_button_tapped.emit()
    # Left half: steer left
    elif pos.x < screen_width / 2:
        _left_touch_id = id
    # Right half (not button zones): steer right
    else:
        _right_touch_id = id
```

### REQ-007-007: Loading States
Every async operation shows a loading indicator. Standard loading overlay:

```
LoadingOverlay.tscn (CanvasLayer, above all other layers)
├── Background (ColorRect, #000000 at 70% opacity)
└── CenterContainer
    ├── SpinnerAnim (AnimatedSprite2D, rotating bike wheel)
    └── LoadingLabel (Label, cycling pun)
```

Loading label puns (cycle through randomly):
- "Pedaling to the server..."
- "Adjusting coaster brake..."
- "Finding the pack..."
- "Checking tire pressure..."
- "Counting laps..."
- "Warming up the oval..."

`LoadingOverlay` is accessible as a method on `GameManager`:
```gdscript
GameManager.show_loading("Pedaling to the server...")
GameManager.hide_loading()
```

### REQ-007-008: Settings Screen
`scenes/ui/Settings.tscn` — accessible from Main Hub bottom nav.

Sections (grouped in panels):

**Audio:**
- Music Volume: Slider 0–100%, updates live
- SFX Volume: Slider 0–100%, updates live
- [Small test tone button next to SFX slider]

**Controls:**
- Use Tilt Controls: Toggle (default ON)
- Tilt Sensitivity: Slider 0.5×–2.0× (only visible when tilt ON)
- [Test Tilt button: shows live tilt reading for calibration]

**Display:**
- Text Scale: S / M / L buttons (radio-style)
- High Contrast Mode: Toggle
- Reduce Motion: Toggle

**Account:**
- Display Name: text input + "SAVE" button
- Player ID: read-only (for support)
- Sign Out (guests: "Your progress is local only" warning)
- Delete Account (destructive, confirmation dialog)

**About:**
- Version: [auto-pulled from project.godot]
- Credits link
- "Little 500 Tribute" flavor note

All settings persist via `SaveManager.set_setting(key, value)` immediately on change (auto-save).

### REQ-007-009: Confirmation Dialogs
All destructive or significant actions require a confirmation dialog.

`scenes/ui/components/ConfirmDialog.tscn`:
```
ConfirmDialog (PanelContainer, centered modal)
├── VBoxContainer
│   ├── TitleLabel (20px, bold)
│   ├── BodyLabel (16px)
│   ├── [Spacer]
│   └── HBoxContainer
│       ├── CancelButton (secondary style, "CANCEL")
│       └── ConfirmButton (primary style, label varies)
```

Use for:
- Delete Account ("This will permanently delete all your progress")
- Wipe Save ("Start fresh? All progress will be lost.")
- Leave Race mid-game ("You'll lose race progress. Leave anyway?")

### REQ-007-010: Error States
Every network failure or unexpected error shows a friendly error panel (not a raw error dialog).

Standard error panel (inline, not blocking):
```
ErrorBanner (HBoxContainer, visible=false by default)
├── IconRect (warning icon)
├── MessageLabel (error message, friendly copy)
└── RetryButton (optional, secondary style)
```

Error messages by code:
- Network error: "Couldn't reach the server. Check your connection."
- Room full: "That race is full. Find another?"
- Session expired: "Your session expired. Refresh to continue."
- General server error: "Something went sideways. Try again in a moment."

---

## Acceptance Criteria

- [ ] All UI renders correctly at 375px viewport width (iPhone SE)
- [ ] All UI renders correctly at 430px viewport width (iPhone 15 Pro Max)
- [ ] All tappable elements are ≥ 44×44 px
- [ ] Portrait orientation locked in all non-race scenes (or landscape handled by rotate overlay)
- [ ] Landscape orientation active during race scene
- [ ] Iris wipe transition plays between all scene changes
- [ ] Theme applied globally — consistent fonts/colors in all scenes
- [ ] StatBar animates smoothly when value changes
- [ ] FatigueArc changes color based on fatigue level
- [ ] ActivityCard: selected state visible, disabled state visible
- [ ] Settings changes persist after app reload
- [ ] Loading overlay shows on matchmaking initiation, disappears on lobby entry
- [ ] Confirmation dialog appears before Delete Account action
- [ ] Error banner appears and dismisses correctly for network errors
- [ ] Safe area respected on iPhone 14 (notch at top, home indicator at bottom)
- [ ] Race HUD elements reachable by thumbs on 375px landscape viewport
