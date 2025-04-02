-- Система мини-игр для сокращения срока
ArrestMaster.Minigames = ArrestMaster.Minigames or {}

-- Хранение данных игроков
local playerData = {}

-- Система достижений
local achievements = {
    ["first_win"] = {
        name = "Первая победа",
        description = "Победа в любой мини-игре",
        reward = 5,
        condition = function(data) return data.gamesWon > 0 end
    },
    ["speed_demon"] = {
        name = "Скоростной демон",
        description = "Победа в игре на скорость печати на сложном уровне",
        reward = 10,
        condition = function(data) return data.typingHardWins > 0 end
    },
    ["math_master"] = {
        name = "Мастер математики",
        description = "Победа в математической игре на сложном уровне",
        reward = 10,
        condition = function(data) return data.mathHardWins > 0 end
    },
    ["memory_king"] = {
        name = "Король памяти",
        description = "Победа в игре на память на сложном уровне",
        reward = 10,
        condition = function(data) return data.memoryHardWins > 0 end
    },
    ["puzzle_pro"] = {
        name = "Профессионал пазлов",
        description = "Победа в головоломке на сложном уровне",
        reward = 10,
        condition = function(data) return data.puzzleHardWins > 0 end
    },
    ["dedicated_player"] = {
        name = "Преданный игрок",
        description = "Сыграно 10 игр",
        reward = 15,
        condition = function(data) return data.gamesPlayed >= 10 end
    },
    ["time_saver"] = {
        name = "Экономист времени",
        description = "Сокращено 30 минут срока",
        reward = 20,
        condition = function(data) return data.totalTimeReduced >= 30 end
    }
}

-- Инициализация данных игрока
local function InitializePlayerData(ply)
    if not playerData[ply:SteamID()] then
        playerData[ply:SteamID()] = {
            lastGame = 0,
            gamesPlayed = 0,
            gamesWon = 0,
            lastReset = os.time(),
            currentGame = nil,
            difficulty = "easy",
            achievements = {},
            totalTimeReduced = 0,
            -- Статистика по играм
            typingHardWins = 0,
            mathHardWins = 0,
            memoryHardWins = 0,
            puzzleHardWins = 0,
            -- Достижения
            unlockedAchievements = {},
            -- Прогресс
            streak = 0,
            bestStreak = 0,
            lastGameTime = 0
        }
    end
end

-- Проверка и выдача достижений
local function CheckAchievements(ply)
    local data = playerData[ply:SteamID()]
    if not data then return end
    
    for id, achievement in pairs(achievements) do
        if not data.unlockedAchievements[id] and achievement.condition(data) then
            data.unlockedAchievements[id] = true
            data.totalTimeReduced = data.totalTimeReduced + achievement.reward
            
            -- Отправляем уведомление о достижении
            ply:ChatPrint(string.format("Достижение разблокировано: %s (+%d минут)", 
                achievement.name, achievement.reward))
            
            -- Логируем получение достижения
            if ArrestMaster.Config.Logging.LogTypes.GameComplete then
                LogAction("Получено достижение", {
                    ["Игрок"] = string.format("%s (%s)", ply:Nick(), ply:SteamID()),
                    ["Достижение"] = achievement.name,
                    ["Награда"] = string.format("%d минут", achievement.reward)
                })
            end
        end
    end
end

-- Проверка валидности входных данных
local function ValidateGameInput(gameType, difficulty)
    if not ArrestMaster.Config.Minigames.Games[gameType] then
        return false, "Неверный тип игры"
    end
    
    if not ArrestMaster.Config.Minigames.Games[gameType].difficulty[difficulty] then
        return false, "Неверный уровень сложности"
    end
    
    return true
end

-- Проверка возможности играть
local function CanPlayGame(ply)
    if not ArrestMaster.Config.Minigames.Enabled then 
        return false, "Система мини-игр отключена"
    end
    
    -- Проверяем, находится ли игрок в камере
    if not ply.ArrestMasterData then 
        return false, "Мини-игры доступны только для заключенных!"
    end
    
    InitializePlayerData(ply)
    local data = playerData[ply:SteamID()]
    
    -- Проверка кулдауна
    if os.time() - data.lastGame < ArrestMaster.Config.Minigames.Cooldown then
        return false, "Подождите перед следующей игрой!"
    end
    
    -- Проверка количества игр в день
    if os.date("%Y-%m-%d") ~= os.date("%Y-%m-%d", data.lastReset) then
        data.gamesPlayed = 0
        data.lastReset = os.time()
    end
    
    if data.gamesPlayed >= ArrestMaster.Config.Minigames.MaxDailyGames then
        return false, "Вы достигли дневного лимита игр!"
    end
    
    return true
end

