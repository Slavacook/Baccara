# res://scripts/FlipCard.gd
extends Node2D

signal flip_finished()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func play_flip(final_texture: Texture2D, callback: Callable = Callable()):
	# Проигрываем анимацию переворота
	animated_sprite.play("flip_card")

	# Ждём окончания анимации
	await animated_sprite.animation_finished

	# После окончания показываем финальную карту
	# (Заменяем AnimatedSprite2D на обычный Sprite2D для показа финальной текстуры)
	var sprite = Sprite2D.new()
	sprite.texture = final_texture
	add_child(sprite)
	animated_sprite.visible = false

	# Уведомляем об окончании
	flip_finished.emit()
	if callback.is_valid():
		callback.call()
