# res://scripts/PayoutPopup.gd
extends PopupPanel

# ← Внутренний класс для управления стопкой фишек
class ChipStack:
	var denomination: float
	var count: int = 0
	var container: PanelContainer  # UI контейнер стопки (кликабельный)
	var texture_rect: TextureRect  # Изображение стека
	var count_label: Label
	var atlas_texture: AtlasTexture  # Для показа части изображения стека
	var full_stack_height: float = 120.0  # Высота полного стека (будет обновлена при загрузке)
	var scale: float = 1.0  # Масштаб стека (1.0 для 6 слотов, 0.6 для 10)

	const MAX_CHIPS = 20
	const BASE_WIDTH = 96  # Базовая ширина стека
	const BASE_HEIGHT = 336  # Базовая высота стека

	func _init(denom: float, stack_scale: float = 1.0):
		denomination = denom
		scale = stack_scale

		# ← PanelContainer для кликабельности (размер зависит от масштаба!)
		container = PanelContainer.new()
		container.custom_minimum_size = Vector2(BASE_WIDTH * scale, BASE_HEIGHT * scale)
		container.size_flags_horizontal = Control.SIZE_FILL  # НЕ растягивать
		container.size_flags_vertical = Control.SIZE_FILL
		container.mouse_filter = Control.MOUSE_FILTER_PASS  # ← Разрешаем события мыши

		# ← Полностью прозрачный фон (убираем серую область)
		var cell_style = StyleBoxFlat.new()
		cell_style.bg_color = Color(0, 0, 0, 0)  # Полностью прозрачный!
		cell_style.border_width_left = 0
		cell_style.border_width_top = 0
		cell_style.border_width_right = 0
		cell_style.border_width_bottom = 0
		container.add_theme_stylebox_override("panel", cell_style)

		# ← Control для абсолютного позиционирования (заполняет весь контейнер)
		var content = Control.new()
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.mouse_filter = Control.MOUSE_FILTER_PASS
		container.add_child(content)

		# ← TextureRect для изображения стека (якорь к нижнему центру!)
		texture_rect = TextureRect.new()
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.visible = false  # ← Скрыт изначально (0 фишек)
		# Якорь: НИЖНИЙ центр (anchor_bottom = 1.0) - фиксированная нижняя граница!
		# Верхняя граница (anchor_top) будет МЕНЯТЬСЯ в зависимости от количества фишек
		texture_rect.anchor_left = 0.5
		texture_rect.anchor_right = 0.5
		texture_rect.anchor_top = 1.0  # Изначально top = bottom (0 высота)
		texture_rect.anchor_bottom = 1.0  # ФИКСИРОВАННАЯ нижняя граница!
		texture_rect.offset_bottom = -25 * scale  # Отступ снизу с учётом масштаба
		texture_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
		content.add_child(texture_rect)

		# ← Label с количеством фишек (якорь к нижнему центру, как стек!)
		count_label = Label.new()
		count_label.text = "0"
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", int(16 * scale))  # Размер шрифта масштабируется!
		count_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))  # Зелёный
		# Якорь: нижний центр (0.5, 1.0) - точно как TextureRect!
		count_label.anchor_left = 0.5
		count_label.anchor_right = 0.5
		count_label.anchor_top = 1.0
		count_label.anchor_bottom = 1.0
		# Центрируем label с учётом масштаба
		count_label.offset_left = -25 * scale
		count_label.offset_right = 25 * scale
		count_label.offset_top = -25 * scale
		content.add_child(count_label)

		# ← Загружаем изображение стека
		# Форматируем номинал: целые числа без .0, дробные как есть
		var denom_str = str(int(denom)) if denom >= 1 else str(denom)
		var stack_path = "res://assets/chips/stack_%s.png" % denom_str
		var full_texture = load(stack_path)

		if full_texture:
			# ← Создаем AtlasTexture для показа части изображения
			atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = full_texture
			full_stack_height = full_texture.get_height()

			# ← Изначально region пустой (0 фишек)
			atlas_texture.region = Rect2(0, full_stack_height, full_texture.get_width(), 0)
			texture_rect.texture = atlas_texture
			print("✓ Стек загружен: ", stack_path, " (размер: ", full_texture.get_width(), "x", full_stack_height, ")")
		else:
			print("✗ Предупреждение: Изображение стека не найдено: ", stack_path)

	# ← Добавить фишку в стопку
	func add_chip() -> bool:
		if count >= MAX_CHIPS:
			return false
		count += 1
		_update_visual()
		return true

	# ← Удалить фишку из стопки
	func remove_chip() -> bool:
		if count <= 0:
			return false
		count -= 1
		_update_visual()
		return true

	# ← Обновить визуальное отображение стека
	func _update_visual():
		count_label.text = str(count)

		if atlas_texture and count > 0:
			var full_width = atlas_texture.atlas.get_width()

			# ← Вычисляем высоту для текущего количества фишек
			# Стек растёт ВВЕРХ от низа, показываем НИЖНЮЮ часть изображения
			var display_height = (full_stack_height * count) / MAX_CHIPS

			# ← Region показывает НИЖНЮЮ часть изображения (стек растет вверх!)
			# y_start начинается с НИЗА минус высота отображения
			var y_start = full_stack_height - display_height

			# ← ВАЖНО: Показываем регион ОТ y_start (нижняя граница стека)
			atlas_texture.region = Rect2(0, y_start, full_width, display_height)

			# ← Устанавливаем размер и позицию TextureRect (масштаб 2x * scale)
			var scaled_width = full_width * 2 * scale
			var scaled_height = display_height * 2 * scale

			# ВАЖНО: offset_left/right для центрирования по горизонтали
			texture_rect.offset_left = -scaled_width / 2
			texture_rect.offset_right = scaled_width / 2

			# КЛЮЧЕВОЕ: offset_top РАСТЕТ ВВЕРХ от нижней границы!
			# Нижняя граница = offset_bottom (-25*scale), верхняя = -25*scale - scaled_height
			var label_height = 25 * scale
			texture_rect.offset_top = -label_height - scaled_height  # Всегда отсчет от НИЗА!
			# offset_bottom уже установлен в _init с учетом scale

			texture_rect.visible = true

			print("  ↳ Стек ", denomination, ": count=", count, " height=", scaled_height, "px (offset_top=", texture_rect.offset_top, ")")
		elif atlas_texture and count == 0:
			# ← При 0 фишек скрываем TextureRect
			texture_rect.visible = false

	# ← Проверка, пуста ли стопка
	func is_empty() -> bool:
		return count == 0

	# ← Получить общую сумму стопки
	func get_total() -> float:
		return denomination * count

	# ← Обновить масштаб стека (при переключении режимов)
	func update_scale(new_scale: float):
		scale = new_scale

		# Обновляем размер контейнера
		container.custom_minimum_size = Vector2(BASE_WIDTH * scale, BASE_HEIGHT * scale)

		# Обновляем offset для TextureRect и Label
		texture_rect.offset_bottom = -25 * scale

		count_label.add_theme_font_size_override("font_size", int(16 * scale))
		count_label.offset_left = -25 * scale
		count_label.offset_right = 25 * scale
		count_label.offset_top = -25 * scale

		# Перерисовываем стек с новым масштабом
		_update_visual()

