# 🔄 MIGRATION GUIDE: Рефакторинг Baccarat 1.0 → 2.0

**Дата рефакторинга:** 2025-11-21
**Версия:** 1.0 → 2.0
**Затронуто:** ~60% кодовой базы

---

## 📋 SUMMARY OF CHANGES

### Удалено
- ❌ 6 State классов (~500 строк)
- ❌ BetManager (старая система ставок)
- ❌ Прямые вызовы toast_manager, stats_manager
- ❌ Внутренний класс ChipStack внутри PayoutPopup

### Добавлено
- ✅ EventBus (28 сигналов)
- ✅ GameStateManager (кэширование)
- ✅ ChipStack, ChipStackManager, PayoutValidator (отдельные модули)
- ✅ ToastPool (object pooling)
- ✅ 112 unit + integration тестов

### Изменено
- 🔄 GameController упрощён (но размер ~тот же)
- 🔄 PayoutPopup: 781 → ~250 строк
- 🔄 StatsManager, ToastManager → autoload синглтоны
- 🔄 GamePhaseManager → использует EventBus

---

## 🗺️ МАППИНГ API (До → После)

### State System

#### Было (State классы)
```gdscript
# scripts/states/CardsDealtState.gd
class_name CardsDealtState
extends GameState

func handle_action(phase_manager):
    # 144 строки логики валидации
    ...
```

#### Стало (GameStateManager)
```gdscript
# scripts/autoload/GameStateManager.gd (autoload)
var state = GameStateManager.determine_state(
    false,           # cards_hidden
    player_hand,     # Array[Card]
    banker_hand,     # Array[Card]
    player_third,    # Card или null
    banker_third     # Card или null
)

if not GameStateManager.is_action_valid(GameStateManager.Action.SELECT_WINNER):
    var msg = GameStateManager.get_error_message(GameStateManager.Action.SELECT_WINNER)
    print(msg)
```

**Миграция:**
1. Удалить все `extends GameState` классы
2. Использовать `GameStateManager.determine_state()` вместо `current_state.handle_action()`
3. Валидацию делать через `is_action_valid()`

---

### StatsManager

#### Было (ручные вызовы)
```gdscript
# GamePhaseManager.gd
var stats_manager: StatsManager

func _validate():
    if error:
        stats_manager.increment_error("player_wrong")
```

#### Стало (EventBus)
```gdscript
# GamePhaseManager.gd
# Больше нет переменной stats_manager

func _validate():
    if error:
        EventBus.action_error.emit("player_wrong", "Сообщение об ошибке")
        # StatsManager автоматически подписан на этот сигнал
```

**Миграция:**
1. Удалить переменные `stats_manager` из всех классов
2. Заменить `stats_manager.increment_correct()` → `EventBus.action_correct.emit(type)`
3. Заменить `stats_manager.increment_error()` → `EventBus.action_error.emit(type, message)`
4. StatsManager теперь autoload, доступен глобально: `StatsManager.instance`

---

### ToastManager

#### Было (ручные вызовы)
```gdscript
# GamePhaseManager.gd
var toast_manager: ToastManager

func _validate():
    if error:
        toast_manager.show_error("Ошибка!")
```

#### Стало (EventBus)
```gdscript
# GamePhaseManager.gd
# Больше нет переменной toast_manager

func _validate():
    if error:
        EventBus.show_toast_error.emit("Ошибка!")
        # ToastManager автоматически подписан на этот сигнал
```

**Миграция:**
1. Удалить переменные `toast_manager` из всех классов
2. Заменить `toast_manager.show_info()` → `EventBus.show_toast_info.emit(message)`
3. Заменить `toast_manager.show_success()` → `EventBus.show_toast_success.emit(message)`
4. Заменить `toast_manager.show_error()` → `EventBus.show_toast_error.emit(message)`

---

### PayoutPopup (Chip System)

