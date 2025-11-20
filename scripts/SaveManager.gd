# res://scripts/SaveManager.gd
extends Node

static var instance: SaveManager

const SAVE_PATH = "user://baccarat_stats.save"
const SETTINGS_PATH = "user://baccarat_settings.save"

var total: int = 0
var correct: int = 0
var errors: Dictionary = {}

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	load_data()

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var({"total": total, "correct": correct, "errors": errors})
		file.close()

func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			file.close()
			if data is Dictionary:
				total = data.get("total", 0)
				correct = data.get("correct", 0)
				errors = data.get("errors", {})

func get_data() -> Dictionary:
	return {"total": total, "correct": correct, "errors": errors}

func increment_total():
	total += 1
	save_data()

func increment_correct():
	correct += 1
	save_data()

func increment_error(type: String):
	errors[type] = errors.get(type, 0) + 1
	save_data()

func reset_stats():
	total = 0
	correct = 0
	errors = {}
	save_data()

# ← Управление настройками игры
func save_settings(settings: Dictionary):
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()

func load_settings() -> Dictionary:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			file.close()
			if data is Dictionary:
				return data
	return {"game_mode": "junket", "survival_mode": false}  # По умолчанию

func save_game_mode(mode: String):
	var settings = load_settings()
	settings["game_mode"] = mode
	save_settings(settings)

func load_game_mode() -> String:
	var settings = load_settings()
	return settings.get("game_mode", "junket")

func save_survival_mode(enabled: bool):
	var settings = load_settings()
	settings["survival_mode"] = enabled
	save_settings(settings)

func load_survival_mode() -> bool:
	var settings = load_settings()
	return settings.get("survival_mode", false)
