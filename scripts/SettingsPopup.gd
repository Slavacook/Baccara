# res://scripts/SettingsPopup.gd
extends PopupPanel

signal mode_changed(mode: String)  # "junket" или "classic"
signal language_changed(lang: String)
signal survival_mode_changed(enabled: bool)  # вкл/выкл режим выживания

enum GameMode { JUNKET, CLASSIC }

var current_mode: GameMode = GameMode.JUNKET
var survival_mode_enabled: bool = false  # Режим выживания выключен по умолчанию

# UI элементы
@onready var junket_button: Button
@onready var classic_button: Button
@onready var mode_info_label: Label
@onready var ru_button: Button
@onready var en_button: Button
@onready var survival_checkbox: CheckButton
@onready var close_button: Button
@onready var bet_profile_button: OptionButton  # Переключатель профиля ставок

func _ready():
	# Скрываем попап при запуске
	hide()

	# ← Устанавливаем непрозрачный фон
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.25, 1.0)  # Тёмно-серый, непрозрачный
	stylebox.border_width_left = 4
	stylebox.border_width_top = 4
	stylebox.border_width_right = 4
	stylebox.border_width_bottom = 4
	stylebox.border_color = Color(0.6, 0.5, 0.3)  # Золотистая рамка
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", stylebox)

	# Получаем ссылки на элементы (с проверкой наличия)
	if has_node("Panel/VBox/ModeContainer/JunketButton"):
		junket_button = get_node("Panel/VBox/ModeContainer/JunketButton")
		junket_button.pressed.connect(_on_junket_pressed)

	if has_node("Panel/VBox/ModeContainer/ClassicButton"):
		classic_button = get_node("Panel/VBox/ModeContainer/ClassicButton")
		classic_button.pressed.connect(_on_classic_pressed)

	if has_node("Panel/VBox/ModeInfoLabel"):
		mode_info_label = get_node("Panel/VBox/ModeInfoLabel")

	if has_node("Panel/VBox/LangContainer/RuButton"):
		ru_button = get_node("Panel/VBox/LangContainer/RuButton")
		ru_button.pressed.connect(_on_ru_pressed)

	if has_node("Panel/VBox/LangContainer/EnButton"):
		en_button = get_node("Panel/VBox/LangContainer/EnButton")
		en_button.pressed.connect(_on_en_pressed)

	if has_node("Panel/VBox/SurvivalContainer/SurvivalCheckbox"):
		survival_checkbox = get_node("Panel/VBox/SurvivalContainer/SurvivalCheckbox")
		survival_checkbox.toggled.connect(_on_survival_toggled)

	if has_node("Panel/VBox/CloseButton"):
		close_button = get_node("Panel/VBox/CloseButton")
		close_button.pressed.connect(_on_close_pressed)

	# Инициализация BetProfileButton (OptionButton)
	if has_node("Panel/VBox/BetProfile/BetProfileButton"):
		bet_profile_button = get_node("Panel/VBox/BetProfile/BetProfileButton")
		_setup_bet_profile_button()

	# Обновляем UI
	_update_mode_buttons()
	_update_mode_info()
	_update_lang_buttons()
	_update_survival_checkbox()
	_update_bet_profile_button()

func _on_junket_pressed():
	current_mode = GameMode.JUNKET
	_update_mode_buttons()
	_update_mode_info()
	mode_changed.emit("junket")

func _on_classic_pressed():
	current_mode = GameMode.CLASSIC
	_update_mode_buttons()
	_update_mode_info()
	mode_changed.emit("classic")

func _on_ru_pressed():
	Localization.set_lang("ru")
	_update_lang_buttons()
	language_changed.emit("ru")

func _on_en_pressed():
	Localization.set_lang("en")
	_update_lang_buttons()
	language_changed.emit("en")

func _on_survival_toggled(pressed: bool):
	survival_mode_enabled = pressed
	survival_mode_changed.emit(pressed)

func _on_close_pressed():
	hide()

func _update_mode_buttons():
	# Выделяем активную кнопку режима
	if not junket_button or not classic_button:
		return

	if current_mode == GameMode.JUNKET:
		junket_button.disabled = true
		classic_button.disabled = false
	else:
		junket_button.disabled = false
		classic_button.disabled = true

func _update_lang_buttons():
	# Выделяем активную кнопку языка
	if not ru_button or not en_button:
		return

	var current_lang = Localization.get_lang()
	ru_button.disabled = (current_lang == "ru")
	en_button.disabled = (current_lang == "en")

func _update_mode_info():
	if not mode_info_label:
		return

	if current_mode == GameMode.JUNKET:
		mode_info_label.text = """Основные ставки: 2000-200000, шаг 500
Tie: 100-900, шаг 25
Пары: 100-900, шаг 25
Комиссия банкира: 95%"""
	else:  # CLASSIC
		mode_info_label.text = """Основные ставки: 50-3000, шаг 1
Tie: 25-300, шаг 1
Пары: 25-200, шаг 1
Комиссия банкира: 50%"""

func _update_survival_checkbox():
	if survival_checkbox:
		survival_checkbox.button_pressed = survival_mode_enabled

func get_current_mode() -> String:
	return "junket" if current_mode == GameMode.JUNKET else "classic"

func set_game_mode(game_mode: String):
	if game_mode == "junket":
		current_mode = GameMode.JUNKET
	else:
		current_mode = GameMode.CLASSIC
	_update_mode_buttons()

func set_survival_mode(enabled: bool):
	survival_mode_enabled = enabled
	_update_survival_checkbox()

# ═══════════════════════════════════════════════════════════════════════════
# ПРОФИЛИ СТАВОК
# ═══════════════════════════════════════════════════════════════════════════

func _setup_bet_profile_button():
	if not bet_profile_button:
		return

	# Очищаем существующие опции
	bet_profile_button.clear()

	# Добавляем все 3 профиля
	bet_profile_button.add_item(Localization.t("BET_PROFILE_SMALL"), 0)   # SMALL
	bet_profile_button.add_item(Localization.t("BET_PROFILE_MEDIUM"), 1)  # MEDIUM
	bet_profile_button.add_item(Localization.t("BET_PROFILE_LARGE"), 2)   # LARGE

	# Устанавливаем текущий профиль
	bet_profile_button.selected = BetProfileManager.get_profile()

	# Подключаем сигнал
	bet_profile_button.item_selected.connect(_on_bet_profile_selected)

func _on_bet_profile_selected(index: int):
	# index = 0 (SMALL), 1 (MEDIUM), 2 (LARGE)
	BetProfileManager.set_profile(index as BetProfileManager.BetProfile)
	print("💰 Профиль ставок изменён: %s" % BetProfileManager.get_profile_name())

func _update_bet_profile_button():
	if not bet_profile_button:
		return

	# Обновляем выбранный элемент (на случай изменения из другого места)
	bet_profile_button.selected = BetProfileManager.get_profile()
