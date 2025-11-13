extends Node

@export var asteroid_scene: PackedScene
@export var spawn_interval: float = 0.9
@export var horizontal_padding: float = 32.0

var _timer: Timer
var _viewport_width: float

func _ready() -> void:
	randomize()
	_viewport_width = get_viewport().get_visible_rect().size.x

	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	_timer.autostart = true
	add_child(_timer)

	_timer.timeout.connect(_on_spawn_timeout)

func _on_spawn_timeout() -> void:
	if asteroid_scene == null:
		return

	var asteroid := asteroid_scene.instantiate() as Area2D

	var x := randf_range(horizontal_padding, _viewport_width - horizontal_padding)
	asteroid.global_position = Vector2(x, -32.0)

	get_tree().current_scene.add_child(asteroid)
