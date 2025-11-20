# res://scripts/GameController.gd
extends Node2D

@export var config: GameConfig

var deck: Deck
var card_manager: CardTextureManager
var ui_manager: UIManager
var phase_manager: GamePhaseManager
var toast_manager: ToastManager
var bet_manager: BetManager
var stats_manager: StatsManager
var limits_manager: LimitsManager
var limits_popup: PopupPanel
var limits_button: Button
var payout_popup: PopupPanel  # ← Новый попап выплат
var settings_popup: PopupPanel  # ← Попап настроек (новое)
var settings_button: Button  # ← Кнопка настроек (новое)
var survival_ui: Control  # ← Режим выживания
var game_over_popup: PopupPanel  # ← Попап окончания игры
var survival_rounds_completed: int = 0
var is_survival_mode: bool = false

func _ready():
	Localization.set_lang("ru")
	
	deck = Deck.new()
	
	if not config:
		config = GameConfig.new()
	
	card_manager = CardTextureManager.new(config)
	toast_manager = ToastManager.new()
	add_child(toast_manager)
	
	ui_manager = UIManager.new(self, card_manager)
	
	# ← Сначала stats_manager
	stats_manager = StatsManager.new(ui_manager.stats_label)
	
	# ← Лимиты
	limits_manager = LimitsManager.new(config)
	limits_popup = get_node("LimitsPopup")
	limits_button = get_node("LimitsButton")
	limits_button.pressed.connect(_on_limits_button_pressed)
	limits_popup.limits_changed.connect(limits_manager.set_limits)
	limits_manager.limits_changed.connect(_on_limits_changed)

	# ← Попап выплат
	payout_popup = get_node("PayoutPopup")
	payout_popup.payout_confirmed.connect(_on_payout_confirmed)
	payout_popup.hint_used.connect(_on_hint_used)

	# ← Режим выживания
	survival_ui = get_node("UI/SurvivalModeUI")
	survival_ui.game_over.connect(_on_survival_game_over)

	# ← Попап Game Over
	game_over_popup = get_node("GameOverPopup")
	game_over_popup.restart_game.connect(_on_restart_game)

	# ← Попап настроек (новое)
	if has_node("SettingsPopup"):
		settings_popup = get_node("SettingsPopup")
		settings_popup.mode_changed.connect(_on_mode_changed)
		settings_popup.language_changed.connect(_on_language_changed)
		settings_popup.survival_mode_changed.connect(_on_survival_mode_changed)

	# ← Кнопка настроек (новое)
	if has_node("SettingsButton"):
		settings_button = get_node("SettingsButton")
		settings_button.pressed.connect(_on_settings_button_pressed)

	# ← Загружаем сохранённые настройки
	GameModeManager.load_saved_mode()
	_load_survival_mode_setting()
	
	# ← Фазы и ставки
	phase_manager = GamePhaseManager.new(deck, card_manager, ui_manager, toast_manager, stats_manager)
	phase_manager.set_game_controller(self)  # ← Передаём ссылку на GameController
	bet_manager = BetManager.new(
		ui_manager.bet_popup,
		ui_manager.bet_chip,
		ui_manager.tie_chip,
		config.commission_rate
	)
	
	# Сигналы
	ui_manager.action_button_pressed.connect(phase_manager.on_action_pressed)
	ui_manager.player_third_toggled.connect(phase_manager.on_player_third_toggled)
	ui_manager.banker_third_toggled.connect(phase_manager.on_banker_third_toggled)
	ui_manager.winner_selected.connect(_on_winner_selected)
	ui_manager.help_button_pressed.connect(_on_help_button_pressed)
	ui_manager.lang_button_pressed.connect(_on_lang_button_pressed)
	# bet_manager.bet_confirmed.connect(_on_bet_confirmed)  # ← Старая система, заменена на PayoutPopup
	
	phase_manager.reset()
	ui_manager.help_popup.hide()
	ui_manager.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))

	# ← Инициализация лимитов из GameModeManager (не из config!)
	var cfg = GameModeManager.get_config()
	limits_manager.set_limits(
		cfg["main_min"], cfg["main_max"], cfg["main_step"],
		cfg["tie_min"], cfg["tie_max"], cfg["tie_step"]
	)  # ← Это вызовет сигнал limits_changed и покажет тост автоматически

	stats_manager.update_stats()

