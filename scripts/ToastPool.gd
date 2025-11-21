# res://scripts/ToastPool.gd
# Пул Toast узлов для переиспользования (избегаем частого instantiate/queue_free)
class_name ToastPool
extends RefCounted

const TOAST_SCENE = preload("res://scenes/Toast.tscn")
const POOL_SIZE = 5  # Макс. 5 одновременных тостов

var available_toasts: Array = []  # Свободные Toast узлы
var active_toasts: Array = []  # Активные Toast узлы
var container: VBoxContainer  # Контейнер для Toast

func _init(toast_container: VBoxContainer):
	container = toast_container
	_create_pool()

# Создать пул из POOL_SIZE узлов
func _create_pool():
	for i in range(POOL_SIZE):
		var toast = TOAST_SCENE.instantiate()
		toast.visible = false
		toast.modulate.a = 0.0
		available_toasts.append(toast)
		# НЕ добавляем в дерево сразу - только при использовании

# Взять Toast из пула (или создать новый, если пул пуст)
func get_toast() -> Node:
	var toast: Node

	if available_toasts.size() > 0:
		toast = available_toasts.pop_back()
	else:
		# Пул исчерпан - создаём временный узел (будет удалён после использования)
		toast = TOAST_SCENE.instantiate()
		print("⚠️ ToastPool исчерпан, создан временный Toast")

	# Добавляем в дерево и активные
	if not toast.is_inside_tree():
		container.add_child(toast)

	toast.visible = true
	active_toasts.append(toast)
	return toast

# Вернуть Toast в пул после использования
func return_toast(toast: Node):
	if not is_instance_valid(toast):
		return

	# Убираем из активных
	var idx = active_toasts.find(toast)
	if idx >= 0:
		active_toasts.remove_at(idx)

	# Проверяем, был ли это узел из пула (или временный)
	var is_pool_node = available_toasts.size() < POOL_SIZE

	if is_pool_node:
		# Сбрасываем состояние и возвращаем в пул
		toast.visible = false
		toast.modulate.a = 0.0

		# НЕ удаляем из дерева - оставляем для переиспользования
		# (это быстрее, чем удалять/добавлять каждый раз)

		available_toasts.append(toast)
	else:
		# Временный узел - удаляем
		if toast.get_parent():
			toast.get_parent().remove_child(toast)
		toast.queue_free()

# Очистить пул (при выходе из игры)
func clear():
	for toast in available_toasts:
		if is_instance_valid(toast):
			if toast.get_parent():
				toast.get_parent().remove_child(toast)
			toast.queue_free()

	for toast in active_toasts:
		if is_instance_valid(toast):
			if toast.get_parent():
				toast.get_parent().remove_child(toast)
			toast.queue_free()

	available_toasts.clear()
	active_toasts.clear()