@onready var result_label = $MarginContainer/VBoxContainer/HeaderHBox/ResultLabel
@onready var stake_label = $MarginContainer/VBoxContainer/HeaderHBox/StakeLabel
@onready var collected_amount_label = $MarginContainer/VBoxContainer/CenterHBox/RightSection/CollectedAmount
@onready var chip_stacks_container = %ChipStacksContainer  # ← Контейнер для стопок
@onready var chip_fleet_label = $MarginContainer/VBoxContainer/ChipFleetLabel
@onready var chip_fleet_container = %ChipFleetContainer
@onready var feedback_label = %FeedbackLabel  # ← Сообщение о правильности
@onready var payout_button = $MarginContainer/VBoxContainer/CenterHBox/RightSection/PayoutButton
@onready var hint_button = $MarginContainer/VBoxContainer/CenterHBox/RightSection/HintButton

signal payout_confirmed(is_correct: bool, collected: float, expected: float)
signal hint_used()  # ← Сигнал использования подсказки

# ← Номиналы фишек (получаются из GameModeManager в зависимости от режима)
var chip_denominations: Array = []

var current_stake: float = 0.0
var current_winner: String = ""  # "Player", "Banker", "Tie"
var expected_payout: float = 0.0
var chip_stacks: Array[ChipStack] = []  # ← Массив стопок фишек (только занятые слоты!)
var stack_slots: Array[Control] = []  # ← Фиксированные слоты для стеков (6 или 10)
var is_button_blocked: bool = false  # ← Блокировка кнопки при ошибке
var current_slot_count: int = 6  # ← Текущее количество слотов (6 или 10)
var current_scale: float = 1.0  # ← Текущий масштаб стеков (1.0 для 6 слотов, меньше для 10)

