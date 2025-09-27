extends Node2D

@onready var Stones = get_tree().root.get_node("/root/Node2D/stones")
@export var StoneScene: PackedScene

var spawn_position: Vector2

func _ready():
	spawn_position = global_position
