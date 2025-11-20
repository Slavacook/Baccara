# res://scripts/ToastManager.gd
class_name ToastManager
extends Node

const TOAST_SCENE = preload("res://scenes/Toast.tscn")

var container: VBoxContainer

func _ready():
	var canvas_layer = get_tree().current_scene.get_node_or_null("UI")
	if canvas_layer:
		container = canvas_layer.get_node_or_null("ToastContainer")
	
	if not container:
		push_error("ToastContainer not found!")

func show_message(text: String, type: String = "info", duration: float = 2.5):
	if not container: return
	
	var toast = TOAST_SCENE.instantiate()
	var label_node = toast.get_node("MarginContainer/Label")
	if label_node:
		label_node.text = text
		label_node.add_theme_color_override("font_color", _get_color(type))
	
	container.add_child(toast)
	toast.show_message(text, duration)

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
