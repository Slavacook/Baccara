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
