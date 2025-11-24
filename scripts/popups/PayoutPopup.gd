# res://scripts/popups/PayoutPopup.gd
# Попап для расчёта выплаты с использованием фишек
# Использует модульную архитектуру: ChipStack, ChipStackManager, PayoutValidator

extends PopupPanel

# ═══════════════════════════════════════════════════════════════════════════
# UI ЭЛЕМЕНТЫ
# ═══════════════════════════════════════════════════════════════════════════

@onready var result_label = $MarginContainer/VBoxContainer/HeaderHBox/ResultLabel
@onready var stake_label = $MarginContainer/VBoxContainer/HeaderHBox/StakeLabel
@onready var collected_amount_label = $MarginContainer/VBoxContainer/CenterHBox/RightSection/CollectedAmount
@onready var chip_stacks_container = %ChipStacksContainer
@onready var chip_fleet_label = $MarginContainer/VBoxContainer/ChipFleetLabel
@onready var chip_fleet_container = %ChipFleetContainer
@onready var feedback_label = %FeedbackLabel  # ← Теперь в FeedbackContainer
@onready var feedback_container = $FeedbackContainer  # ← Контейнер для управления видимостью
@onready var payout_button = $MarginContainer/VBoxContainer/CenterHBox/RightSection/PayoutButton
@onready var hint_button = $MarginContainer/VBoxContainer/CenterHBox/RightSection/HintButton

# ═══════════════════════════════════════════════════════════════════════════
# СИГНАЛЫ
# ═══════════════════════════════════════════════════════════════════════════

signal payout_confirmed(is_correct: bool, collected: float, expected: float)
signal hint_used()

# ═══════════════════════════════════════════════════════════════════════════
# МОДУЛИ
# ═══════════════════════════════════════════════════════════════════════════

var stack_manager: ChipStackManager  # Управление стопками фишек
var validator: PayoutValidator       # Валидация выплаты

# ═══════════════════════════════════════════════════════════════════════════
# ПЕРЕМЕННЫЕ
# ═══════════════════════════════════════════════════════════════════════════

var chip_denominations: Array = []  # Номиналы фишек (из GameModeManager)
var current_stake: float = 0.0      # Текущая ставка
var current_winner: String = ""     # "Player", "Banker", "Tie"
var expected_payout: float = 0.0    # Ожидаемая выплата
var is_button_blocked: bool = false # Блокировка кнопки при ошибке

# ═══════════════════════════════════════════════════════════════════════════
# ИНИЦИАЛИЗАЦИЯ
# ═══════════════════════════════════════════════════════════════════════════

func _ready():
	# Создаём модули
	stack_manager = ChipStackManager.new(chip_stacks_container)
	validator = PayoutValidator.new()

	# Подписываемся на события
	stack_manager.total_changed.connect(_on_total_changed)
	stack_manager.stack_added.connect(_on_stack_added)
	GameModeManager.mode_changed.connect(_on_mode_changed)

	# Получаем номиналы фишек
	_update_chip_denominations()

	# Настройка окна
	_setup_window()
	_setup_styles()

	# Скрываем флот фишек label
	chip_fleet_label.visible = false

	# Скрываем контейнер обратной связи по умолчанию
	feedback_container.visible = false

	# Создаём кнопки номиналов
	_create_chip_buttons()

	# Подключаем сигналы кнопок
	payout_button.pressed.connect(_on_payout_pressed)
	hint_button.pressed.connect(_on_hint_pressed)

# ═══════════════════════════════════════════════════════════════════════════
# ПУБЛИЧНЫЕ МЕТОДЫ
# ═══════════════════════════════════════════════════════════════════════════

# ← Показать попап с результатом раунда
func show_payout(winner: String, stake: float, payout: float):
	current_winner = winner
	current_stake = stake
	expected_payout = payout

	# Очищаем все стопки
	stack_manager.clear_all()

	# Устанавливаем заголовок и цвет
	_set_result_header(winner)

	# Ставка рядом с заголовком
	stake_label.text = Localization.t("PAYOUT_STAKE", [_format_amount(stake)])

	# Кнопка "Выплата:"
	payout_button.text = "Выплата:"

	# Число справа внизу (начинаем с 0)
	collected_amount_label.text = "0"

	# Показываем попап с отступом сверху, чтобы не перекрывать Сердечки
	popup_centered()
	var screen_size = DisplayServer.screen_get_size()
	position.y = 80  # ← Отступ сверху для Сердечек (они на высоте 10-60px)

# ═══════════════════════════════════════════════════════════════════════════
# ОБРАБОТЧИКИ СОБЫТИЙ
# ═══════════════════════════════════════════════════════════════════════════

