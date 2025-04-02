-- Загрузка конфигурации
include("arrestmaster/config.lua")

-- Управление камерами
local occupiedCells = {}
local arrestTimers = {}

-- Поиск свободной камеры
local function FindAvailableCell()
    return ArrestMaster.Config:GetRandomCell()
end

-- Функция логирования
local function LogAction(action, data)
    if not ArrestMaster.Config.Logging.Enabled then return end
    
    -- Создаем директорию если её нет
    local logDir = ArrestMaster.Config.Logging.Directory
    if not file.Exists(logDir, "DATA") then
        file.CreateDir(logDir)
    end
    
    -- Форматируем дату и время
    local currentDate = os.date(ArrestMaster.Config.Logging.Format)
    local currentTime = os.date(ArrestMaster.Config.Logging.TimeFormat)
    
    -- Формируем путь к файлу лога
    local logFile = logDir .. "/" .. currentDate .. ".txt"
    
    -- Формируем строку лога
    local logString = string.format("[%s] %s\n", currentTime, action)
    for k, v in pairs(data) do
        logString = logString .. string.format("  %s: %s\n", k, tostring(v))
    end
    logString = logString .. "\n"
    
    -- Записываем лог
    file.Append(logFile, logString)
    
    -- Очищаем старые файлы логов
    local files = file.Find(logDir .. "/*.txt", "DATA")
    if #files > ArrestMaster.Config.Logging.MaxLogFiles then
        table.sort(files)
        for i = 1, #files - ArrestMaster.Config.Logging.MaxLogFiles do
            file.Delete(logDir .. "/" .. files[i])
        end
    end
end

-- Серверная проверка прав
function ArrestMaster.HasPermission(ply)
    if not IsValid(ply) then return false end
    
    local userGroup = ply:GetUserGroup()
    
    -- Проверяем специальные группы
    if userGroup == "superadmin" or userGroup == "Dev Leader" then
        return true
    end
    
    -- Проверяем админ группы
    if ArrestMaster.Config.Access.AdminGroups[userGroup] then
        return true
    end
    
    -- Проверяем профессию УСБ
    local job = ply:getJobTable()
    if job and ArrestMaster.Config.Access.AllowedJobs[job.name] then
        return true
    end
    
    return false
end

-- Заключение игрока
local function JailPlayer(ply, time, reason)
    if not ArrestMaster.Config:IsValidTime(time) then
        print("[ArrestMaster] Неверное время ареста:", time)
        return false
    end
    
    local cellPos, cellAng = FindAvailableCell()
    
    if not cellPos then
        print("[ArrestMaster] Нет свободных камер!")
        ply:ChatPrint("Нет свободных камер!")
        return false
    end
    
    -- Сохранение позиции и инвентаря игрока
    if ArrestMaster.Config.Security.SavePosition then
        ply.ArrestMasterData = {
            originalPos = ply:GetPos(),
            originalAng = ply:EyeAngles(),
            inventory = ArrestMaster.Config.Security.StripWeapons and ply:GetWeapons() or {},
            arrestTime = time,
            arrestReason = reason,
            startTime = os.time(),
            lastCheck = os.time(),
            escapeAttempts = 0,
            lastPosition = cellPos
        }
    end
    
    -- Установка времени заключения
    print("[ArrestMaster] Установка времени ареста для", ply:Nick(), ":", time)
    ply:SetNWInt("ArrestMaster_JailTime", time)
    ply:SetNWString("ArrestMaster_JailReason", reason)
    
    -- Проверяем, что время установилось
    local checkTime = ply:GetNWInt("ArrestMaster_JailTime", 0)
    print("[ArrestMaster] Проверка установленного времени:", checkTime)
    
    -- Перемещение игрока в камеру
    ply:SetPos(cellPos)
    ply:SetEyeAngles(cellAng)
    
    -- Изъятие оружия и предметов
    if ArrestMaster.Config.Security.StripWeapons then
        for _, weapon in ipairs(ply:GetWeapons()) do
            ply:StripWeapon(weapon:GetClass())
        end
    end
    
    -- Отключение способностей
    ply:SetWalkSpeed(ply:GetWalkSpeed() * 0.5)
    ply:SetJumpPower(0)
    ply:SetCanWalk(false)
    ply:SetCanJump(false)
    ply:SetCanZoom(false)
    
    -- Отметка камеры как занятой
    occupiedCells[cellPos] = ply
    
    -- Создаем таймер для отслеживания времени
    arrestTimers[ply:SteamID()] = {
        remainingTime = time * 60,
        lastUpdate = os.time()
    }
    
    -- Уведомление игрока
    if ArrestMaster.Config.Notifications.Enabled then
        ply:ChatPrint(string.format("Вы были заключены на %s. Причина: %s", 
            ArrestMaster.Config:FormatTime(time), reason))
        -- Добавляем подсказку о мини-играх
        ply:ChatPrint(ArrestMaster.Config.Commands.Messages.MinigameHint)
    end
    
    -- Отправляем информацию на HUD
    net.Start("ArrestMaster_UpdateHUD")
        net.WriteString(reason)
        net.WriteUInt(time, 32)
    net.Send(ply)
    
    print("[ArrestMaster] Игрок успешно арестован:", ply:Nick())
    return true
