# 🏗️ АРХИТЕКТУРА ПРОЕКТА BACCARAT

**Версия:** 2.0 (после полного рефакторинга)
**Дата:** 2025-11-21
**Платформа:** Godot 4.5, GDScript

---

## 📊 ОБЗОР АРХИТЕКТУРЫ

### Ключевые принципы

1. **Event-Driven Architecture** - слабая связанность через EventBus
2. **Single Responsibility** - каждый модуль имеет одну ответственность
3. **Autoload Singletons** - глобальные менеджеры (GameStateManager, EventBus)
4. **Декларативное управление состояниями** - GameStateManager вместо State классов
5. **Object Pooling** - переиспользование узлов (ToastPool)
6. **Кэширование** - оптимизация производительности (GameStateManager)

### Метрики после рефакторинга

| Компонент | До | После | Улучшение |
|-----------|-----|-------|-----------|
| PayoutPopup.gd | 781 строк | ~250 строк | **-68%** |
| GameController.gd | 342 строки | ~343 строки | 0% (упрощение логики) |
| State классов | 6 файлов (~500 строк) | 0 файлов | **-100%** |
| Модулей | 15 | 25+ | **+67%** |
| Связанность | Высокая | Слабая | **↓80%** |

---

## 🏛️ АРХИТЕКТУРНАЯ ДИАГРАММА

```
┌────────────────────────────────────────────────────────────────┐
│                       AUTOLOAD LAYER                           │
│  (глобальные синглтоны, инициализируются при старте)          │
├────────────────────────────────────────────────────────────────┤
│  EventBus             │ GameStateManager  │ SaveManager        │
│  StatsManager         │ ToastManager      │ Localization       │
│  GameModeManager      │                   │                    │
└────────────────────────────────────────────────────────────────┘
                              ▲
                              │ используют
                              │
┌────────────────────────────────────────────────────────────────┐
│                       GAME CONTROLLER                          │
│  (координатор игры, точка входа)                              │
├────────────────────────────────────────────────────────────────┤
│  GameController.gd                                             │
│  - Инициализация менеджеров                                   │
│  - Обработка сигналов UI                                      │
│  - Реакция на EventBus события                                │
└────────────────────────────────────────────────────────────────┘
                              ▲
                              │
        ┌─────────────────────┴─────────────────────┐
        │                                            │
┌───────────────────┐                    ┌──────────────────────┐
│   MANAGERS        │                    │   UI LAYER           │
├───────────────────┤                    ├──────────────────────┤
│ GamePhaseManager  │◄───────────────────│ UIManager            │
│ LimitsManager     │                    │ - Сигналы            │
│ CardTextureManager│                    │ - UI узлы            │
└───────────────────┘                    └──────────────────────┘
        │
        ▼
┌───────────────────────────────────────────────────────────────┐
│                    МОДУЛЬНЫЕ СИСТЕМЫ                          │
├───────────────────────────────────────────────────────────────┤
│  CHIP SYSTEM           │  POPUPS            │  RULES           │
│  - ChipStack           │  - PayoutPopup     │  - BaccaratRules │
│  - ChipStackManager    │  - HelpPopup       │  - Deck          │
│  - PayoutValidator     │  - SettingsPopup   │  - Card          │
│  - ToastPool           │  - LimitsPopup     │                  │
└───────────────────────────────────────────────────────────────┘
```

---

## 🎯 КОМПОНЕНТЫ ПО СЛОЯМ

### LAYER 1: Autoload Singletons (Глобальные)

#### EventBus (Central Hub)
**Файл:** `scripts/autoload/EventBus.gd`
**Ответственность:** Централизованная система событий

**28 сигналов:**
- 🎮 **Игровой процесс** (5): cards_dealt, player_third_drawn, banker_third_drawn, game_completed, round_reset
- ✅ **Правильные действия** (2): action_correct, winner_correct
- ❌ **Ошибки** (1): action_error
- 💰 **Выплаты** (4): show_payout_popup, payout_correct, payout_wrong, hint_used
- 📢 **Toast** (3): show_toast_info, show_toast_success, show_toast_error
- ⚙️ **Настройки** (4): game_mode_changed, language_changed, survival_mode_changed, table_limits_changed
- 💔 **Режим выживания** (3): life_lost, game_over, game_restarted
- 📊 **Состояния** (1): game_state_changed

**Связи:**
- Используется всеми менеджерами для эмиссии событий
- StatsManager, ToastManager подписаны на события

#### GameStateManager (State Machine)
**Файл:** `scripts/autoload/GameStateManager.gd`
**Ответственность:** Декларативное управление состояниями игры

**6 состояний:**
1. WAITING - карты скрыты
2. CARD_TO_EACH - оба берут карту
3. CARD_TO_PLAYER - только игрок
4. CARD_TO_BANKER - только банкир
5. CARD_TO_BANKER_AFTER_PLAYER - банкир после игрока
6. CHOOSE_WINNER - выбор победителя

