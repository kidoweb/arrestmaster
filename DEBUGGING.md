# Отладка ArrestMaster

## Общая информация

### Текущая версия
- Версия: 1.0.0
- Статус: В разработке

### Требования
- Garry's Mod
- Консоль разработчика
- Доступ к логам

## Инструменты отладки

### Консольные команды
```lua
-- Включение режима отладки
arrestmaster_debug 1

-- Просмотр информации об аресте
arrestmaster_debug_arrest <игрок>

-- Просмотр информации о мини-игре
arrestmaster_debug_minigame <игрок>

-- Просмотр информации о побеге
arrestmaster_debug_escape <игрок>

-- Просмотр информации о камерах
arrestmaster_debug_cameras

-- Просмотр логов
arrestmaster_debug_logs
```

### Логирование
```lua
-- Логирование ареста
arrestmaster.LogDebug("arrest", {
    player = ply,
    time = time,
    reason = reason
})

-- Логирование мини-игры
arrestmaster.LogDebug("minigame", {
    player = ply,
    game = gameType,
    result = result
})

-- Логирование побега
arrestmaster.LogDebug("escape", {
    player = ply,
    success = success,
    punishment = punishment
})
```

## Отладка системы арестов

### Проверка состояния
```lua
local function DebugArrestState(ply)
    local state = {
        arrested = arrestmaster.IsPlayerArrested(ply),
        time = arrestmaster.GetArrestTime(ply),
        reason = arrestmaster.GetArrestReason(ply),
        location = ply:GetPos()
    }
    
    PrintTable(state)
    return state
end
```

### Отслеживание изменений
```lua
hook.Add("ArrestMaster_PlayerArrested", "DebugArrest", function(ply, time, reason)
    if not arrestmaster.IsDebugEnabled() then return end
    
    arrestmaster.LogDebug("arrest", {
        player = ply,
        time = time,
        reason = reason,
        location = ply:GetPos()
    })
end)
```

## Отладка мини-игр

### Проверка состояния
```lua
local function DebugMinigameState(ply)
    local state = {
        active = arrestmaster.IsMinigameActive(ply),
        type = arrestmaster.GetMinigameType(ply),
        progress = arrestmaster.GetMinigameProgress(ply),
        reward = arrestmaster.GetMinigameReward(ply)
    }
    
    PrintTable(state)
    return state
end
```

### Отслеживание изменений
```lua
hook.Add("ArrestMaster_MinigameStarted", "DebugMinigame", function(ply, gameType)
    if not arrestmaster.IsDebugEnabled() then return end
    
    arrestmaster.LogDebug("minigame", {
        player = ply,
        game = gameType,
        start_time = CurTime()
    })
end)
```

## Отладка системы побега

### Проверка состояния
```lua
local function DebugEscapeState(ply)
    local state = {
        can_escape = arrestmaster.CanPlayerEscape(ply),
        attempts = arrestmaster.GetEscapeAttempts(ply),
        last_attempt = arrestmaster.GetLastEscapeAttempt(ply),
        punishment = arrestmaster.GetEscapePunishment(ply)
    }
    
    PrintTable(state)
    return state
end
```

### Отслеживание изменений
```lua
hook.Add("ArrestMaster_PlayerEscaped", "DebugEscape", function(ply, success)
    if not arrestmaster.IsDebugEnabled() then return end
    
    arrestmaster.LogDebug("escape", {
        player = ply,
        success = success,
        location = ply:GetPos()
    })
end)
```

## Отладка системы камер

### Проверка состояния
```lua
local function DebugCameraState()
    local state = {
        total = arrestmaster.GetTotalCameras(),
        active = arrestmaster.GetActiveCameras(),
        locations = arrestmaster.GetCameraLocations()
    }
    
    PrintTable(state)
    return state
end
```

### Отслеживание изменений
```lua
hook.Add("ArrestMaster_CameraAdded", "DebugCamera", function(pos, ang)
    if not arrestmaster.IsDebugEnabled() then return end
    
    arrestmaster.LogDebug("camera", {
        position = pos,
        angle = ang,
        time = CurTime()
    })
end)
```

## Отладка производительности

### Измерение времени
```lua
local function DebugPerformance(func)
    local start = SysTime()
    local result = func()
    local duration = SysTime() - start
    
    arrestmaster.LogDebug("performance", {
        function = func,
        duration = duration,
        result = result
    })
    
    return result, duration
end
```

### Мониторинг ресурсов
```lua
local function DebugResources()
    local state = {
        memory = collectgarbage("count"),
        fps = 1 / FrameTime(),
        players = player.GetCount(),
        entities = #ents.GetAll()
    }
    
    PrintTable(state)
    return state
end
```

## Устранение неполадок

### Общие проблемы
1. Проверка версий
2. Проверка зависимостей
3. Проверка прав доступа
4. Проверка конфликтов

### Решение проблем
1. Анализ логов
2. Проверка состояния
3. Тестирование функций
4. Восстановление данных

## Контакты

Для вопросов по отладке:
- GitHub Issues
- Steam: [profile]
- Discord: [server] 