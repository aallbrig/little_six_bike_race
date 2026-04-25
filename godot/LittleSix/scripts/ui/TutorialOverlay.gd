extends CanvasLayer
class_name TutorialOverlay

# Tutorial overlay for guiding new players through Little Six

signal tutorial_completed
signal step_advanced

@export var current_step: int = 0
@export var tutorial_active: bool = true

@onready var panel: PanelContainer = $PanelContainer
@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $PanelContainer/VBoxContainer/DescriptionLabel
@onready var next_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/NextButton
@onready var skip_button: Button = $PanelContainer/VBoxContainer/HBoxContainer/SkipButton

const TUTORIAL_STEPS = [
    {
        "title": "Welcome to Little Six!",
        "description": "You're about to embark on an epic cycling journey to win the Little 500! Let's get you started with your first training day.",
        "highlight": null
    },
    {
        "title": "Your Training Activities",
        "description": "These cards represent different training activities. Each one gives different stat boosts but costs fatigue. Choose wisely!",
        "highlight": "ActivityCard"
    },
    {
        "title": "Understanding Fatigue",
        "description": "Watch your fatigue level - if it gets too high, you'll be limited to recovery activities. Balance is key!",
        "highlight": "FatigueArc"
    },
    {
        "title": "Track Your Progress",
        "description": "Your stats determine your race performance. Speed, Endurance, and Handling are crucial for victory.",
        "highlight": "StatBar"
    },
    {
        "title": "Complete Your Training",
        "description": "Select 3 activities for your first training day. Ready to start your Little 500 journey?",
        "highlight": null
    }
]

func _ready() -> void:
    if not tutorial_active:
        hide_tutorial()
        return

    setup_tutorial()
    show_current_step()

func setup_tutorial() -> void:
    next_button.pressed.connect(_on_next_pressed)
    skip_button.pressed.connect(_on_skip_pressed)

    # Connect to training events
    EventBus.training_activity_chosen.connect(_on_activity_chosen)

func _on_next_pressed() -> void:
    current_step += 1
    if current_step >= TUTORIAL_STEPS.size():
        complete_tutorial()
    else:
        show_current_step()
        step_advanced.emit()

func _on_skip_pressed() -> void:
    complete_tutorial()

func _on_activity_chosen(activity: int, slot: int) -> void:
    # If player has chosen activities, advance tutorial
    if current_step < TUTORIAL_STEPS.size() - 1:
        current_step = TUTORIAL_STEPS.size() - 1
        show_current_step()

func show_current_step() -> void:
    if current_step >= TUTORIAL_STEPS.size():
        return

    var step = TUTORIAL_STEPS[current_step]
    title_label.text = step.title
    description_label.text = step.description

    # Update button text
    if current_step == TUTORIAL_STEPS.size() - 1:
        next_button.text = "Start Training!"
    else:
        next_button.text = "Next"

    panel.visible = true
    modulate.a = 1.0

func complete_tutorial() -> void:
    tutorial_active = false
    hide_tutorial()
    tutorial_completed.emit()

func hide_tutorial() -> void:
    panel.visible = false
    modulate.a = 0.0