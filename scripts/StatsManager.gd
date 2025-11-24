# res://scripts/StatsManager.gd
# Менеджер статистики - подписан на события EventBus
extends Node

static var instance: StatsManager

var stats_label: Label = null  # Будет установлена из GameController

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	# Подписываемся на события EventBus
	EventBus.action_correct.connect(_on_action_correct)
	EventBus.action_error.connect(_on_action_error)
	EventBus.payout_correct.connect(_on_payout_correct)
	EventBus.payout_wrong.connect(_on_payout_wrong)

	print("📊 StatsManager готов! Подписан на EventBus.")

	# Загружаем статистику
	SaveManager.instance.load_data()

# ← Установить Label из GameController
func set_label(label: Label):
	stats_label = label
	update_stats()

# ← Обновить текст статистики
func update_stats():
	if not stats_label:
		return

	var data = SaveManager.instance.get_data()
	var total_errors = data.errors.values().reduce(func(a, b): return a + b, 0) if data.errors.size() > 0 else 0
	stats_label.text = "Правильно: %d | Ошибок: %d" % [data.correct, total_errors]

# ← Сбросить статистику
func reset():
	SaveManager.instance.reset_stats()
	update_stats()

# ═══════════════════════════════════════════════════════════════════════════
# ОБРАБОТЧИКИ СОБЫТИЙ EventBus
# ═══════════════════════════════════════════════════════════════════════════

func _on_action_correct(_type: String):
	SaveManager.instance.increment_correct()
	update_stats()

func _on_action_error(type: String, _message: String):
	SaveManager.instance.increment_error(type)
	update_stats()

func _on_payout_correct(_collected: float, _expected: float):
	SaveManager.instance.increment_correct()
	update_stats()

func _on_payout_wrong(_collected: float, _expected: float):
	SaveManager.instance.increment_error("payout_wrong")
	update_stats()