end

-- Функция для оповещения администраторов
local function AlertAdmins(ply, distance, attempt, type)
    if not ArrestMaster.Config.Escape.Enabled then return end
    
    local alertMessage = string.format(
        "[ArrestMaster] Попытка побега!\nИгрок: %s (%s)\nТип: %s\nПопытка: %d/%d\nРасстояние: %.2f",
        ply:Nick(),
        ply:SteamID(),
        type,
        attempt,
        ArrestMaster.Config.Escape.MaxAttempts,
        distance
    )
    
    -- Отправляем оповещение всем администраторам в радиусе
    for _, admin in pairs(player.GetAll()) do
        if ArrestMaster.HasPermission(admin) then
            local adminPos = admin:GetPos()
            local distanceToAdmin = adminPos:Distance(ply:GetPos())
            
            if distanceToAdmin <= ArrestMaster.Config.Escape.AlertRadius then
                -- Отправляем сетевой пакет
                net.Start("ArrestMaster_EscapeAlert")
                    net.WriteString(alertMessage)
                    net.WriteEntity(ply)
                    net.WriteFloat(distance)
                    net.WriteInt(attempt, 8)
                    net.WriteString(type)
                net.Send(admin)
                
                -- Отправляем сообщение в чат
                admin:ChatPrint(alertMessage)
                
                -- Проигрываем звук оповещения
                admin:EmitSound(ArrestMaster.Config.Escape.Sounds.Alert, 0, 100, 1, CHAN_AUTO)
            end
        end
    end
end

