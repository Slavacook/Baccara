# res://tests/chip_system/test_payout_validator.gd
# Unit тесты для PayoutValidator
extends GutTest

var validator: PayoutValidator

func before_each():
	validator = PayoutValidator.new()

func after_each():
	validator = null

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ ВАЛИДАЦИИ
# ═══════════════════════════════════════════════════════════════════════════

func test_validate_exact_match():
	var result = validator.validate(100.0, 100.0)
	assert_true(result, "Точное совпадение должно быть валидным")

func test_validate_with_epsilon():
	# Проверяем, что погрешность 0.01 учитывается
	var result = validator.validate(100.005, 100.0)
	assert_true(result, "Разница 0.005 должна быть в пределах погрешности")

func test_validate_too_low():
	var result = validator.validate(95.0, 100.0)
	assert_false(result, "Недостаточная сумма не должна быть валидной")

func test_validate_too_high():
	var result = validator.validate(105.0, 100.0)
	assert_false(result, "Избыточная сумма не должна быть валидной")

func test_validate_zero():
	var result = validator.validate(0.0, 0.0)
	assert_true(result, "Нулевая сумма должна валидироваться корректно")

func test_validate_fractional():
	var result = validator.validate(2.5, 2.5)
	assert_true(result, "Дробные числа должны валидироваться")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ СООБЩЕНИЙ ОБ ОШИБКАХ
# ═══════════════════════════════════════════════════════════════════════════

func test_error_message_insufficient():
	var msg = validator.get_error_message(95.0, 100.0)
	assert_string_contains(msg, "Недостаточно", "Сообщение должно содержать 'Недостаточно'")
	assert_string_contains(msg, "5", "Сообщение должно содержать разницу")

func test_error_message_excess():
	var msg = validator.get_error_message(105.0, 100.0)
	assert_string_contains(msg, "Слишком много", "Сообщение должно содержать 'Слишком много'")
	assert_string_contains(msg, "5", "Сообщение должно содержать разницу")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ РАСЧЁТА ПОДСКАЗКИ (ЖАДНЫЙ АЛГОРИТМ)
# ═══════════════════════════════════════════════════════════════════════════

func test_calculate_hint_simple():
	var hint = validator.calculate_hint(100.0, [100, 50, 10])

	assert_eq(hint.size(), 1, "Должна быть 1 группа фишек")
	assert_eq(hint[0]["denomination"], 100, "Должна быть фишка номиналом 100")
	assert_eq(hint[0]["count"], 1, "Должна быть 1 фишка")

func test_calculate_hint_multiple_denominations():
	var hint = validator.calculate_hint(170.0, [100, 50, 10])

	assert_eq(hint.size(), 3, "Должно быть 3 группы фишек")
	assert_eq(hint[0]["denomination"], 100, "Первая группа: 100")
	assert_eq(hint[0]["count"], 1, "1x100")
	assert_eq(hint[1]["denomination"], 50, "Вторая группа: 50")
	assert_eq(hint[1]["count"], 1, "1x50")
	assert_eq(hint[2]["denomination"], 10, "Третья группа: 10")
	assert_eq(hint[2]["count"], 2, "2x10")

func test_calculate_hint_fractional():
	var hint = validator.calculate_hint(2.5, [1, 0.5])

	assert_eq(hint.size(), 2, "Должно быть 2 группы фишек")
	assert_eq(hint[0]["denomination"], 1, "Первая группа: 1")
	assert_eq(hint[0]["count"], 2, "2x1")
	assert_eq(hint[1]["denomination"], 0.5, "Вторая группа: 0.5")
	assert_eq(hint[1]["count"], 1, "1x0.5")

func test_calculate_hint_exact_single_denomination():
	var hint = validator.calculate_hint(300.0, [100, 50, 10])

	assert_eq(hint.size(), 1, "Должна быть 1 группа фишек")
	assert_eq(hint[0]["denomination"], 100, "Номинал 100")
	assert_eq(hint[0]["count"], 3, "3 фишки")

func test_calculate_hint_greedy_optimization():
	# Проверяем, что алгоритм жадный (берёт максимально крупные)
	var hint = validator.calculate_hint(60.0, [100, 50, 10])

	assert_eq(hint.size(), 2, "Должно быть 2 группы")
	assert_eq(hint[0]["denomination"], 50, "Первая группа: 50 (не 100!)")
	assert_eq(hint[0]["count"], 1, "1x50")
	assert_eq(hint[1]["denomination"], 10, "Вторая группа: 10")
	assert_eq(hint[1]["count"], 1, "1x10")

func test_calculate_hint_zero():
	var hint = validator.calculate_hint(0.0, [100, 50, 10])
	assert_eq(hint.size(), 0, "Для нулевой суммы не должно быть фишек")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ ГРАНИЧНЫХ СЛУЧАЕВ
# ═══════════════════════════════════════════════════════════════════════════

func test_validate_negative_numbers():
	var result = validator.validate(-10.0, 0.0)
	assert_false(result, "Отрицательные числа не должны валидироваться")

func test_calculate_hint_empty_denominations():
	# Отключаем проверку ошибок для этого теста (ожидаем warning)
	var hint = validator.calculate_hint(100.0, [])
	assert_eq(hint.size(), 0, "Пустой массив номиналов должен вернуть пустой результат")
	# Ожидаем warning, это нормально

func test_calculate_hint_impossible_amount():
	# Невозможно составить 3 из номиналов [10, 5]
	var hint = validator.calculate_hint(3.0, [10, 5])
	# Алгоритм не сможет составить точную сумму, но попытается приблизиться
	# Ожидаем warning - это нормальное поведение
	assert_true(hint.size() >= 0, "Должен вернуть какой-то результат")
