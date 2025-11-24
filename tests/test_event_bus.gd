# res://tests/test_event_bus.gd
# Unit тесты для EventBus (autoload singleton)
extends GutTest

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ НАЛИЧИЯ СИГНАЛОВ
# ═══════════════════════════════════════════════════════════════════════════

func test_has_game_process_signals():
	assert_has_signal(EventBus, "cards_dealt", "Должен быть сигнал cards_dealt")
	assert_has_signal(EventBus, "player_third_drawn", "Должен быть сигнал player_third_drawn")
	assert_has_signal(EventBus, "banker_third_drawn", "Должен быть сигнал banker_third_drawn")
	assert_has_signal(EventBus, "game_completed", "Должен быть сигнал game_completed")
	assert_has_signal(EventBus, "round_reset", "Должен быть сигнал round_reset")

func test_has_action_signals():
	assert_has_signal(EventBus, "action_correct", "Должен быть сигнал action_correct")
	assert_has_signal(EventBus, "winner_correct", "Должен быть сигнал winner_correct")

func test_has_error_signals():
	assert_has_signal(EventBus, "action_error", "Должен быть сигнал action_error")

func test_has_payout_signals():
	assert_has_signal(EventBus, "show_payout_popup", "Должен быть сигнал show_payout_popup")
	assert_has_signal(EventBus, "payout_correct", "Должен быть сигнал payout_correct")
	assert_has_signal(EventBus, "payout_wrong", "Должен быть сигнал payout_wrong")
	assert_has_signal(EventBus, "hint_used", "Должен быть сигнал hint_used")

func test_has_toast_signals():
	assert_has_signal(EventBus, "show_toast_info", "Должен быть сигнал show_toast_info")
	assert_has_signal(EventBus, "show_toast_success", "Должен быть сигнал show_toast_success")
	assert_has_signal(EventBus, "show_toast_error", "Должен быть сигнал show_toast_error")

func test_has_settings_signals():
	assert_has_signal(EventBus, "game_mode_changed", "Должен быть сигнал game_mode_changed")
	assert_has_signal(EventBus, "language_changed", "Должен быть сигнал language_changed")
	assert_has_signal(EventBus, "survival_mode_changed", "Должен быть сигнал survival_mode_changed")
	assert_has_signal(EventBus, "table_limits_changed", "Должен быть сигнал table_limits_changed")

func test_has_survival_signals():
	assert_has_signal(EventBus, "life_lost", "Должен быть сигнал life_lost")
	assert_has_signal(EventBus, "game_over", "Должен быть сигнал game_over")
	assert_has_signal(EventBus, "game_restarted", "Должен быть сигнал game_restarted")

func test_has_state_signals():
	assert_has_signal(EventBus, "game_state_changed", "Должен быть сигнал game_state_changed")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ ЭМИССИИ СИГНАЛОВ
# ═══════════════════════════════════════════════════════════════════════════

func test_cards_dealt_emission():
	watch_signals(EventBus)

	var player_hand = [Card.new(0, 1), Card.new(1, 5)]  # A♠, 5♥
	var banker_hand = [Card.new(2, 10), Card.new(3, 3)]  # 10♦, 3♣

	EventBus.cards_dealt.emit(player_hand, banker_hand)

	assert_signal_emitted(EventBus, "cards_dealt", "Сигнал cards_dealt должен эмититься")
	assert_signal_emit_count(EventBus, "cards_dealt", 1, "Сигнал должен эмититься ровно 1 раз")

func test_action_correct_emission():
	watch_signals(EventBus)
	EventBus.action_correct.emit("player_third")
	assert_signal_emitted(EventBus, "action_correct", "Сигнал action_correct должен эмититься")

func test_action_error_emission():
	watch_signals(EventBus)
	EventBus.action_error.emit("banker_wrong", "Банкиру не нужна карта")
	assert_signal_emitted(EventBus, "action_error", "Сигнал action_error должен эмититься")

func test_show_toast_info_emission():
	watch_signals(EventBus)
	EventBus.show_toast_info.emit("Тестовое сообщение")
	assert_signal_emitted(EventBus, "show_toast_info", "Сигнал show_toast_info должен эмититься")

func test_show_toast_success_emission():
	watch_signals(EventBus)
	EventBus.show_toast_success.emit("Правильно!")
	assert_signal_emitted(EventBus, "show_toast_success", "Сигнал show_toast_success должен эмититься")

func test_show_toast_error_emission():
	watch_signals(EventBus)
	EventBus.show_toast_error.emit("Ошибка!")
	assert_signal_emitted(EventBus, "show_toast_error", "Сигнал show_toast_error должен эмититься")