-- Добавляем функцию проверки побега
local function CheckEscapeAttempt(ply)
    if not ply.ArrestMasterData or not ArrestMaster.Config.Escape.Enabled then return end
    
    local currentPos = ply:GetPos()
    local lastPos = ply.ArrestMasterData.lastPosition
    local distance = currentPos:Distance(lastPos)
    
    -- Проверяем кулдаун
    if ply.ArrestMasterData.lastEscapeAttempt and 
       CurTime() - ply.ArrestMasterData.lastEscapeAttempt < ArrestMaster.Config.Escape.CooldownTime then
        return
    end
    
    -- Если игрок слишком далеко от камеры
    if distance > ArrestMaster.Config.Escape.WarningDistance then
        -- Увеличиваем счетчик попыток
        ply.ArrestMasterData.escapeAttempts = (ply.ArrestMasterData.escapeAttempts or 0) + 1
        
        -- Проверяем, не превышен ли лимит попыток
        if ply.ArrestMasterData.escapeAttempts >= ArrestMaster.Config.Escape.MaxAttempts then
            -- Увеличиваем время ареста
            local currentTime = ply:GetNWInt("ArrestMaster_JailTime", 0)
            ply:SetNWInt("ArrestMaster_JailTime", currentTime + ArrestMaster.Config.Escape.PenaltyTime)
            
            -- Оповещаем администраторов о критической попытке побега
            AlertAdmins(ply, distance, ply.ArrestMasterData.escapeAttempts, "КРИТИЧЕСКАЯ")
            
            -- Возвращаем игрока в камеру
            ply:SetPos(lastPos)
            
            -- Уведомление игрока
            if ArrestMaster.Config.Notifications.Enabled then
                ply:ChatPrint(string.format("Превышен лимит попыток побега! Время ареста увеличено на %d минут.", 
                    ArrestMaster.Config.Escape.PenaltyTime))
            end
            
            -- Логируем критическую попытку побега
            if ArrestMaster.Config.Logging.LogTypes.EscapeAttempt then
                LogAction("Критическая попытка побега", {
                    ["Игрок"] = string.format("%s (%s)", ply:Nick(), ply:SteamID()),
                    ["Попытка"] = ply.ArrestMasterData.escapeAttempts,
                    ["Расстояние"] = string.format("%.2f", distance)
                })
            end
        else
            -- Предупреждение о попытке побега
            AlertAdmins(ply, distance, ply.ArrestMasterData.escapeAttempts, "ПРЕДУПРЕЖДЕНИЕ")
            
            -- Возвращаем игрока в камеру
            ply:SetPos(lastPos)
            
            -- Уведомление игрока
            if ArrestMaster.Config.Notifications.Enabled then
                ply:ChatPrint(string.format("Попытка побега зафиксирована! Осталось попыток: %d", 
                    ArrestMaster.Config.Escape.MaxAttempts - ply.ArrestMasterData.escapeAttempts))
            end
            
            -- Логируем попытку побега
            if ArrestMaster.Config.Logging.LogTypes.EscapeAttempt then
                LogAction("Попытка побега", {
                    ["Игрок"] = string.format("%s (%s)", ply:Nick(), ply:SteamID()),
                    ["Попытка"] = ply.ArrestMasterData.escapeAttempts,
                    ["Расстояние"] = string.format("%.2f", distance)
                })
            end
        end
        
        -- Обновляем время последней попытки
        ply.ArrestMasterData.lastEscapeAttempt = CurTime()
    end
    
    -- Обновляем последнюю позицию
    ply.ArrestMasterData.lastPosition = currentPos
    ply.ArrestMasterData.lastCheck = os.time()
end

-- Добавляем хук для проверки побега
hook.Add("Think", "ArrestMaster_CheckEscape", function()
    for _, ply in pairs(player.GetAll()) do
        if ply.ArrestMasterData then
            CheckEscapeAttempt(ply)
        end
    end
end)

-- Добавляем новую функцию для обновления времени ареста
local function UpdateArrestTime()
    for steamID, timerData in pairs(arrestTimers) do
        local ply = player.GetBySteamID(steamID)
        if not IsValid(ply) then
            print("[ArrestMaster] Игрок не найден:", steamID)
            arrestTimers[steamID] = nil
            continue
        end
        
        local currentTime = os.time()
        local timeDiff = currentTime - timerData.lastUpdate
        timerData.remainingTime = timerData.remainingTime - timeDiff
        timerData.lastUpdate = currentTime
        
        if timerData.remainingTime <= 0 then
            print("[ArrestMaster] Время ареста истекло для:", ply:Nick())
            -- Перереспавн игрока при истечении срока
            ply:Spawn()
            UnjailPlayer(ply)
            arrestTimers[steamID] = nil
        else
            -- Обновляем отображаемое время
            local minutesLeft = math.ceil(timerData.remainingTime / 60)
            print("[ArrestMaster] Обновление времени для", ply:Nick(), ":", minutesLeft)
            ply:SetNWInt("ArrestMaster_JailTime", minutesLeft)
        end
    end
end

-- Добавляем хук для обновления времени
hook.Add("Think", "ArrestMaster_UpdateTime", UpdateArrestTime)

