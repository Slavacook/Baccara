# res://scripts/states/DealingState.gd
@tool
class_name DealingState
extends State

var CardsDealtStateClass = preload("res://scripts/states/CardsDealtState.gd")

func enter():
	context.deal_first_four()
	context.change_state(CardsDealtStateClass.new(context))
