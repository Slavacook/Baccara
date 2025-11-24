# res://scripts/ToastManager.gd
# Менеджер всплывающих уведомлений - подписан на события EventBus
extends Node

const TOAST_SCENE = preload("res://scenes/Toast.tscn")

static var instance: ToastManager

var container: VBoxContainer
var toast_pool: ToastPool  # ← Пул Toast узлов для переиспользования

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	var canvas_layer = get_tree().current_scene.get_node_or_null("UI")
	if canvas_layer:
		container = canvas_layer.get_node_or_null("ToastContainer")

	if not container:
		push_error("ToastContainer not found!")
		return

	# ← Инициализируем пул Toast узлов
	toast_pool = ToastPool.new(container)

	# Подписываемся на события EventBus
	EventBus.show_toast_info.connect(_on_show_toast_info)
	EventBus.show_toast_success.connect(_on_show_toast_success)
	EventBus.show_toast_error.connect(_on_show_toast_error)

	print("🍞 ToastManager готов! Подписан на EventBus. Пул: %d узлов." % ToastPool.POOL_SIZE)

# ═══════════════════════════════════════════════════════════════════════════
# ОБРАБОТЧИКИ СОБЫТИЙ EventBus
# ═══════════════════════════════════════════════════════════════════════════

func _on_show_toast_info(message: String):
	show_info(message)

func _on_show_toast_success(message: String):
	show_success(message)

func _on_show_toast_error(message: String):
	show_error(message)

# ═══════════════════════════════════════════════════════════════════════════
# ПУБЛИЧНЫЕ МЕТОДЫ (для прямых вызовов, если нужно)
# ═══════════════════════════════════════════════════════════════════════════

func show_message(text: String, type: String = "info", duration: float = 2.5):
	if not container or not toast_pool: return

	# ← Берём Toast из пула (переиспользование)
	var toast = toast_pool.get_toast()
	var label_node = toast.get_node("MarginContainer/Label")
	if label_node:
		label_node.text = text
		label_node.add_theme_color_override("font_color", _get_color(type))

	# ← Передаём callback для возврата в пул после анимации
	var return_callback = func(): toast_pool.return_toast(toast)
	toast.show_message(text, duration, return_callback)

func show_error(text: String, duration: float = 3.0):
	show_message(text, "error", duration)

func show_info(text: String, duration: float = 2.5):
	show_message(text, "info", duration)

func show_success(text: String, duration: float = 2.5):
	show_message(text, "success", duration)

func _get_color(type: String) -> Color:
	match type:
		"error": return Color(1, 0.3, 0.3)
		"success": return Color(0.3, 1, 0.3)
		"info": return Color(0.8, 0.8, 1)
		_: return Color.WHITE
