# res://scripts/CardTextureManager.gd
class_name CardTextureManager

const SUIT_TO_FOLDER = {
	Card.Suit.CLUBS:    "clubs",
	Card.Suit.HEARTS:   "hearts",
	Card.Suit.SPADES:   "spades",
	Card.Suit.DIAMONDS: "diamonds"
}

const VALUE_TO_NAME = {
	1:  "ace",  2:  "2",  3:  "3",  4:  "4",  5:  "5",
	6:  "6",  7:  "7",  8:  "8",  9:  "9", 10: "10",
	11: "jack", 12: "queen", 13: "king"
}

var _texture_cache = {}
var config: GameConfig

func _init(conf: GameConfig):
	config = conf

func get_card_texture(suit: int, value: int) -> Texture2D:
	var suit_name = SUIT_TO_FOLDER.get(suit, "")
	var value_name = VALUE_TO_NAME.get(value, "")
	if suit_name == "" or value_name == "":
		push_error("Invalid suit or value: %d, %d" % [suit, value])
		return null

	var path = config.card_paths[suit_name] % value_name

	if _texture_cache.has(path):
		return _texture_cache[path]

	if not FileAccess.file_exists(path):
		push_error("Card file not found: %s" % path)
		return null

	var texture = load(path)
	if texture:
		_texture_cache[path] = texture
	return texture

func get_back_texture() -> Texture2D:
	return _load_cached(config.back_card_path)

func get_back_question_texture() -> Texture2D:
	return _load_cached(config.back_question_path)

func get_back_exclamation_texture() -> Texture2D:
	return _load_cached(config.back_exclamation_path)

func _load_cached(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	if not FileAccess.file_exists(path):
		push_error("Back texture not found: %s" % path)
		return null
	var tex = load(path)
	_texture_cache[path] = tex
	return tex
