# res://scripts/GameStateManager.gd
# Глобальный менеджер состояний игры
# Определяет текущее состояние игры на основе карт на столе
extends Node

# ========================================
# СИГНАЛЫ
# ========================================

signal state_changed(old_state: GameState, new_state: GameState)

# ========================================
# ENUM: Состояния игры
# ========================================

enum GameState {
	WAITING = 1,                    # Карты скрыты, ждём кнопку "Карты"
	CARD_TO_EACH = 2,               # Банкир 0-2, Игрок 0-5 → карта каждому
	CARD_TO_PLAYER = 3,             # Банкир 3-7, Игрок 0-5 → карта игроку
	CARD_TO_BANKER = 4,             # Банкир 0-5, Игрок 6-7 → карта банкиру
	CARD_TO_BANKER_AFTER_PLAYER = 5,# Банкир 3-6 после третьей игрока
	CHOOSE_WINNER = 6               # Все карты открыты, выбор победителя
}

# ========================================
# ENUM: Действия игрока
# ========================================

enum Action {
	DEAL_CARDS,        # Нажата кнопка "Карты"
	PLAYER_THIRD,      # Заказ третьей карты игроку
	BANKER_THIRD,      # Заказ третьей карты банкиру
	SELECT_WINNER      # Выбор победителя (Player/Banker/Tie)
}

# ========================================
# ПЕРЕМЕННЫЕ
# ========================================

var current_state: GameState = GameState.WAITING

# ========================================
# ФУНКЦИИ: Получение информации о состоянии
# ========================================

# Получить название состояния на русском
func get_state_name(state: GameState) -> String:
	match state:
		GameState.WAITING:
			return "Ожидание"
		GameState.CARD_TO_EACH:
			return "Карта каждому"
		GameState.CARD_TO_PLAYER:
			return "Карта игроку"
		GameState.CARD_TO_BANKER:
			return "Карта банкиру"
		GameState.CARD_TO_BANKER_AFTER_PLAYER:
			return "Карта банкиру после игрока"
		GameState.CHOOSE_WINNER:
			return "Выбор победителя"
		_:
			return "Неизвестное состояние"

# Получить название действия на русском
func get_action_name(action: Action) -> String:
	match action:
		Action.DEAL_CARDS:
			return "Раздать карты"
		Action.PLAYER_THIRD:
			return "Карта игроку"
		Action.BANKER_THIRD:
			return "Карта банкиру"
		Action.SELECT_WINNER:
			return "Выбрать победителя"
		_:
			return "Неизвестное действие"

# ========================================
# ФУНКЦИИ: Основная логика
# ========================================

