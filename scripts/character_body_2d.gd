extends CharacterBody2D

@onready var Sprite = $Sprite2D
@onready var CollisionShape = $CollisionShape2D
@onready var Stones = get_node("/root/Node2D/stones")

@export var StoneScene: PackedScene

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const SPAWN_POS = Vector2(0, 0)

func reset_to_spawn():
	# coll check
	
	global_position = SPAWN_POS
	velocity = Vector2.ZERO


func stoned():
	# Make a new stone at player’s current position
	var stone = StoneScene.instantiate()
	stone.global_position = global_position

	# Add to the Stones folder
	Stones.add_child(stone)

	# Reset the player
	reset_to_spawn()

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


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
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