# ← Обработка клика на номинал фишки (добавление)
func _on_chip_clicked(denomination: float):
	stack_manager.add_chip(denomination)

# ← Обработка правого клика по кнопке фишки (удаление)
func _on_chip_button_input(event: InputEvent, denomination: float):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		stack_manager.remove_chip(denomination)

# ← Обработчик добавления новой стопки (подключаем обработчик кликов)
func _on_stack_added(stack: ChipStack, _index: int):
	# Подключаем обработчик кликов к контейнеру стопки
	stack.container.gui_input.connect(_on_stack_clicked.bind(stack))

# ← Обработка клика на стопку (удаление из последнего стека)
func _on_stack_clicked(event: InputEvent, stack: ChipStack):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stack_manager.remove_chip(stack.denomination)

# ← Обновление суммы при изменении стопок
func _on_total_changed(new_total: float):
	collected_amount_label.text = _format_amount(new_total)

# ← Обработка нажатия кнопки "Выплата:"
func _on_payout_pressed():
	if is_button_blocked:
		return

	var collected_total = stack_manager.get_total()
	var is_correct = validator.validate(collected_total, expected_payout)

	if is_correct:
		_show_success_animation()
	else:
		_show_error_animation(collected_total)

	payout_confirmed.emit(is_correct, collected_total, expected_payout)

# ← Обработка кнопки подсказки
func _on_hint_pressed():
	# Очищаем текущие стопки
	stack_manager.clear_all()

	# Рассчитываем оптимальное распределение фишек
	var hint = validator.calculate_hint(expected_payout, chip_denominations)

	# Добавляем фишки согласно подсказке
	for item in hint:
		var denomination = item["denomination"]
		var count = item["count"]

		for i in range(count):
			stack_manager.add_chip(denomination)

	# Отправляем сигнал
	hint_used.emit()
	print("💡 Подсказка использована! Ожидаемая выплата: %s" % expected_payout)

# ← Обработчик изменения режима игры
func _on_mode_changed(_mode: String):
	_update_chip_denominations()
	_create_chip_buttons()
	stack_manager.clear_all()
	collected_amount_label.text = "0"

# ═══════════════════════════════════════════════════════════════════════════
# ПРИВАТНЫЕ МЕТОДЫ - НАСТРОЙКА UI
# ═══════════════════════════════════════════════════════════════════════════

func _setup_window():
	var screen_size = DisplayServer.screen_get_size()
	min_size = GameConstants.PAYOUT_POPUP_MIN_SIZE
	size = Vector2(
		min(GameConstants.PAYOUT_POPUP_MAX_WIDTH, screen_size.x * GameConstants.PAYOUT_POPUP_WIDTH_MULT),
		min(GameConstants.PAYOUT_POPUP_MAX_HEIGHT, screen_size.y * GameConstants.PAYOUT_POPUP_HEIGHT_MULT)
	)

func _setup_styles():
	# Фиолетовый фон в стиле велюрового стола баккара
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.45, 0.25, 0.55, 0.97)  # ← Вернули непрозрачность
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = Color(0.7, 0.5, 0.2)  # ← Рамка непрозрачная
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", stylebox)

	# Отступы
	$MarginContainer.add_theme_constant_override("margin_left", GameConstants.PAYOUT_POPUP_MARGIN)
	$MarginContainer.add_theme_constant_override("margin_right", GameConstants.PAYOUT_POPUP_MARGIN)
	$MarginContainer.add_theme_constant_override("margin_top", GameConstants.PAYOUT_POPUP_MARGIN_TOP)
	$MarginContainer.add_theme_constant_override("margin_bottom", GameConstants.PAYOUT_POPUP_MARGIN_BOTTOM)

	# Заголовок
	result_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_RESULT_LABEL)
	result_label.add_theme_color_override("font_color", Color(0.8, 0.15, 0.15))
	result_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	result_label.add_theme_constant_override("outline_size", 3)

	# Ставка
	stake_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_STAKE_LABEL)
	stake_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))

	# Число справа
	collected_amount_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_COLLECTED_AMOUNT)
	collected_amount_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.7))

	# Размеры контейнеров
	chip_stacks_container.custom_minimum_size = Vector2(0, GameConstants.CHIP_STACKS_CONTAINER_HEIGHT)
	chip_stacks_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var right_section = $MarginContainer/VBoxContainer/CenterHBox/RightSection
	right_section.custom_minimum_size = Vector2(GameConstants.RIGHT_SECTION_WIDTH, 0)
	right_section.size_flags_horizontal = Control.SIZE_SHRINK_END

	# Кнопка "Выплата:"
	payout_button.text = "Выплата:"
	payout_button.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_PAYOUT_BUTTON)
	payout_button.custom_minimum_size = GameConstants.PAYOUT_BUTTON_SIZE

	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = Color(0.15, 0.45, 0.4)
	button_style_normal.border_width_left = 3
	button_style_normal.border_width_top = 3
	button_style_normal.border_width_right = 3
	button_style_normal.border_width_bottom = 3
	button_style_normal.border_color = Color(0, 0, 0)
	button_style_normal.corner_radius_top_left = 8
	button_style_normal.corner_radius_top_right = 8
	button_style_normal.corner_radius_bottom_left = 8
	button_style_normal.corner_radius_bottom_right = 8
	payout_button.add_theme_stylebox_override("normal", button_style_normal)

	var button_style_hover = StyleBoxFlat.new()
	button_style_hover.bg_color = Color(0.2, 0.55, 0.5)
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

	payout_button.add_theme_color_override("font_color", Color(1, 1, 1))