# Определить состояние игры на основе карт на столе
# Параметры:
#   cards_hidden: bool - карты скрыты?
#   player_hand: Array[Card] - рука игрока (2 карты)
#   banker_hand: Array[Card] - рука банкира (2 карты)
#   player_third: Card или null - третья карта игрока
#   banker_third: Card или null - третья карта банкира
func determine_state(
	cards_hidden: bool,
	player_hand: Array,  # Array[Card]
	banker_hand: Array,  # Array[Card]
	player_third = null,  # Card или null
	banker_third = null   # Card или null
) -> GameState:

	# ========================================
	# State 1: Карты скрыты
	# ========================================
	if cards_hidden or player_hand.size() < 2 or banker_hand.size() < 2:
		return GameState.WAITING

	# Вычисляем значения рук (первые 2 карты)
	var player_value = BaccaratRules.hand_value(player_hand.slice(0, 2))
	var banker_value = BaccaratRules.hand_value(banker_hand.slice(0, 2))

	# ========================================
	# State 6: Натуральные 8-9
	# ========================================
	if player_value >= 8 or banker_value >= 8:
		return GameState.CHOOSE_WINNER

	# ========================================
	# State 6: Особые комбинации (6v7, 7v6, 7v7, 6v6)
	# ========================================
	if _is_special_combination(player_value, banker_value):
		return GameState.CHOOSE_WINNER

	# ========================================
	# Если игрок НЕ взял третью карту
	# ========================================
	if player_third == null:
		# Игрок должен брать карту (0-5)
		if player_value in [0, 1, 2, 3, 4, 5]:
			# Банкир 0-2 → обоим нужна третья карта
			if banker_value in [0, 1, 2]:
				return GameState.CARD_TO_EACH
			# Банкир 3-7 → только игроку нужна третья карта
			else:  # banker_value in [3, 4, 5, 6, 7]
				return GameState.CARD_TO_PLAYER

		# Игрок стоит (6-7)
		else:  # player_value in [6, 7]
			# Банкир 0-5 → только банкиру нужна третья карта
			if banker_value in [0, 1, 2, 3, 4, 5]:
				return GameState.CARD_TO_BANKER
			# Банкир 6-7 → оба стоят, выбор победителя
			else:  # banker_value in [6, 7]
				return GameState.CHOOSE_WINNER

	# ========================================
	# Если игрок УЖЕ взял третью карту
	# ========================================
	else:
		# Банкир уже взял третью → выбор победителя
		if banker_third != null:
			return GameState.CHOOSE_WINNER

		# Банкир с 7 всегда стоит
		if banker_value == 7:
			return GameState.CHOOSE_WINNER

		# Банкир 0-2 всегда берёт (но это уже обработано в CARD_TO_EACH)
		# Банкир 3-6 → проверяем по сложным правилам
		if banker_value in [3, 4, 5, 6]:
			# Используем правила из BaccaratRules
			var player_drew = true
			if BaccaratRules.banker_should_draw(banker_hand.slice(0, 2), player_drew, player_third):
				return GameState.CARD_TO_BANKER_AFTER_PLAYER
			else:
				return GameState.CHOOSE_WINNER

	# ========================================
	# Fallback: все карты открыты
	# ========================================
	return GameState.CHOOSE_WINNER

# Проверка особых комбинаций (6v7, 7v6, 7v7, 6v6)
func _is_special_combination(player_value: int, banker_value: int) -> bool:
	# Обе руки должны быть 6 или 7
	if player_value not in [6, 7] or banker_value not in [6, 7]:
		return false

	# 6v7, 7v6, 7v7, 6v6
	return true

# Обновить текущее состояние игры
func update_state(new_state: GameState):
	if new_state != current_state:
		var old = current_state
		current_state = new_state
		state_changed.emit(old, new_state)
		print("🎮 Состояние изменилось: %s → %s" % [get_state_name(old), get_state_name(new_state)])

# Получить текущее состояние
func get_current_state() -> GameState:
	return current_state

# Сбросить состояние в начальное
func reset():
	update_state(GameState.WAITING)
	print("🔄 Состояние сброшено в WAITING")

# Определить и обновить состояние на основе карт
# Удобный метод для вызова из GameController
func determine_and_update_state(
	cards_hidden: bool,
	player_hand: Array,
	banker_hand: Array,
	player_third = null,
	banker_third = null
):
	var new_state = determine_state(cards_hidden, player_hand, banker_hand, player_third, banker_third)
	update_state(new_state)

# ========================================
# ФУНКЦИИ: Валидация действий
# ========================================

# Проверить допустимость действия в текущем состоянии
func is_action_valid(action: Action, state: GameState = current_state) -> bool:
	match state:
		GameState.WAITING:
			# В ожидании можно только раздать карты
			return action == Action.DEAL_CARDS

		GameState.CARD_TO_EACH:
			# Нужна карта каждому (но проверяем отдельно player и banker)
			# Это специальный случай - оба должны быть заказаны
			return action in [Action.PLAYER_THIRD, Action.BANKER_THIRD]

		GameState.CARD_TO_PLAYER:
			# Только карта игроку
			return action == Action.PLAYER_THIRD

		GameState.CARD_TO_BANKER, GameState.CARD_TO_BANKER_AFTER_PLAYER:
			# Только карта банкиру
			return action == Action.BANKER_THIRD

		GameState.CHOOSE_WINNER:
			# Можно выбрать победителя или нажать "Карты" (не ошибка, просто ничего не делает)
			return action in [Action.SELECT_WINNER, Action.DEAL_CARDS]

		_:
			return false

