# res://scripts/Dust.gd
extends Node2D

signal dust_finished()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func play_dust_1_card(callback: Callable = Callable()):
	animated_sprite.play("dust_1_card")
	await animated_sprite.animation_finished
	dust_finished.emit()
	if callback.is_valid():
		callback.call()
	queue_free()  # Удаляем после проигрывания

func play_dust_2_card(callback: Callable = Callable()):
	animated_sprite.play("dust_2_card")
	await animated_sprite.animation_finished
	dust_finished.emit()
	if callback.is_valid():
		callback.call()
	queue_free()  # Удаляем после проигрывания
