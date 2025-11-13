extends Area2D

@export var max_speed: float = 420.0 # px/s
@export var accel: float = 12.0 # lerp factor per second
@export var horizontal_padding: float = 26.0

var _vx: float = 0.0
var _x_min: float
var _x_max: float

var _touch_left: bool = false
var _touch_right: bool = false
var viewport_width: float = 0.0

func _ready() -> void:
	viewport_width = get_viewport_rect().size.x
	_x_min = horizontal_padding
	_x_max = viewport_width - horizontal_padding
	
func _physics_process(delta: float) -> void:
	var target_vx: float = 0.0
	
	var left_pressed := Input.is_action_pressed("move_left") or _touch_left
	var right_pressed := Input.is_action_pressed("move_right") or _touch_right
	
	if left_pressed and not right_pressed:
		target_vx = -max_speed
	elif right_pressed and not left_pressed:
		target_vx = max_speed
	
	_vx = lerp(_vx, target_vx, accel*delta)
	
	var pos := global_position
	pos.x += _vx * delta
	pos.x = clamp(pos.x, _x_min, _x_max)
	global_position = pos

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("asteroid"):
		get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse clicks in browser also count as touch
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed := event.is_pressed()
		var pos: Vector2 = event.position
		
		if pressed:
			# Decide which half of the screen was tapped
			if pos.x < viewport_width * 0.5:
				_touch_left = true
				_touch_right = false
			else:
				_touch_left = false
				_touch_right = true
		else:
			# Finger/mouse is released: stop touch movement
			_touch_left = false
			_touch_right = false
