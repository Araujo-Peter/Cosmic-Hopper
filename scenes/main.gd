extends Node2D

@onready var score_label: Label = $UI/ScoreLabel

var score: float = 0.0

func _process(delta: float) -> void:
	# Score goes up over time (1 point per second)\
	score += delta
	score_label.text = str(int(score))