func _ready():
	# ← Получаем номиналы фишек из GameModeManager
	_update_chip_denominations()

	# ← Подписываемся на изменение режима игры
	GameModeManager.mode_changed.connect(_on_mode_changed)

	# ← Окно занимает большую часть экрана (компактный макет)
	var screen_size = DisplayServer.screen_get_size()
	min_size = Vector2(1000, 600)
	size = Vector2(min(1100, screen_size.x * 0.9), min(650, screen_size.y * 0.85))

	# ← Фиолетовый фон в стиле велюрового стола баккара
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.45, 0.25, 0.55, 0.95)  # Насыщенный фиолетовый
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = Color(0.7, 0.5, 0.2)  # Золотая окантовка
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", stylebox)

	# ← Отступы (компактные)
	$MarginContainer.add_theme_constant_override("margin_left", 25)
	$MarginContainer.add_theme_constant_override("margin_right", 25)
	$MarginContainer.add_theme_constant_override("margin_top", 20)
	$MarginContainer.add_theme_constant_override("margin_bottom", 20)

	# ← Заголовок "БАНКИР" (красный, жирный, большой)
	result_label.add_theme_font_size_override("font_size", 48)
	result_label.add_theme_color_override("font_color", Color(0.8, 0.15, 0.15))  # Красный
	result_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	result_label.add_theme_constant_override("outline_size", 3)

	# ← Ставка (зеленая, обычная)
	stake_label.add_theme_font_size_override("font_size", 28)
	stake_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))  # Зеленоватая

	# ← Число справа внизу (светло-серый, очень крупный)
	collected_amount_label.add_theme_font_size_override("font_size", 72)
	collected_amount_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.7))  # Светло-серый

	# ← Скрываем флот фишек label (не нужен на эскизе)
	chip_fleet_label.visible = false

	# ← ФИКСИРУЕМ размеры контейнеров, чтобы они не влияли друг на друга
	# ChipStacksContainer - только фиксированная высота (ширина зависит от слотов)
	chip_stacks_container.custom_minimum_size = Vector2(0, 360)
	chip_stacks_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# RightSection (кнопка + число) - фиксированная ширина
	var right_section = $MarginContainer/VBoxContainer/CenterHBox/RightSection
	right_section.custom_minimum_size = Vector2(250, 0)
	right_section.size_flags_horizontal = Control.SIZE_SHRINK_END

	# ← Создаём фиксированные слоты для стеков (изначально 6)
	_initialize_stack_slots(6)

	# ← Создаём кнопки номиналов
	_create_chip_buttons()

	# ← Кнопка "Выплата:" (темно-зеленая, как на эскизе)
	payout_button.text = "Выплата:"
	payout_button.add_theme_font_size_override("font_size", 26)
	payout_button.custom_minimum_size = Vector2(200, 60)

	# ← Стиль кнопки (темно-зеленая с черной рамкой, как на эскизе)
	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = Color(0.15, 0.45, 0.4)  # Темно-зеленый (как на эскизе)
	button_style_normal.border_width_left = 3
	button_style_normal.border_width_top = 3
	button_style_normal.border_width_right = 3
	button_style_normal.border_width_bottom = 3
	button_style_normal.border_color = Color(0, 0, 0)  # Черная рамка
	button_style_normal.corner_radius_top_left = 8
	button_style_normal.corner_radius_top_right = 8
	button_style_normal.corner_radius_bottom_left = 8
	button_style_normal.corner_radius_bottom_right = 8
	payout_button.add_theme_stylebox_override("normal", button_style_normal)

	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = Color(0.2, 0.55, 0.5)  # Светлее при наведении
	button_style_hover.border_width_left = 3
	button_style_hover.border_width_top = 3
	button_style_hover.border_width_right = 3
	button_style_hover.border_width_bottom = 3
	button_style_hover.border_color = Color(0.1, 0.1, 0.1)
	button_style_hover.corner_radius_top_left = 8
	button_style_hover.corner_radius_top_right = 8
	button_style_hover.corner_radius_bottom_left = 8
	button_style_hover.corner_radius_bottom_right = 8
	payout_button.add_theme_stylebox_override("hover", button_style_hover)

	# ← Белый текст на кнопке
	payout_button.add_theme_color_override("font_color", Color(1, 1, 1))

	payout_button.pressed.connect(_on_payout_pressed)
	hint_button.pressed.connect(_on_hint_pressed)