#### Было (монолит)
```gdscript
# scripts/popups/PayoutPopup.gd (781 строка)

# Внутренний класс ChipStack
class ChipStack:
    var denomination: float
    var count: int
    func add_chip(): ...
    func remove_chip(): ...

# Логика управления стопками
var chip_stacks: Array[ChipStack] = []
func _add_chip(denomination: float): ...
func _remove_chip(denomination: float): ...

# Логика валидации
func _validate_payout(): ...
func _calculate_hint(): ...
```

#### Стало (модули)
```gdscript
# scripts/chip_system/ChipStack.gd (отдельный модуль)
class_name ChipStack
extends RefCounted
# Управление одной стопкой

# scripts/chip_system/ChipStackManager.gd (отдельный модуль)
class_name ChipStackManager
extends RefCounted
# Управление коллекцией стопок

# scripts/chip_system/PayoutValidator.gd (отдельный модуль)
class_name PayoutValidator
extends RefCounted
# Валидация и расчёт подсказки

# scripts/popups/PayoutPopup.gd (~250 строк)
# Только UI координация
```

**Миграция:**
1. Импортировать модули:
   ```gdscript
   var chip_stack_manager: ChipStackManager
   var payout_validator: PayoutValidator
   ```
2. Инициализировать в `_ready()`:
   ```gdscript
   chip_stack_manager = ChipStackManager.new(chip_stacks_container)
   payout_validator = PayoutValidator.new()
   ```
3. Использовать методы:
   ```gdscript
   # Добавление фишки
   chip_stack_manager.add_chip(100.0)

   # Получение суммы
   var total = chip_stack_manager.get_total()

   # Валидация
   var is_correct = payout_validator.validate(collected, expected)

   # Подсказка
   var hint = payout_validator.calculate_hint(target_amount, denominations)
   ```

---

### GamePhaseManager

#### Было (State-based)
```gdscript
# scripts/GamePhaseManager.gd
var current_state: GameState

func on_action_pressed():
    current_state.handle_action(self)
    current_state = current_state.next_state()
```

#### Стало (EventBus + GameStateManager)
```gdscript
# scripts/GamePhaseManager.gd
func on_action_pressed():
    var state = GameStateManager.get_current_state()

    match state:
        GameStateManager.GameState.WAITING:
            deal_first_four()
        GameStateManager.GameState.CARD_TO_PLAYER:
            _validate_and_execute_third_cards()
        # ...

    # Обновляем состояние после действия
    _update_game_state_manager()
```

**Миграция:**
1. Удалить переменную `current_state: GameState`
2. Использовать `GameStateManager.get_current_state()` вместо `current_state`
3. Заменить `current_state.handle_action()` → match по состояниям
4. После каждого действия вызывать `_update_game_state_manager()`

---

## 🔧 BREAKING CHANGES

### 1. Autoload регистрация

**Обязательно добавить в project.godot:**
```ini
[autoload]
EventBus="*res://scripts/autoload/EventBus.gd"
GameStateManager="*res://scripts/autoload/GameStateManager.gd"
StatsManager="*res://scripts/StatsManager.gd"
ToastManager="*res://scripts/ToastManager.gd"
```

### 2. Сигналы вместо прямых вызовов

**Старый код перестанет работать:**
```gdscript
toast_manager.show_error("Ошибка")  # ❌ Нет переменной toast_manager
```

**Новый код:**
```gdscript
EventBus.show_toast_error.emit("Ошибка")  # ✅
```

### 3. State классы удалены

**Старый код перестанет работать:**
```gdscript
var current_state: GameState = WaitingState.new()  # ❌ Класс не существует
```

**Новый код:**
```gdscript
var state = GameStateManager.get_current_state()  # ✅ Используй autoload
```

### 4. ChipStack вынесен из PayoutPopup

**Старый код перестанет работать:**
```gdscript
var stack = PayoutPopup.ChipStack.new(100.0)  # ❌ Внутреннего класса нет
```

**Новый код:**
```gdscript
var stack = ChipStack.new(100.0, 1.0)  # ✅ Отдельный модуль
```

