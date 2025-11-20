# res://scripts/UIManager.gd
class_name UIManager
extends RefCounted

signal action_button_pressed()
signal player_third_toggled(selected: bool)
signal banker_third_toggled(selected: bool)
signal winner_selected(winner: String)
signal help_button_pressed()
signal lang_button_pressed()

var action_button: Button
var player_card1: TextureRect
var player_card2: TextureRect
var player_card3: TextureRect
var banker_card1: TextureRect
var banker_card2: TextureRect
var banker_card3: TextureRect
var player_third_toggle: TextureRect
var banker_third_toggle: TextureRect
var help_button: Button
var help_popup: Popup
var player_marker: Control
var banker_marker: Control
var tie_marker: Control
var stats_label: Label
var lang_button: Button
var bet_chip: TextureButton
var bet_popup: PopupPanel
var card_manager: CardTextureManager
var tie_chip: TextureButton

func _init(scene: Node, cm: CardTextureManager):
	card_manager = cm

	action_button = scene.get_node("CardsButton")
	player_card1 = scene.get_node("PlayerZone/Card1")
	player_card2 = scene.get_node("PlayerZone/Card2")
	player_card3 = scene.get_node("PlayerZone/Card3")
	banker_card1 = scene.get_node("BankerZone/Card1")
	banker_card2 = scene.get_node("BankerZone/Card2")
	banker_card3 = scene.get_node("BankerZone/Card3")
	player_third_toggle = scene.get_node("PlayerZone/PlayerThirdCardToggle")
	banker_third_toggle = scene.get_node("BankerZone/BankerThirdCardToggle")
	help_button = scene.get_node("HelpButton")
	help_popup = scene.get_node("HelpPopup")
	player_marker = scene.get_node("PlayerMarker")
	banker_marker = scene.get_node("BankerMarker")
	tie_marker = scene.get_node("TieMarker")
	stats_label = scene.get_node("StatsLabel")

	# ← LangButton теперь опциональна (может быть скрыта/удалена)
	if scene.has_node("LangButton"):
		lang_button = scene.get_node("LangButton")
		lang_button.pressed.connect(func(): lang_button_pressed.emit())

	bet_chip = scene.get_node("BetChip")
	bet_popup = scene.get_node("BetPopup")

	action_button.pressed.connect(func(): action_button_pressed.emit())
	player_third_toggle.gui_input.connect(_on_player_toggle_input)
	banker_third_toggle.gui_input.connect(_on_banker_toggle_input)
	help_button.pressed.connect(func(): help_button_pressed.emit())

	connect_winner_button(player_marker, "Player")
	connect_winner_button(banker_marker, "Banker")
	connect_winner_button(tie_marker, "Tie")

	tie_chip = scene.get_node("TieChip")  # ← НОВОЕ

# ... остальной код без изменений (show_first_four_cards, reset_ui, _show_initial_backs и т.д.)

func _on_player_toggle_input(event):
	if event is InputEventMouseButton and event.pressed:
		var selected = player_third_toggle.texture == card_manager.get_back_exclamation_texture()
		player_third_toggled.emit(!selected)

func _on_banker_toggle_input(event):
	if event is InputEventMouseButton and event.pressed:
		var selected = banker_third_toggle.texture == card_manager.get_back_exclamation_texture()
		banker_third_toggled.emit(!selected)

func connect_winner_button(button: Control, winner: String):
	button.pressed.connect(func(): winner_selected.emit(winner))

func show_first_four_cards(player_hand: Array[Card], banker_hand: Array[Card]):
	player_card1.texture = player_hand[0].get_texture(card_manager)
	player_card2.texture = player_hand[1].get_texture(card_manager)
	banker_card1.texture = banker_hand[0].get_texture(card_manager)
	banker_card2.texture = banker_hand[1].get_texture(card_manager)
	player_card1.visible = true
	player_card2.visible = true
	banker_card1.visible = true
	banker_card2.visible = true

func show_player_third_card(card: Card):
	player_card3.texture = card.get_texture(card_manager)
	player_card3.visible = true

func show_banker_third_card(card: Card):
	banker_card3.texture = card.get_texture(card_manager)
	banker_card3.visible = true

func reset_ui():
	_hide_all_cards()
	_show_initial_backs()
	player_third_toggle.visible = true
	banker_third_toggle.visible = true
	update_player_toggle(false)
	update_banker_toggle(false)
	update_action_button(Localization.t("ACTION_BUTTON_CARDS"))
	action_button.disabled = false

func _hide_all_cards():
	player_card1.visible = false
	player_card2.visible = false
	player_card3.visible = false
	banker_card1.visible = false
	banker_card2.visible = false
	banker_card3.visible = false

func _show_initial_backs():
	var back = card_manager.get_back_texture()
	player_card1.texture = back
	player_card2.texture = back
	banker_card1.texture = back
	banker_card2.texture = back
	player_card1.visible = true
	player_card2.visible = true
	banker_card1.visible = true
	banker_card2.visible = true

func hide_player_toggle():
	player_third_toggle.visible = false

func hide_banker_toggle():
	banker_third_toggle.visible = false

func hide_both_toggles():
	hide_player_toggle()
	hide_banker_toggle()

func update_player_toggle(selected: bool):
	player_third_toggle.texture = card_manager.get_back_exclamation_texture() if selected else card_manager.get_back_question_texture()

func update_banker_toggle(selected: bool):
	banker_third_toggle.texture = card_manager.get_back_exclamation_texture() if selected else card_manager.get_back_question_texture()

func update_action_button(text: String):
	action_button.text = text

func update_lang_button():
	if lang_button:
		lang_button.text = Localization.get_lang().to_upper()