-- Освобождение игрока
local function UnjailPlayer(ply)
    if not ply.ArrestMasterData then return end
    
    -- Удаляем таймер
    arrestTimers[ply:SteamID()] = nil
    
    -- Поиск и очистка камеры
    for pos, cellPly in pairs(occupiedCells) do
        if cellPly == ply then
            occupiedCells[pos] = nil
            break
        end
    end
    
    -- Восстанавливаем способности
    ply:SetWalkSpeed(ply:GetWalkSpeed() * 2) -- Возвращаем нормальную скорость
    ply:SetJumpPower(100) -- Возвращаем возможность прыгать
    ply:SetCanWalk(true)
    ply:SetCanJump(true)
    ply:SetCanZoom(true)
    
    -- Возврат игрока
    if ArrestMaster.Config.Security.ReturnToPosition then
        ply:SetPos(ply.ArrestMasterData.originalPos)
        ply:SetEyeAngles(ply.ArrestMasterData.originalAng)
    end
    
    -- Возврат оружия
    if ArrestMaster.Config.Security.ReturnWeapons then
        for _, weapon in ipairs(ply.ArrestMasterData.inventory) do
            ply:Give(weapon:GetClass())
        end
    end
    
    -- Очистка данных заключения
    ply:SetNWInt("ArrestMaster_JailTime", 0)
    ply:SetNWString("ArrestMaster_JailReason", "")
    ply.ArrestMasterData = nil
    
    -- Уведомление игрока
    if ArrestMaster.Config.Notifications.Enabled then
        ply:ChatPrint("Вы были освобождены из камеры!")
    end
    
    -- Убираем HUD
    net.Start("ArrestMaster_RemoveHUD")
    net.Send(ply)
    
    -- Перереспавн игрока
    ply:Spawn()
end

-- В начало файла добавляем все необходимые сетевые строки
util.AddNetworkString("ArrestMaster_Arrest")
util.AddNetworkString("ArrestMaster_EarlyRelease")
util.AddNetworkString("ArrestMaster_RequestLogs")
util.AddNetworkString("ArrestMaster_SendLogs")
util.AddNetworkString("ArrestMaster_RequestMenu")
util.AddNetworkString("ArrestMaster_OpenMenu")
util.AddNetworkString("ArrestMaster_CheckPermission")
util.AddNetworkString("ArrestMaster_UpdateHUD")
util.AddNetworkString("ArrestMaster_RemoveHUD")
util.AddNetworkString("ArrestMaster_EscapeAlert")

-- Регистрация сетевых сообщений
util.AddNetworkString("ArrestMaster_RequestGame")
util.AddNetworkString("ArrestMaster_GameComplete")
util.AddNetworkString("ArrestMaster_MemoryGame")
util.AddNetworkString("ArrestMaster_MathGame")
util.AddNetworkString("ArrestMaster_TypingGame")
util.AddNetworkString("ArrestMaster_PuzzleGame")

-- Хранение логов
local arrestLogs = {}

-- Функция для добавления лога
local function AddLog(action, data)
    if not ArrestMaster.Config.Logging.Enabled then return end
    
    local log = {
        time = os.date(ArrestMaster.Config.Logging.TimeFormat),
        action = action,
        details = string.format("%s (%s) - %s", data.player, data.steamid, data.details)
    }
    
    -- Добавляем лог в начало массива
    table.insert(arrestLogs, 1, log)
    
    -- Ограничиваем количество логов в памяти
    if #arrestLogs > ArrestMaster.Config.Logging.MaxLogsInMemory then
        table.remove(arrestLogs)
    end
    
    -- Сохраняем лог в файл
    LogAction(action, data)
end

-- Обработчик ареста
net.Receive("ArrestMaster_Arrest", function(len, ply)
    if not ArrestMaster.HasPermission(ply) then
        ply:ChatPrint("У вас нет прав для ареста игроков!")
        return
    end
    
    local target = net.ReadEntity()
    local reason = net.ReadString()
    local time = net.ReadUInt(16)
    
    if not IsValid(target) or not target:IsPlayer() then
        ply:ChatPrint("Неверная цель!")
        return
    end
    
    -- Проверяем только самоарест
    if ArrestMaster.Config.Security.PreventSelfArrest and target == ply then
        ply:ChatPrint("Вы не можете арестовать себя!")
        return
    end
    
    -- Заключение игрока
    if JailPlayer(target, time, reason) then
        -- Уведомления
        if ArrestMaster.Config.Notifications.Enabled then
            ply:ChatPrint(string.format("Вы арестовали %s на %s. Причина: %s", 
                target:Nick(), ArrestMaster.Config:FormatTime(time), reason))
            target:ChatPrint(string.format("Вы были арестованы на %s. Причина: %s",
                ArrestMaster.Config:FormatTime(time), reason))
        end
        
        -- Логирование
        if ArrestMaster.Config.Logging.LogTypes.Arrest then
            AddLog("Арест игрока", {
                player = string.format("%s (%s)", target:Nick(), target:SteamID()),
                steamid = target:SteamID(),
                details = string.format("Арестован игроком %s на %s. Причина: %s", 
                    ply:Nick(), ArrestMaster.Config:FormatTime(time), reason)
            })
        end
    end
end)

