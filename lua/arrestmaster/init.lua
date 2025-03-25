-- Загрузка конфигурации
include("arrestmaster/config.lua")

-- Управление камерами
local occupiedCells = {}

-- Поиск свободной камеры
local function FindAvailableCell()
    return ArrestMaster.Config:GetRandomCell()
end

-- Функция логирования
local function LogAction(action, data)
    if not ArrestMaster.Config.Logging.Enabled then return end
    
    local logFile = ArrestMaster.Config.Logging.Directory .. "/" .. os.date(ArrestMaster.Config.Logging.Format) .. ".txt"
    local logDir = ArrestMaster.Config.Logging.Directory
    
    -- Создаем директорию если её нет
    if not file.Exists(logDir, "DATA") then
        file.CreateDir(logDir)
    end
    
    -- Формируем строку лога
    local logString = string.format("[%s] %s\n", os.date(ArrestMaster.Config.Logging.TimeFormat), action)
    for k, v in pairs(data) do
        logString = logString .. string.format("  %s: %s\n", k, tostring(v))
    end
    logString = logString .. "\n"
    
    -- Записываем лог
    file.Append(logFile, logString)
end

-- Функция проверки прав
local function HasPermission(ply)
    -- Проверка на админа или выше
    if ply:IsAdmin() or ply:IsSuperAdmin() then
        return true
    end
    
    -- Проверка на профессию УСБ
    local job = ply:getJobTable()
    if job and ArrestMaster.Config.AllowedJobs[job.name] then
        return true
    end
    
    return false
end

-- Заключение игрока
local function JailPlayer(ply, time, reason)
    if not ArrestMaster.Config:IsValidTime(time) then
        return false
    end
    
    local cellPos, cellAng = FindAvailableCell()
    
    if not cellPos then
        ply:ChatPrint("Нет свободных камер!")
        return false
    end
    
    -- Сохранение позиции и инвентаря игрока
    if ArrestMaster.Config.Security.SavePosition then
        ply.ArrestMasterData = {
            originalPos = ply:GetPos(),
            originalAng = ply:EyeAngles(),
            inventory = ArrestMaster.Config.Security.StripWeapons and ply:GetWeapons() or {}
        }
    end
    
    -- Установка времени заключения
    ply:SetNWInt("ArrestMaster_JailTime", time)
    ply:SetNWString("ArrestMaster_JailReason", reason)
    
    -- Перемещение игрока в камеру
    ply:SetPos(cellPos)
    ply:SetEyeAngles(cellAng)
    
    -- Изъятие оружия
    if ArrestMaster.Config.Security.StripWeapons then
        for _, weapon in ipairs(ply:GetWeapons()) do
            ply:StripWeapon(weapon:GetClass())
        end
    end
    
    -- Отметка камеры как занятой
    occupiedCells[cellPos] = ply
    
    -- Запуск таймера заключения
    timer.Create("ArrestMaster_JailTimer_" .. ply:SteamID(), time * 60, 1, function()
        if IsValid(ply) then
            UnjailPlayer(ply)
        end
    end)
    
    -- Уведомление игрока
    if ArrestMaster.Config.Notifications.Enabled then
        ply:ChatPrint(string.format("Вы были заключены на %s. Причина: %s", 
            ArrestMaster.Config:FormatTime(time), reason))
    end
    
    return true
end

-- Освобождение игрока
local function UnjailPlayer(ply)
    if not ply.ArrestMasterData then return end
    
    -- Поиск и очистка камеры
    for pos, cellPly in pairs(occupiedCells) do
        if cellPly == ply then
            occupiedCells[pos] = nil
            break
        end
    end
    
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
end

-- Сетевые строки
util.AddNetworkString("ArrestMaster_Arrest")
util.AddNetworkString("ArrestMaster_EarlyRelease")

-- Обработчик ареста
net.Receive("ArrestMaster_Arrest", function(len, ply)
    if not ArrestMaster.Config:HasPermission(ply) then
        ply:ChatPrint("У вас нет прав для ареста игроков! Только УСБ и администраторы могут использовать эту систему.")
        return
    end
    
    local reason = net.ReadString()
    local time = net.ReadUInt(16)
    
    -- Проверка времени
    time = math.Clamp(time, ArrestMaster.Config.MinJailTime, ArrestMaster.Config.MaxJailTime)
    
    -- Получение целевого игрока
    local tr = ply:GetEyeTrace()
    local target = tr.Entity
    
    if not IsValid(target) or not target:IsPlayer() then
        ply:ChatPrint("Неверная цель!")
        return
    end
    
    -- Проверки безопасности
    if ArrestMaster.Config.Security.PreventSelfArrest and target == ply then
        ply:ChatPrint("Вы не можете арестовать себя!")
        return
    end
    
    if not ArrestMaster.Config:IsInRange(ply, target) then
        ply:ChatPrint("Цель слишком далеко!")
        return
    end
    
    if not ArrestMaster.Config:HasLineOfSight(ply, target) then
        ply:ChatPrint("Нет прямой видимости цели!")
        return
    end
    
    if not ArrestMaster.Config:IsCuffed(target) then
        ply:ChatPrint("Игрок должен быть в наручниках!")
        return
    end
    
    -- Заключение игрока
    if JailPlayer(target, time, reason) then
        -- Уведомление арестовавшего
        if ArrestMaster.Config.Notifications.Enabled then
            ply:ChatPrint(string.format("Вы арестовали %s на %s. Причина: %s", 
                target:Nick(), ArrestMaster.Config:FormatTime(time), reason))
        end
            
        -- Логирование ареста
        if ArrestMaster.Config.Logging.LogTypes.Arrest then
            LogAction("Арест игрока", {
                ["Арестовавший"] = string.format("%s (%s) [%s]", ply:Nick(), ply:SteamID(), ply:getJobTable().name),
                ["Арестованный"] = string.format("%s (%s) [%s]", target:Nick(), target:SteamID(), target:getJobTable().name),
                ["Время"] = ArrestMaster.Config:FormatTime(time),
                ["Причина"] = reason,
                ["Позиция"] = string.format("X: %.2f, Y: %.2f, Z: %.2f", target:GetPos().x, target:GetPos().y, target:GetPos().z)
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
        LogAction("Досрочное освобождение", {
            ["Освободивший"] = string.format("%s (%s) [%s]", ply:Nick(), ply:SteamID(), ply:getJobTable().name),
            ["Освобожденный"] = string.format("%s (%s) [%s]", target:Nick(), target:SteamID(), target:getJobTable().name),
            ["Причина"] = reason,
            ["Оставшееся время"] = ArrestMaster.Config:FormatTime(target:GetNWInt("ArrestMaster_JailTime", 0)),
            ["Позиция"] = string.format("X: %.2f, Y: %.2f, Z: %.2f", target:GetPos().x, target:GetPos().y, target:GetPos().z)
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