func _on_limits_button_pressed():
	limits_popup.show_current_limits(
		limits_manager.min_bet,
		limits_manager.max_bet,
		limits_manager.step,
		limits_manager.tie_min,
		limits_manager.tie_max,
		limits_manager.tie_step
	)

func _on_limits_changed(min_bet: int, max_bet: int, step: int, tie_min: int, tie_max: int, tie_step: int):
	toast_manager.show_info(
		"Лимиты: %d–%d (шаг %d)\nTIE: %d–%d (шаг %d)" % 
		[min_bet, max_bet, step, tie_min, tie_max, tie_step]
	)

func _on_winner_selected(chosen: String):
	# ← ИСПРАВЛЕНО: Проверяем, можно ли выбирать победителя (игра завершена)
	if not phase_manager.can_choose_winner():
		toast_manager.show_error(Localization.t("ERR_FINISH_DEAL"))
		stats_manager.increment_error("winner_early")  # ← Ошибка: выбор победителя раньше времени
		if is_survival_mode:
			survival_ui.lose_life()
		return

	var actual = BaccaratRules.get_winner(phase_manager.player_hand, phase_manager.banker_hand)
	var res = _format_result()
	var t = Localization.t("WIN_PLAYER") if actual == "Player" else Localization.t("WIN_BANKER") if actual == "Banker" else Localization.t("WIN_TIE")
	var chosen_t = Localization.t("WIN_PLAYER") if chosen == "Player" else Localization.t("WIN_BANKER") if chosen == "Banker" else Localization.t("WIN_TIE")

	if chosen == actual:
		toast_manager.show_success(Localization.t("WIN_CORRECT", [t, res]))
		stats_manager.increment_correct()

		# ← Показываем новый PayoutPopup для всех вариантов
		var stake: float = 0.0
		var payout: float = 0.0

		if actual == "Banker":
			stake = limits_manager.generate_bet()
			var commission = GameModeManager.get_banker_commission()

			# ← НОВАЯ ЛОГИКА для Classic: если банкир выигрывает с 6 очками → 50% выплата
			if GameModeManager.get_mode_string() == "classic":
				var banker_value = BaccaratRules.hand_value(phase_manager.banker_hand)
				if banker_value == 6:
					commission = 0.5  # ← 50% выплата при выигрыше с 6

			payout = stake * commission
		elif actual == "Tie":
			stake = limits_manager.generate_tie_bet()
			payout = stake * 8.0  # ← 8:1
		else:  # Player
			stake = limits_manager.generate_bet()
			payout = stake * 1.0  # ← 1:1

		payout_popup.show_payout(actual, stake, payout)
	else:
		toast_manager.show_error(Localization.t("WIN_INCORRECT", [chosen_t, t, res]))
		stats_manager.increment_error("winner_wrong")
		if is_survival_mode:
			survival_ui.lose_life()

func _format_result() -> String:
	var p0 = BaccaratRules.hand_value([phase_manager.player_hand[0], phase_manager.player_hand[1]])
	var b0 = BaccaratRules.hand_value([phase_manager.banker_hand[0], phase_manager.banker_hand[1]])
	if p0 >= 8 or b0 >= 8:
		return "Натуральная %d против %d" % [p0 if p0 >= 8 else b0, b0 if p0 >= 8 else p0]
	return "%d против %d" % [BaccaratRules.hand_value(phase_manager.banker_hand), BaccaratRules.hand_value(phase_manager.player_hand)]

func _on_help_button_pressed():
	ui_manager.help_popup.popup_centered()

func _on_lang_button_pressed():
	var new_lang = "en" if Localization.get_lang() == "ru" else "ru"
	Localization.set_lang(new_lang)
	
	ui_manager.update_lang_button()
	ui_manager.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))
	
	if ui_manager.player_third_toggle.visible:
		ui_manager.update_player_toggle(phase_manager.player_third_selected)
	if ui_manager.banker_third_toggle.visible:
		ui_manager.update_banker_toggle(phase_manager.banker_third_selected)