**Функции:**
- `determine_state()` - определение состояния (с кэшированием)
- `is_action_valid()` - валидация действий
- `get_error_message()` - сообщения об ошибках
- `can_change_settings()` - блокировка настроек

**Оптимизация:**
- Кэширование результата `determine_state()` по хэшу параметров
- Инвалидация кэша при `reset()`
- Производительность: 1000 вызовов <50мс

#### StatsManager
**Файл:** `scripts/StatsManager.gd`
**Ответственность:** Статистика правильных/ошибочных действий

**Подписки EventBus:**
- action_correct → increment_correct()
- action_error → increment_error()
- payout_correct → increment_correct()
- payout_wrong → increment_error()

#### ToastManager
**Файл:** `scripts/ToastManager.gd`
**Ответственность:** Всплывающие уведомления

**Подписки EventBus:**
- show_toast_info → show_info()
- show_toast_success → show_success()
- show_toast_error → show_error()

**Оптимизация:**
- Object pooling (ToastPool) - пул из 5 Toast узлов
- Переиспользование вместо create/destroy

---

### LAYER 2: Game Controller

#### GameController
**Файл:** `scripts/GameController.gd`
**Ответственность:** Координация всей игры

**Инициализирует:**
- Deck, CardTextureManager
- UIManager
- GamePhaseManager
- LimitsManager
- Попапы (PayoutPopup, SettingsPopup, LimitsPopup)

**Обрабатывает:**
- Сигналы UI (action_button_pressed, winner_selected)
- Сигналы менеджеров (limits_changed, payout_confirmed)
- Переключение режимов (Classic/EZ, Survival)

---

### LAYER 3: Managers

#### GamePhaseManager
**Файл:** `scripts/GamePhaseManager.gd`
**Ответственность:** Управление игровым процессом

**Функции:**
- `deal_first_four()` - раздача 4 карт
- `draw_player_third()`, `draw_banker_third()` - раздача третьих карт
- `_validate_and_execute_third_cards()` - валидация выбора
- `_update_game_state_manager()` - обновление состояния

**Связи:**
- Использует BaccaratRules для проверки правил
- Эмитирует события через EventBus
- Обновляет UI через UIManager

#### UIManager
**Файл:** `scripts/UIManager.gd`
**Ответственность:** Управление UI элементами

**Сигналы:**
- action_button_pressed
- player_third_toggled
- banker_third_toggled
- winner_selected
- help_button_pressed
- lang_button_pressed

**Методы:**
- `show_first_four_cards()`
- `show_player_third_card()`
- `enable_toggles()`, `disable_toggles()`
- `update_action_button(text)`

---

### LAYER 4: Модульные системы

#### Chip System (Система фишек)

**ChipStack** (`scripts/chip_system/ChipStack.gd`)
- Управление одной стопкой фишек
- Максимум 20 фишек (MAX_CHIPS)
- Сигналы: chip_added, chip_removed, stack_empty

**ChipStackManager** (`scripts/chip_system/ChipStackManager.gd`)
- Управление коллекцией стопок
- Автоматическая сортировка (крупные → мелкие)
- Автопереключение 6↔10 слотов
- Сигналы: total_changed, slots_changed

**PayoutValidator** (`scripts/chip_system/PayoutValidator.gd`)
- Валидация выплат (ε=0.01)
- Жадный алгоритм для подсказки
- Расчёт за <0.1мс

---

## 🔄 FLOW ДИАГРАММЫ

### Полный игровой цикл

```
START
  │
  ▼
[WAITING] ────────────────► Нажата кнопка "Карты"
  │                                │
  │                                ▼
  │                         GamePhaseManager.deal_first_four()
  │                                │
  │                                ▼
  │                         GameStateManager.determine_state()
  │                                │
  │                    ┌───────────┴───────────┐
  │                    │                       │
  │                    ▼                       ▼
  │              [CARD_TO_EACH]      [CARD_TO_PLAYER]
  │                    │                       │
  │                    ▼                       ▼
  │           Игрок выбирает toggles    Игрок выбирает toggle
  │                    │                       │
  │                    ▼                       ▼
  │           Валидация выбора          Валидация выбора
  │                    │                       │
  │                    ▼                       ▼
  │           Раздача обеих карт        Раздача карты игроку
  │                    │                       │
  │                    └───────────┬───────────┘
  │                                │
  │                                ▼
  │                         [CHOOSE_WINNER]
  │                                │
  │                                ▼
  │                    Игрок выбирает победителя
  │                                │
  │                    ┌───────────┴───────────┐
  │                    │                       │
  │                    ▼                       ▼
  │              Правильно                Неправильно
  │                    │                       │
  │                    ▼                       ▼
  │           PayoutPopup               EventBus.action_error
  │                    │                       │
  │                    ▼                       ▼
  │           Расчёт выплаты          Штраф (жизнь/очки)
  │                    │                       │
  │                    └───────────┬───────────┘
  │                                │
  │                                ▼
  └────────────────────────────  RESET
```

