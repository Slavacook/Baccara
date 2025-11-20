# res://scripts/Card.gd
class_name Card
enum Suit { CLUBS, HEARTS, SPADES, DIAMONDS }

var suit: int
var value: int  # 1=A, 2-10, 11=J, 12=Q, 13=K

func _init(s: int, v: int):
	suit = s
	value = v

func get_point() -> int:
	if value >= 11: return 0
	if value == 1: return 1
	return value

func get_texture(card_manager: CardTextureManager) -> Texture2D:
	return card_manager.get_card_texture(suit, value)

func card_to_string() -> String:
	const SUITS = ["C", "H", "S", "D"]
	const VALUES = {1:"A",2:"2",3:"3",4:"4",5:"5",6:"6",7:"7",8:"8",9:"9",10:"10",11:"J",12:"Q",13:"K"}
	if suit < 0 or suit > 3: return "??"
	return VALUES.get(value, "?") + SUITS[suit]
