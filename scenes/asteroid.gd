extends Area2D

@export var speed_min: float = 160.0
@export var speed_max: float = 300.0
@export var extra_offscreen_margin: float = 64.0

# For visual variety
@export var scale_min: float = 1.6 # overall asteroid scale
@export var scale_max: float = 2.3
@export var rotation_speed_min: float = -180.0 # deg/s
@export var rotation_speed_max: float = 180.0 

# Assigning several textures for variety
@export var textures: Array[Texture2D] = []

@onready var sprite: Sprite2D = $Sprite2D

var _vy: float = 0.0
var _viewport_height: float
var _rotation_speed: float = 0.0

func _ready() -> void:
	_viewport_height = get_viewport_rect().size.y
	_vy = randf_range(speed_min, speed_max)
	
	# Choose a random texture
	if textures.size() > 0:
		sprite.texture = textures[randi() % textures.size()]
		
	# Random overall scale
	var s := randf_range(scale_min, scale_max)
	scale = Vector2(s, s)
	
	# Random rotation speed
	_rotation_speed = randf_range(rotation_speed_min, rotation_speed_max)
	
func _physics_process(delta: float) -> void:
	# Fall
	var pos:= global_position
	pos.y += _vy * delta
	global_position = pos
	
	# Spin
	rotation_degrees += _rotation_speed * delta
	
	# Clean up when off-screen
	if global_position.y > _viewport_height + extra_offscreen_margin:
		queue_free()
