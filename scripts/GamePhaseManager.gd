# res://scripts/GamePhaseManager.gd
@tool
class_name GamePhaseManager
extends RefCounted



var current_state: State = null
var StartStateClass = preload("res://scripts/states/StartState.gd")

var toast: ToastManager
var stats: StatsManager  # ← Для обновления статистики из состояний
var game_controller = null  # ← Ссылка на GameController для режима выживания

var player_hand: Array[Card] = []
var banker_hand: Array[Card] = []
var player_third_selected: bool = false
var banker_third_selected: bool = false

var deck: Deck
var card_manager: CardTextureManager
var ui: UIManager  # ← ИСПРАВЛЕНО: UIManager, а не GameUI

func _init(deck_ref: Deck, card_manager_ref: CardTextureManager, ui_ref: UIManager, toast_ref: ToastManager, stats_ref: StatsManager):
	deck = deck_ref
	card_manager = card_manager_ref
	ui = ui_ref
	toast = toast_ref
	stats = stats_ref
	change_state(StartStateClass.new(self))

# ← Установить ссылку на GameController
func set_game_controller(controller) -> void:
	game_controller = controller

# ← Вызывается из состояний при ошибках (для режима выживания)
func on_error_occurred() -> void:
	if game_controller and game_controller.is_survival_mode:
		game_controller.survival_ui.lose_life()

func change_state(new_state: State):
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()

func reset():
	player_hand.clear()
	banker_hand.clear()
	player_third_selected = false
	banker_third_selected = false
	change_state(StartStateClass.new(self))
	ui.reset_ui()

	# ← НОВАЯ СИСТЕМА: Сброс состояния в WAITING
	_update_game_state_manager()

func deal_first_four():
	player_hand = [deck.draw(), deck.draw()]
	banker_hand = [deck.draw(), deck.draw()]
	ui.show_first_four_cards(player_hand, banker_hand)

	# ← НОВАЯ СИСТЕМА: Обновить состояние после раздачи
	_update_game_state_manager()

func draw_player_third():
	player_hand.append(deck.draw())
	ui.show_player_third_card(player_hand[2])
	ui.hide_player_toggle()

	# ← НОВАЯ СИСТЕМА: Обновить состояние после третьей карты игрока
	_update_game_state_manager()

func draw_banker_third():
	banker_hand.append(deck.draw())

	# ← НОВАЯ СИСТЕМА: Обновить состояние после третьей карты банкира
	_update_game_state_manager()
	ui.show_banker_third_card(banker_hand[2])
	ui.hide_banker_toggle()

func complete_game():
	ui.hide_both_toggles()
	ui.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))
	toast.show_info(Localization.t("INFO_ALL_OPENED_CHOOSE_WINNER"))

func _should_banker_draw() -> bool:
	return BaccaratRules.banker_should_draw(
		[banker_hand[0], banker_hand[1]],
		player_hand.size() >= 3,
		player_hand[2] if player_hand.size() >= 3 else null
	)

func on_action_pressed():
	current_state.handle_input(_create_input_event("confirm"))

func on_player_third_toggled(selected: bool):
	current_state.handle_input(_create_input_event("player_third", selected))

func on_banker_third_toggled(selected: bool):
	current_state.handle_input(_create_input_event("banker_third", selected))

func _create_input_event(action: String, pressed: bool = true) -> InputEventAction:
	var event = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event

# ← Проверка, можно ли выбирать победителя (игра завершена)
func can_choose_winner() -> bool:
	if current_state == null:
		return false

	# ← Победителя можно выбрать в RevealedState
	if current_state.get_script().resource_path.ends_with("RevealedState.gd"):
		return true

	# ← ТАКЖЕ можно выбрать в CardsDealtState при натуральной/6-7
	if current_state.get_script().resource_path.ends_with("CardsDealtState.gd"):
		if player_hand.size() >= 2 and banker_hand.size() >= 2:
			var ps = BaccaratRules.hand_value([player_hand[0], player_hand[1]])
			var bs = BaccaratRules.hand_value([banker_hand[0], banker_hand[1]])

			var natural = ps >= 8 or bs >= 8
			var no_third = (ps == 6 and bs == 6) or (ps == 7 and bs == 7) or (ps == 6 and bs == 7) or (ps == 7 and bs == 6)

			return natural or no_third

	return false

# ========================================
# НОВАЯ СИСТЕМА: Обновление GameStateManager
# ========================================

# Обновить состояние в GameStateManager на основе текущих карт
func _update_game_state_manager():
	# Определяем скрыты ли карты (StartState)
	var cards_hidden = current_state != null and current_state.get_script().resource_path.ends_with("StartState.gd")

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
