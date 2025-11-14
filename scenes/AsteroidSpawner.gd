extends Node

@export var asteroid_scene: PackedScene
@export var spawn_interval: float = 0.9 # starting spawn rate for the asteroids
@export var min_spawn_interval: float = 0.3 # minimum spawn rate per second for each asteroid
@export var horizontal_padding: float = 32.0
@export var spawn_interval_decay: float = 0.012 # how much the spawn rate reduces, per spawn

var _timer: Timer
var _viewport_width: float
var _current_interval: float
var _enabled: bool = false

func _ready() -> void:
	randomize()
	_viewport_width = get_viewport().get_visible_rect().size.x
	
	_current_interval = spawn_interval

	_timer = Timer.new()
	_timer.wait_time = _current_interval
	_timer.one_shot = false
	_timer.autostart = false
	add_child(_timer)

	_timer.timeout.connect(_on_spawn_timeout)

func _on_spawn_timeout() -> void:
	if not _enabled:
		return
	
	if asteroid_scene == null:
		return

	var asteroid := asteroid_scene.instantiate() as Area2D

	var x := randf_range(horizontal_padding, _viewport_width - horizontal_padding)
	asteroid.global_position = Vector2(x, -32.0)

	get_tree().current_scene.add_child(asteroid)
	
	# after spawning, speed up the next spawn
	_current_interval = max(min_spawn_interval, _current_interval - spawn_interval_decay)
	_timer.wait_time = _current_interval
	
	#print("Current spawn interval: ", _current_interval)

# Helper methods
func set_enabled(value: bool) -> void:
	_enabled = value
	
	if _timer == null:
		return
		
	if _enabled:
		if _timer.is_stopped():
			_timer.start()
	else:
		_timer.stop()
			
func reset_difficulty() -> void:
	_current_interval = spawn_interval
	if _timer:
		_timer.wait_time = _current_interval
