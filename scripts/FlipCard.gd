extends Node2D
class_name FlipCard

@onready var flip_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var flip_sound: AudioStreamPlayer = $FlipSound  # новый аудио-узел!
var flip_sounds : Array[AudioStream] = []


func _ready():
	visible = false
	flip_anim.connect("animation_finished", Callable(self, "_hide_after_flip"))
	randomize()

	# Загружаем звуки через константы
	for i in range(1, GameConstants.FLIP_CARD_SOUNDS_COUNT + 1):
		var sound_path = GameConstants.FLIP_CARD_SOUND_PATH_TEMPLATE % i
		var sound = load(sound_path)
		if sound:
			flip_sounds.append(sound)
		else:
			push_warning("FlipCard: звук не найден: %s" % sound_path)
	
	
func play_flip():
	visible = true   # Показать FlipCard перед анимацией
	flip_anim.frame = 0
	flip_anim.play("flip_card")
	if flip_sounds.size() > 0 and flip_sound:
		var rand_index = randi() % flip_sounds.size()
		flip_sound.stream = flip_sounds[rand_index]
		flip_sound.play()

func _hide_after_flip():
	visible = false  # FlipCard исчезает сразу после flip
