# res://scripts/states/StartState.gd
@tool
class_name StartState
extends State

var DealingStateClass = preload("res://scripts/states/DealingState.gd")

func enter():
	context.ui.update_action_button(Localization.t("ACTION_BUTTON_CARDS"))

func handle_input(event):
	if event is InputEventAction and event.action == "confirm" and event.pressed:
		context.change_state(DealingStateClass.new(context))
