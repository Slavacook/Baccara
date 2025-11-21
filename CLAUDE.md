# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Обзор проекта

**Баккара 5.9** - тренажёр для обучения правилам игры в баккара, разработанный на Godot 4.5. Проект помогает дилерам и крупье практиковать:
- Знание правил добора третьей карты
- Расчёт выплат с комиссией 5% на банкира
- Расчёт выплат 8:1 на ничью
- Определение победителя

Игра полностью локализована (русский/английский), работает с джойпадом, имеет систему статистики и настраиваемые лимиты стола.

## Архитектура

### Главный контроллер: GameController

`scripts/GameController.gd` - точка входа, координирует все подсистемы:

```gdscript
- deck: Deck - колода карт (52 карты, перемешивается при создании)
- card_manager: CardTextureManager - загрузка текстур карт из assets/cards/
- ui_manager: UIManager - управление UI элементами и сигналами
- phase_manager: GamePhaseManager - управление игровым процессом и валидация действий
- toast_manager: ToastManager - всплывающие уведомления (успех/ошибка/инфо)
- bet_manager: BetManager - расчёт ставок и выплат
- stats_manager: StatsManager - статистика правильных/ошибочных ответов
- limits_manager: LimitsManager - управление лимитами стола
```

### Система управления состояниями

Игровой процесс управляется через **GameStateManager** (autoload singleton) и **GamePhaseManager**.

**GameStateManager** (`scripts/GameStateManager.gd`) - декларативная система состояний:
- Определяет текущее состояние игры на основе карт на столе
- 6 состояний: WAITING, CARD_TO_EACH, CARD_TO_PLAYER, CARD_TO_BANKER, CARD_TO_BANKER_AFTER_PLAYER, CHOOSE_WINNER
- Валидирует допустимые действия: `is_action_valid(action)`
- Выдает сообщения об ошибках: `get_error_message(action)`
- Блокирует изменение настроек во время раздачи: `can_change_settings()`

**GamePhaseManager** (`scripts/GamePhaseManager.gd`) - управление игровым процессом:
- Раздача карт: `deal_first_four()`, `draw_player_third()`, `draw_banker_third()`
- Валидация действий игрока: `_validate_and_execute_third_cards()`, `_validate_banker_after_player()`
- Обновление GameStateManager после каждого действия
- Управление UI toggles и кнопками
- Обработка ошибок и режима выживания

**Состояния игры** (enum GameStateManager.GameState):
1. **WAITING** - карты скрыты, ожидание кнопки "Карты"
2. **CARD_TO_EACH** - банкир 0-2, игрок 0-5 → карта каждому
3. **CARD_TO_PLAYER** - банкир 3-7, игрок 0-5 → карта игроку
4. **CARD_TO_BANKER** - банкир 0-5, игрок 6-7 → карта банкиру
5. **CARD_TO_BANKER_AFTER_PLAYER** - банкир 3-6 после третьей игрока
6. **CHOOSE_WINNER** - все карты открыты, выбор победителя

### Правила баккара: BaccaratRules

`scripts/BaccaratRules.gd` - статический класс с логикой:

**Ключевые методы**:
- `hand_value(hand: Array[Card]) -> int` - сумма очков % 10
- `is_natural(hand) -> bool` - проверка натуральной 8 или 9
- `player_should_draw(player_hand) -> bool` - игрок берёт при ≤5
- `banker_should_draw(banker_hand, player_drew, player_third) -> bool` - сложные правила банкира:
  - 0-2: всегда берёт
  - 7-9: никогда не берёт
  - 3-6: зависит от третьей карты игрока (см. таблицу в методе)
- `get_winner(player_hand, banker_hand) -> String` - возвращает "Player"/"Banker"/"Tie"

### UI система: UIManager

`scripts/UIManager.gd` - управляет всеми UI элементами через сигналы:

**Сигналы**:
- `action_button_pressed()` - кнопка "Раздать карты" / "Открыть"
- `player_third_toggled(selected: bool)` - переключатель третьей карты игрока
- `banker_third_toggled(selected: bool)` - переключатель третьей карты банкира
- `winner_selected(winner: String)` - выбран победитель (Player/Banker/Tie)
- `help_button_pressed()` - кнопка помощи
- `lang_button_pressed()` - переключение языка

**Важно**: UIManager получает ссылку на CardTextureManager для управления текстурами рубашек (?, !, обычная).

### Система ставок: BetManager

`scripts/BetManager.gd` - управляет попапами ввода выплат:

