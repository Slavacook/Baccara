# res://scripts/HelpPopup.gd
extends PopupPanel

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var table_grid = $MarginContainer/VBoxContainer/TableGrid
@onready var close_button = $MarginContainer/VBoxContainer/CloseButton

func _ready():
	close_button.pressed.connect(hide)
	populate_table()
	hide()

func populate_table():
	title_label.text = Localization.t("HELP_TITLE")

	for child in table_grid.get_children():
		child.queue_free()

	_add_cell("", true)
	_add_cell("0–2", true)
	_add_cell("3", true)
	_add_cell("4", true)
	_add_cell("5", true)
	_add_cell("6", true)
	_add_cell("7", true)
	_add_cell("8–9", true)

	_add_cell(Localization.t("HELP_PLAYER_THIRD"), true)
	_add_cell(Localization.t("HELP_DRAW"), false)     # 0–2
	_add_cell("≠8", false)                                 # 3
	_add_cell("2–7", false)                                # 4
	_add_cell("4–7", false)                                # 5
	_add_cell("6–7", false)                                # 6
	_add_cell(Localization.t("HELP_NO_DRAW"), false) # 7
	_add_cell(Localization.t("HELP_NO_DRAW"), false) # 8–9

	_add_cell(Localization.t("HELP_BANKER"), true)
	for i in range(8):
		_add_cell(Localization.t("HELP_DRAW") if i < 7 else Localization.t("HELP_NO_DRAW"), false)

func _add_cell(text: String, is_header: bool):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(50, 40)
	if is_header:
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
	table_grid.add_child(label)
