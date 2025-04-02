-- Конфигурация системы арестов
ArrestMaster = ArrestMaster or {}
ArrestMaster.Config = {
    -- Основные настройки
    DefaultJailTime = 5,           -- Стандартное время заключения в минутах
    MaxJailTime = 1440,            -- Максимальное время заключения в минутах (24 часа)
    MinJailTime = 1,               -- Минимальное время заключения в минутах
    MaxDistance = 200,             -- Максимальное расстояние для ареста
    
    -- Настройки камер
    JailPositions = {
        Vector(8075.637695, 12704.158203, -8539.968750)
    },
    JailSpawnAng = Angle(1.349399, 89.245888, 0.000000),
    
    -- Настройки прав доступа
    Access = {
        -- Пустая таблица, так как проверка на группы больше не нужна
    },
    
    -- Настройки интерфейса
    UI = {
        MenuWidth = 1200,
        MenuHeight = 800,
        MenuColor = Color(20, 21, 35, 250),
        TextColor = Color(255, 255, 255),
        AccentColor = Color(65, 105, 225),
        ButtonColor = Color(35, 36, 55),
        ButtonHoverColor = Color(45, 46, 65),
        TabColor = Color(25, 26, 45),
        TabActiveColor = Color(65, 105, 225),
        HeaderColor = Color(25, 26, 45),
        BorderColor = Color(65, 105, 225),
        InputColor = Color(35, 36, 55),
        SuccessColor = Color(46, 213, 115),
        ErrorColor = Color(255, 71, 87),
        CardBackground = Color(30, 31, 50),
        SecondaryText = Color(150, 150, 150),
        
        -- Настройки анимаций
        Animations = {
            Enabled = true,
            Duration = 0.3,
            Easing = "easeOutQuad",
            MenuOpen = true,
            MenuClose = true,
            TabSwitch = true,
            ButtonHover = true
        },
        
        -- Настройки звуков
        Sounds = {
            Enabled = true,
            MenuOpen = "ui/buttonclick.wav",
            MenuClose = "ui/buttonclickrelease.wav",
            TabSwitch = "ui/buttonclick.wav",
            ButtonHover = "ui/buttonhover.wav",
            Success = "buttons/button14.wav",
            Error = "buttons/button11.wav"
        }
    },
    
    -- Настройки уведомлений
    Notifications = {
        Enabled = true,                    -- Включить уведомления
        Duration = 5,                      -- Длительность (секунды)
        Position = "top",                  -- Позиция (top/bottom)
        Sound = "buttons/button15.wav",    -- Звук уведомления
        Colors = {
            Success = Color(46, 213, 115), -- Цвет успеха
            Error = Color(255, 71, 87),    -- Цвет ошибки
            Info = Color(65, 105, 225)     -- Цвет информации
        },
        
        -- Типы уведомлений
        Types = {
            Arrest = true,                 -- Уведомления об аресте
            Release = true,                -- Уведомления об освобождении
            Escape = true,                 -- Уведомления о побеге
            Minigame = true,               -- Уведомления о мини-играх
            Admin = true                   -- Уведомления администратора
        }
    },
    
    -- Настройки логирования
    Logging = {
        Enabled = true,                    -- Включить логирование
        Directory = "arrestmaster/logs",   -- Директория логов
        Format = "%Y-%m-%d",              -- Формат даты
        TimeFormat = "%H:%M:%S",          -- Формат времени
        MaxLogsInMemory = 100,            -- Максимальное количество логов в памяти
        MaxLogFiles = 30,                 -- Максимальное количество файлов логов
        LogTypes = {                      -- Типы логов
            Arrest = true,                -- Аресты
            Release = true,               -- Освобождения
            EarlyRelease = true,          -- Досрочные освобождения
            Disconnect = true,            -- Отключения
            AdminAction = true,           -- Действия админов
            CommandUse = true,            -- Использование команд
            EscapeAttempt = true,         -- Попытки побега
            Minigame = true,              -- Мини-игры
            Error = true                  -- Ошибки системы
        },
        
        -- Настройки ротации логов
        Rotation = {
            Enabled = true,
            MaxSize = 1024 * 1024 * 10,   -- 10MB
            CompressOld = true,           -- Сжимать старые логи
            KeepDays = 30                 -- Хранить логи 30 дней
        }
    },
    
    -- Настройки безопасности
    Security = {
        PreventSelfArrest = true,         -- Запрет самоареста
        StripWeapons = true,              -- Изымать оружие
        ReturnWeapons = true,             -- Возвращать оружие
        SavePosition = true,              -- Сохранять позицию
        ReturnToPosition = true,          -- Возвращать на позицию
        CheckLOS = true,                  -- Проверка прямой видимости
        RequireCuffs = false,             -- Требовать наручники
        
        -- Ограничения
        Restrictions = {
            PreventArrestingAdmins = false,  -- Запрет ареста админов
            PreventArrestingUSB = false,     -- Запрет ареста УСБ
            MaxSimultaneousArrests = 5,      -- Максимум одновременных арестов
            RequireReason = true,            -- Требовать причину ареста
            MinReasonLength = 5,             -- Минимальная длина причины
            MaxReasonLength = 200            -- Максимальная длина причины
        },
        
        -- Настройки анти-чит
        AntiCheat = {
            Enabled = true,
            CheckSpeed = true,             -- Проверка скорости
            CheckTeleport = true,          -- Проверка телепортации
            CheckNoclip = true,            -- Проверка ноклипа
            MaxSpeed = 400,                -- Максимальная скорость
            MaxTeleportDistance = 1000,    -- Максимальное расстояние телепортации
            PenaltyTime = 30               -- Дополнительное время за читерство
        }
    },
    
    -- Настройки камер
    Camera = {
        Enabled = true,                    -- Включить систему камер
        AutoAssign = true,                 -- Автоназначение камер
        AllowCustomPositions = false,      -- Разрешить свои позиции
        MaxCameras = 5,                    -- Максимум камер
        CameraSize = Vector(100, 100, 100), -- Размер камеры
        
        -- Настройки просмотра
        ViewSettings = {
            FOV = 90,                      -- Поле зрения
            UpdateRate = 0.1,              -- Частота обновления
            MaxDistance = 1000,            -- Максимальное расстояние
            AllowZoom = false              -- Разрешить зум
        }
    },
    
    -- Настройки команд
    Commands = {
        -- Настройки команд
        UnjailCommand = "arrestmaster_unjail", -- Команда для принудительного освобождения
        AdminOnly = true,           -- Только для администраторов
        RequireReason = true,       -- Требовать причину при использовании
        LogUsage = true,            -- Логировать использование команд
        
        -- Сообщения команд
        Messages = {
            NoPermission = "У вас нет прав для использования этой команды!",
            MenuOpened = "Меню арестов открыто",
            InvalidTarget = "Выберите игрока для ареста",
            Success = "Команда выполнена успешно",
            PlayerArrested = "Игрок успешно арестован",
            PlayerReleased = "Игрок успешно освобожден",
            MinigameHint = "Для сокращения срока заключения используйте команду /minigame",
            MinigameNoAccess = "Мини-игры доступны только для заключенных!",
            MinigameMenuOpened = "Меню мини-игр открыто",
            InvalidReason = "Укажите причину ареста!",
            InvalidTime = "Укажите корректное время ареста!",
            PlayerTooFar = "Игрок слишком далеко!",
            NoLineOfSight = "Нет прямой видимости игрока!",
            PlayerNotArrested = "Этот игрок не находится под арестом!",
            MaxArrestsReached = "Достигнут лимит одновременных арестов!",
            InvalidCommand = "Неверная команда! Используйте /арест или /minigame"
        }
    },
    
    -- Настройки системы побега
    Escape = {
        Enabled = true,                    -- Включить систему побега
        MaxAttempts = 3,                   -- Максимальное количество попыток
        WarningDistance = 100,             -- Расстояние для предупреждения
        EscapeDistance = 200,              -- Расстояние для побега
        WarningTime = 5,                   -- Время предупреждения в секундах
        PenaltyTime = 10,                  -- Дополнительное время за попытку побега
        AlertRadius = 1000,                -- Радиус оповещения администраторов
        CooldownTime = 30,                 -- Время между попытками побега
        
        -- Настройки UI
        UI = {
            WarningColor = Color(255, 193, 7),  -- Цвет предупреждения
            DangerColor = Color(244, 67, 54),   -- Цвет опасности
            SuccessColor = Color(76, 175, 80),  -- Цвет успеха
            TextColor = Color(255, 255, 255),   -- Цвет текста
            BackgroundColor = Color(0, 0, 0, 200) -- Цвет фона
        },
        
        -- Настройки звуков
        Sounds = {
            Warning = "ambient/alarms/klaxon1.wav",
            Alert = "ambient/alarms/klaxon2.wav",
            Success = "ambient/alarms/klaxon3.wav"
        },
        
        -- Настройки наказаний
        Penalties = {
            FirstAttempt = 5,              -- Дополнительное время за первую попытку
            SecondAttempt = 10,            -- Дополнительное время за вторую попытку
            ThirdAttempt = 15,             -- Дополнительное время за третью попытку
            MaxPenalty = 30                -- Максимальное дополнительное время
        }
    },
    
    -- Настройки мини-игр
    Minigames = {
        Enabled = true,                    -- Включить систему мини-игр
        Cooldown = 300,                    -- Кулдаун между играми (5 минут)
        MaxDailyGames = 10,                -- Максимум игр в день
        MinPlayers = 2,                    -- Минимум игроков для начала
        TimeReduction = {                  -- Сокращение времени за игру
            ["memory"] = 5,                -- Игра на память
            ["math"] = 3,                  -- Математическая игра
            ["typing"] = 2,                -- Игра на скорость печати
            ["puzzle"] = 4                 -- Головоломка
        },
        
        -- Настройки игр
        Games = {
            ["memory"] = {
                name = "Игра на память",
                description = "Найдите все парные карточки",
                difficulty = {
                    easy = { pairs = 6, time = 60 },
                    medium = { pairs = 8, time = 90 },
                    hard = { pairs = 12, time = 120 }
                },
                rewards = {
                    easy = 3,              -- Минуты за легкий уровень
                    medium = 4,            -- Минуты за средний уровень
                    hard = 5               -- Минуты за сложный уровень
                }
            },
            ["math"] = {
                name = "Математическая игра",
                description = "Решите математические примеры",
                difficulty = {
                    easy = { problems = 5, time = 30 },
                    medium = { problems = 8, time = 45 },
                    hard = { problems = 12, time = 60 }
                },
                rewards = {
                    easy = 2,              -- Минуты за легкий уровень
                    medium = 3,            -- Минуты за средний уровень
                    hard = 4               -- Минуты за сложный уровень
                }
            },
            ["typing"] = {
                name = "Игра на скорость печати",
                description = "Напечатайте текст как можно быстрее",
                difficulty = {
                    easy = { words = 10, time = 30 },
                    medium = { words = 15, time = 45 },
                    hard = { words = 20, time = 60 }
                },
                rewards = {
                    easy = 1,              -- Минуты за легкий уровень
                    medium = 2,            -- Минуты за средний уровень
                    hard = 3               -- Минуты за сложный уровень
                }
            },
            ["puzzle"] = {
                name = "Головоломка",
                description = "Соберите пазл",
                difficulty = {
                    easy = { pieces = 9, time = 60 },
                    medium = { pieces = 16, time = 90 },
                    hard = { pieces = 25, time = 120 }
                },
                rewards = {
                    easy = 3,              -- Минуты за легкий уровень
                    medium = 4,            -- Минуты за средний уровень
                    hard = 5               -- Минуты за сложный уровень
                }
            }
        },
        
        -- Настройки UI для мини-игр
        UI = {
            BackgroundColor = Color(0, 0, 0, 200),
            TextColor = Color(255, 255, 255),
            AccentColor = Color(65, 105, 225),
            SuccessColor = Color(46, 213, 115),
            ErrorColor = Color(255, 71, 87),
            TimerColor = Color(255, 193, 7)
        },
        
        -- Настройки звуков для мини-игр
        Sounds = {
            Start = "buttons/button14.wav",
            Success = "buttons/button15.wav",
            Fail = "buttons/button11.wav",
            Timer = "buttons/button9.wav"
        }
    }
}

