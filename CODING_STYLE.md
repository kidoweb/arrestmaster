# Стиль кода ArrestMaster

## Общие правила

### Отступы
- Используйте 4 пробела для отступов
- Не используйте табуляцию
- Выравнивайте блоки кода

### Длина строки
- Максимальная длина: 100 символов
- Разбивайте длинные строки на несколько строк
- Используйте операторы для разбиения

### Пробелы
- Один пробел после запятых
- Один пробел вокруг операторов
- Без пробелов в конце строк
- Одна пустая строка между функциями

## Именование

### Переменные
```lua
-- Локальные переменные
local playerName = "Player"
local arrestTime = 300

-- Глобальные переменные
ArrestMaster = ArrestMaster or {}
ArrestMaster.Config = {}
```

### Функции
```lua
-- Именование функций
local function GetPlayerArrestTime(ply)
    return ply.ArrestTime or 0
end

local function SetPlayerArrestTime(ply, time)
    ply.ArrestTime = time
end
```

### Классы
```lua
-- Именование классов
local ArrestSystem = {}
ArrestSystem.__index = ArrestSystem

function ArrestSystem.new()
    local self = setmetatable({}, ArrestSystem)
    return self
end
```

## Структура кода

### Файлы
```lua
-- Заголовок файла
--[[
    ArrestMaster
    Автор: [Vadim]
    Версия: 1.0.0
    Дата: 2024-03-XX
]]

-- Импорты
local ArrestMaster = ArrestMaster or {}
local Config = ArrestMaster.Config

-- Локальные переменные
local debug = false

-- Функции
local function Initialize()
    -- Код инициализации
end

-- Хуки
hook.Add("Initialize", "ArrestMaster_Init", Initialize)

-- Экспорты
return ArrestMaster
```

### Функции
```lua
-- Структура функции
local function ProcessArrest(ply, time, reason)
    -- Проверки
    if not IsValid(ply) then return false end
    if not time or time <= 0 then return false end
    
    -- Логика
    local success = ArrestPlayer(ply, time, reason)
    
    -- Логирование
    if success then
        LogArrest(ply, time, reason)
    end
    
    -- Возврат
    return success
end
```

## Комментарии

### Документация
```lua
--[[
    Описание функции
    @param {Player} ply - Игрок
    @param {number} time - Время ареста
    @param {string} reason - Причина ареста
    @return {boolean} - Успех операции
]]
local function ArrestPlayer(ply, time, reason)
    -- Код функции
end
```

### Внутренние комментарии
```lua
local function ProcessMinigame(ply, gameType)
    -- Проверка состояния
    if not IsValid(ply) then return false end
    
    -- Инициализация игры
    local game = InitializeGame(gameType)
    
    -- Запуск игры
    StartGame(ply, game)
    
    -- Обработка результатов
    return true
end
```

## Обработка ошибок

### Проверки
```lua
local function SafeArrest(ply, time, reason)
    -- Проверка параметров
    if not IsValid(ply) then
        return false, "Неверный игрок"
    end
    
    if not time or time <= 0 then
        return false, "Неверное время"
    end
    
    if not reason or reason == "" then
        return false, "Не указана причина"
    end
    
    -- Выполнение операции
    return ArrestPlayer(ply, time, reason)
end
```

### Обработка исключений
```lua
local function SafeOperation(func)
    local success, result = pcall(func)
    
    if not success then
        LogError(result)
        return false, result
    end
    
    return true, result
end
```

## Оптимизация

### Кэширование
```lua
-- Кэширование часто используемых функций
local IsValid = IsValid
local CurTime = CurTime
local player_GetAll = player.GetAll
```

### Локальные переменные
```lua
local function ProcessPlayers()
    local players = player_GetAll()
    local currentTime = CurTime()
    
    for _, ply in ipairs(players) do
        if IsValid(ply) then
            ProcessPlayer(ply, currentTime)
        end
    end
end
```

## Тестирование

### Модульные тесты
```lua
local function TestArrest()
    local ply = Player(1)
    local time = 60
    local reason = "Тест"
    
    local success = ArrestPlayer(ply, time, reason)
    assert(success, "Арест должен быть успешным")
    assert(IsPlayerArrested(ply), "Игрок должен быть арестован")
end
```

### Проверки
```lua
local function ValidateConfig(config)
    assert(type(config) == "table", "Конфиг должен быть таблицей")
    assert(type(config.ArrestTime) == "number", "Время ареста должно быть числом")
    assert(config.ArrestTime > 0, "Время ареста должно быть положительным")
end
```

## Контакты

Для вопросов по стилю кода:
- GitHub Issues
- Steam: [profile]
- Discord: [server] 