-- Обработчик досрочного освобождения
net.Receive("ArrestMaster_EarlyRelease", function(len, ply)
    if not ArrestMaster.Config:HasPermission(ply) then
        ply:ChatPrint("У вас нет прав для освобождения игроков! Только УСБ и администраторы могут использовать эту систему.")
        return
    end
    
    local target = net.ReadEntity()
    local reason = net.ReadString()
    
    if not IsValid(target) or not target:IsPlayer() then
        ply:ChatPrint("Неверная цель!")
        return
    end
    
    -- Проверки безопасности
    if not ArrestMaster.Config:IsInRange(ply, target) then
        ply:ChatPrint("Цель слишком далеко!")
        return
    end
    
    if not ArrestMaster.Config:HasLineOfSight(ply, target) then
        ply:ChatPrint("Нет прямой видимости цели!")
        return
    end
    
    -- Проверка, находится ли игрок в камере
    if not target.ArrestMasterData then
        ply:ChatPrint("Этот игрок не находится в камере!")
        return
    end
    
    -- Освобождение игрока
    UnjailPlayer(target)
    
    -- Уведомления
    if ArrestMaster.Config.Notifications.Enabled then
        ply:ChatPrint(string.format("Вы освободили %s досрочно. Причина: %s", target:Nick(), reason))
        target:ChatPrint(string.format("Вас освободили досрочно. Причина: %s", reason))
    end
    
    -- Логирование досрочного освобождения
    if ArrestMaster.Config.Logging.LogTypes.EarlyRelease then
        AddLog("Досрочное освобождение", {
            player = string.format("%s (%s)", target:Nick(), target:SteamID()),
            steamid = target:SteamID(),
            details = string.format("Освобожден игроком %s. Причина: %s", 
                ply:Nick(), reason)
        })
    end
end)

-- Очистка при отключении игрока
hook.Add("PlayerDisconnected", "ArrestMaster_PlayerDisconnect", function(ply)
    if ply.ArrestMasterData then
        -- Логирование отключения заключенного игрока
        if ArrestMaster.Config.Logging.LogTypes.Disconnect then
            LogAction("Отключение заключенного игрока", {
                ["Игрок"] = string.format("%s (%s)", ply:Nick(), ply:SteamID()),
                ["Оставшееся время"] = ArrestMaster.Config:FormatTime(ply:GetNWInt("ArrestMaster_JailTime", 0)),
                ["Позиция"] = string.format("X: %.2f, Y: %.2f, Z: %.2f", ply:GetPos().x, ply:GetPos().y, ply:GetPos().z)
            })
        end
        
        UnjailPlayer(ply)
    end
end)

-- Админ-команда для принудительного освобождения
concommand.Add(ArrestMaster.Config.Commands.UnjailCommand, function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local target = Player(tonumber(args[1]) or 0)
    if not IsValid(target) then return end
    
    if target.ArrestMasterData then
        -- Логирование принудительного освобождения
        if ArrestMaster.Config.Logging.LogTypes.AdminAction then
            LogAction("Принудительное освобождение (админ)", {
                ["Администратор"] = string.format("%s (%s)", ply:Nick(), ply:SteamID()),
                ["Освобожденный"] = string.format("%s (%s)", target:Nick(), target:SteamID()),
                ["Оставшееся время"] = ArrestMaster.Config:FormatTime(target:GetNWInt("ArrestMaster_JailTime", 0)),
                ["Позиция"] = string.format("X: %.2f, Y: %.2f, Z: %.2f", target:GetPos().x, target:GetPos().y, target:GetPos().z)
            })
        end
        
        UnjailPlayer(target)
        if ArrestMaster.Config.Notifications.Enabled then
            ply:ChatPrint(string.format("Вы освободили %s", target:Nick()))
        end
    end
end)