-- Функция для проверки прав доступа
function ArrestMaster.Config:HasPermission(ply)
    if not IsValid(ply) then return false end
    
    -- Проверяем наличие датапада
    if ply:HasWeapon("datapad") then
        return true
    end
    
    return false
end

-- Функция для проверки прямой видимости
function ArrestMaster.Config:HasLineOfSight(ply, target)
    if not self.Security.CheckLOS then return true end
    
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = target:EyePos(),
        filter = {ply, target}
    })
    
    return not tr.Hit
end

-- Функция для проверки наручников
function ArrestMaster.Config:IsCuffed(ply)
    if not self.Security.RequireCuffs then return true end
    
    -- Здесь можно добавить проверку на наличие наручников
    -- Например, если используется DarkRP jail system
    return true
end

-- Функция для форматирования времени
function ArrestMaster.Config:FormatTime(minutes)
    if minutes < 60 then
        return string.format("%d мин.", minutes)
    elseif minutes < 1440 then
        return string.format("%d ч. %d мин.", math.floor(minutes/60), minutes%60)
    else
        return string.format("%d дн. %d ч.", math.floor(minutes/1440), math.floor((minutes%1440)/60))
    end
end

-- Функция для проверки валидности времени
function ArrestMaster.Config:IsValidTime(time)
    return time >= self.MinJailTime and time <= self.MaxJailTime