# ← Обработчик нового попапа выплат (Этап 4: полная интеграция со статистикой)
func _on_payout_confirmed(is_correct: bool, collected: float, expected: float):
	if is_correct:
		# ← Правильная выплата
		stats_manager.increment_correct()
		print("✅ Правильно! Выплата: %s" % expected)

		# ← Увеличиваем счётчик раундов в режиме выживания
		if is_survival_mode:
			survival_rounds_completed += 1
	else:
		# ← Неправильная выплата
		stats_manager.increment_error("payout_wrong")
		print("❌ Ошибка! Собрано: %s, ожидалось: %s" % [collected, expected])

		# ← Теряем жизнь в режиме выживания
		if is_survival_mode:
			survival_ui.lose_life()

	# ← Сбрасываем игру только при правильном ответе (попап автоматически закрывается)
	if is_correct:
		phase_manager.reset()

# ← Обработчик game over в режиме выживания
func _on_survival_game_over(_rounds: int):
	print("🎮 GAME OVER! Раундов выжито: %d" % survival_rounds_completed)
	game_over_popup.show_game_over(survival_rounds_completed)

# ← Обработчик рестарта игры из попапа Game Over
func _on_restart_game():
	survival_rounds_completed = 0
	stats_manager.reset()
	survival_ui.reset()
	survival_ui.activate()
	phase_manager.reset()

# ← Обработчик открытия/закрытия меню настроек (toggle)
func _on_settings_button_pressed():
	if settings_popup:
		if settings_popup.visible:
			settings_popup.hide()
		else:
			settings_popup.popup_centered()

# ← Обработчик изменения режима игры (новое)
func _on_mode_changed(mode: String):
	print("Режим игры изменён на: ", mode)

	# ← ВАЖНО: Устанавливаем режим в GameModeManager
	GameModeManager.set_mode(mode)

	# Обновляем лимиты из GameModeManager
	var cfg = GameModeManager.get_config()
	limits_manager.set_limits(
		cfg["main_min"], cfg["main_max"], cfg["main_step"],
		cfg["tie_min"], cfg["tie_max"], cfg["tie_step"]
	)

	# Генерируем новую ставку с новыми лимитами
	_on_limits_changed(
		cfg["main_min"], cfg["main_max"], cfg["main_step"],
		cfg["tie_min"], cfg["tie_max"], cfg["tie_step"]
	)

# ← Обработчик изменения языка из меню (новое)
func _on_language_changed(_lang: String):
	# Язык уже изменён в Localization, просто обновляем UI
	ui_manager.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))

	if ui_manager.player_third_toggle.visible:
		ui_manager.update_player_toggle(phase_manager.player_third_selected)
	if ui_manager.banker_third_toggle.visible:
		ui_manager.update_banker_toggle(phase_manager.banker_third_selected)

# ← Обработчик изменения режима выживания (новое)
func _on_survival_mode_changed(enabled: bool):
	is_survival_mode = enabled
	SaveManager.save_survival_mode(enabled)

	if enabled:
		survival_ui.activate()
		# Скрываем статистику в режиме выживания
		ui_manager.stats_label.visible = false
		print("Режим выживания включён")
	else:
		survival_ui.deactivate()
		# Показываем статистику когда режим выживания выключен
		ui_manager.stats_label.visible = true
		print("Режим выживания выключен")

# ← Загрузка сохранённой настройки режима выживания
func _load_survival_mode_setting():
	var enabled = SaveManager.load_survival_mode()
	is_survival_mode = enabled

	# Обновляем UI в попапе настроек, если он есть
	if settings_popup:
		settings_popup.set_survival_mode(enabled)

	# Активируем/деактивируем режим
	if enabled:
		survival_ui.activate()
		# Скрываем статистику
		ui_manager.stats_label.visible = false
	else:
		survival_ui.deactivate()
		# Показываем статистику
		ui_manager.stats_label.visible = true

# ← Обработчик использования подсказки
func _on_hint_used():
	if is_survival_mode:
		# В режиме выживания: теряем 1 жизнь
		survival_ui.lose_life()
		toast_manager.show_info("💡 Подсказка использована (-1 жизнь)")
		print("💡 Подсказка: -1 жизнь")
	else:
		# В обычном режиме: отнимаем 10 правильных действий
		for i in range(10):
			if stats_manager.correct > 0:
				stats_manager.correct -= 1
		stats_manager.update_stats()
		toast_manager.show_info("💡 Подсказка использована (-10 очков)")
		print("💡 Подсказка: -10 очков")