# ← Создание фиксированных слотов для стеков
func _initialize_stack_slots(slot_count: int):
	# Очищаем старые слоты, если есть
	for slot in stack_slots:
		chip_stacks_container.remove_child(slot)
		slot.queue_free()
	stack_slots.clear()

	current_slot_count = slot_count
	current_scale = 1.0 if slot_count == 6 else 0.6  # Масштаб для 10 слотов

	# Создаём пустые слоты
	for i in range(slot_count):
		# Используем VBoxContainer для выравнивания по низу
		var slot = VBoxContainer.new()
		slot.custom_minimum_size = Vector2(96 * current_scale, 336)  # ВЫСОТА ФИКСИРОВАНА = 336!
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.alignment = BoxContainer.ALIGNMENT_END  # Выравнивание СНИЗУ!
		chip_stacks_container.add_child(slot)
		stack_slots.append(slot)

	print("Инициализировано ", slot_count, " слотов с масштабом ", current_scale)

# ← Создание кнопок для каждого номинала фишки (1 ряд)
func _create_chip_buttons():
	# ← Очищаем контейнер
	for child in chip_fleet_container.get_children():
		child.queue_free()

	# ← Настраиваем HBoxContainer
	chip_fleet_container.add_theme_constant_override("separation", 10)

	for denomination in chip_denominations:
		# ← TextureButton с иконкой фишки
		var button = TextureButton.new()
		button.custom_minimum_size = Vector2(90, 90)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		# ← Загружаем текстуру фишки
		var denom_str = str(int(denomination)) if denomination >= 1 else str(denomination)
		var chip_path = "res://assets/chips/chip_%s.png" % denom_str
		var texture = load(chip_path)
		if texture:
			button.texture_normal = texture
		else:
			print("Предупреждение: Текстура не найдена: ", chip_path)

		# ← Подключаем сигналы
		button.pressed.connect(_on_chip_clicked.bind(denomination))  # Левый клик = добавить
		button.gui_input.connect(_on_chip_button_input.bind(denomination))  # Правый клик = удалить

		chip_fleet_container.add_child(button)

# ← Форматирование числа: "2345" для целых, "2345.5" для дробных
func _format_amount(amount: float) -> String:
	# Проверяем, является ли число целым
	if amount == floor(amount):
		return str(int(amount))  # "2345"
	else:
		return str(amount)  # "2345.5"