end

-- Функция для получения случайной камеры
function ArrestMaster.Config:GetRandomCell()
    if #self.JailPositions == 0 then return nil, nil end
    
    local index = math.random(#self.JailPositions)
    return self.JailPositions[index], self.JailSpawnAng
end

-- Функция для проверки возможности играть в мини-игры
function ArrestMaster.Config:CanPlayMinigame(ply)
    if not self.Minigames.Enabled then return false end
    
    -- Проверяем, находится ли игрок в камере
    if not ply.ArrestMasterData then return false end
    
    -- Проверяем кулдаун
    if ply.ArrestMasterData.lastGameTime then
        local timeSinceLastGame = os.time() - ply.ArrestMasterData.lastGameTime
        if timeSinceLastGame < self.Minigames.Cooldown then
            return false
        end
    end
    
    -- Проверяем лимит игр в день
    if ply.ArrestMasterData.gamesPlayed and ply.ArrestMasterData.gamesPlayed >= self.Minigames.MaxDailyGames then
        return false
    end
    
    return true
end

-- Функция для генерации данных мини-игры
function ArrestMaster.Config:GenerateMinigameData(gameName)
    local gameData = self.Minigames.Games[gameName]
    if not gameData then return nil end
    
    local difficulty = "medium" -- По умолчанию средняя сложность
    local settings = gameData.difficulty[difficulty]
    
    local gameState = {
        difficulty = difficulty,
        timeLimit = settings.time,
        settings = settings
    }
    
    -- Генерируем специфичные данные для каждой игры
    if gameName == "memory" then
        gameState.symbols = self:GenerateMemorySymbols(settings.pairs)
    elseif gameName == "math" then
        gameState.problems = self:GenerateMathProblems(settings.problems)
    elseif gameName == "typing" then
        gameState.words = self:GenerateTypingWords(settings.words)
    elseif gameName == "puzzle" then
        gameState.pieces = self:GeneratePuzzlePieces(settings.pieces)
    end
    
    return gameState
end

-- Вспомогательные функции для генерации данных мини-игр
function ArrestMaster.Config:GenerateMemorySymbols(pairs)
    local symbols = {}
    for i = 1, pairs do
        table.insert(symbols, i)
        table.insert(symbols, i)
    end
    return table.Shuffle(symbols)
end

function ArrestMaster.Config:GenerateMathProblems(count)
    local problems = {}
    for i = 1, count do
        local a = math.random(1, 20)
        local b = math.random(1, 20)
        local operation = math.random(1, 4)
        local answer
        
        if operation == 1 then
            answer = a + b
            problems[i] = {text = string.format("%d + %d = ?", a, b), answer = answer}
        elseif operation == 2 then
            answer = a - b
            problems[i] = {text = string.format("%d - %d = ?", a, b), answer = answer}
        elseif operation == 3 then
            answer = a * b
            problems[i] = {text = string.format("%d × %d = ?", a, b), answer = answer}
        else
            answer = math.floor(a / b)
            problems[i] = {text = string.format("%d ÷ %d = ?", a, b), answer = answer}
        end
    end
    return problems
end

function ArrestMaster.Config:GenerateTypingWords(count)
    local words = {
        "программирование", "компьютер", "интернет", "база данных", "алгоритм",
        "функция", "переменная", "массив", "класс", "объект", "метод", "свойство",
        "событие", "обработчик", "интерфейс", "модуль", "библиотека", "фреймворк"
    }
    local result = {}
    for i = 1, count do
        table.insert(result, words[math.random(#words)])
    end
    return result
end

function ArrestMaster.Config:GeneratePuzzlePieces(pieces)
    local result = {}
    for i = 1, pieces do
        table.insert(result, i)
    end
    return table.Shuffle(result)
end

return ArrestMaster.Config 