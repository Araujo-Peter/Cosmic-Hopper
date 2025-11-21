extends Node2D

# For Leaderboard Management UI elements
@onready var name_popup: Control = $UI/NamePopup
@onready var name_input: LineEdit = $UI/NamePopup/Panel/MarginContainer/VBoxContainer/NameInput
@onready var name_error_label: Label = $UI/NamePopup/Panel/MarginContainer/VBoxContainer/NameErrorLabel
@onready var name_confirm_button: Button = $UI/NamePopup/Panel/MarginContainer/VBoxContainer/NameConfirmButton

@onready var leaderboard_panel: Control = $UI/Leaderboard
@onready var scores_container: VBoxContainer = $UI/Leaderboard/Panel/MarginContainer/VBoxContainer/ScoresContainer
@onready var close_leaderboard_button: Button = $UI/Leaderboard/Panel/MarginContainer/VBoxContainer/CloseLeaderboardButton
@onready var leaderboard_butotn: Button = $UI/MainMenu/Panel/MarginContainer/VBoxContainer/LeaderboardButton

# For global leaderboard functionality
@onready var leaderboard_request: HTTPRequest = $LeaderboardRequest

const SUPABASE_URL := "https://oylnzajtywgpjmdnnlgw.supabase.co"
const SUPABASE_TABLE := "scores"
const SUPABASE_ANON_KEY := "sb_publishable_tiPtH6mosLwkNM2nILBKPQ_V8v2CPY1"

var player_name: String = "" # will be set by player via name-entry UI

const NAME_SAVE_PATH := "user://player_name.cfg"
const NAME_SECTION := "player"
const NAME_KEY := "username"

# For sound based entities
@onready var sfx_hit: AudioStreamPlayer2D = $SFX_Hit
@onready var sfx_button: AudioStreamPlayer2D = $SFX_Button
@onready var music: AudioStreamPlayer2D = $Music

# For camera shake on hit
@onready var camera: Camera2D = $Camera2D
@onready var hit_flash: ColorRect = $UI/HitFlash

var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_magnitude: float = 0.0
var _camera_base_offset: Vector2 = Vector2.ZERO

