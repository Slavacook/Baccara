# res://resources/GameConfig.gd
class_name GameConfig
extends Resource

@export var card_paths: Dictionary = {
	"clubs": "res://assets/cards/%s_clubs.png",
	"hearts": "res://assets/cards/%s_hearts.png",
	"spades": "res://assets/cards/%s_spades.png",
	"diamonds": "res://assets/cards/%s_diamonds.png"
}
@export var back_card_path: String = "res://assets/cards/back/card_back.png"
@export var back_question_path: String = "res://assets/cards/back/card_back_?.png"
@export var back_exclamation_path: String = "res://assets/cards/back/card_back_!.png"
@export var min_bet: int = 500
@export var max_bet: int = 200000
@export var commission_rate: float = 0.95
@export var languages: Array[String] = ["ru", "en"]
@export var default_lang: String = "ru"

@export var table_min_bet: int = 1000
@export var table_max_bet: int = 2000
@export var table_step: int = 500

@export var tie_min_bet: int = 1
@export var tie_max_bet: int = 100
@export var tie_step: int = 1