# ← Показать попап с результатом раунда
func show_payout(winner: String, stake: float, payout: float):
	current_winner = winner
	current_stake = stake
	expected_payout = payout

	# ← Очищаем все стопки
	_clear_all_stacks()

	# ← ВАЖНО: Всегда сбрасываем на 6 слотов при новой выплате!
	if current_slot_count != 6:
		_initialize_stack_slots(6)

	# ← Устанавливаем заголовок и цвет
	_set_result_header(winner)

	# ← Ставка рядом с заголовком (форматируем число)
	stake_label.text = Localization.t("PAYOUT_STAKE", [_format_amount(stake)])

	# ← Кнопка "Выплата:" (текст не меняется)
	payout_button.text = "Выплата:"

	# ← Число справа внизу (светло-серое, начинаем с 0)
	collected_amount_label.text = "0"

	popup_centered()

# ← Очистить все стопки фишек
func _clear_all_stacks():
	for i in range(chip_stacks.size()):
		var stack = chip_stacks[i]
		var slot = stack_slots[i]
		slot.remove_child(stack.container)
		stack.container.queue_free()
	chip_stacks.clear()

# ← Переключение на 10 слотов с масштабированием
func _rescale_to_10_slots():
	print("Переключаюсь на 10 слотов...")

	# Сохраняем текущие стеки
	var saved_stacks = chip_stacks.duplicate()

	# Удаляем стеки из старых слотов
	for i in range(saved_stacks.size()):
		var stack = saved_stacks[i]
		var old_slot = stack_slots[i]
		old_slot.remove_child(stack.container)

	# Пересоздаём слоты (10 штук с меньшим масштабом)
	_initialize_stack_slots(10)

	# ВАЖНО: Обновляем масштаб всех существующих стеков!
	for stack in saved_stacks:
		stack.update_scale(current_scale)  # current_scale теперь = 0.6

	# Возвращаем стеки в новые слоты
	chip_stacks.clear()
	for i in range(saved_stacks.size()):
		var stack = saved_stacks[i]
		chip_stacks.append(stack)
		var new_slot = stack_slots[i]
		new_slot.add_child(stack.container)

		# Пересоздаём привязку сигнала с новым индексом
		# ВАЖНО: Отключаем ВСЕ подключения к gui_input перед новым подключением
		for connection in stack.container.gui_input.get_connections():
			if connection["signal"].get_name() == "gui_input":
				stack.container.gui_input.disconnect(connection["callable"])

		# Подключаем сигнал только если он ещё не подключен
		if not stack.container.gui_input.is_connected(_on_stack_gui_input):
			stack.container.gui_input.connect(_on_stack_gui_input.bind(stack, i))

	print("Переключено на 10 слотов (масштаб ", current_scale, "), текущих стеков: ", chip_stacks.size())

# ← Найти позицию для вставки стека (сортировка от крупного к мелкому)
func _find_sorted_position(denomination: float) -> int:
	# Ищем позицию, где стеки становятся меньше данного номинала
	for i in range(chip_stacks.size()):
		if chip_stacks[i].denomination < denomination:
			return i
	# Если все стеки крупнее или массив пуст, добавляем в конец
	return chip_stacks.size()

# ← Пересборка стеков в слотах (после вставки/удаления)
func _rebuild_slots():
	# Удаляем все стеки из слотов
	for i in range(chip_stacks.size()):
		var stack = chip_stacks[i]
		if stack.container.get_parent():
			stack.container.get_parent().remove_child(stack.container)

	# Добавляем стеки обратно в правильном порядке
	for i in range(chip_stacks.size()):
		var stack = chip_stacks[i]
		var slot = stack_slots[i]
		slot.add_child(stack.container)

		# Отключаем старые сигналы и подключаем новые с правильным индексом
		for connection in stack.container.gui_input.get_connections():
			if connection["signal"].get_name() == "gui_input":
				stack.container.gui_input.disconnect(connection["callable"])

		# Подключаем сигнал только если он ещё не подключен
		if not stack.container.gui_input.is_connected(_on_stack_gui_input):
			stack.container.gui_input.connect(_on_stack_gui_input.bind(stack, i))

