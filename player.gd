extends CharacterBody2D

@export var wheel_base = 30
@export var steering_angle = 15
@export var speed = 500

var velocity = Vector2.ZERO
var steering_direction

func _physics_process(delta):
	get_input()
	calculate_steering(delta)
	velocity = move_and_slide(velocity)

func get_input():
	var direction = 0
	if Input.is_action_pressed("steer_right"):
		direction += 1
	if Input.is_action_pressed("steer_left"):
		direction -= 1
	steering_direction = direction * deg_to_rad(steering_angle)
	
	velocity = Vector2.ZERO
	if Input.is_action_pressed("accelerate"):
		velocity.x = transform.x * 500

func calculate_steering(delta):
	var rear_wheel = position - transform.x * wheel_base / 2
	var front_wheel = position + transform.x * wheel_base / 2
	
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steering_direction) * delta
	
	var new_heading = (front_wheel - rear_wheel).normalized()
	
	velocity = new_heading * velocity.length()
	rotation = new_heading.angle()
