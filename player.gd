extends CharacterBody2D

@export var wheel_base = 60
@export var steering_angle = 5
@export var speed = 300
@export var engine_power = 800
@export var friction = -0.9
@export var drag = -0.001
@export var braking = -450
@export var max_speed_reverse = 250

@export var slip_speed = 400
@export var traction_fast = 0.7
@export var traction_slow = 0.9
@export var traction_drift = 0.05
@export var drifting_angle = 10

@export var mini_turbo_strength = 1600
@export var orange_turbo_strength = 2000
@export var purple_turbo_strength = 2400
var mini_turbo_mult = 0.3
var orange_turbo_mult = 0.4
var purple_turbo_mult = 0.5
var mini_turbo_bool = false
var orange_turbo_bool = false
var purple_turbo_bool = false

var acceleration = Vector2.ZERO
var steering_direction
var drift_timer = 0.0
var turbo_length = 0

func _physics_process(delta):
	acceleration = Vector2.ZERO
	if turbo_length > 0:
		turbo_length -= delta
	get_input()
	apply_friction()
	calculate_steering(delta)
	velocity += acceleration * delta
	move_and_slide()

func apply_friction():
	if velocity.length() < 5:
		velocity = Vector2.ZERO
	var friction_force = velocity * friction
	var drag_force = velocity * velocity.length() * drag
	acceleration += drag_force + friction_force

func get_input():
	var direction = 0
	if Input.is_action_pressed("steer_right"):
		direction += 1
	if Input.is_action_pressed("steer_left"):
		direction -= 1
	steering_direction = direction * deg_to_rad(steering_angle)
	if Input.is_action_pressed("drift"):
		steering_direction = direction * deg_to_rad(drifting_angle)
	
	
	if Input.is_action_pressed("accelerate"):
		if turbo_length > 0:
			if mini_turbo_bool:
				acceleration = transform.x * mini_turbo_strength
			elif orange_turbo_bool:
				acceleration = transform.x * orange_turbo_strength
			elif purple_turbo_bool:
				acceleration = transform.x * purple_turbo_strength
		else:
			acceleration = transform.x * engine_power
	if Input.is_action_pressed("brake"):
		acceleration = transform.x * braking

func calculate_steering(delta):
	var rear_wheel = position - transform.x * wheel_base / 2
	var front_wheel = position + transform.x * wheel_base / 2
	
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steering_direction) * delta
	
	var new_heading = (front_wheel - rear_wheel).normalized()
	var traction = traction_slow
	if velocity.length() > slip_speed:
		traction = traction_fast
	if Input.is_action_pressed("drift"):
		traction = traction_drift
		drift_timer += delta
	if Input.is_action_just_released("drift"):
		turbo_length = drift_timer
		do_turbo()
		drift_timer = 0
	
	var d = new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = velocity.lerp(new_heading * velocity.length(), traction)
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	
	rotation = new_heading.angle()

func do_turbo():
	if drift_timer >= 0.5 && drift_timer < 0.1:
		turbo_length = drift_timer * mini_turbo_mult
		mini_turbo_bool = true
	if drift_timer >= 1.0 && drift_timer < 1.5:
		turbo_length = drift_timer * orange_turbo_mult
		orange_turbo_bool = true
	if drift_timer >= 1.5:
		turbo_length = drift_timer * purple_turbo_mult
		purple_turbo_bool = true
