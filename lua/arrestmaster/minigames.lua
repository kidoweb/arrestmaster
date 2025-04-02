-- Система мини-игр для сокращения срока
ArrestMaster.Minigames = ArrestMaster.Minigames or {}

-- Хранение данных игроков
local playerData = {}

-- Инициализация данных игрока
local function InitializePlayerData(ply)
    if not playerData[ply:SteamID()] then
        playerData[ply:SteamID()] = {
            lastGame = 0,
            gamesPlayed = 0,
            lastReset = os.time(),
            currentGame = nil,
            difficulty = "easy"
        }
    end
end

-- Проверка возможности играть
local function CanPlayGame(ply)
    if not ArrestMaster.Config.Minigames.Enabled then return false end
    
    InitializePlayerData(ply)
    local data = playerData[ply:SteamID()]
    
    -- Проверка кулдауна
    if CurTime() - data.lastGame < ArrestMaster.Config.Minigames.Cooldown then
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

-- Игра на память
local function MemoryGame(ply)
    local data = playerData[ply:SteamID()]
    local difficulty = data.difficulty
    local config = ArrestMaster.Config.Minigames.Games.memory.difficulty[difficulty]
    
    -- Создаем сетку карточек
    local cards = {}
    local pairs = config.pairs
    local symbols = {"♠", "♥", "♦", "♣", "★", "☆", "☀", "☽", "⚡", "☂", "☃", "☘"}
    
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
        net.WriteTable(cards)
    net.Send(ply)
end

-- Математическая игра
local function MathGame(ply)
    local data = playerData[ply:SteamID()]
    local difficulty = data.difficulty
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
        net.WriteTable(problems)
    net.Send(ply)
end

-- Игра на скорость печати
local function TypingGame(ply)
    local data = playerData[ply:SteamID()]
    local difficulty = data.difficulty
    local config = ArrestMaster.Config.Minigames.Games.typing.difficulty[difficulty]
    
    -- Список слов для игры
    local words = {
        "программирование", "компьютер", "интернет", "база данных", "сервер",
        "клиент", "сеть", "система", "безопасность", "разработка", "код",
        "функция", "переменная", "массив", "объект", "класс", "метод",
        "параметр", "результат", "операция", "условие", "цикл", "команда"
    }
    
    -- Выбираем случайные слова
    local selectedWords = {}
    for i = 1, config.words do
        table.insert(selectedWords, words[math.random(#words)])
    end
    
    -- Отправляем данные на клиент
    net.Start("ArrestMaster_TypingGame")
        net.WriteUInt(config.words, 8)
        net.WriteUInt(config.time, 8)
        net.WriteTable(selectedWords)
    net.Send(ply)
end

-- Головоломка
local function PuzzleGame(ply)
    local data = playerData[ply:SteamID()]
    local difficulty = data.difficulty
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
    local gameFuncs = {
        ["memory"] = MemoryGame,
        ["math"] = MathGame,
        ["typing"] = TypingGame,
        ["puzzle"] = PuzzleGame
    }
    
    if gameFuncs[gameType] then
        gameFuncs[gameType](ply)
        playerData[ply:SteamID()].lastGame = CurTime()
        playerData[ply:SteamID()].gamesPlayed = playerData[ply:SteamID()].gamesPlayed + 1
    end
end)

-- Обработчик завершения игры
net.Receive("ArrestMaster_GameComplete", function(len, ply)
    if not IsValid(ply) then return end
    
    local gameType = net.ReadString()
    local success = net.ReadBool()
    
    if success then
        local reduction = ArrestMaster.Config.Minigames.TimeReduction[gameType]
        local currentTime = ply:GetNWInt("ArrestMaster_JailTime", 0)
        local newTime = math.max(0, currentTime - reduction)
        
        ply:SetNWInt("ArrestMaster_JailTime", newTime)
        ply:ChatPrint(string.format("Поздравляем! Вы сократили срок на %d минут!", reduction))
        
        -- Логируем успешное завершение игры
        if ArrestMaster.Config.Logging.LogTypes.GameComplete then
            LogAction("Успешное завершение мини-игры", {
                ["Игрок"] = string.format("%s (%s)", ply:Nick(), ply:SteamID()),
                ["Игра"] = gameType,
                ["Сокращение"] = string.format("%d минут", reduction)
            })
        end
    else
        ply:ChatPrint("Попробуйте еще раз!")
    end
end)

-- Очистка данных при отключении игрока
hook.Add("PlayerDisconnected", "ArrestMaster_MinigamesCleanup", function(ply)
    playerData[ply:SteamID()] = nil
end) 