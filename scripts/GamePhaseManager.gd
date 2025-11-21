# res://scripts/GamePhaseManager.gd
# Менеджер игрового процесса (без State классов)
# Управляет раздачей карт, валидацией действий, переходами между фазами
@tool
class_name GamePhaseManager
extends RefCounted

var toast: ToastManager
var stats: StatsManager  # ← Для обновления статистики
var game_controller = null  # ← Ссылка на GameController для режима выживания

var player_hand: Array[Card] = []
var banker_hand: Array[Card] = []
var player_third_selected: bool = false
var banker_third_selected: bool = false

var deck: Deck
var card_manager: CardTextureManager
var ui: UIManager

func _init(deck_ref: Deck, card_manager_ref: CardTextureManager, ui_ref: UIManager, toast_ref: ToastManager, stats_ref: StatsManager):
	deck = deck_ref
	card_manager = card_manager_ref
	ui = ui_ref
	toast = toast_ref
	stats = stats_ref
	ui.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))

# ← Установить ссылку на GameController
func set_game_controller(controller) -> void:
	game_controller = controller

# ← Вызывается из состояний при ошибках (для режима выживания)
func on_error_occurred() -> void:
	if game_controller and game_controller.is_survival_mode:
		game_controller.survival_ui.lose_life()

func reset():
	player_hand.clear()
	banker_hand.clear()
	player_third_selected = false
	banker_third_selected = false
	ui.reset_ui()
	ui.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))

	# ← Состояние WAITING: отключить toggles, включить кнопку "карты"
	ui.disable_toggles()
	ui.enable_action_button()

	# ← Сброс состояния в WAITING
	_update_game_state_manager()

func deal_first_four():
	player_hand = [deck.draw(), deck.draw()]
	banker_hand = [deck.draw(), deck.draw()]

	# Сбросить выбор toggles (могли быть выбраны до раздачи)
	player_third_selected = false
	banker_third_selected = false
	ui.update_player_toggle(false)
	ui.update_banker_toggle(false)

	ui.show_first_four_cards(player_hand, banker_hand)

	# ← Включить toggles после раздачи (теперь можно заказывать карты)
	ui.enable_toggles()

	# ← Обновить состояние после раздачи
	_update_game_state_manager()

func draw_player_third():
	player_hand.append(deck.draw())
	ui.show_player_third_card(player_hand[2])
	ui.hide_player_toggle()  # ← Скрыть toggle после раздачи карты
	player_third_selected = false  # ← Сбросить флаг после раздачи

	# ← Обновить состояние после третьей карты игрока
	_update_game_state_manager()

func draw_banker_third():
	banker_hand.append(deck.draw())
	ui.show_banker_third_card(banker_hand[2])
	ui.hide_banker_toggle()  # ← Скрыть toggle после раздачи карты
	banker_third_selected = false  # ← Сбросить флаг после раздачи

	# ← Обновить состояние после третьей карты банкира
	_update_game_state_manager()

func complete_game():
	ui.hide_both_toggles()
	ui.disable_action_button()  # ← Отключить кнопку "карты" при завершении
	ui.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))
	toast.show_info(Localization.t("INFO_ALL_OPENED_CHOOSE_WINNER"))

func _should_banker_draw() -> bool:
	return BaccaratRules.banker_should_draw(
		[banker_hand[0], banker_hand[1]],
		player_hand.size() >= 3,
		player_hand[2] if player_hand.size() >= 3 else null
	)

func on_action_pressed():
	var state = GameStateManager.get_current_state()

	# WAITING: Раздать первые 4 карты
	if state == GameStateManager.GameState.WAITING:
		deal_first_four()
		return

	# CARD_TO_BANKER_AFTER_PLAYER: Карта банкиру после игрока (особая логика)
	if state == GameStateManager.GameState.CARD_TO_BANKER_AFTER_PLAYER:
		_validate_banker_after_player()
		return

	# Остальные состояния: валидация выбора третьих карт
	_validate_and_execute_third_cards()

func on_player_third_toggled(selected: bool):
	player_third_selected = selected
	ui.update_player_toggle(player_third_selected)

func on_banker_third_toggled(selected: bool):
	banker_third_selected = selected
	ui.update_banker_toggle(banker_third_selected)

# ========================================
# ВАЛИДАЦИЯ ДЕЙСТВИЙ (перенесено из CardsDealtState)
# ========================================