# ← Сжатие стеков (сдвиг влево после удаления)
func _compact_stacks():
	# Удаляем все стеки из слотов
	for i in range(chip_stacks.size()):
		var stack = chip_stacks[i]
		if stack.container.get_parent():
			stack.container.get_parent().remove_child(stack.container)

	# Добавляем стеки обратно по порядку
	for i in range(chip_stacks.size()):
		var stack = chip_stacks[i]
		var slot = stack_slots[i]
		slot.add_child(stack.container)

		# Пересоздаём привязку сигнала с обновлённым индексом
		# ВАЖНО: Отключаем ВСЕ подключения к gui_input перед новым подключением
		for connection in stack.container.gui_input.get_connections():
			if connection["signal"].get_name() == "gui_input":
				stack.container.gui_input.disconnect(connection["callable"])

		# Подключаем сигнал только если он ещё не подключен
		if not stack.container.gui_input.is_connected(_on_stack_gui_input):
			stack.container.gui_input.connect(_on_stack_gui_input.bind(stack, i))

	# Если стеков <= 6 и текущий режим 10 слотов, возвращаемся к 6
	if chip_stacks.size() <= 6 and current_slot_count == 10:
		print("Возвращаюсь к 6 слотам...")
		var saved_stacks = chip_stacks.duplicate()

		# Удаляем стеки из текущих слотов
		for stack in saved_stacks:
			if stack.container.get_parent():
				stack.container.get_parent().remove_child(stack.container)

		# Пересоздаём 6 слотов
		_initialize_stack_slots(6)

		# ВАЖНО: Обновляем масштаб всех стеков обратно на 1.0!
		for stack in saved_stacks:
			stack.update_scale(current_scale)  # current_scale теперь = 1.0

		# Возвращаем стеки
		chip_stacks.clear()
		for i in range(saved_stacks.size()):
			var stack = saved_stacks[i]
			chip_stacks.append(stack)
			var slot = stack_slots[i]
			slot.add_child(stack.container)

			# Подключаем сигнал только если он ещё не подключен
			if not stack.container.gui_input.is_connected(_on_stack_gui_input):
				stack.container.gui_input.connect(_on_stack_gui_input.bind(stack, i))

		print("Возвращено к 6 слотам (масштаб ", current_scale, ")")

# ← Установка заголовка с цветом
func _set_result_header(winner: String):
	match winner:
		"Banker":
			result_label.text = Localization.t("WIN_BANKER")
			result_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))  # Красный
		"Player":
			result_label.text = Localization.t("WIN_PLAYER")
			result_label.add_theme_color_override("font_color", Color(0.2, 0.4, 0.9))  # Синий
		"Tie":
			result_label.text = Localization.t("WIN_TIE")
			result_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))  # Золотой

# ← Обработка правого клика по кнопке фишки (удаление из последнего стека)
func _on_chip_button_input(event: InputEvent, denomination: float):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# Ищем ПОСЛЕДНИЙ стек данного номинала (справа)
		var target_stack: ChipStack = null
		var target_slot_index: int = -1

		for i in range(chip_stacks.size() - 1, -1, -1):  # С конца!
			var stack = chip_stacks[i]
			if stack.denomination == denomination:
				target_stack = stack
				target_slot_index = i
				break

		if target_stack != null:
			# Удаляем одну фишку
			if target_stack.remove_chip():
				print("Удалена фишка номинала %s, осталось: %d (слот %d)" % [denomination, target_stack.count, target_slot_index])

				# Если стопка опустела, удаляем её
				if target_stack.is_empty():
					var slot = stack_slots[target_slot_index]
					slot.remove_child(target_stack.container)
					target_stack.container.queue_free()
					chip_stacks.erase(target_stack)
					print("Стопка номинала %s удалена (пуста, слот %d)" % [denomination, target_slot_index])

					# Пересобираем слоты
					_compact_stacks()

				_update_total()
		else:
			print("Нет стека номинала %s для удаления" % denomination)