# Enum to control game states
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
	
	_camera_base_offset = camera.offset
	
	hit_flash.visible = false
	hit_flash.modulate.a = 0.0
	
	# HTTPRequest connect for leaderboard
	leaderboard_request.request_completed.connect(_on_leaderboard_request_completed)
	
	leaderboard_butotn.pressed.connect(_on_leaderboard_button_pressed)
	close_leaderboard_button.pressed.connect(_on_close_leaderboard_pressed)
	
	# Connect UI signals
	play_button.pressed.connect(_on_play_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	
	# Connect player hit signal
	if player.has_signal("hit"):
		player.hit.connect(_on_player_hit)
		
	# Connect name entry components
	name_confirm_button.pressed.connect(_on_name_confirm_pressed)
	name_input.text_changed.connect(_on_name_input_changed)
	
	_load_player_name()
		
	_enter_menu_state()
	
func _on_play_pressed() -> void:
	if player_name.is_empty():
		_show_name_popup()
		return
		
	if sfx_button:
		sfx_button.play()
	_start_run()
	
func _on_retry_pressed() -> void:
	if player_name.is_empty():
		_show_name_popup()
		return
		
	if sfx_button:
		sfx_button.play()
	_start_run()
	
func _on_player_hit() -> void:
	if state != State.PLAYING:
		return
		
	if sfx_hit:
		sfx_hit.play()
		
	start_screen_shake(0.25, 5.0)
	play_hit_flash()
	
	_enter_game_over_state()

func _process(delta: float) -> void:
	if state == State.PLAYING:
		# Score goes up over time (1 point per second)\
		score += delta
		score_label.text = str(int(score))
		
	_update_screen_shake(delta)
	
func _update_screen_shake(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		var t :float = clamp(_shake_time / max(_shake_duration, 0.001), 0.0, 1.0)
		# Fade out the shake over time
		var current_mag := _shake_magnitude * t
		var offset := Vector2(
			randf_range(-current_mag, current_mag),
			randf_range(-current_mag, current_mag)
		)
		camera.offset = _camera_base_offset + offset
	else:
		camera.offset = _camera_base_offset
		
func start_screen_shake(duration: float = 0.25, magnitude: float = 4.0) -> void:
	_shake_time = duration
	_shake_duration = duration
	_shake_magnitude = magnitude

func play_hit_flash() -> void:
	hit_flash.modulate.a = 0.5
	hit_flash.visible = true
	
	var tween := create_tween()
	tween.tween_property(hit_flash, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func() -> void:
		hit_flash.visible = false
	)

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
		
	_stop_music()
	_update_best_score_labels()
	
func _enter_playing_state() -> void:
	state = State.PLAYING
	
	main_menu.visible = false
	game_over.visible = false
	score_label.visible = true
	
	_start_music()
	
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
		
	# Only submit to global leaderboard if this score matches or beats our local best
	if current_score > best_score and not player_name.is_empty():
		submit_score_global(player_name, current_score)
		
	final_score_label.text = "Score  %d" % current_score
	_update_best_score_labels()
	
	main_menu.visible = false
	game_over.visible = true
	score_label.visible = true # Keep the latest score visible
	
	_stop_music()
	
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
		
# Helper methods to control music play
func _start_music() -> void:
	if music and music.stream and not music.playing:
		music.play()
		
func _stop_music() -> void:
	if music and music.playing:
		music.stop()
		
# Name Entry UI methods
func _on_name_input_changed(new_text: String) -> void:
	var filtered := ""
	
	for i in new_text.length():
		var ch: String = new_text[i]  # single-character string
		var code: int = ch.unicode_at(0)

		# '0'–'9'
		var is_digit := code >= 48 and code <= 57
		# 'A'–'Z'
		var is_upper := code >= 65 and code <= 90
		# 'a'–'z'
		var is_lower := code >= 97 and code <= 122

		if is_digit or is_upper or is_lower:
			filtered += ch

	# Force uppercase and respect Max Length = 6 on the LineEdit
	filtered = filtered.to_upper()
	if filtered.length() > 6:
		filtered = filtered.substr(0, 6)

	# Avoid infinite recursion when we modify text from inside the signal
	if filtered != name_input.text:
		name_input.text = filtered
		name_input.caret_column = filtered.length()

	name_error_label.text = ""

func _on_name_confirm_pressed() -> void:
	var name := name_input.text.strip_edges()
	
	if name.length() != 6:
		name_error_label.text = "Name must be 6 characters."
		return
		
	var valid := true
	for i in name.length():
		var ch: String = name[i]
		var code: int = ch.unicode_at(0)
		var is_digit := code >= 48 and code <= 57
		var is_upper := code >= 65 and code <= 90
		
		if not (is_digit or is_upper):
			valid = false
			break
			
	if not valid:
		name_error_label.text = "Only letters and digits allowed."
		return
		
	player_name = name
	_save_player_name()
	name_popup.visible = false

func _load_player_name() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(NAME_SAVE_PATH)
	if err == OK:
		player_name = str(cfg.get_value(NAME_SECTION, NAME_KEY, ""))
	else:
		player_name = ""
	
	if player_name.is_empty():
		_show_name_popup()
		
func _save_player_name() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(NAME_SECTION, NAME_KEY, player_name)
	cfg.save(NAME_SAVE_PATH)
	
func _show_name_popup() -> void:
	name_input.text = ""
	name_error_label.text = ""
	name_popup.visible = true
	
func submit_score_global(name: String, score: int) -> void:
	if name.is_empty():
		return
	
	var url = "%s/rest/v1/%s?on_conflict=username" % [SUPABASE_URL, SUPABASE_TABLE]
	
	var body = {
		"username": name,
		"score": score,
		"recorded_at": Time.get_datetime_string_from_system(true)
	}
	var json_body = JSON.stringify(body)
	
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Authorization: Bearer %s" % SUPABASE_ANON_KEY,
		"Prefer: resolution=merge-duplicates" 
	])
	
	var err := leaderboard_request.request(
		url,
		headers, 
		HTTPClient.METHOD_POST,
		json_body
	)
	
	if err != OK:
		push_warning("Failed to send score: %s" % err)
	
# Fetch top 6 scores
func fetch_top_scores(limit: int = 6) -> void:
	var url = "%s/rest/v1/%s?select=*&order=score.desc,recorded_at.asc&limit=%d" % [
		SUPABASE_URL,
		SUPABASE_TABLE,
		limit
	]
	
	var headers := PackedStringArray([
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Authorization: Bearer %s" % SUPABASE_ANON_KEY
	])

	var err := leaderboard_request.request(
		url,
		headers,
		HTTPClient.METHOD_GET
	)

	if err != OK:
		push_warning("Failed to fetch leaderboard: %s" % err)

func _on_leaderboard_button_pressed() -> void:
	fetch_top_scores(6)

func _on_close_leaderboard_pressed() -> void:
	leaderboard_panel.visible = false
	
func _on_leaderboard_request_completed(
		result: int,
		response_code: int,
		headers: PackedStringArray,
		body: PackedByteArray
	) -> void:
	if response_code < 200 or response_code >= 300:
		push_warning("Leaderboard HTTP error: %d" % response_code)
		return

	var text := body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if parsed == null or not (parsed is Array):
		push_warning("Failed to parse leaderboard JSON")
	return

	_populate_leaderboard_ui(parsed)

func _populate_leaderboard_ui(rows: Array) -> void:
	# Clear old entries
	for child in scores_container.get_children():
		child.queue_free()

	var rank := 1
	for row in rows:
		var username := str(row.get("username", "??????"))
		var score := int(row.get("score", 0))

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.text = "%d. %s  -  %d" % [rank, username, score]

		scores_container.add_child(label)
		rank += 1

	leaderboard_panel.visible = true

	
