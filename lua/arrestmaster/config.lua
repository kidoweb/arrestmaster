-- Конфигурация системы арестов
ArrestMaster = ArrestMaster or {}
ArrestMaster.Config = {
    -- Основные настройки
    DefaultJailTime = 5,           -- Стандартное время заключения в минутах
    MaxJailTime = 1440,            -- Максимальное время заключения в минутах (24 часа)
    MinJailTime = 1,               -- Минимальное время заключения в минутах
    
    -- Настройки камер
    JailPositions = {
        Vector(-1620, -1000, -100),
        Vector(-1620, -1100, -100),
        Vector(-1620, -1200, -100),
        Vector(-1620, -1300, -100),
        Vector(-1620, -1400, -100)
    },
    JailSpawnAng = Angle(0, 90, 0), -- Угол поворота в камерах
    
    -- Настройки прав доступа
    AllowedJobs = {
        ["director_usb"] = true,           -- Директор УСБ
        ["operative_agent"] = true,        -- Оперативный Агент УСБ
        ["usb_officer"] = true,            -- Офицер УСБ
        ["specops_usb"] = true,            -- Группа Спец Назначения УСБ
        ["usb_pilot"] = true,              -- Пилот-Диспетчер УСБ
        ["prk_usb"] = true,                -- Рекрутированный ПРК УСБ
        ["medic_usb"] = true,              -- Медэксперт УСБ
        ["shock_usb"] = true               -- Ударный Солдат УСБ
    },
    
    -- Настройки интерфейса
    UI = {
        ArrestKey = KEY_F3,                -- Клавиша для открытия меню ареста
        ReleaseKey = KEY_F4,               -- Клавиша для открытия меню освобождения
        MenuWidth = 400,                   -- Ширина меню в пикселях
        MenuHeight = 500,                  -- Высота меню в пикселях
        MenuColor = Color(40, 40, 40, 230), -- Цвет фона меню
        TextColor = Color(255, 255, 255),  -- Цвет текста
        AccentColor = Color(178, 34, 34),  -- Акцентный цвет (красный УСБ)
        ButtonColor = Color(60, 60, 60),   -- Цвет кнопок
        ButtonHoverColor = Color(80, 80, 80) -- Цвет кнопок при наведении
    },
    
    -- Настройки уведомлений
    Notifications = {
        Enabled = true,                    -- Включить систему уведомлений
        Duration = 5,                      -- Длительность уведомлений в секундах
        Position = "top",                  -- Позиция уведомлений (top/bottom)
        Sound = "buttons/button15.wav",    -- Звук уведомлений
        Color = Color(178, 34, 34, 255)    -- Цвет уведомлений
    },
    
    -- Настройки логирования
    Logging = {
        Enabled = true,                    -- Включить систему логирования
        Directory = "arrestmaster/logs",    -- Директория для логов
        Format = "YYYY-MM-DD",             -- Формат имени файла лога
        TimeFormat = "HH:MM:SS",           -- Формат времени в логах
        LogTypes = {                       -- Типы действий для логирования
            Arrest = true,                 -- Аресты
            Release = true,                -- Освобождения
            EarlyRelease = true,           -- Досрочные освобождения
            Disconnect = true,             -- Отключения игроков
            AdminAction = true             -- Действия администраторов
        }
    },
    
    -- Настройки безопасности
    Security = {
        MaxDistance = 100,                 -- Максимальная дистанция для ареста/освобождения
        CheckLOS = true,                   -- Проверка прямой видимости
        PreventSelfArrest = true,          -- Запретить самому себе арест
        PreventArrestingAdmins = true,     -- Запретить арест администраторов
        PreventArrestingUSB = true,        -- Запретить арест сотрудников УСБ
        RequireCuffs = false,              -- Требовать наручники для ареста
        StripWeapons = true,               -- Изымать оружие при аресте
        ReturnWeapons = true,              -- Возвращать оружие при освобождении
        SavePosition = true,               -- Сохранять позицию при аресте
        ReturnToPosition = true            -- Возвращать на позицию при освобождении
    },
    
    -- Настройки камер
    Camera = {
        Enabled = true,                    -- Включить систему камер
        AutoAssign = true,                 -- Автоматическое назначение камер
        AllowCustomPositions = false,      -- Разрешить пользовательские позиции камер
        MaxCameras = 5,                    -- Максимальное количество камер
        CameraSize = Vector(100, 100, 100) -- Размер камеры для проверки занятости
    },
    
    -- Настройки команд
    Commands = {
        UnjailCommand = "arrestmaster_unjail", -- Команда для принудительного освобождения
        AdminOnly = true,                  -- Только для администраторов
        RequireReason = true,              -- Требовать причину при использовании
        LogUsage = true                    -- Логировать использование команд
    }
}

-- Функция для проверки прав доступа
function ArrestMaster.Config:HasPermission(ply)
    if not IsValid(ply) then return false end
    
    -- Проверка на админа
    if self.Security.PreventArrestingAdmins and ply:IsAdmin() then
        return false
    end
    
    -- Проверка на УСБ
    if self.Security.PreventArrestingUSB then
        local job = ply:getJobTable()
        if job and self.AllowedJobs[job.name] then
            return false
        end
    end
    
    return true
end

-- Функция для проверки дистанции
function ArrestMaster.Config:IsInRange(ply, target)
    if not IsValid(ply) or not IsValid(target) then return false end
    return ply:GetPos():Distance(target:GetPos()) <= self.Security.MaxDistance
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
    if not self.Camera.Enabled or not self.Camera.AutoAssign then
        return self.JailPositions[1], self.JailSpawnAng
    end
    
    local available = {}
    for i, pos in ipairs(self.JailPositions) do
        local tr = util.TraceHull({
            start = pos,
            endpos = pos + Vector(0, 0, 10),
            mins = -self.Camera.CameraSize/2,
            maxs = self.Camera.CameraSize/2,
            filter = player.GetAll()
        })
        
        if not tr.Hit then
            table.insert(available, i)
        end
    end
    
    if #available == 0 then
        return nil, nil
    end
    
    local index = available[math.random(#available)]
    return self.JailPositions[index], self.JailSpawnAng
end

return ArrestMaster.Config 