-- Функция для расчета награды
local function CalculateReward(gameType, difficulty, success, timeLeft)
    if not success then return 0 end
    
    local baseReward = ArrestMaster.Config.Minigames.TimeReduction[gameType]
    local difficultyMultiplier = {
        easy = 1,
        medium = 1.5,
        hard = 2
    }
    
    -- Бонус за скорость
    local speedBonus = 0
    if timeLeft > 0 then
        speedBonus = math.floor(timeLeft / 10) -- 1 минута бонуса за каждые 10 секунд
    end
    
    -- Бонус за серию побед
    local data = playerData[ply:SteamID()]
    if data and data.streak > 0 then
        speedBonus = speedBonus + math.floor(data.streak * 0.5) -- 0.5 минуты за каждую победу в серии
    end
    
    return math.floor(baseReward * difficultyMultiplier[difficulty] + speedBonus)
end

-- Игра на память
local function MemoryGame(ply, difficulty)
    local isValid, error = ValidateGameInput("memory", difficulty)
    if not isValid then
        ply:ChatPrint(error)
        return
    end
    
    local data = playerData[ply:SteamID()]
    local config = ArrestMaster.Config.Minigames.Games.memory.difficulty[difficulty]
    
    -- Создаем сетку карточек
    local cards = {}
    local pairs = config.pairs
    local symbols = {"♠", "♥", "♦", "♣", "★", "☆", "☀", "☽", "⚡", "☂", "☃", "☘"}
    
    -- Проверяем достаточность символов
    if #symbols < pairs then
        ply:ChatPrint("Ошибка: недостаточно символов для игры")
        return
    end
    
    -- Заполняем карточки
    for i = 1, pairs do
        table.insert(cards, {symbol = symbols[i], revealed = false, matched = false})
        table.insert(cards, {symbol = symbols[i], revealed = false, matched = false})
    end
    
    -- Перемешиваем карточки
    for i = #cards, 2, -1 do
        local j = math.random(i)
        cards[i], cards[j] = cards[j], cards[i]
    end
    
    -- Отправляем данные на клиент
    net.Start("ArrestMaster_MemoryGame")
        net.WriteUInt(pairs, 8)
        net.WriteUInt(config.time, 8)
        net.WriteString(difficulty)
        net.WriteTable(cards)
    net.Send(ply)
end

-- Математическая игра
local function MathGame(ply, difficulty)
    local isValid, error = ValidateGameInput("math", difficulty)
    if not isValid then
        ply:ChatPrint(error)
        return
    end
    
    local data = playerData[ply:SteamID()]
    local config = ArrestMaster.Config.Minigames.Games.math.difficulty[difficulty]
    
    -- Генерируем задачи
    local problems = {}
    for i = 1, config.problems do
        local a = math.random(1, 100)
        local b = math.random(1, 100)
        local operation = math.random(1, 4)
        local answer
        
        if operation == 1 then
            answer = a + b
        elseif operation == 2 then
            answer = a - b
        elseif operation == 3 then
            answer = a * b
        else
            -- Проверяем деление на ноль
            if b == 0 then b = 1 end
            answer = math.floor(a / b)
        end
        
        table.insert(problems, {
            a = a,
            b = b,
            operation = operation,
            answer = answer
        })
    end
    
    -- Отправляем данные на клиент
    net.Start("ArrestMaster_MathGame")
        net.WriteUInt(config.problems, 8)
        net.WriteUInt(config.time, 8)
        net.WriteString(difficulty)
        net.WriteTable(problems)
    net.Send(ply)
end