# Валидировать выбор третьих карт и выполнить действие
func _validate_and_execute_third_cards():
	var ps = BaccaratRules.hand_value([player_hand[0], player_hand[1]])
	var bs = BaccaratRules.hand_value([banker_hand[0], banker_hand[1]])

	# СИТУАЦИЯ 1: Натурал (8/9) или без третьих (6-6,7-7,6-7,7-6)
	var natural = ps >= 8 or bs >= 8
	var no_third = (ps == 6 and bs == 6) or (ps == 7 and bs == 7) or (ps == 6 and bs == 7) or (ps == 7 and bs == 6)

	if natural or no_third:
		if player_third_selected or banker_third_selected:
			toast.show_error(Localization.t("ERR_NATURAL_NO_DRAW"))
			stats.increment_error("natural_draw")
			on_error_occurred()
			player_third_selected = false
			banker_third_selected = false
			ui.update_player_toggle(false)
			ui.update_banker_toggle(false)
			return
		toast.show_info(Localization.t("INFO_NATURAL_CHOOSE_WINNER"))
		complete_game()
		return

	# Флаги для упрощения
	var player_draw = ps <= 5
	var banker_draw_always = bs <= 2

	# СИТУАЦИЯ 2: Карта КАЖДОМУ (банкир 0-2 И игрок 0-5)
	if banker_draw_always and player_draw:
		if not player_third_selected or not banker_third_selected:
			toast.show_error(Localization.t("BOTH_CARDS_NEEDED"))
			stats.increment_error("both_wrong")
			on_error_occurred()
			player_third_selected = true
			banker_third_selected = true
			ui.update_player_toggle(true)
			ui.update_banker_toggle(true)
			return
		draw_player_third()
		draw_banker_third()
		complete_game()
		return

	# СИТУАЦИЯ 4: Карта ИГРОКУ (игрок 0-5 И банкир 7)
	if player_draw and bs == 7:
		if not player_third_selected:
			toast.show_error(Localization.t("ERR_PLAYER_MUST_DRAW", [ps]))
			stats.increment_error("player_wrong")
			on_error_occurred()
			player_third_selected = true
			ui.update_player_toggle(true)
			return
		if banker_third_selected:
			toast.show_error(Localization.t("ERR_BANKER_NO_DRAW", [bs]))
			stats.increment_error("banker_wrong")
			on_error_occurred()
			banker_third_selected = false
			ui.update_banker_toggle(false)
			return
		draw_player_third()
		complete_game()
		return

	# СИТУАЦИЯ 3: Карта ИГРОКУ, банкир 3-6 ждёт
	if player_draw and bs >= 3 and bs <= 6:
		if not player_third_selected:
			toast.show_error(Localization.t("ERR_PLAYER_MUST_DRAW", [ps]))
			stats.increment_error("player_wrong")
			on_error_occurred()
			player_third_selected = true
			ui.update_player_toggle(true)
			return
		if banker_third_selected:
			toast.show_error(Localization.t("BANKER_NO_CARD_YET"))
			stats.increment_error("banker_wrong")
			on_error_occurred()
			banker_third_selected = false
			ui.update_banker_toggle(false)
			return
		draw_player_third()
		# Переходим к следующему этапу - нужна карта банкиру
		_handle_banker_after_player()
		return

	# СИТУАЦИЯ: Только БАНКИРУ (игрок >5, банкир <=5 или по правилам)
	var banker_draw = _should_banker_draw()
	if not player_draw and banker_draw:
		if not banker_third_selected:
			toast.show_error(Localization.t("ERR_BANKER_MUST_DRAW", [bs]))
			stats.increment_error("banker_wrong")
			on_error_occurred()
			banker_third_selected = true
			ui.update_banker_toggle(true)
			return
		if player_third_selected:
			toast.show_error(Localization.t("ERR_PLAYER_NO_DRAW", [ps]))
			stats.increment_error("player_wrong")
			on_error_occurred()
			player_third_selected = false
			ui.update_player_toggle(false)
			return
		draw_banker_third()
		complete_game()
		return

	# Если ничего не подходит — конец игры
	complete_game()

# Обработка ситуации "банкир после игрока" (банкир 3-6 после третьей игрока)
func _handle_banker_after_player():
	# Проверяем, нужна ли карта банкиру по правилам
	var banker_draw = _should_banker_draw()

	if banker_draw:
		# Банкиру нужна карта - НЕ скрываем toggles (для обучения через ошибки)
		toast.show_info(Localization.t("INFO_BANKER_DECISION"))
	else:
		# Банкиру не нужна карта - завершаем игру
		toast.show_info(Localization.t("INFO_ALL_OPENED_CHOOSE_WINNER"))
		complete_game()

# Валидация карты банкиру после того, как игрок уже получил третью карту
func _validate_banker_after_player():
	var bs = BaccaratRules.hand_value([banker_hand[0], banker_hand[1]])
	var banker_draw = _should_banker_draw()

	if banker_draw:
		# Банкиру НУЖНА карта
		if not banker_third_selected:
			toast.show_error(Localization.t("ERR_BANKER_MUST_DRAW", [bs]))
			stats.increment_error("banker_wrong")
			on_error_occurred()
			banker_third_selected = true
			ui.update_banker_toggle(true)
			return
		# Проверка: игрок не должен получать вторую карту
		if player_third_selected:
			toast.show_error("Игроку уже дали карту!")
			stats.increment_error("player_wrong")
			on_error_occurred()
			player_third_selected = false
			ui.update_player_toggle(false)
			return
		# Всё правильно - раздаём карту банкиру
		draw_banker_third()
		complete_game()
	else:
		# Банкиру НЕ нужна карта
		if banker_third_selected:
			toast.show_error(Localization.t("ERR_BANKER_NO_DRAW", [bs]))
			stats.increment_error("banker_wrong")
			on_error_occurred()
			banker_third_selected = false
			ui.update_banker_toggle(false)
			return
		# Всё правильно - игра завершена
		complete_game()

# ========================================
# НОВАЯ СИСТЕМА: Обновление GameStateManager
# ========================================

# Обновить состояние в GameStateManager на основе текущих карт
func _update_game_state_manager():
	# Определяем скрыты ли карты (если руки пусты = состояние WAITING)
	var cards_hidden = player_hand.size() == 0 or banker_hand.size() == 0

	# Получаем третьи карты (если есть)
	var player_third_card = player_hand[2] if player_hand.size() > 2 else null
	var banker_third_card = banker_hand[2] if banker_hand.size() > 2 else null

	# Обновляем состояние
	GameStateManager.determine_and_update_state(
		cards_hidden,
		player_hand,
		banker_hand,
		player_third_card,
		banker_third_card
	)
