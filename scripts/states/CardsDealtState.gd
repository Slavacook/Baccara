# res://scripts/states/CardsDealtState.gd
@tool
class_name CardsDealtState
extends State

var PlayerCardOpenedStateClass = preload("res://scripts/states/PlayerCardOpenedState.gd")
var RevealedStateClass = preload("res://scripts/states/RevealedState.gd")

func enter():
	context.ui.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))

	# ← АВТОМАТИЧЕСКАЯ ПРОВЕРКА: можно ли сразу выбирать победителя?
	var ps = BaccaratRules.hand_value([context.player_hand[0], context.player_hand[1]])
	var bs = BaccaratRules.hand_value([context.banker_hand[0], context.banker_hand[1]])

	var natural = ps >= 8 or bs >= 8
	var no_third = (ps == 6 and bs == 6) or (ps == 7 and bs == 7) or (ps == 6 and bs == 7) or (ps == 7 and bs == 6)

	if natural or no_third:
		# ← Игра заканчивается сразу, но toggles остаются (чтобы дилер мог ошибиться)
		context.toast.show_info(Localization.t("INFO_NATURAL_CHOOSE_WINNER"))
		# НЕ вызываем complete_game() - toggles остаются видимыми для тренировки
		# Остаёмся в CardsDealtState, но разрешаем выбор победителя

func handle_input(event):
	if event is InputEventAction:
		if event.action == "confirm" and event.pressed:
			_handle_confirm()
		elif event.action == "player_third":
			context.player_third_selected = event.pressed
			context.ui.update_player_toggle(context.player_third_selected)
		elif event.action == "banker_third":
			context.banker_third_selected = event.pressed
			context.ui.update_banker_toggle(context.banker_third_selected)

func _handle_confirm():
	var ps = BaccaratRules.hand_value([context.player_hand[0], context.player_hand[1]])
	var bs = BaccaratRules.hand_value([context.banker_hand[0], context.banker_hand[1]])
	
	# СИТУАЦИЯ 1: Натурал (8/9) или без третьих (6-6,7-7,6-7,7-6)
	var natural = ps >= 8 or bs >= 8
	var no_third = (ps == 6 and bs == 6) or (ps == 7 and bs == 7) or (ps == 6 and bs == 7) or (ps == 7 and bs == 6)
	if natural or no_third:
		if context.player_third_selected or context.banker_third_selected:
			context.toast.show_error(Localization.t("ERR_NATURAL_NO_DRAW"))
			context.stats.increment_error("natural_draw")
			context.on_error_occurred()  # ← Режим выживания
			context.player_third_selected = false
			context.banker_third_selected = false
			context.ui.update_player_toggle(false)
			context.ui.update_banker_toggle(false)
			return
		context.toast.show_info(Localization.t("INFO_NATURAL_CHOOSE_WINNER"))
		context.complete_game()
		context.change_state(RevealedStateClass.new(context))
		return

	# Общие флаги
	var player_draw = ps <= 5
	var banker_draw_always = bs <= 2  # Для ситуации 2

	# СИТУАЦИЯ 2: Карта КАЖДОМУ (банкир 0-2 И игрок 0-5)
	if banker_draw_always and player_draw:
		if not context.player_third_selected or not context.banker_third_selected:
			context.toast.show_error(Localization.t("BOTH_CARDS_NEEDED"))
			context.stats.increment_error("both_wrong")
			context.on_error_occurred()  # ← Режим выживания
			context.player_third_selected = true
			context.banker_third_selected = true
			context.ui.update_player_toggle(true)
			context.ui.update_banker_toggle(true)
			return
		context.draw_player_third()
		context.draw_banker_third()
		context.complete_game()
		context.change_state(RevealedStateClass.new(context))
		return

	# СИТУАЦИЯ 4: Карта ИГРОКУ (игрок 0-5 И банкир 7)
	if player_draw and bs == 7:
		if not context.player_third_selected:
			context.toast.show_error(Localization.t("ERR_PLAYER_MUST_DRAW", [ps]))
			context.stats.increment_error("player_wrong")
			context.on_error_occurred()  # ← Режим выживания
			context.player_third_selected = true
			context.ui.update_player_toggle(true)
			return
		if context.banker_third_selected:
			context.toast.show_error(Localization.t("ERR_BANKER_NO_DRAW", [bs]))
			context.stats.increment_error("banker_wrong")
			context.on_error_occurred()  # ← Режим выживания
			context.banker_third_selected = false
			context.ui.update_banker_toggle(false)
			return
		context.draw_player_third()
		context.complete_game()
		context.change_state(RevealedStateClass.new(context))
		return

	# СИТУАЦИЯ 3: Карта ИГРОКУ, банкир 3-6 ждёт
	if player_draw and bs >= 3 and bs <= 6:
		if not context.player_third_selected:
			context.toast.show_error(Localization.t("ERR_PLAYER_MUST_DRAW", [ps]))
			context.stats.increment_error("player_wrong")
			context.on_error_occurred()  # ← Режим выживания
			context.player_third_selected = true
			context.ui.update_player_toggle(true)
			return
		if context.banker_third_selected:
			context.toast.show_error(Localization.t("BANKER_NO_CARD_YET"))
			context.stats.increment_error("banker_wrong")
			context.on_error_occurred()  # ← Режим выживания
			context.banker_third_selected = false
			context.ui.update_banker_toggle(false)
			return
		context.draw_player_third()
		context.change_state(PlayerCardOpenedStateClass.new(context))
		return

	# СИТУАЦИЯ: Только БАНКИРУ (игрок >5, банкир <=5 или по правилам)
	var banker_draw = context._should_banker_draw()  # Используем существующую функцию (без player_drew)
	if not player_draw and banker_draw:
		if not context.banker_third_selected:
			context.toast.show_error(Localization.t("ERR_BANKER_MUST_DRAW", [bs]))
			context.stats.increment_error("banker_wrong")
			context.on_error_occurred()  # ← Режим выживания
			context.banker_third_selected = true
			context.ui.update_banker_toggle(true)
			return
		if context.player_third_selected:
			context.toast.show_error(Localization.t("ERR_PLAYER_NO_DRAW", [ps]))
			SaveManager.instance.increment_error("player_wrong")
			context.on_error_occurred()  # ← Режим выживания
			context.player_third_selected = false
			context.ui.update_player_toggle(false)
			return
		context.draw_banker_third()
		context.complete_game()
		context.change_state(RevealedStateClass.new(context))
		return

	# Если ничего не подходит — конец (например, банкир >7 или игрок >5 и банкир не нуждается)
	context.complete_game()
	context.change_state(RevealedStateClass.new(context))