# ← Обработка клика на номинал фишки (добавление фишки в слот)
func _on_chip_clicked(denomination: float):
	# ← НОВАЯ ЛОГИКА: Ищем ПОСЛЕДНИЙ стек этого номинала с свободным местом
	# (чтобы заполнялись слева направо, и удаление было справа)
	var target_stack: ChipStack = null
	var target_slot_index: int = -1

	# Ищем ПОСЛЕДНИЙ стек данного номинала
	for i in range(chip_stacks.size() - 1, -1, -1):  # Идём с конца!
		var stack = chip_stacks[i]
		if stack.denomination == denomination and stack.count < ChipStack.MAX_CHIPS:
			target_stack = stack
			target_slot_index = i
			break

	# ← Если нет подходящей стопки, создаём новую
	if target_stack == null:
		# Проверяем, есть ли свободный слот
		if chip_stacks.size() >= current_slot_count:
			# Нужно переключиться на 10 слотов
			if current_slot_count == 6:
				_rescale_to_10_slots()
			else:
				print("Все слоты заняты! Максимум 10 стеков.")
				return

		# Создаём новый стек с текущим масштабом
		target_stack = ChipStack.new(denomination, current_scale)

		# СОРТИРОВКА: Находим правильную позицию (от крупного к мелкому)
		target_slot_index = _find_sorted_position(denomination)

		# Вставляем стек в нужную позицию
		chip_stacks.insert(target_slot_index, target_stack)

		# Пересобираем все стеки в слотах (так как позиции изменились)
		_rebuild_slots()

	# ← Добавляем фишку в стопку
	if target_stack.add_chip():
		_update_total()
		print("Добавлена фишка номинала %s, всего в стопке: %d (слот %d)" % [denomination, target_stack.count, target_slot_index])
	else:
		print("Стопка полна! (макс 20 фишек)")

# ← Обработка клика на стопку (удаление фишки из ПОСЛЕДНЕГО стека этого номинала!)
func _on_stack_gui_input(event: InputEvent, clicked_stack: ChipStack, _clicked_slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var denomination = clicked_stack.denomination

		# КЛЮЧЕВАЯ ЛОГИКА: Ищем ПОСЛЕДНИЙ (правый) стек данного номинала
		var target_stack: ChipStack = null
		var target_slot_index: int = -1

		for i in range(chip_stacks.size() - 1, -1, -1):  # С конца!
			var stack = chip_stacks[i]
			if stack.denomination == denomination:
				target_stack = stack
				target_slot_index = i
				break

		if target_stack == null:
			print("Ошибка: не найден стек номинала %s" % denomination)
			return

		# ← Удаляем одну фишку из ПОСЛЕДНЕГО стека
		if target_stack.remove_chip():
			print("Удалена фишка номинала %s из последнего стека, осталось: %d (слот %d)" % [denomination, target_stack.count, target_slot_index])

			# ← Если стопка опустела, удаляем её из слота
			if target_stack.is_empty():
				var slot = stack_slots[target_slot_index]
				slot.remove_child(target_stack.container)
				target_stack.container.queue_free()
				chip_stacks.erase(target_stack)
				print("Последний стек номинала %s удалён (пуст, слот %d)" % [denomination, target_slot_index])

				# ← Пересобираем слоты (сдвигаем оставшиеся стеки влево)
				_compact_stacks()

			# ← Обновляем сумму и формулу
			_update_total()
		else:
			print("Последний стек уже пуст!")

# ← Обновить общую сумму (только число справа)
func _update_total():
	var total: float = 0.0

	for stack in chip_stacks:
		if stack.count > 0:
			total += stack.get_total()

	# ← Обновляем светло-серое число справа (форматируем: "2345" или "2345.5")
	collected_amount_label.text = _format_amount(total)

# ← Обработка нажатия кнопки (Этап 4: полная проверка)
func _on_payout_pressed():
	# ← Проверка блокировки
	if is_button_blocked:
		return

	# ← Получаем собранную сумму (float для поддержки 0.5)
	var collected_total: float = 0.0
	for stack in chip_stacks:
		collected_total += stack.get_total()

	# ← Проверяем правильность (с учётом дробных остатков)
	var is_correct = abs(collected_total - expected_payout) < 0.01  # Погрешность для float

	if is_correct:
		_show_success_animation()
	else:
		_show_error_animation(collected_total)

	# ← Отправляем сигнал с результатом
	payout_confirmed.emit(is_correct, collected_total, expected_payout)

# ← Анимация успеха
func _show_success_animation():
	# ← Показываем зелёную надпись "Верно!"
	feedback_label.text = "Верно!"
	feedback_label.add_theme_font_size_override("font_size", 48)
	feedback_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))  # Зелёный

	# ← Закрываем попап через 1 секунду
	await get_tree().create_timer(1.0).timeout
	feedback_label.text = ""
	hide()

