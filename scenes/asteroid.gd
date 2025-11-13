extends Area2D

@export var speed_min: float = 160.0
@export var speed_max: float = 300.0
@export var extra_offscreen_margin: float = 64.0

var _vy: float = 0.0
var _viewport_height: float

func _ready() -> void:
	_viewport_height = get_viewport_rect().size.y
	_vy = randf_range(speed_min, speed_max)
	
func _physics_process(delta: float) -> void:
	var pos:= global_position
	pos.y += _vy * delta
	global_position = pos
	if global_position.y > _viewport_height + extra_offscreen_margin:
		queue_free()
