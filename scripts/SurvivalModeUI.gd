# res://scripts/SurvivalModeUI.gd
extends Control

signal game_over(rounds_survived: int)

@onready var hearts: Array[Label] = [
	%Heart1, %Heart2, %Heart3, %Heart4, %Heart5, %Heart6, %Heart7
]

const MAX_LIVES = 7
var current_lives: int = MAX_LIVES
var is_active: bool = false

func _ready():
	hide()  # Скрыто по умолчанию

# ← Активировать режим выживания
func activate():
	is_active = true
	current_lives = MAX_LIVES
	_update_hearts()
	show()
	print("Режим выживания активирован! Жизней: ", current_lives)

# ← Деактивировать режим выживания
func deactivate():
	is_active = false
	hide()
	print("Режим выживания деактивирован")

# ← Потерять жизнь при ошибке
func lose_life():
	if not is_active:
		return

	current_lives -= 1
	print("Жизнь потеряна! Осталось: ", current_lives)

	_update_hearts()
	_play_damage_animation()

	if current_lives <= 0:
		_trigger_game_over()

# ← Обновить визуальное отображение сердечек
func _update_hearts():
	for i in range(MAX_LIVES):
		if i < current_lives:
			hearts[i].text = "❤️"  # Полное сердечко
		else:
			hearts[i].text = "🖤"  # Пустое сердечко

# ← Анимация потери жизни
func _play_damage_animation():
	# Простая анимация: мигание красным
	var tween = create_tween()
	tween.set_parallel(true)

	# Все сердечки мигают
	for heart in hearts:
		tween.tween_property(heart, "modulate", Color(1, 0.3, 0.3), 0.1)

	tween.chain().set_parallel(true)
	for heart in hearts:
		tween.tween_property(heart, "modulate", Color.WHITE, 0.1)

# ← Триггер окончания игры
func _trigger_game_over():
	is_active = false
	print("GAME OVER! Режим выживания завершён")
	# Эмитим сигнал для GameController (rounds будет передан позже)
	game_over.emit(0)  # 0 пока, GameController передаст реальное значение

# ← Сбросить жизни (для начала новой игры)
func reset():
	current_lives = MAX_LIVES
	_update_hearts()
