# API ArrestMaster

## Общая информация

### Версия API
- Текущая: 1.0.0
- Статус: Стабильная

### Подключение
```lua
local arrestmaster = include("arrestmaster/shared.lua")
```

## Основные функции

### Арест игрока
```lua
arrestmaster.ArrestPlayer(ply, time, reason)
```
- `ply` - Игрок для ареста
- `time` - Время ареста в секундах
- `reason` - Причина ареста

### Освобождение игрока
```lua
arrestmaster.ReleasePlayer(ply)
```
- `ply` - Игрок для освобождения

### Проверка ареста
```lua
arrestmaster.IsPlayerArrested(ply)
```
- `ply` - Игрок для проверки
- Возвращает: `boolean`

### Получение времени ареста
```lua
arrestmaster.GetArrestTime(ply)
```
- `ply` - Игрок
- Возвращает: `number` (время в секундах)

## Мини-игры

### Запуск мини-игры
```lua
arrestmaster.StartMinigame(ply, gameType, difficulty)
```
- `ply` - Игрок
- `gameType` - Тип мини-игры
- `difficulty` - Сложность

### Получение награды
```lua
arrestmaster.GiveMinigameReward(ply, gameType, difficulty)
```
- `ply` - Игрок
- `gameType` - Тип мини-игры
- `difficulty` - Сложность

## Система побега

### Попытка побега
```lua
arrestmaster.AttemptEscape(ply)
```
- `ply` - Игрок
- Возвращает: `boolean`

### Проверка возможности побега
```lua
arrestmaster.CanPlayerEscape(ply)
```
- `ply` - Игрок
- Возвращает: `boolean`

## Система камер

### Добавление камеры
```lua
arrestmaster.AddCamera(pos, ang)
```
- `pos` - Позиция камеры
- `ang` - Угол камеры

### Удаление камеры
```lua
arrestmaster.RemoveCamera(id)
```
- `id` - ID камеры

## Система логирования

### Логирование действия
```lua
arrestmaster.LogAction(action, data)
```
- `action` - Тип действия
- `data` - Данные действия

### Получение логов
```lua
arrestmaster.GetLogs(filter)
```
- `filter` - Фильтр логов
- Возвращает: `table`

## Система уведомлений

### Отправка уведомления
```lua
arrestmaster.SendNotification(ply, type, message)
```
- `ply` - Игрок
- `type` - Тип уведомления
- `message` - Сообщение

### Настройка уведомлений
```lua
arrestmaster.SetNotificationSettings(ply, settings)
```
- `ply` - Игрок
- `settings` - Настройки

## Хуки

### Хук ареста
```lua
hook.Add("ArrestMaster_PlayerArrested", "MyHook", function(ply, time, reason)
    -- Ваш код
end)
```

### Хук освобождения
```lua
hook.Add("ArrestMaster_PlayerReleased", "MyHook", function(ply)
    -- Ваш код
end)
```

### Хук побега
```lua
hook.Add("ArrestMaster_PlayerEscaped", "MyHook", function(ply)
    -- Ваш код
end)
```

## Примеры использования

### Арест игрока
```lua
local function ArrestPlayer(ply, time, reason)
    if arrestmaster.IsPlayerArrested(ply) then
        return false
    end
    
    arrestmaster.ArrestPlayer(ply, time, reason)
    arrestmaster.SendNotification(ply, "arrest", "Вы были арестованы")
    return true
end
```

### Мини-игра
```lua
local function StartMinigame(ply)
    if not arrestmaster.IsPlayerArrested(ply) then
        return false
    end
    
    arrestmaster.StartMinigame(ply, "puzzle", "medium")
    return true
end
```

## Обработка ошибок

### Проверка ошибок
```lua
local success, error = pcall(function()
    arrestmaster.ArrestPlayer(ply, time, reason)
end)

if not success then
    print("Ошибка: " .. error)
end
```

## Контакты

Для вопросов по API:
- GitHub Issues
- Steam: [profile]
- Discord: [server] 