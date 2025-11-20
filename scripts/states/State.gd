# res://scripts/states/State.gd
@tool
class_name State
extends RefCounted

var context: GamePhaseManager

func _init(ctx: GamePhaseManager):
	context = ctx

func enter(): pass
func exit(): pass
func update(_delta: float): pass
func handle_input(_event): pass