**Логика выплат**:
- **Банкир**: stake × 0.95 (комиссия 5%) → `int(stake * commission_rate)`
- **Игрок**: stake × 1.0 (без попапа, сразу сброс)
- **Ничья**: stake × 8.0

**Сигнал**: `bet_confirmed(payout: int, bet_mode: String, is_correct: bool)`

### Лимиты стола: LimitsManager

`scripts/LimitsManager.gd` - управляет min/max/step для обычных ставок и TIE:

```gdscript
- min_bet, max_bet, step - для Player/Banker
- tie_min, tie_max, tie_step - для Tie (обычно меньше)
```

Методы:
- `generate_bet() -> int` - случайная ставка в пределах лимитов
- `generate_tie_bet() -> int` - случайная ставка для TIE

### Autoload синглтоны

**SaveManager** (`scripts/SaveManager.gd`):
- Сохранение/загрузка настроек
- Путь: `user://save_data.json`

**Localization** (`scripts/Localization.gd`):
- Поддержка ru/en
- Метод `t(key: String, args: Array = []) -> String` - перевод с подстановкой
- `set_lang(lang: String)`, `get_lang() -> String`

## Игровой процесс

1. **Старт** → WAITING
   - Показываются рубашки карт
   - Toggles третьих карт **отключены** (mouse_filter = IGNORE, полупрозрачные)
   - Кнопка "Раздать карты" активна
   - Попытка выбрать победителя → toast без штрафа

2. **Раздача** → CARD_TO_PLAYER / CARD_TO_BANKER / CARD_TO_EACH
   - Раздаются 4 карты (2 игроку, 2 банкиру)
   - Toggles **включаются** (можно заказывать третьи карты)
   - GameStateManager определяет состояние на основе очков
   - Проверка натуральных (8-9) → сразу CHOOSE_WINNER

3. **Заказ третьих карт** → валидация в GamePhaseManager
   - Игрок ставит галочки на toggles (? ↔ !)
   - Нажимает кнопку "карты" для подтверждения
   - `_validate_and_execute_third_cards()` проверяет правильность
   - Если **правильно** → раздача карты, toggle скрывается
   - Если **неправильно** → toast с ошибкой, штраф (жизнь/очки), toggle остается

4. **Банкир после игрока** → CARD_TO_BANKER_AFTER_PLAYER
   - После раздачи третьей карты игроку
   - `_handle_banker_after_player()` показывает toast "Решение банкира"
   - Игрок выбирает toggle банкира, нажимает "карты"
   - `_validate_banker_after_player()` валидирует выбор

5. **Выбор победителя** → CHOOSE_WINNER
   - Все карты открыты, кнопка "карты" **отключена**
   - Игрок кликает на маркер (Player/Banker/Tie)
   - Проверка через `GameStateManager.is_action_valid(SELECT_WINNER)`
   - Сравнение с `BaccaratRules.get_winner()`
   - Если **правильно** → PayoutPopup для расчёта выплаты
   - Если **неправильно** → toast с ошибкой, штраф

6. **Расчёт выплаты** (PayoutPopup)
   - Флот фишек разных номиналов (100000, 50000, ..., 0.5)
   - Игрок собирает стопки фишек (max 20 в стопке)
   - Кнопка "Подсказка" → автоматический расчёт (жадный алгоритм)
   - Проверка через `PayoutValidator.validate(collected, expected)`
   - Если **правильно** → сброс раунда, +1 очко
   - Если **неправильно** → toast с ошибкой, штраф

## Конфигурация: GameConfig

`resources/GameConfig.gd` - ресурс с настройками:

```gdscript
@export var card_paths: Dictionary  # Пути к текстурам карт
@export var back_card_path: String  # Обычная рубашка
@export var back_question_path: String  # Рубашка с ?
@export var back_exclamation_path: String  # Рубашка с !
@export var commission_rate: float = 0.95  # Комиссия банкира
@export var table_min_bet, table_max_bet, table_step: int
@export var tie_min_bet, tie_max_bet, tie_step: int
```

## Тестирование

Проект использует **GUT (Godot Unit Testing)** framework:

**Запуск тестов**:
1. В редакторе: нижняя панель → GUT → Run All
2. Из командной строки: `godot --path . --headless --script addons/gut/gut_cmdln.gd`

**Структура тестов**:
- `tests/test_baccarat_rules.gd` - тесты правил баккара

**Создание нового теста**:
```gdscript
extends GutTest

func test_something():
    assert_eq(expected, actual, "Optional message")
```

## Ключевые технические детали

### Карты