-- Игра на скорость печати
local function TypingGame(ply, difficulty)
    local isValid, error = ValidateGameInput("typing", difficulty)
    if not isValid then
        ply:ChatPrint(error)
        return
    end
    
    local data = playerData[ply:SteamID()]
    local config = ArrestMaster.Config.Minigames.Games.typing.difficulty[difficulty]
    
    -- Список слов для игры
    local words = {
        "программирование", "компьютер", "интернет", "база данных", "сервер",
        "клиент", "сеть", "система", "безопасность", "разработка", "код",
        "функция", "переменная", "массив", "объект", "класс", "метод",
        "параметр", "результат", "операция", "условие", "цикл", "команда"
    }
    
    -- Проверяем достаточность слов
    if #words < config.words then
        ply:ChatPrint("Ошибка: недостаточно слов для игры")
        return
    end
    
    -- Выбираем случайные слова
    local selectedWords = {}
    for i = 1, config.words do
        table.insert(selectedWords, words[math.random(#words)])
    end
    
    -- Отправляем данные на клиент
    net.Start("ArrestMaster_TypingGame")
        net.WriteUInt(config.words, 8)
        net.WriteUInt(config.time, 8)
        net.WriteString(difficulty)
        net.WriteTable(selectedWords)
    net.Send(ply)
end

-- Головоломка
local function PuzzleGame(ply, difficulty)
    local isValid, error = ValidateGameInput("puzzle", difficulty)
    if not isValid then
        ply:ChatPrint(error)
        return
    end
    
    local data = playerData[ply:SteamID()]
    local config = ArrestMaster.Config.Minigames.Games.puzzle.difficulty[difficulty]
    
    -- Создаем пазл
    local pieces = {}
    for i = 1, config.pieces do
        table.insert(pieces, {
            id = i,
            position = i,
            correct = i
        })
    end
    
    -- Перемешиваем пазл
    for i = #pieces, 2, -1 do
        local j = math.random(i)
        pieces[i].position, pieces[j].position = pieces[j].position, pieces[i].position
    end
    
    -- Отправляем данные на клиент
    net.Start("ArrestMaster_PuzzleGame")
        net.WriteUInt(config.pieces, 8)
        net.WriteUInt(config.time, 8)
        net.WriteString(difficulty)
        net.WriteTable(pieces)
    net.Send(ply)
end

-- Обработчик запроса игры
net.Receive("ArrestMaster_RequestGame", function(len, ply)
    if not IsValid(ply) then return end
    
    local canPlay, message = CanPlayGame(ply)
    if not canPlay then
        ply:ChatPrint(message)
        return
    end
    
    local gameType = net.ReadString()
    local difficulty = net.ReadString()
    
    local gameFuncs = {
        ["memory"] = MemoryGame,
        ["math"] = MathGame,
        ["typing"] = TypingGame,
        ["puzzle"] = PuzzleGame
    }
    
    if gameFuncs[gameType] then
        gameFuncs[gameType](ply, difficulty)
        playerData[ply:SteamID()].lastGame = os.time()
        playerData[ply:SteamID()].gamesPlayed = playerData[ply:SteamID()].gamesPlayed + 1
    end
end)

-- Обработчик завершения игры
net.Receive("ArrestMaster_GameComplete", function(len, ply)
    if not IsValid(ply) then return end
    
    local gameType = net.ReadString()
    local difficulty = net.ReadString()
    local success = net.ReadBool()
    local timeLeft = net.ReadUInt(8)
    
    if success then
        local reward = CalculateReward(gameType, difficulty, true, timeLeft)
        local currentTime = ply:GetNWInt("ArrestMaster_JailTime", 0)
        local newTime = math.max(0, currentTime - reward)
        
        ply:SetNWInt("ArrestMaster_JailTime", newTime)
        
        -- Обновляем статистику игрока
        local data = playerData[ply:SteamID()]
        data.totalTimeReduced = data.totalTimeReduced + reward
        data.gamesWon = data.gamesWon + 1
        data.streak = data.streak + 1
        data.bestStreak = math.max(data.bestStreak, data.streak)
        
        -- Обновляем статистику по играм
        if difficulty == "hard" then
            if gameType == "typing" then data.typingHardWins = data.typingHardWins + 1
            elseif gameType == "math" then data.mathHardWins = data.mathHardWins + 1
            elseif gameType == "memory" then data.memoryHardWins = data.memoryHardWins + 1
            elseif gameType == "puzzle" then data.puzzleHardWins = data.puzzleHardWins + 1
            end
        end
        
        -- Проверяем достижения
        CheckAchievements(ply)
        
        -- Отправляем уведомление
        local streakText = data.streak > 1 and string.format(" (Серия побед: %d)", data.streak) or ""
        ply:ChatPrint(string.format("Поздравляем! Вы сократили срок на %d минут! (Всего сокращено: %d минут)%s", 
            reward, data.totalTimeReduced, streakText))
        
        -- Логируем успешное завершение игры
        if ArrestMaster.Config.Logging.LogTypes.GameComplete then
            LogAction("Успешное завершение мини-игры", {
                ["Игрок"] = string.format("%s (%s)", ply:Nick(), ply:SteamID()),
                ["Игра"] = gameType,
                ["Сложность"] = difficulty,
                ["Сокращение"] = string.format("%d минут", reward),
                ["Всего сокращено"] = string.format("%d минут", data.totalTimeReduced),
                ["Серия побед"] = data.streak,
                ["Лучшая серия"] = data.bestStreak
            })
        end
    else
        -- Сбрасываем серию при проигрыше
        local data = playerData[ply:SteamID()]
        if data then
            data.streak = 0
        end
        ply:ChatPrint("Попробуйте еще раз!")
    end
end)

-- Очистка данных при отключении игрока
hook.Add("PlayerDisconnected", "ArrestMaster_MinigamesCleanup", function(ply)
    playerData[ply:SteamID()] = nil
end) 