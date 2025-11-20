# res://scripts/LimitsManager.gd
class_name LimitsManager
extends RefCounted

signal limits_changed(
	min_bet: int, max_bet: int, step: int,
	tie_min: int, tie_max: int, tie_step: int
)

var min_bet: int = 2000
var max_bet: int = 200000
var step: int = 500
var tie_min: int = 100
var tie_max: int = 10000
var tie_step: int = 100
var config: GameConfig

func _init(conf: GameConfig):
	config = conf
	min_bet = conf.table_min_bet
	max_bet = conf.table_max_bet
	step = conf.table_step
	tie_min = conf.tie_min_bet
	tie_max = conf.tie_max_bet
	tie_step = conf.tie_step

func set_limits(
	new_min: int, new_max: int, new_step: int,
	new_tie_min: int, new_tie_max: int, new_tie_step: int
):
	min_bet = new_min
	max_bet = new_max
	step = new_step
	tie_min = new_tie_min
	tie_max = new_tie_max
	tie_step = new_tie_step
	
	config.table_min_bet = new_min
	config.table_max_bet = new_max
	config.table_step = new_step
	config.tie_min_bet = new_tie_min
	config.tie_max_bet = new_tie_max
	config.tie_step = new_tie_step
	
	limits_changed.emit(new_min, new_max, new_step, new_tie_min, new_tie_max, new_tie_step)

# ← ВЕРНУЛИ! Генерация ставки для Banker/Player
func generate_bet() -> int:
	if min_bet >= max_bet:
		return min_bet
	var range_size = int((max_bet - min_bet) / float(step))
	if range_size <= 0:
		return min_bet
	var random_step = randi() % (range_size + 1)
	return min_bet + random_step * step

# ← ВЕРНУЛИ! Генерация ставки для TIE
func generate_tie_bet() -> int:
	if tie_min >= tie_max:
		return tie_min
	var range_size = int((tie_max - tie_min) / float(tie_step))
	if range_size <= 0:
		return tie_min
	var random_step = randi() % (range_size + 1)
	return tie_min + random_step * tie_step
