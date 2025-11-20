# res://scripts/states/PlayerCardOpenedState.gd
@tool
class_name PlayerCardOpenedState
extends State

var RevealedStateClass = preload("res://scripts/states/RevealedState.gd")

func enter():
	context.toast.show_info(Localization.t("INFO_PLAYER_CARD_OPENED", [context.player_hand[2].card_to_string()]))

func handle_input(event):
	if event is InputEventAction and event.action == "confirm" and event.pressed:
		_handle_confirm()
	elif event.action == "banker_third":
		# ← РАЗРЕШАЕМ клик по toggle банкира
		context.banker_third_selected = event.pressed
		context.ui.update_banker_toggle(context.banker_third_selected)

func _handle_confirm():
	var banker_draw = context._should_banker_draw()

	if banker_draw:
		if not context.banker_third_selected:
			context.toast.show_error(Localization.t("ERR_BANKER_MUST_DRAW_AFTER_PLAYER", [context.player_hand[2].card_to_string()]))
			context.stats.increment_error("banker_wrong")
			context.on_error_occurred()  # ← Режим выживания
			context.banker_third_selected = true
			context.ui.update_banker_toggle(true)
			return
		context.draw_banker_third()
	else:
		if context.banker_third_selected:
			context.toast.show_error(Localization.t("ERR_BANKER_NO_DRAW"))
			context.stats.increment_error("banker_wrong")
			context.on_error_occurred()  # ← Режим выживания
			context.banker_third_selected = false
			context.ui.update_banker_toggle(false)
			return
	
	context.complete_game()
	context.change_state(RevealedStateClass.new(context))
