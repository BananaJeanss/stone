extends CharacterBody2D

@onready var Sprite = $Sprite2D
@onready var CollisionShape = $CollisionShape2D
@onready var Stones = get_node("/root/Node2D/stones")
@onready var stonebox = get_node("/root/Node2D/UI/stonebox")
@onready var spawnPoint = get_node("/root/Node2D/Spawnpoint")

@export var StoneScene: PackedScene

const SPEED = 350.0
const JUMP_VELOCITY = -450.0
@onready var SPAWN_POS = spawnPoint.position

var available_stones = 3
var spawn

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
		return "no"
		

var squishdb = false;
func squish():
	if squishdb:
		return
	squishdb = true

	# Ensure sprite is centered (so scaling is around center)
	if Sprite.has_method("set_centered"):
		Sprite.centered = true

	# Duplicate the shape so we don't edit a shared resource
	var rect_shape : RectangleShape2D = (CollisionShape.shape as RectangleShape2D).duplicate() as RectangleShape2D
	CollisionShape.shape = rect_shape

	var tween = create_tween()
	var original_scale = Sprite.scale
	var original_size = rect_shape.size

	# squish parameters
	const s = 0.2         # relative squash factor (20%)
	const dur = 0.15      # speed

	# Area-preserving/stretchy scale:
	# x scales up by (1 + s); y scales down by dividing by (1 + s)
	var squish_scale = Vector2(original_scale.x * (1.0 + s), original_scale.y / (1.0 + s))
	var squish_size  = Vector2(original_size.x  * (1.0 + s), original_size.y  / (1.0 + s))

	# Apply squash
	tween.tween_property(Sprite, "scale", squish_scale, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(rect_shape, "size", squish_size, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Return to normal
	tween.tween_property(Sprite, "scale", original_scale, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(rect_shape, "size", original_size, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished
	squishdb = false


@export var JumpParticle : PackedScene

func particles():
	var _particle = JumpParticle.instantiate()
	_particle.position = global_position
	_particle.rotation = global_rotation
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)

var hasJumped = false

@onready var bowomp = $bowomp
@onready var spikes = get_node("/root/Node2D/spikes")

var movAllow = true

func _physics_process(delta: float) -> void:
	
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		hasJumped = false
		

	# Handle jump
	if Input.is_action_just_pressed("jump") and hasJumped == false and movAllow:
		hasJumped = true
		particles()
		$Sprite2D.texture = load("res://textures/Rock man game jumping-.png")
		velocity.y = JUMP_VELOCITY
	
	if hasJumped == false:
		$Sprite2D.texture = load("res://textures/Stone game Player Standing.png")
	
	# Squish
	if Input.is_action_just_pressed("squish") and movAllow:
		squish()
	
	# Stoned
	if Input.is_action_just_pressed("stoned") and movAllow:
		stoned()

	# Movement input
	var direction = Input.get_axis("left", "right")

	if direction != 0 and movAllow:
		velocity.x = direction * SPEED
		
		# Flip the sprite based on direction
		if direction < 0:
			$Sprite2D.flip_h = true
		elif direction > 0:
			$Sprite2D.flip_h = false

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Move once
	move_and_slide()

	# Spike collision check after movement
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == spikes and movAllow:
			bowomp.play(0.5)
			if stoned() == "no":
				reset_to_spawn()
			break

@export var Confetti : PackedScene

func confparticles():
	var _particle = Confetti.instantiate()
	add_child(_particle)  # Parent first
	var finPos = Vector2(global_position.x, global_position.y + -75)
	_particle.global_position = finPos  # Then set global position
	_particle.emitting = true


func _on_endpoint_body_entered(_body: Node2D) -> void:
	if _body is CharacterBody2D:
		confparticles()
		$clap.play(1)
		movAllow = false
