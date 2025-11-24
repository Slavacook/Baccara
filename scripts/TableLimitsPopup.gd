# res://scripts/TableLimitsPopup.gd
extends PopupPanel

@onready var min_input: LineEdit = $MarginContainer/GridContainer/MinInput
@onready var max_input: LineEdit = $MarginContainer/GridContainer/MaxInput
@onready var step_input: LineEdit = $MarginContainer/GridContainer/StepInput

@onready var tie_min_input: LineEdit = $MarginContainer/GridContainer2/TieMinInput
@onready var tie_max_input: LineEdit = $MarginContainer/GridContainer2/TieMaxInput
@onready var tie_step_input: LineEdit = $MarginContainer/GridContainer2/TieStepInput

@onready var confirm_button: Button = $MarginContainer2/ConfirmButton

signal limits_changed(
	min_bet: int, max_bet: int, step: int,
	tie_min: int, tie_max: int, tie_step: int
)

func _ready():
	# ← ВАЖНО: включаем фокус для всех LineEdit и Button
	min_input.focus_mode = Control.FOCUS_ALL
	max_input.focus_mode = Control.FOCUS_ALL
	step_input.focus_mode = Control.FOCUS_ALL
	tie_min_input.focus_mode = Control.FOCUS_ALL
	tie_max_input.focus_mode = Control.FOCUS_ALL
	tie_step_input.focus_mode = Control.FOCUS_ALL
	confirm_button.focus_mode = Control.FOCUS_ALL

	# ← Сигналы
	confirm_button.pressed.connect(_on_confirm)
	
	# Enter → OK
	min_input.text_submitted.connect(func(_t): _on_confirm())
	max_input.text_submitted.connect(func(_t): _on_confirm())
	step_input.text_submitted.connect(func(_t): _on_confirm())
	tie_min_input.text_submitted.connect(func(_t): _on_confirm())
	tie_max_input.text_submitted.connect(func(_t): _on_confirm())
	tie_step_input.text_submitted.connect(func(_t): _on_confirm())

func show_current_limits(
	min_bet: int, max_bet: int, step: int,
	tie_min: int, tie_max: int, tie_step: int
):
	min_input.text = str(min_bet)
	max_input.text = str(max_bet)
	step_input.text = str(step)
	tie_min_input.text = str(tie_min)
	tie_max_input.text = str(tie_max)
	tie_step_input.text = str(tie_step)
	
	# ← УБРАЛИ grab_focus() — теперь клик сам даст фокус
	popup_centered()

func _on_confirm():
	var main_min = _to_int(min_input.text, 25)
	var main_max = _to_int(max_input.text, 200000)
	var main_step = _to_int(step_input.text, 25)
	
	var tie_min = _to_int(tie_min_input.text, 10)
	var tie_max = _to_int(tie_max_input.text, 1000)
	var tie_step = _to_int(tie_step_input.text, 10)
	
	# Защита
	if main_min >= main_max: main_max = main_min + main_step
	if tie_min >= tie_max: tie_max = tie_min + tie_step
	if main_step <= 0: main_step = 25
	if tie_step <= 0: tie_step = 10
	
	limits_changed.emit(
		main_min, main_max, main_step,
		tie_min, tie_max, tie_step
	)
	hide()

func _to_int(text: String, default: int) -> int:
	return int(text) if text.is_valid_int() else default
