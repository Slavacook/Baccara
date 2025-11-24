# res://scripts/BetPopup.gd
extends PopupPanel

@onready var bet_label = $MarginContainer/VBoxContainer/BetLabel
@onready var bet_input = $MarginContainer/VBoxContainer/BetInput
@onready var confirm_button = $MarginContainer/VBoxContainer/ConfirmButton

signal confirmed(payout: int, bet_mode: String)

var current_bet_mode: String = "banker"

func _ready():
	min_size = Vector2(500, 300)
	size = Vector2(500, 300)
	
	$MarginContainer.add_theme_constant_override("margin_left", 40)
	$MarginContainer.add_theme_constant_override("margin_right", 40)
	$MarginContainer.add_theme_constant_override("margin_top", 40)
	$MarginContainer.add_theme_constant_override("margin_bottom", 40)
	
	bet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bet_label.add_theme_font_size_override("font_size", 28)
	
	bet_input.placeholder_text = "Введите выплату..."
	bet_input.add_theme_font_size_override("font_size", 24)
	bet_input.custom_minimum_size = Vector2(0, 60)
	bet_input.caret_blink = true
	
	confirm_button.text = "Подтвердить"
	confirm_button.add_theme_font_size_override("font_size", 24)
	confirm_button.custom_minimum_size = Vector2(0, 60)
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	bet_input.text_submitted.connect(func(_text): _on_confirm_pressed())

func show_bet(amount: int, bet_mode: String = "banker"):
	current_bet_mode = bet_mode
	var key = "BANKER_BET" if bet_mode == "banker" else "TIE_BET"
	bet_label.text = Localization.t(key, [amount])
	bet_input.text = ""
	bet_input.grab_focus()
	popup_centered()

func _on_confirm_pressed():
	var text = bet_input.text.strip_edges()
	if text.is_empty() or not text.is_valid_int():
		_clear_and_refocus()
		return
	
	var payout = int(text)
	confirmed.emit(payout, current_bet_mode)
	hide()

func _clear_and_refocus():
	bet_input.text = ""
	bet_input.grab_focus()