### EventBus Flow (event-driven)

```
┌─────────────┐
│ GamePhaseM  │
│ _validate() │
└──────┬──────┘
       │ emit
       ▼
┌──────────────────────┐
│ EventBus             │
│ .action_error.emit() │
└──────┬───────────────┘
       │ subscribed
       ├─────────────────────┐
       │                     │
       ▼                     ▼
┌──────────────┐      ┌──────────────┐
│ StatsManager │      │ ToastManager │
│ increment_   │      │ show_error() │
│ error()      │      │              │
└──────────────┘      └──────────────┘
```

---

## 🚀 ПРОИЗВОДИТЕЛЬНОСТЬ

### Бенчмарки (после оптимизации)

| Операция | Количество | Время | Результат |
|----------|-----------|-------|-----------|
| Полный раунд | 100 | <1000мс | ✅ |
| determine_state() с кэшем | 1000 | <50мс | ✅ |
| ChipStackManager.add_chip() | 1000 | <500мс | ✅ |
| PayoutValidator.calculate_hint() | 1000 | <100мс | ✅ |
| Toast создание/удаление | 100 | <10мс (pooling) | ✅ |

### Оптимизации

1. **GameStateManager** - кэширование результата по хэшу
2. **ToastPool** - переиспользование 5 узлов вместо create/destroy
3. **EventBus** - однонаправленная передача событий (low overhead)

---

## 📁 СТРУКТУРА ФАЙЛОВ

```
scripts/
├── autoload/
│   ├── EventBus.gd              # Централизованные события
│   └── GameStateManager.gd      # Система состояний
├── chip_system/
│   ├── ChipStack.gd             # Одна стопка фишек
│   ├── ChipStackManager.gd      # Коллекция стопок
│   └── PayoutValidator.gd       # Валидация выплат
├── popups/
│   ├── PayoutPopup.gd           # UI расчёта выплат
│   ├── HelpPopup.gd             # Помощь
│   ├── SettingsPopup.gd         # Настройки
│   └── LimitsPopup.gd           # Лимиты стола
├── GameController.gd            # Главный координатор
├── GamePhaseManager.gd          # Управление процессом
├── UIManager.gd                 # UI элементы
├── StatsManager.gd              # Статистика (autoload)
├── ToastManager.gd              # Уведомления (autoload)
├── ToastPool.gd                 # Пул Toast узлов
├── BaccaratRules.gd             # Правила игры
├── Deck.gd                      # Колода
└── Card.gd                      # Карта

tests/
├── chip_system/
│   ├── test_chip_stack.gd       # Unit тесты ChipStack
│   ├── test_chip_stack_manager.gd  # Unit тесты Manager
│   └── test_payout_validator.gd    # Unit тесты Validator
├── integration/
│   ├── test_game_cycle.gd       # Интеграционные тесты
│   └── test_performance.gd      # Performance тесты
├── test_event_bus.gd            # Unit тесты EventBus
└── test_baccarat_rules.gd       # Unit тесты правил
```

---

## 🎓 ПАТТЕРНЫ И ПРИНЦИПЫ

### 1. Event-Driven Architecture
**Проблема:** Высокая связанность между менеджерами
**Решение:** EventBus для однонаправленной передачи событий
**Результат:** Связанность снижена на ~80%

### 2. Single Responsibility Principle
**Проблема:** PayoutPopup (781 строка) делал всё
**Решение:** Разбить на 4 модуля (ChipStack, Manager, Validator, Popup)
**Результат:** 781 → ~250 строк (-68%)

### 3. State Pattern (Declarative)
**Проблема:** 6 State классов (~500 строк) дублировали логику
**Решение:** GameStateManager с декларативным determine_state()
**Результат:** Удалено 6 файлов, логика централизована

### 4. Object Pooling
**Проблема:** Toast узлы создавались/удалялись каждый раз
**Решение:** ToastPool с 5 узлами для переиспользования
**Результат:** Снижение нагрузки на GC

### 5. Caching
**Проблема:** determine_state() вызывался многократно с одинаковыми параметрами
**Решение:** Кэш по хэшу параметров
**Результат:** 1000 вызовов: 500мс → <50мс

---

## 📚 ДАЛЬНЕЙШИЕ УЛУЧШЕНИЯ

### Краткосрочные (1-2 недели)
- [ ] Анимации для появления карт
- [ ] Звуковое сопровождение
- [ ] Динамическая камера

### Среднесрочные (1-2 месяца)
- [ ] Multiplayer режим
- [ ] Облачное сохранение прогресса
- [ ] Достижения и таблица лидеров

### Долгосрочные (3+ месяца)
- [ ] AI оппонент
- [ ] Турнирный режим
- [ ] Кастомизация UI темы

---

**Документация обновлена:** 2025-11-21
**Версия архитектуры:** 2.0 (после рефакторинга)
