extends Area2D

@export var max_speed: float = 420.0 # px/s
@export var accel: float = 12.0 # lerp factor per second
@export var horizontal_padding: float = 26.0

var _vx: float = 0.0
var _x_min: float
var _x_max: float

func _ready() -> void:
	var viewport_width: float = get_viewport_rect().size.x
	_x_min = horizontal_padding
	_x_max = viewport_width - horizontal_padding
	
func _physics_process(delta: float) -> void:
	var target_vx: float = 0.0
	
	if Input.is_action_pressed("move_left"):
		target_vx = -max_speed
	elif Input.is_action_pressed("move_right"):
		target_vx = max_speed
	
	_vx = lerp(_vx, target_vx, accel*delta)
	var pos := global_position
	pos.x += _vx * delta
	pos.x = clamp(pos.x, _x_min, _x_max)
	global_position = pos


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("asteroid"):
		get_tree().reload_current_scene()
