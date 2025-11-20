# res://scripts/Deck.gd
class_name Deck

var cards: Array[Card] = []

func _init():
	shuffle()

func shuffle():
	cards.clear()
	for i in 8:
		for suit_index in 4:
			for value in range(1, 14):
				cards.append(Card.new(suit_index, value))
	cards.shuffle()

func draw() -> Card:
	if cards.is_empty():
		shuffle()
	return cards.pop_back()
