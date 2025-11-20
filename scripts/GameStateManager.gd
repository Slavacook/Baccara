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
