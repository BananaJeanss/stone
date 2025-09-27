extends CharacterBody2D

@onready var Sprite = $Sprite2D
@onready var CollisionShape = $CollisionShape2D
@onready var Stones = get_node("/root/Node2D/stones")
@onready var stonebox = get_node("/root/Node2D/CanvasLayer/stonebox")

@export var StoneScene: PackedScene

const SPEED = 350.0
const JUMP_VELOCITY = -450.0
const SPAWN_POS = Vector2(0, 0)

var available_stones = 3

func reset_to_spawn():
	global_position = SPAWN_POS
	velocity = Vector2.ZERO
	
	# Collision check and nudge upwards
	var step_up = 50 # how many pixels to move up each iteration
	
	while true:
		# If moving here would collide, move up
		if test_move(global_transform, Vector2.ZERO):
			global_position.y -= step_up
		else:
			break

func update_stonebox():
	for i in range(3):
		var rock = stonebox.get_node(str(i + 1)) # Assuming names are "1", "2", "3"
		if i < available_stones:
			# Active stone: normal color
			rock.modulate = Color(1, 1, 1, 1)
		else:
			# Used stone: grayscale
			rock.modulate = Color(0.2, 0.2, 0.2, 1)

func stoned():
	if available_stones > 0:
		# Make a new stone at player’s current position
		var stone = StoneScene.instantiate()
		stone.global_position = global_position

		# Add to the Stones folder
		Stones.add_child(stone)
		
		# deduct stone
		available_stones -= 1
		update_stonebox()

		# Reset the player
		reset_to_spawn()
		
	else:
		print("No stones available")
		

func squish():
	var tween = create_tween()
	var original_scale = Sprite.scale
	var rect_shape = CollisionShape.shape as RectangleShape2D
	var original_size = rect_shape.size

	# Squash sprite
	var squish_scale = Vector2(original_scale.x * 1.2, original_scale.y * 0.8)
	# Squash collision shape in the same way
	var squish_size = Vector2(original_size.x * 1.2, original_size.y * 0.8)

	tween.tween_property(Sprite, "scale", squish_scale, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(rect_shape, "size", squish_size, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Return to normal
	tween.tween_property(Sprite, "scale", original_scale, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(rect_shape, "size", original_size, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

@export var JumpParticle : PackedScene

func particles():
	var _particle = JumpParticle.instantiate()
	_particle.position = global_position
	_particle.rotation = global_rotation
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)

var hasJumped = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		hasJumped = false

	# Handle jump.
	if Input.is_action_just_pressed("jump") and hasJumped == false:
		hasJumped = true
		particles()
		velocity.y = JUMP_VELOCITY
	
	# squish 
	if is_on_floor() and velocity.y == 0 and Input.is_action_just_pressed("squish"):
		squish()
	
	# stoned
	if Input.is_action_just_pressed("stoned"):
		stoned()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	# 
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
