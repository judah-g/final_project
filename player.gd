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
@export var traction_fast = 0.1
@export var traction_slow = 0.7

var acceleration = Vector2.ZERO
var steering_direction

func _physics_process(delta):
	acceleration = Vector2.ZERO
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
	
	if Input.is_action_pressed("accelerate"):
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
	var d = new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = velocity.lerp(new_heading * velocity.length(), traction)
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	
	rotation = new_heading.angle()
