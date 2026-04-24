extends VBoxContainer

@export var sprint_energy: float = 100.0:
	set(value):
		sprint_energy = clamp(value, 0, 100)
		$ProgressBar.value = sprint_energy