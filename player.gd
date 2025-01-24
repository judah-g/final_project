extends CharacterBody2D

@export var wheel_base = 60
@export var steering_angle_fast = 5
@export var steering_angle_slow = 10
@export var speed = 300
@export var engine_power = 800
@export var friction = -0.9
@export var drag = -0.001
@export var braking = -450
@export var max_speed_reverse = 250

@export var slip_speed = 400
@export var traction_fast = 0.7
@export var traction_slow = 0.8
@export var traction_drift = 0.05
@export var drifting_angle = 10

@export var mini_turbo_strength = 2000
@export var orange_turbo_strength = 2200
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
var drift_buffer = 0.0
var input_buffer = 0.0
var drift_direction = ""

var hazard_bool = false
var hazard_tax = 0.5 
var checkpoint_bool = false
var lap_number = 1

signal race_finish
signal lap

func start_game():
	position = Vector2(376, 568)
	rotation = deg_to_rad(270)
	velocity = Vector2.ZERO
	acceleration = Vector2.ZERO
	turbo_length = 0
	drift_timer = 0
	lap_number = 1

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
	if Input.is_action_pressed("accelerate"):
		steering_direction = direction * deg_to_rad(steering_angle_fast)
	else:
		steering_direction = direction * deg_to_rad(steering_angle_slow)
	
	if Input.is_action_pressed("drift"):
		steering_direction = direction * deg_to_rad(drifting_angle)
	
	
	if Input.is_action_pressed("accelerate"):
		if turbo_length > 0:
			$LeftWheelMini.visible = true
			$RightWheelMini.visible = true
			if mini_turbo_bool:
				acceleration = transform.x * mini_turbo_strength
				$LeftWheelMini.play("mini")
				$RightWheelMini.play("mini")
			elif orange_turbo_bool:
				acceleration = transform.x * orange_turbo_strength
				$LeftWheelMini.play("orange")
				$RightWheelMini.play("orange")
			elif purple_turbo_bool:
				acceleration = transform.x * purple_turbo_strength
				$LeftWheelMini.play("purple")
				$RightWheelMini.play("purple")
		else:
			acceleration = transform.x * engine_power
			$LeftWheelMini.visible = false
			$RightWheelMini.visible = false
			mini_turbo_bool = false
			orange_turbo_bool = false
			purple_turbo_bool = false
	
	if Input.is_action_pressed("brake"):
		acceleration = transform.x * braking
	
	if hazard_bool:
		acceleration *= hazard_tax

func calculate_steering(delta):
	
	var rear_wheel = position - transform.x * wheel_base / 2
	var front_wheel = position + transform.x * wheel_base / 2
	
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steering_direction) * delta
	
	var new_heading = (front_wheel - rear_wheel).normalized()
	var traction = traction_slow
	if velocity.length() > slip_speed:
		traction = traction_fast
	
	if input_buffer > 0:
		input_buffer -= delta
	
	if Input.is_action_pressed("drift") && input_buffer <= 0:
		if !Input.is_action_pressed("steer_left") != !Input.is_action_pressed("steer_right"):
			traction = traction_drift
			if Input.is_action_pressed("steer_left") && drift_timer == 0:
				drift_direction = "left"
			elif Input.is_action_pressed("steer_right") && drift_timer == 0:
				drift_direction = "right"
			drift_timer += delta
			
			
		if drift_direction == "left" && !Input.is_action_pressed("steer_left"):
			drift_buffer += delta
		elif drift_direction == "right" && !Input.is_action_pressed("steer_right"):
			drift_buffer += delta
	
	if Input.is_action_just_released("drift") || drift_buffer > 0.25:
		turbo_length = drift_timer
		do_turbo()
		drift_timer = 0
		drift_buffer = 0
		drift_direction = null
		input_buffer = 0.125
	
	
	var d = new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = velocity.lerp(new_heading * velocity.length(), traction)
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	
	rotation = new_heading.angle()

func do_turbo():
	if drift_timer >= 0.3 && drift_timer < 0.7:
		turbo_length = drift_timer * mini_turbo_mult
		mini_turbo_bool = true
	elif drift_timer >= 0.7 && drift_timer < 1.2:
		turbo_length = drift_timer * orange_turbo_mult
		orange_turbo_bool = true
	elif drift_timer >= 1.2:
		turbo_length = drift_timer * purple_turbo_mult
		purple_turbo_bool = true
	elif drift_timer < 0.5:
		turbo_length = 0

func _on_hazard_entered(area):
	hazard_bool = true

func _on_hazard_exited(area):
	hazard_bool = false

func _on_checkpoint_entered(area):
	checkpoint_bool = true

func _on_finish_entered(area):
	if checkpoint_bool == true:
		checkpoint_bool = false
		lap_number += 1
		emit_signal("lap")
	if lap_number == 4:
		emit_signal("race_finish")