# ← Анимация ошибки
func _show_error_animation(_collected: float):
	# ← Блокируем кнопку на 2 секунды
	is_button_blocked = true
	payout_button.disabled = true

	# ← Показываем сообщение об ошибке
	feedback_label.text = "Ошибка!\nПопробуй ещё раз"
	feedback_label.add_theme_font_size_override("font_size", 32)
	feedback_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))  # Красный

	# ← Анимация тряски кнопки (Tween)
	var tween = create_tween()
	var original_pos = payout_button.position
	tween.tween_property(payout_button, "position:x", original_pos.x + 10, 0.05)
	tween.tween_property(payout_button, "position:x", original_pos.x - 10, 0.05)
	tween.tween_property(payout_button, "position:x", original_pos.x + 10, 0.05)
	tween.tween_property(payout_button, "position:x", original_pos.x - 10, 0.05)
	tween.tween_property(payout_button, "position:x", original_pos.x, 0.05)

	# ← Разблокируем кнопку через 2 секунды
	await get_tree().create_timer(2.0).timeout
	is_button_blocked = false
	payout_button.disabled = false
	feedback_label.text = ""

	# ← АВТОМАТИЧЕСКИ ОЧИЩАЕМ ВСЕ ФИШКИ для нового ввода
	_clear_all_stacks()

# ← Обновить номиналы фишек из GameModeManager
func _update_chip_denominations():
	chip_denominations = GameModeManager.get_chip_denominations()
	print("Номиналы фишек обновлены: ", chip_denominations)

# ← Обработчик изменения режима игры
func _on_mode_changed(_mode: String):
	# Обновляем номиналы
	_update_chip_denominations()

	# Пересоздаём кнопки фишек с новыми номиналами
	_create_chip_buttons()

	# Очищаем текущие стеки
	_clear_all_stacks()
	collected_amount_label.text = "0"

# ← Обработчик кнопки подсказки
func _on_hint_pressed():
	# Очищаем текущие стопки
	_clear_all_stacks()

	# Автоматически заполняем правильную сумму
	var remaining = expected_payout
	var sorted_denoms = chip_denominations.duplicate()
	sorted_denoms.sort()
	sorted_denoms.reverse()  # От большего к меньшему

	# Жадный алгоритм: берём максимально крупные номиналы
	for denom in sorted_denoms:
		while remaining >= denom - 0.01:  # ← Учитываем погрешность float
			# Добавляем фишку
			_on_chip_clicked(denom)
			remaining -= denom

			if remaining < 0.01:  # ← Учитываем погрешность float
				break

		if remaining < 0.01:  # ← Учитываем погрешность float
			break

	# Обновляем отображение
	_update_total()

	# Отправляем сигнал что использована подсказка
	hint_used.emit()
	print("💡 Подсказка использована! Ожидаемая выплата: ", expected_payout)
