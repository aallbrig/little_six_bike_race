extends Node
class_name BikePhysics

# Advanced coaster brake bike physics simulation
# Based on Spec 010 Race Physics & Simulation

# Physical constants
const MASS = 85.0  # kg (rider + bike)
const GRAVITY = 9.8	 # m/s²

# Game-tuned constants for feel
const ACCEL = 5.0  # m/s² (pedaling acceleration)
const COAST_DECEL = 0.05  # m/s² (rolling resistance only)
const BRAKE_DECEL = 7.0	 # m/s² (coaster brake deceleration)

# Aerodynamic constants
var DRAG_COEFFICIENT: float = 0.3  # Simplified drag coefficient (F_drag = 0.3 * v²)

# Input state
var is_pedaling: bool = false
var is_braking: bool = false
var velocity: float = 0.0  # m/s

func calculate_acceleration() -> float:
	"""
	Calculate net acceleration based on current physics state.
	Returns acceleration in m/s².
	"""
	var net_force = 0.0

	# Pedal force (forward acceleration)
	if is_pedaling and not is_braking:
		net_force += ACCEL * MASS

	# Aerodynamic drag (always present, opposes motion)
	var drag_force = calculate_drag_force(abs(velocity))
	net_force -= drag_force * sign(velocity)  # Drag opposes velocity direction

	# Rolling resistance (always present, opposes motion)
	var rolling_force = calculate_rolling_force()
	net_force -= rolling_force * sign(velocity)

	# Brake force (coaster brake)
	if is_braking:
		var brake_force = calculate_brake_force()
		net_force -= brake_force * sign(velocity)

	# Convert force to acceleration
	return net_force / MASS

func calculate_drag_force(speed: float) -> float:
	"""
	Calculate aerodynamic drag force.
	F_drag = 0.5 * Cd * A * ρ * v², simplified to F_drag = DRAG_COEFFICIENT * v²
	"""
	return DRAG_COEFFICIENT * speed * speed

func calculate_rolling_force() -> float:
	"""
	Calculate rolling resistance force.
	F_roll = μ_r * m * g, where μ_r = 0.005 (cinder track)
	"""
	var rolling_coefficient = 0.005
	return rolling_coefficient * MASS * GRAVITY

func calculate_brake_force() -> float:
	"""
	Calculate coaster brake force.
	F_brake = μ_b * m * g, where μ_b = 0.7 (coaster brake coefficient)
	"""
	var brake_coefficient = 0.7
	return brake_coefficient * MASS * GRAVITY

func update_velocity(delta: float) -> void:
	"""
	Update velocity based on current acceleration over time delta.
	"""
	var acceleration = calculate_acceleration()
	velocity += acceleration * delta

	# Prevent negative velocity (bike can't go backwards from physics)
	if velocity < 0.0:
		velocity = 0.0

func get_speed_kph() -> float:
	"""
	Get current speed in km/h for display.
	"""
	return velocity * 3.6

func get_speed_mph() -> float:
	"""
	Get current speed in mph for display.
	"""
	return velocity * 2.237

func reset() -> void:
	"""
	Reset physics state.
	"""
	velocity = 0.0
	is_pedaling = false
	is_braking = false