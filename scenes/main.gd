extends Node2D

enum State { MENU, PLAYING, GAME_OVER }

@onready var score_label: Label = $UI/ScoreLabel
@onready var main_menu: Control = $UI/MainMenu
@onready var game_over: Control = $UI/GameOver

@onready var title_label: Label = $UI/MainMenu/Panel/MarginContainer/VboxContainer/TitleLabel
@onready var best_score_menu_label: Label = $UI/MainMenu/Panel/MarginContainer/VBoxContainer/BestScoreLabel
@onready var play_button: Button = $UI/MainMenu/Panel/MarginContainer/VBoxContainer/PlayButton

@onready var final_score_label: Label = $UI/GameOver/Panel/MarginContainer/VBoxContainer/FinalScoreLabel
@onready var best_score_over_label: Label = $UI/GameOver/Panel/MarginContainer/VBoxContainer/BestScoreLabel
@onready var retry_button: Button = $UI/GameOver/Panel/MarginContainer/VBoxContainer/RetryButton

@onready var player: Area2D = $Player
@onready var spawner: Node = $AsteroidSpawner

var state: State = State.MENU
var score: float = 0.0
var best_score: int = 0

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "scores"
const SAVE_KEY := "best_score"

func _ready() -> void:
	_load_best_score()
	
	# Connect UI signals
	play_button.pressed.connect(_on_play_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	
	# Connect player hit signal
	if player.has_signal("hit"):
		player.hit.connect(_on_player_hit)
		
	_enter_menu_state()
	
func _on_play_pressed() -> void:
	_start_run()
	
func _on_retry_pressed() -> void:
	_start_run()
	
func _on_player_hit() -> void:
	if state != State.PLAYING:
		return
	_enter_game_over_state()

func _process(delta: float) -> void:
	if state == State.PLAYING:
		# Score goes up over time (1 point per second)\
		score += delta
		score_label.text = str(int(score))
		
func _start_run() -> void:
	score = 0.0
	score_label.text = "0"
	
	_clear_asteroids()
	
	# reset difficulty and enable spawner
	if "reset_difficulty" in spawner:
		spawner.reset_difficulty()
	if "set_enabled" in spawner:
		spawner.set_enabled(true)
		
	# reset player and enable control
	if "reset_to_start" in player:
		player.reset_to_start()
	if "set_enabled" in player:
		player.set_enabled(true)
		
	_enter_playing_state()
	
func _enter_menu_state() -> void:
	state = State.MENU
	
	main_menu.visible = true
	game_over.visible = false
	score_label.visible = false
	
	if "set_enabled" in spawner:
		spawner.set_enabled(false)
	if "set_enabled" in player:
		player.set_enabled(false)
		
	_update_best_score_labels()
	
func _enter_playing_state() -> void:
	state = State.PLAYING
	
	main_menu.visible = false
	game_over.visible = false
	score_label.visible = true
	
func _enter_game_over_state() -> void:
	state = State.GAME_OVER
	
	if "set_enabled" in spawner:
		spawner.set_enabled(false)
	if "set_enabled" in player:
		player.set_enabled(false)
		
	var current_score: int = int(score)
	if current_score > best_score:
		best_score = current_score
		_save_best_score()
		
	final_score_label.text = "Score  %d" % current_score
	_update_best_score_labels()
	
	main_menu.visible = false
	game_over.visible = true
	score_label.visible = true # Keep the latest score visible
	
# Clear any existing asteroids between runs
func _clear_asteroids() -> void:
	for asteroid in get_tree().get_nodes_in_group("asteroid"):
		asteroid.queue_free()
		
func _update_best_score_labels() -> void:
	var txt := "Best %d" % best_score
	best_score_menu_label.text = txt
	best_score_over_label.text = txt
		
# Saving/Loading methods
func _load_best_score() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		best_score = int(cfg.get_value(SAVE_SECTION, SAVE_KEY, 0))
	else:
		best_score = 0

func _save_best_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_SECTION, SAVE_KEY, best_score)
	var err:= cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save best score %s" % err)
	