Класс `Card` (`scripts/Card.gd`):
```gdscript
var suit: String  # "clubs", "hearts", "spades", "diamonds"
var rank: String  # "A", "2"-"10", "J", "Q", "K"

func get_point() -> int:
    # A=1, 2-9=номинал, 10/J/Q/K=0
```

### Колода

`scripts/Deck.gd`:
- 52 карты, перемешивается в конструкторе
- `draw() -> Card` - взять карту
- Нет автоматического перемешивания при исчерпании (для тренажёра это норма)

### Toast система

`scripts/ToastManager.gd` + `scripts/Toast.gd`:
- `show_success(text)` - зелёный toast
- `show_error(text)` - красный toast
- `show_info(text)` - серый toast
- Автоматически исчезают через несколько секунд

### Статистика

`scripts/StatsManager.gd`:
- Хранит счётчики: `correct`, `errors` (словарь по типам)
- `increment_correct()` - +1 правильный ответ
- `increment_error(error_type: String)` - +1 ошибка типа
- Типы ошибок: "player_third_wrong", "banker_third_wrong", "winner_wrong", "commission_wrong", "tie_payout_wrong"
- `update_stats()` - обновляет Label в UI

## Управление

### Клавиатура / Мышь
- Все кнопки кликабельны
- Переключатели третьей карты - клик по TextureRect

### Джойпад
Настроены InputMap actions в `project.godot`:
- `deal` - раздать карты (кнопка 9)
- `open_cards` - открыть карты (кнопка 9)
- `player_third` - третья карта игрока (кнопка 4)
- `banker_third` - третья карта банкира (кнопка 3)
- `select_player` - выбрать игрока (кнопка 5)
- `select_banker` - выбрать банкира (кнопка 2)
- `select_tie` - выбрать ничью (кнопка 1)
- `confirm` - подтвердить (кнопка 9)

## Структура сцены Game.tscn

Главная сцена: `scenes/Game.tscn`

Иерархия узлов:
- **PlayerZone** - зона карт игрока
  - Card1, Card2, Card3 (TextureRect)
  - PlayerThirdCardToggle (TextureRect) - переключатель ?/!
- **BankerZone** - зона карт банкира
  - Card1, Card2, Card3 (TextureRect)
  - BankerThirdCardToggle (TextureRect)
- **CardsButton** - главная кнопка действия
- **PlayerMarker**, **BankerMarker**, **TieMarker** - кнопки выбора победителя
- **BetChip**, **TieChip** - кнопки для показа попапов ставок
- **BetPopup** (PopupPanel) - попап ввода выплаты
- **LimitsPopup** (PopupPanel) - попап настройки лимитов
- **HelpPopup** - попап помощи
- **StatsLabel** - Label со статистикой
- **HelpButton** - кнопка помощи
- **LangButton** - кнопка смены языка
- **LimitsButton** - кнопка настройки лимитов

## Планы развития

Из `redme.txt` (приоритизированный список):

1. **Интерфейс выплаты с фишками** - новая система расчёта выплат:
   - Флот фишек разных номиналов (100000, 50000, ..., 0.5)
   - Визуальное формирование стопок фишек
   - Максимум 20 фишек в стопке
   - Автоматический расчёт суммы
   - Проверка правильности выплаты

2. **Подсказка с подсветкой зон** - визуальная помощь новичкам

3. **Улучшенные комментарии в тостах** - более информативные сообщения

4. **Анимация** - плавные переходы, появление карт

5. **Звуки** - звуковое сопровождение действий

6. **Камера** - динамическая камера для акцентов

## Рекомендации при разработке

### При добавлении нового функционала:
1. Определить, в какой менеджер он относится
2. Если нужен новый state - создать в `scripts/states/`
3. Добавить переводы в `Localization.gd` (ru + en)
4. Обновить `GameConfig.gd` если нужны настройки
5. Написать тесты в `tests/`

### При изменении игровой логики:
1. **Всегда** обновлять тесты в `tests/test_baccarat_rules.gd`
2. Проверять соответствие официальным правилам баккара
3. Тестировать все edge cases (натуральные, равенство, etc.)

### При работе с UI:
1. Все UI элементы управляются через UIManager
2. Используй сигналы, не прямые вызовы
3. Обновляй локализацию при смене языка
4. Проверяй работу с джойпадом

### Стиль кода:
- Типизация обязательна: `var hand: Array[Card]`
- Комментарии на русском в коде
- Имена переменных/методов на английском
- Используй `# ←` для важных комментариев
- Группируй связанные методы вместе

### Отладка:
- `print()` для логов
- Toast для пользовательских уведомлений
- GUT тесты для проверки логики
- Проверяй console на ошибки после каждого изменения