-- Обработчик запроса логов
net.Receive("ArrestMaster_RequestLogs", function(len, ply)
    if not ArrestMaster.Config:HasPermission(ply) then return end
    
    net.Start("ArrestMaster_SendLogs")
        net.WriteTable(arrestLogs)
    net.Send(ply)
end)

-- Обработчик чат-команды на сервере
hook.Add("PlayerSay", "ArrestMaster_ChatCommand", function(ply, text)
    local lowerText = text:lower()
    
    -- Проверяем команду ареста
    if lowerText:StartsWith("!arrest") or lowerText:StartsWith("/арест") then
        if ArrestMaster.HasPermission(ply) then
            -- Отправляем клиенту команду открытия меню
            net.Start("ArrestMaster_OpenMenu")
            net.Send(ply)
            return ""
        else
            ply:ChatPrint("[ArrestMaster] У вас нет прав для использования этой команды!")
            return ""
        end
    end
    
    -- Проверяем команду мини-игр
    if lowerText:StartsWith("!minigame") or lowerText:StartsWith("/minigame") then
        -- Проверяем, находится ли игрок в камере
        if not ply.ArrestMasterData then
            ply:ChatPrint(ArrestMaster.Config.Commands.Messages.MinigameNoAccess)
            return ""
        end
        
        -- Отправляем клиенту команду открытия меню мини-игр
        net.Start("ArrestMaster_OpenMinigameMenu")
        net.Send(ply)
        return ""
    end
end)

-- Обработчик запроса на открытие меню
net.Receive("ArrestMaster_RequestMenu", function(len, ply)
    if not IsValid(ply) then return end
    
    -- Проверяем права
    local hasPermission = ArrestMaster.HasPermission(ply)
    
    if hasPermission then
        -- Если есть права, сразу отправляем команду на открытие меню
        net.Start("ArrestMaster_OpenMenu")
        net.Send(ply)
    else
        -- Отправляем сообщение об отказе
        ply:ChatPrint("[ArrestMaster] У вас нет прав для использования этой команды!")
    end
end)

-- Обработчик запроса мини-игры
net.Receive("ArrestMaster_RequestMinigame", function(len, ply)
    local gameName = net.ReadString()
    
    -- Проверяем, может ли игрок играть
    if not ArrestMaster.CanPlayMinigame(ply) then
        ply:ChatPrint("Вы не можете играть в мини-игры в данный момент!")
        return
    end
    
    -- Получаем данные игры
    local gameData = ArrestMaster.Config.Minigames.Games[gameName]
    if not gameData then
        ply:ChatPrint("Ошибка: игра не найдена!")
        return
    end
    
    -- Генерируем данные игры
    local gameState = ArrestMaster.GenerateMinigameData(gameName)
    
    -- Отправляем данные игры клиенту
    net.Start("ArrestMaster_StartMinigame")
        net.WriteString(gameName)
        net.WriteTable(gameState)
    net.Send(ply)
end)

-- Обработчик завершения мини-игры
net.Receive("ArrestMaster_CompleteMinigame", function(len, ply)
    local gameName = net.ReadString()
    local success = net.ReadBool()
    
    if success then
        -- Получаем данные игры
        local gameData = ArrestMaster.Config.Minigames.Games[gameName]
        if gameData then
            -- Уменьшаем время заключения
            local timeReduction = gameData.timeReduction * 60 -- конвертируем в секунды
            local currentTime = ply:GetNWInt("ArrestMaster_JailTime", 0)
            local newTime = math.max(0, currentTime - timeReduction)
            
            ply:SetNWInt("ArrestMaster_JailTime", newTime)
            
            -- Обновляем данные игрока
            if ply.ArrestMasterData then
                ply.ArrestMasterData.gamesPlayed = (ply.ArrestMasterData.gamesPlayed or 0) + 1
                ply.ArrestMasterData.lastGameTime = os.time()
            end
            
            -- Отправляем результат
            net.Start("ArrestMaster_MinigameResult")
                net.WriteBool(true)
                net.WriteString(string.format("Поздравляем! Вы уменьшили время заключения на %d минут!", gameData.timeReduction))
            net.Send(ply)
        end
    else
            net.Start("ArrestMaster_MinigameResult")
                net.WriteBool(false)
                net.WriteString("К сожалению, вы не справились с заданием. Попробуйте еще раз!")
            net.Send(ply)
    end
end) 