---

## 🛠️ ПОШАГОВАЯ МИГРАЦИЯ

### Шаг 1: Обновить project.godot
Добавить 4 новых autoload (см. выше)

### Шаг 2: Удалить старые импорты
```gdscript
# Удалить:
var toast_manager: ToastManager  # ❌
var stats_manager: StatsManager  # ❌
var current_state: GameState     # ❌
```

### Шаг 3: Заменить toast вызовы
```bash
# Поиск и замена:
toast_manager.show_info → EventBus.show_toast_info.emit
toast_manager.show_success → EventBus.show_toast_success.emit
toast_manager.show_error → EventBus.show_toast_error.emit
```

### Шаг 4: Заменить stats вызовы
```bash
# Поиск и замена:
stats_manager.increment_correct → EventBus.action_correct.emit
stats_manager.increment_error → EventBus.action_error.emit
```

### Шаг 5: Обновить PayoutPopup
Если используешь PayoutPopup:
1. Импортировать ChipStackManager, PayoutValidator
2. Удалить внутренний класс ChipStack
3. Использовать новые методы

### Шаг 6: Обновить GamePhaseManager
Если используешь GamePhaseManager:
1. Заменить State-based логику на match по GameStateManager.GameState
2. Вызывать `_update_game_state_manager()` после каждого действия

---

## ✅ ТЕСТИРОВАНИЕ ПОСЛЕ МИГРАЦИИ

### 1. Unit тесты
```bash
# Запустить все тесты
godot --path . --headless --script addons/gut/gut_cmdln.gd

# Ожидается: 112 тестов проходят
```

### 2. Интеграционные тесты
```bash
# Запустить интеграционные тесты
godot --path . --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/integration/

# Ожидается: 16 тестов проходят
```

### 3. Ручное тестирование
Используй `TESTING_GUIDE_STAGE3.md` для проверки:
- Игра запускается без ошибок
- Статистика обновляется через EventBus
- Тосты показываются через EventBus
- Режим выживания работает
- Полный игровой цикл (5+ раундов) без ошибок

---

## 📊 МЕТРИКИ УСПЕШНОЙ МИГРАЦИИ

| Критерий | Как проверить |
|----------|--------------|
| Все тесты проходят | `godot --headless --script gut_cmdln.gd` |
| Нет orphan nodes | Запустить 10 раундов, проверить Print Stray Nodes |
| Toast показываются | Сделать ошибку → должен появиться toast |
| Статистика работает | Сыграть 5 раундов → счётчики обновляются |
| Производительность | 100 раундов <1 секунды (см. test_performance.gd) |

---

## 🐛 ЧАСТЫЕ ПРОБЛЕМЫ

### Проблема 1: "EventBus не найден"
**Причина:** Autoload не зарегистрирован
**Решение:** Добавить в project.godot (см. Шаг 1)

### Проблема 2: "Toast не показываются"
**Причина:** ToastManager не подписан на EventBus
**Решение:** Проверить, что ToastManager autoload зарегистрирован и `_ready()` вызван

### Проблема 3: "Статистика не обновляется"
**Причина:** StatsManager не подписан на EventBus
**Решение:** Проверить, что StatsManager autoload зарегистрирован и `_ready()` вызван

### Проблема 4: "ChipStack not found"
**Причина:** Используется старый API PayoutPopup.ChipStack
**Решение:** Заменить на `ChipStack.new()` (отдельный модуль)

### Проблема 5: "State класс не найден"
**Причина:** Используются удалённые State классы
**Решение:** Заменить на GameStateManager.get_current_state()

---

## 📞 ПОДДЕРЖКА

Если возникли проблемы при миграции:
1. Проверить console на ошибки
2. Запустить unit тесты для диагностики
3. Сверить код с примерами в ARCHITECTURE.md
4. Проверить CLAUDE.md для актуальной документации

---

**Последнее обновление:** 2025-11-21
**Версия гайда:** 1.0
