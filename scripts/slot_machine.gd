extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var config_json = FileAccess.get_file_as_string("res://scripts/config.json")
	var config = JSON.parse_string(config_json)
	for reel_idx in range(config['reels'].size()):
		var reel_config := config['reels'][reel_idx] as Dictionary
		var reel = Reel.new(reel_config)
		reel.position = Vector2i(reel_idx * 200 + 200, 200)
		add_child(reel)
