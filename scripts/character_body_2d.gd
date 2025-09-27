extends CharacterBody2D

@onready var Sprite = $Sprite2D
@onready var CollisionShape = $CollisionShape2D
@onready var Stones = get_node("/root/Node2D/stones")
@onready var stonebox = get_node("/root/Node2D/UI/stonebox")
@onready var spawnPoint = get_node("/root/Node2D/Spawnpoint")

@export var StoneScene: PackedScene

const SPEED = 350.0
const JUMP_VELOCITY = -450.0

# Squish parameters
const SQUISH_FACTOR = 0.50   
const SQUISH_TWEEN_DUR = 0.12     # tween duration
const SQUISH_GRAVITY_MULT = 2.0   # how much stronger gravity is while squished

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
		

# --- Squish state & storage ---
var squished = false
var squish_tween: Tween = null
var squish_rect_shape: RectangleShape2D = null

# store originals to restore on unsquish
var original_scale: Vector2
var original_shape: Shape2D
var original_size: Vector2

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

# gravity multiplier (1.0 normal, SQUISH_GRAVITY_MULT while squished)
var gravity_mult := 1.0

# start smooth squish (tween in). Immediately sets gravity_mult so effect is felt while holding.
func start_squish():
	# If already squished or a squish tween currently moving towards squish, ignore
	if squished:
		return

	# kill any running unsquish tween
	if squish_tween:
		# safe kill if still valid
		squish_tween.kill()
		squish_tween = null

	# duplicate shape so we don't edit shared resource, then assign
	var rect_shape : RectangleShape2D = (original_shape as RectangleShape2D).duplicate() as RectangleShape2D
	CollisionShape.shape = rect_shape
	squish_rect_shape = rect_shape

	# compute targets
	var squish_scale = Vector2(original_scale.x * (1.0 + SQUISH_FACTOR), original_scale.y / (1.0 + SQUISH_FACTOR))
	var squish_size  = Vector2(original_size.x  * (1.0 + SQUISH_FACTOR), original_size.y  / (1.0 + SQUISH_FACTOR))

	# create tween to squish
	squish_tween = create_tween()
	squish_tween.tween_property(Sprite, "scale", squish_scale, SQUISH_TWEEN_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	squish_tween.parallel().tween_property(rect_shape, "size", squish_size, SQUISH_TWEEN_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# once the tween finishes, mark squished = true
	squish_tween.finished.connect(func():
		squished = true
		# stronger gravity while squished
		gravity_mult = SQUISH_GRAVITY_MULT
		squish_tween = null
	)

	# also set gravity_mult immediately so the gameplay effect is felt even during the tween
	gravity_mult = SQUISH_GRAVITY_MULT


# smooth unsquish (tween back to normal)
func stop_squish():
	# if we are not squished and there's no squish-tween in flight, nothing to do
	if not squished and not squish_tween:
		return

	# kill any running squish tween (the one heading to squish)
	if squish_tween:
		squish_tween.kill()
		squish_tween = null

	# get current rect shape (we duplicated when squishing). If none, create a duplicate to tween back.
	var rect_shape : RectangleShape2D = CollisionShape.shape as RectangleShape2D
	if rect_shape == null:
		rect_shape = (original_shape as RectangleShape2D).duplicate() as RectangleShape2D
		CollisionShape.shape = rect_shape

	# create tween to return to original
	var unsquish_tween = create_tween()
	unsquish_tween.tween_property(Sprite, "scale", original_scale, SQUISH_TWEEN_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	unsquish_tween.parallel().tween_property(rect_shape, "size", original_size, SQUISH_TWEEN_DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# on finish restore original shape resource (to avoid leaving a duplicated resource)
	unsquish_tween.finished.connect(func():
		# restore original shape resource (not the duplicate)
		CollisionShape.shape = original_shape
		squish_rect_shape = null
		squished = false
		gravity_mult = 1.0
	)

func _physics_process(delta: float) -> void:
	# Apply gravity, scaled by gravity_mult, only while airborne
	if not is_on_floor():
		velocity += get_gravity() * gravity_mult * delta
	else:
		# reset jump flag when grounded
		hasJumped = false

	# Handle jump (normal behavior)
	if Input.is_action_just_pressed("jump") and not hasJumped and movAllow:
		hasJumped = true
		particles()
		$Sprite2D.texture = load("res://textures/Rock man game jumping-.png")
		velocity.y = JUMP_VELOCITY

	if not hasJumped:
		$Sprite2D.texture = load("res://textures/Stone game Player Standing.png")

	# Squish input handling: usable anytime, no movAllow gate here (per your request).
	# Start squish on just_pressed, stop on just_released.
	if Input.is_action_just_pressed("squish"):
		start_squish()
	elif Input.is_action_just_released("squish"):
		stop_squish()

	# Stoned
	if Input.is_action_just_pressed("stoned") and movAllow:
		stoned()

	# Movement input
	var direction = Input.get_axis("left", "right")

	if direction != 0 and movAllow:
		velocity.x = direction * SPEED
		$Sprite2D.flip_h = direction < 0
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


func _ready() -> void:
	# Save original size/scale/shape for resetting
	original_scale = Sprite.scale
	original_shape = CollisionShape.shape
	original_size = (original_shape as RectangleShape2D).size

	reset_to_spawn()
