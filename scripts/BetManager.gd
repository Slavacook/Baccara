# res://scripts/BetManager.gd
class_name BetManager
extends RefCounted

signal bet_confirmed(payout: int, bet_mode: String, is_correct: bool)

var popup: PopupPanel
var banker_chip: TextureButton
var tie_chip: TextureButton
var commission_rate: float = 0.95
var tie_rate: float = 8.0
var current_bet: int = 0
var current_mode: String = "banker"

func _init(popup_ref: PopupPanel, banker_chip_ref: TextureButton, tie_chip_ref: TextureButton, rate: float):
	popup = popup_ref
	banker_chip = banker_chip_ref
	tie_chip = tie_chip_ref
	commission_rate = rate
	
	if banker_chip:
		banker_chip.visible = false
		banker_chip.pressed.connect(func(): _show_bet("banker"))
	
	if tie_chip:
		tie_chip.visible = false
		tie_chip.pressed.connect(func(): _show_bet("tie"))
	
	if popup:
		popup.confirmed.connect(_on_confirmed)

func show_bet(bet: int, mode: String = "banker"):
	current_bet = bet
	current_mode = mode
	
	var chip = banker_chip if mode == "banker" else tie_chip
	if chip:
		chip.visible = true
	
	if popup:
		popup.show_bet(bet, mode)

func _show_bet(mode: String):
	var chip = banker_chip if mode == "banker" else tie_chip
	if chip:
		chip.visible = false
	
	if popup:
		popup.show_bet(current_bet, mode)

# ← ИСПРАВЛЕНО: принимает 2, передаёт 3
func _on_confirmed(payout: int, bet_mode: String):
	var rate = commission_rate if bet_mode == "banker" else tie_rate
	var correct_payout = int(current_bet * rate)
	var is_correct = payout == correct_payout
	bet_confirmed.emit(payout, bet_mode, is_correct)

func get_correct_payout() -> int:
	var rate = commission_rate if current_mode == "banker" else tie_rate
	return int(current_bet * rate)

func hide_popup():
	if popup:
		popup.hide()

func clear_input():
	if popup and popup.has_node("MarginContainer/VBoxContainer/BetInput"):
		var input = popup.get_node("MarginContainer/VBoxContainer/BetInput")
		input.text = ""
		input.grab_focus()