# Получить список допустимых действий для состояния
func get_valid_actions(state: GameState = current_state) -> Array:
	var actions: Array = []

	match state:
		GameState.WAITING:
			actions = [Action.DEAL_CARDS]
		GameState.CARD_TO_EACH:
			actions = [Action.PLAYER_THIRD, Action.BANKER_THIRD]  # Оба!
		GameState.CARD_TO_PLAYER:
			actions = [Action.PLAYER_THIRD]
		GameState.CARD_TO_BANKER, GameState.CARD_TO_BANKER_AFTER_PLAYER:
			actions = [Action.BANKER_THIRD]
		GameState.CHOOSE_WINNER:
			actions = [Action.SELECT_WINNER]

	return actions

# Получить сообщение об ошибке для недопустимого действия
func get_error_message(action: Action, state: GameState = current_state) -> String:
	# Если действие допустимо, нет ошибки
	if is_action_valid(action, state):
		return ""

	# Генерируем сообщение об ошибке
	match state:
		GameState.WAITING:
			match action:
				Action.PLAYER_THIRD, Action.BANKER_THIRD:
					return "Сначала нажмите кнопку \"Карты\""
				Action.SELECT_WINNER:
					return "Игра ещё не началась"
				_:
					return "Недопустимое действие"

		GameState.CARD_TO_EACH:
			match action:
				Action.SELECT_WINNER:
					return "Сначала закажите карты каждому (игроку И банкиру)"
				Action.DEAL_CARDS:
					return "Закажите третьи карты игроку И банкиру"
				_:
					return "Недопустимое действие"

		GameState.CARD_TO_PLAYER:
			match action:
				Action.BANKER_THIRD:
					return "Банкиру карта не нужна! Только игроку"
				Action.SELECT_WINNER:
					return "Сначала откройте карты"
				Action.DEAL_CARDS:
					return "Закажите третью карту игроку"
				_:
					return "Недопустимое действие"

		GameState.CARD_TO_BANKER, GameState.CARD_TO_BANKER_AFTER_PLAYER:
			match action:
				Action.PLAYER_THIRD:
					return "Игроку карта не нужна! Только банкиру"
				Action.SELECT_WINNER:
					return "Сначала откройте карты"
				Action.DEAL_CARDS:
					return "Закажите третью карту банкиру"
				_:
					return "Недопустимое действие"

		GameState.CHOOSE_WINNER:
			match action:
				Action.PLAYER_THIRD, Action.BANKER_THIRD:
					return "Все карты уже открыты. Выберите победителя"
				_:
					return "Выберите победителя"

		_:
			return "Неизвестная ошибка"

# Проверка специального случая State 2: обе карты должны быть заказаны
func is_both_third_cards_selected(player_selected: bool, banker_selected: bool, state: GameState = current_state) -> bool:
	if state != GameState.CARD_TO_EACH:
		return true  # Не применимо для других состояний

	return player_selected and banker_selected

# ========================================
# ФУНКЦИИ: Блокировка настроек
# ========================================

# Можно ли менять настройки (режим игры, лимиты)?
# Настройки можно менять только в состояниях WAITING и CHOOSE_WINNER
func can_change_settings(state: GameState = current_state) -> bool:
	return state in [GameState.WAITING, GameState.CHOOSE_WINNER]

# Сообщение почему нельзя менять настройки
func get_settings_lock_message(state: GameState = current_state) -> String:
	if can_change_settings(state):
		return ""  # Нет блокировки

	return "Нельзя менять настройки во время раздачи! Завершите раунд."
