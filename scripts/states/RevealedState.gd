# res://scripts/states/RevealedState.gd
@tool
class_name RevealedState
extends State

var StartStateClass = preload("res://scripts/states/StartState.gd")

func enter():
	context.ui.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))
	context.toast.show_info(Localization.t("INFO_ALL_OPENED_CHOOSE_WINNER"))

func handle_input(event):
	if event is InputEventAction and event.action == "confirm" and event.pressed:
		context.change_state(StartStateClass.new(context))
