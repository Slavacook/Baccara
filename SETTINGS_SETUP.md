# Инструкция по добавлению меню настроек

## Шаг 1: Добавить SettingsPopup в сцену Game.tscn

1. Откройте `scenes/Game.tscn` в редакторе Godot
2. Нажмите правой кнопкой на корневом узле `Game`
3. Выберите "Instantiate Child Scene"
4. Выберите `scenes/SettingsPopup.tscn`
5. Узел `SettingsPopup` будет добавлен

## Шаг 2: Добавить кнопку настроек

1. Выберите узел `Game` в дереве сцены
2. Добавьте новый узел `Button` (правой кнопкой → Add Child Node → Button)
3. Назовите его `SettingsButton`
4. В Inspector установите:
   - Text: `⚙️`
   - Position: справа вверху (например, offset_left=1050, offset_top=-8)
   - Size: custom_minimum_size = (50, 40)
   - Font Size: 24

## Шаг 3: Переместить SurvivalModeUI вниз

1. Найдите узел `UI/SurvivalModeUI` в дереве сцены
2. В Inspector найдите `Layout → Anchors Preset`
3. Выберите `Bottom Wide` (якорь к нижнему краю)
4. Или установите вручную:
   - anchor_top = 1.0
   - anchor_bottom = 1.0
   - offset_top = -50 (отступ снизу)
   - offset_bottom = 0

## Шаг 4: Скрыть/удалить старую кнопку языка

1. Найдите узел `LangButton` в дереве сцены
2. В Inspector снимите галочку `Visible` (или удалите узел)

## Готово!

Теперь сохраните сцену и запустите GameController - всё должно работать автоматически.
