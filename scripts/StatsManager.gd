# res://scripts/StatsManager.gd
class_name StatsManager
extends RefCounted

var stats_label: Label

func _init(label: Label):
	stats_label = label
	SaveManager.instance.load_data()
	update_stats()

func update_stats():
	var data = SaveManager.instance.get_data()
	var total_errors = data.errors.values().reduce(func(a, b): return a + b, 0) if data.errors.size() > 0 else 0
	stats_label.text = "Правильно: %d | Ошибок: %d" % [data.correct, total_errors]

func increment_correct():
	SaveManager.instance.increment_correct()
	update_stats()

func increment_error(type: String):
	SaveManager.instance.increment_error(type)
	update_stats()

func reset():
	SaveManager.instance.reset_stats()
	update_stats()
