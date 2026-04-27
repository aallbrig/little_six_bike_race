extends GutTest

class_name TestBikePhysics

var physics_calculator: BikePhysics

func before_each():
	physics_calculator = BikePhysics.new()
	add_child(physics_calculator)

func after_each():
	physics_calculator.queue_free()

func test_coaster_brake_behavior():
	# Given: Bike at speed with no input
	physics_calculator.velocity = 10.0
	physics_calculator.is_pedaling = false
	physics_calculator.is_braking = false

	# When: Physics updated
	var acceleration = physics_calculator.calculate_acceleration()

	# Then: Only rolling resistance applies (very slow deceleration)
	assert_almost_eq(acceleration, -physics_calculator.COAST_DECEL, 0.01,
		"Coasting should only have rolling resistance deceleration")

func test_brake_deceleration():
	# Given: Bike at speed with brake engaged
	physics_calculator.velocity = 15.0
	physics_calculator.is_pedaling = false
	physics_calculator.is_braking = true

	# When: Physics updated
	var acceleration = physics_calculator.calculate_acceleration()

	# Then: Strong brake deceleration
	assert_almost_eq(acceleration, -physics_calculator.BRAKE_DECEL, 0.01,
		"Braking should provide strong deceleration")

func test_pedaling_acceleration():
	# Given: Bike stationary with pedaling
	physics_calculator.velocity = 0.0
	physics_calculator.is_pedaling = true
	physics_calculator.is_braking = false

	# When: Physics updated
	var acceleration = physics_calculator.calculate_acceleration()

	# Then: Forward acceleration
	assert_almost_eq(acceleration, physics_calculator.ACCEL, 0.01,
		"Pedaling should provide forward acceleration")

func test_aerodynamic_drag_increases_with_speed():
	# Given: Bike at different speeds
	var speed_low = 5.0
	var speed_high = 15.0

	# When: Drag calculated
	var drag_low = physics_calculator.calculate_drag_force(speed_low)
	var drag_high = physics_calculator.calculate_drag_force(speed_high)

	# Then: Higher speed = more drag (drag force increases with v²)
	assert_gt(drag_high, drag_low,
		"Aerodynamic drag should increase with speed")
	assert_almost_eq(drag_high / (speed_high * speed_high), drag_low / (speed_low * speed_low), 0.01,
		"Drag should be proportional to velocity squared")

func test_terminal_velocity_reached():
	# Given: Bike pedaling at high speed
	physics_calculator.velocity = 20.0	# Above expected terminal velocity
	physics_calculator.is_pedaling = true
	physics_calculator.is_braking = false

	# When: Physics updated
	var acceleration = physics_calculator.calculate_acceleration()

	# Then: Net acceleration approaches zero at terminal velocity
	# Terminal velocity occurs when F_pedal = F_drag
	var drag = physics_calculator.calculate_drag_force(physics_calculator.velocity)
	var expected_accel = physics_calculator.ACCEL - (drag / physics_calculator.MASS)

	assert_almost_eq(acceleration, expected_accel, 0.01,
		"Acceleration should balance drag at terminal velocity")

func test_max_speed_calculation():
	# Given: Pedal force equals drag force
	var terminal_velocity = sqrt(physics_calculator.ACCEL * physics_calculator.MASS / physics_calculator.DRAG_COEFFICIENT)

	# When: Bike reaches terminal velocity
	physics_calculator.velocity = terminal_velocity
	physics_calculator.is_pedaling = true

	# Then: Net acceleration is zero (equilibrium)
	var acceleration = physics_calculator.calculate_acceleration()
	assert_almost_eq(acceleration, 0.0, 0.01,
		"At terminal velocity, acceleration should be zero")