# ← Создание кнопок для каждого номинала фишки
func _create_chip_buttons():
	# Очищаем контейнер
	for child in chip_fleet_container.get_children():
		child.queue_free()

	chip_fleet_container.add_theme_constant_override("separation", 10)

	for denomination in chip_denominations:
		var button = TextureButton.new()
		button.custom_minimum_size = GameConstants.CHIP_BUTTON_SIZE
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		# Загружаем текстуру фишки
		var denom_str = str(int(denomination)) if denomination >= 1 else str(denomination)
		var chip_path = GameConstants.CHIP_TEXTURE_PATH_TEMPLATE % denom_str
		var texture = load(chip_path)
		if texture:
			button.texture_normal = texture
		else:
			push_warning("PayoutPopup: текстура не найдена: %s" % chip_path)

		# Подключаем сигналы
		button.pressed.connect(_on_chip_clicked.bind(denomination))
		button.gui_input.connect(_on_chip_button_input.bind(denomination))

		chip_fleet_container.add_child(button)

# ← Установка заголовка с цветом
func _set_result_header(winner: String):
	match winner:
		"Banker":
			result_label.text = Localization.t("WIN_BANKER")
			result_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		"Player":
			result_label.text = Localization.t("WIN_PLAYER")
			result_label.add_theme_color_override("font_color", Color(0.2, 0.4, 0.9))
		"Tie":
			result_label.text = Localization.t("WIN_TIE")
			result_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))

# ← Обновить номиналы фишек из GameModeManager
func _update_chip_denominations():
	chip_denominations = GameModeManager.get_chip_denominations()
	print("PayoutPopup: Номиналы фишек обновлены: ", chip_denominations)

# ← Форматирование числа
func _format_amount(amount: float) -> String:
	if amount == floor(amount):
		return str(int(amount))
	else:
		return str(amount)

# ═══════════════════════════════════════════════════════════════════════════
# АНИМАЦИИ
# ═══════════════════════════════════════════════════════════════════════════

func _show_success_animation():
	feedback_container.visible = true
	feedback_label.text = "Верно!"
	feedback_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_RESULT_LABEL * 2)  # ← Крупнее
	feedback_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	feedback_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	feedback_label.add_theme_constant_override("outline_size", 5)

	await get_tree().create_timer(GameConstants.SUCCESS_ANIMATION_DURATION).timeout
	feedback_container.visible = false
	feedback_label.text = ""
	hide()

func _show_error_animation(collected: float):
	is_button_blocked = true
	payout_button.disabled = true

	feedback_container.visible = true
	var error_msg = validator.get_error_message(collected, expected_payout)
	feedback_label.text = "Ошибка!\n%s" % error_msg
	feedback_label.add_theme_font_size_override("font_size", GameConstants.FONT_SIZE_FEEDBACK_ERROR * 1.5)  # ← Крупнее
	feedback_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	feedback_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	feedback_label.add_theme_constant_override("outline_size", 5)

	# Анимация тряски кнопки
	var tween = create_tween()
	var original_pos = payout_button.position
	var shake = GameConstants.SHAKE_OFFSET
	var dur = GameConstants.SHAKE_DURATION
	tween.tween_property(payout_button, "position:x", original_pos.x + shake, dur)
	tween.tween_property(payout_button, "position:x", original_pos.x - shake, dur)
	tween.tween_property(payout_button, "position:x", original_pos.x + shake, dur)
	tween.tween_property(payout_button, "position:x", original_pos.x - shake, dur)
	tween.tween_property(payout_button, "position:x", original_pos.x, dur)

	await get_tree().create_timer(GameConstants.ERROR_ANIMATION_DURATION).timeout
	is_button_blocked = false
	payout_button.disabled = false
	feedback_container.visible = false
	feedback_label.text = ""

	# Автоматически очищаем все фишки
	stack_manager.clear_all()
