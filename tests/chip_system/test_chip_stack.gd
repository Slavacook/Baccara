# res://tests/chip_system/test_chip_stack.gd
# Unit тесты для ChipStack
extends GutTest

var chip_stack: ChipStack

func before_each():
	chip_stack = ChipStack.new(100.0, 1.0)  # Номинал 100, масштаб 1.0

func after_each():
	# Освобождаем UI узлы, чтобы избежать orphans
	# Используем free() вместо queue_free() для немедленного удаления
	if chip_stack and chip_stack.container:
		chip_stack.container.free()
	chip_stack = null

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ БАЗОВОЙ ФУНКЦИОНАЛЬНОСТИ
# ═══════════════════════════════════════════════════════════════════════════

func test_initial_count_is_zero():
	assert_eq(chip_stack.count, 0, "Начальное количество фишек должно быть 0")

func test_denomination_is_set():
	assert_eq(chip_stack.denomination, 100.0, "Номинал должен быть 100.0")

func test_scale_is_set():
	assert_eq(chip_stack.scale, 1.0, "Масштаб должен быть 1.0")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ ДОБАВЛЕНИЯ ФИШЕК
# ═══════════════════════════════════════════════════════════════════════════

func test_add_chip_increases_count():
	var result = chip_stack.add_chip()
	assert_true(result, "add_chip() должен вернуть true")
	assert_eq(chip_stack.count, 1, "Количество фишек должно увеличиться до 1")

func test_add_multiple_chips():
	chip_stack.add_chip()
	chip_stack.add_chip()
	chip_stack.add_chip()
	assert_eq(chip_stack.count, 3, "Количество фишек должно быть 3")

func test_max_chips_limit():
	# Добавляем 20 фишек (максимум)
	for i in range(GameConstants.CHIP_STACK_MAX_CHIPS):
		chip_stack.add_chip()

	assert_eq(chip_stack.count, GameConstants.CHIP_STACK_MAX_CHIPS, "Должно быть %d фишек" % GameConstants.CHIP_STACK_MAX_CHIPS)

	# Попытка добавить 21-ю фишку должна провалиться
	var result = chip_stack.add_chip()
	assert_false(result, "add_chip() должен вернуть false при превышении лимита")
	assert_eq(chip_stack.count, GameConstants.CHIP_STACK_MAX_CHIPS, "Количество не должно превысить максимум")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ УДАЛЕНИЯ ФИШЕК
# ═══════════════════════════════════════════════════════════════════════════

func test_remove_chip_decreases_count():
	chip_stack.add_chip()
	chip_stack.add_chip()

	var result = chip_stack.remove_chip()
	assert_true(result, "remove_chip() должен вернуть true")
	assert_eq(chip_stack.count, 1, "Количество фишек должно уменьшиться до 1")

func test_remove_chip_from_empty_stack():
	var result = chip_stack.remove_chip()
	assert_false(result, "remove_chip() должен вернуть false для пустого стека")
	assert_eq(chip_stack.count, 0, "Количество должно остаться 0")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ РАСЧЁТА СУММЫ
# ═══════════════════════════════════════════════════════════════════════════

func test_get_total_zero():
	assert_eq(chip_stack.get_total(), 0.0, "Сумма пустого стека должна быть 0")

func test_get_total_single_chip():
	chip_stack.add_chip()
	assert_eq(chip_stack.get_total(), 100.0, "Сумма 1 фишки номиналом 100 = 100")

func test_get_total_multiple_chips():
	chip_stack.add_chip()
	chip_stack.add_chip()
	chip_stack.add_chip()
	assert_eq(chip_stack.get_total(), 300.0, "Сумма 3 фишек номиналом 100 = 300")

func test_get_total_fractional_denomination():
	var stack_half = ChipStack.new(0.5, 1.0)
	stack_half.add_chip()
	stack_half.add_chip()
	assert_eq(stack_half.get_total(), 1.0, "Сумма 2 фишек номиналом 0.5 = 1.0")

	# Освобождаем дополнительный стек (немедленно)
	if stack_half and stack_half.container:
		stack_half.container.free()

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ ПРОВЕРОК
# ═══════════════════════════════════════════════════════════════════════════

func test_is_empty_true():
	assert_true(chip_stack.is_empty(), "Новый стек должен быть пустым")

func test_is_empty_false():
	chip_stack.add_chip()
	assert_false(chip_stack.is_empty(), "Стек с фишками не должен быть пустым")

func test_is_empty_after_remove_all():
	chip_stack.add_chip()
	chip_stack.add_chip()
	chip_stack.remove_chip()
	chip_stack.remove_chip()
	assert_true(chip_stack.is_empty(), "Стек должен стать пустым после удаления всех фишек")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ МАСШТАБИРОВАНИЯ
# ═══════════════════════════════════════════════════════════════════════════

func test_update_scale():
	chip_stack.update_scale(0.6)
	assert_eq(chip_stack.scale, 0.6, "Масштаб должен обновиться до 0.6")

func test_update_scale_updates_container_size():
	var original_width = chip_stack.container.custom_minimum_size.x
	chip_stack.update_scale(0.5)
	var new_width = chip_stack.container.custom_minimum_size.x
	assert_eq(new_width, original_width * 0.5, "Размер контейнера должен масштабироваться")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ СИГНАЛОВ
# ═══════════════════════════════════════════════════════════════════════════

func test_chip_added_signal():
	watch_signals(chip_stack)
	chip_stack.add_chip()
	assert_signal_emitted(chip_stack, "chip_added", "Сигнал chip_added должен быть эмитирован")

func test_chip_removed_signal():
	chip_stack.add_chip()
	watch_signals(chip_stack)
	chip_stack.remove_chip()
	assert_signal_emitted(chip_stack, "chip_removed", "Сигнал chip_removed должен быть эмитирован")

func test_stack_empty_signal():
	chip_stack.add_chip()
	watch_signals(chip_stack)
	chip_stack.remove_chip()
	assert_signal_emitted(chip_stack, "stack_empty", "Сигнал stack_empty должен быть эмитирован")

func test_total_changed_signal():
	watch_signals(chip_stack)
	chip_stack.add_chip()
	assert_signal_emitted(chip_stack, "total_changed", "Сигнал total_changed должен быть эмитирован")