func test_payout_correct_emission():
	watch_signals(EventBus)
	EventBus.payout_correct.emit(95.0, 95.0)
	assert_signal_emitted(EventBus, "payout_correct", "Сигнал payout_correct должен эмититься")

func test_payout_wrong_emission():
	watch_signals(EventBus)
	EventBus.payout_wrong.emit(100.0, 95.0)
	assert_signal_emitted(EventBus, "payout_wrong", "Сигнал payout_wrong должен эмититься")

func test_life_lost_emission():
	watch_signals(EventBus)
	EventBus.life_lost.emit()
	assert_signal_emitted(EventBus, "life_lost", "Сигнал life_lost должен эмититься")

func test_game_over_emission():
	watch_signals(EventBus)
	EventBus.game_over.emit(15)
	assert_signal_emitted(EventBus, "game_over", "Сигнал game_over должен эмититься")

func test_game_mode_changed_emission():
	watch_signals(EventBus)
	EventBus.game_mode_changed.emit("classic")
	assert_signal_emitted(EventBus, "game_mode_changed", "Сигнал game_mode_changed должен эмититься")

func test_language_changed_emission():
	watch_signals(EventBus)
	EventBus.language_changed.emit("en")
	assert_signal_emitted(EventBus, "language_changed", "Сигнал language_changed должен эмититься")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ ПОДПИСКИ НА СИГНАЛЫ
# ═══════════════════════════════════════════════════════════════════════════

func test_subscribe_to_action_correct():
	var callback_called = false

	var callback = func(type: String):
		callback_called = true

	EventBus.action_correct.connect(callback)
	EventBus.action_correct.emit("test_action")

	assert_true(callback_called, "Callback должен быть вызван при эмиссии сигнала")

func test_subscribe_to_toast_info():
	var received_message = ""

	var callback = func(message: String):
		received_message = message

	EventBus.show_toast_info.connect(callback)
	EventBus.show_toast_info.emit("Тестовое сообщение")

	assert_eq(received_message, "Тестовое сообщение", "Должно быть получено правильное сообщение")

func test_subscribe_to_payout_correct():
	var received_collected = 0.0
	var received_expected = 0.0

	var callback = func(collected: float, expected: float):
		received_collected = collected
		received_expected = expected

	EventBus.payout_correct.connect(callback)
	EventBus.payout_correct.emit(95.0, 95.0)

	assert_eq(received_collected, 95.0, "Должна быть получена правильная collected сумма")
	assert_eq(received_expected, 95.0, "Должна быть получена правильная expected сумма")

func test_multiple_subscribers():
	var callback1_called = false
	var callback2_called = false

	var callback1 = func(_type: String): callback1_called = true
	var callback2 = func(_type: String): callback2_called = true

	EventBus.action_correct.connect(callback1)
	EventBus.action_correct.connect(callback2)
	EventBus.action_correct.emit("test")

	assert_true(callback1_called, "Первый callback должен быть вызван")
	assert_true(callback2_called, "Второй callback должен быть вызван")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ ОТПИСКИ ОТ СИГНАЛОВ
# ═══════════════════════════════════════════════════════════════════════════

func test_disconnect_from_signal():
	var callback_called = false

	var callback = func(_type: String): callback_called = true

	EventBus.action_correct.connect(callback)
	EventBus.action_correct.disconnect(callback)
	EventBus.action_correct.emit("test")

	assert_false(callback_called, "Callback НЕ должен быть вызван после disconnect")

# ═══════════════════════════════════════════════════════════════════════════
# ТЕСТЫ ГРАНИЧНЫХ СЛУЧАЕВ
# ═══════════════════════════════════════════════════════════════════════════

func test_emit_without_subscribers():
	# Эмиссия без подписчиков не должна вызывать ошибок
	EventBus.action_correct.emit("test")
	assert_true(true, "Эмиссия без подписчиков не должна вызывать ошибок")

func test_emit_multiple_times():
	watch_signals(EventBus)

	EventBus.action_correct.emit("test1")
	EventBus.action_correct.emit("test2")
	EventBus.action_correct.emit("test3")

	assert_signal_emit_count(EventBus, "action_correct", 3, "Сигнал должен эмититься 3 раза")

func test_emit_with_null_parameters():
	# Некоторые сигналы могут принимать null (например, player_third_drawn с null картой)
	watch_signals(EventBus)
	EventBus.player_third_drawn.emit(null)
	assert_signal_emitted(EventBus, "player_third_drawn", "Сигнал должен эмититься даже с null")
