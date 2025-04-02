-- Базовая инициализация
ArrestMaster = ArrestMaster or {}
ArrestMaster.OpenMenus = ArrestMaster.OpenMenus or {}

-- Проверяем загрузку конфига
if not ArrestMaster.Config then
    include("arrestmaster/config.lua")
end

-- Определение функции CreateMenu в глобальной области видимости
function ArrestMaster.CreateMenu()
    print("[ArrestMaster] Attempting to create menu...")
    
    -- Проверяем, не открыто ли уже меню
    if #ArrestMaster.OpenMenus > 0 then
        print("[ArrestMaster] Menu already open!")
        return
    end
    
    if not ArrestMaster or not ArrestMaster.Config then
        print("[ArrestMaster] Error: Config not loaded!")
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then 
        print("[ArrestMaster] Error: Invalid player!")
        return 
    end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    
    print("[ArrestMaster] Looking at entity:", ent)
    
    if IsValid(ent) and ent:IsPlayer() then
        local distance = ply:GetPos():Distance(ent:GetPos())
        print("[ArrestMaster] Distance to player:", distance)
        
        if distance <= ArrestMaster.Config.Security.MaxDistance then
            local frame = vgui.Create("ArrestMaster_Menu")
            if frame then
                frame:SetPos(ScrW()/2 - ArrestMaster.Config.UI.MenuWidth/2, ScrH()/2 - ArrestMaster.Config.UI.MenuHeight/2)
                table.insert(ArrestMaster.OpenMenus, frame)
                print("[ArrestMaster] Menu created successfully")
            else
                print("[ArrestMaster] Error: Failed to create menu panel!")
            end
        else
            notification.AddLegacy("Игрок слишком далеко!", NOTIFY_ERROR, 3)
            print("[ArrestMaster] Error: Player too far!")
        end
    else
        notification.AddLegacy("Нет подходящего игрока рядом!", NOTIFY_ERROR, 3)
        print("[ArrestMaster] Error: No valid player target!")
    end
end

-- Обновляем команды
concommand.Add("am_test", function()
    print("[ArrestMaster] Test command executed")
    if ArrestMaster.CreateMenu then
        ArrestMaster.CreateMenu()
    else
        print("[ArrestMaster] Error: CreateMenu function not found in ArrestMaster table!")
        print("Available functions in ArrestMaster:", table.ToString(ArrestMaster))
    end
end)

-- Проверка инициализации
hook.Add("InitPostEntity", "ArrestMaster_InitCheck", function()
    print("[ArrestMaster] Addon initialized!")
    print("[ArrestMaster] Config loaded:", ArrestMaster.Config ~= nil)
    print("[ArrestMaster] CreateMenu function available:", ArrestMaster.CreateMenu ~= nil)
    
    notification.AddLegacy("ArrestMaster загружен! Нажмите H для открытия меню.", NOTIFY_GENERIC, 5)
end)

local PANEL = {}

-- Colors
local COLORS = {
    background = Color(0, 0, 0, 200),
    header = Color(40, 40, 40, 255),
    button = Color(60, 60, 60, 255),
    buttonHover = Color(80, 80, 80, 255),
    text = Color(255, 255, 255, 255),
    accent = Color(255, 59, 48, 255),
    success = Color(52, 199, 89, 255),
    tab = Color(50, 50, 50),
    tabActive = Color(70, 70, 70)
}

-- Причины ареста
local ARREST_REASONS = {
    "RDM",
    "Нарушение RP",
    "Нарушение правил",
    "Неуважение",
    "Другое"
}

-- Причины досрочного освобождения
local RELEASE_REASONS = {
    "Хорошее поведение",
    "Ошибка в аресте",
    "Достигнуто соглашение",
    "Другое"
}

-- В начале файла добавим создание шрифтов
local function CreateFonts()
    surface.CreateFont("ArrestMaster_Title", {
        font = "Roboto",
        size = 32,
        weight = 700,
        antialias = true
    })
    
    surface.CreateFont("ArrestMaster_Header", {
        font = "Roboto",
        size = 24,
        weight = 600,
        antialias = true
    })
    
    surface.CreateFont("ArrestMaster_Normal", {
        font = "Roboto",
        size = 18,
        weight = 400,
        antialias = true
    })
    
    surface.CreateFont("ArrestMaster_Small", {
        font = "Roboto",
        size = 14,
        weight = 400,
        antialias = true
    })
end

-- Вызываем создание шрифтов при загрузке
hook.Add("Initialize", "ArrestMaster_CreateFonts", CreateFonts)

-- Обновляем конфигурацию шрифтов
local FONTS = {
    Title = "ArrestMaster_Title",
    Header = "ArrestMaster_Header",
    Normal = "ArrestMaster_Normal",
    Small = "ArrestMaster_Small"
}

-- Создаем шрифт для HUD
surface.CreateFont("ArrestMaster_HUD", {
    font = "Roboto",
    size = 24,
    weight = 600,
    antialias = true
})

-- Добавляем переменную для отслеживания состояния ареста
local isArrested = false
local arrestReason = ""
local arrestTime = 0

-- Добавляем переменные для оповещений
local escapeAlerts = {}
local alertDuration = 10 -- Длительность показа оповещения в секундах

-- Переменные для отображения предупреждений
local escapeWarning = {
    active = false,
    text = "",
    color = Color(255, 255, 255),
    startTime = 0,
    fadeTime = 0
}

-- Функция отрисовки HUD
local function DrawArrestHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local jailTime = ply:GetNWInt("ArrestMaster_JailTime", 0)
    local jailReason = ply:GetNWString("ArrestMaster_JailReason", "")
    
    if jailTime <= 0 then return end
    
    local w, h = ScrW(), ScrH()
    local config = ArrestMaster.Config.UI
    
    -- Фон
    draw.RoundedBox(8, w/2 - 200, h - 100, 400, 80, Color(0, 0, 0, 200))
    
    -- Иконка тюрьмы
    surface.SetDrawColor(config.AccentColor)
    surface.SetMaterial(Material("icon16/lock.png"))
    surface.DrawTexturedRect(w/2 - 190, h - 90, 24, 24)
    
    -- Причина ареста
    draw.SimpleText("Причина: " .. jailReason, "ArrestMaster_HUD", w/2 - 150, h - 90, config.TextColor)
    
    -- Оставшееся время
    local timeText = ArrestMaster.Config:FormatTime(jailTime)
    draw.SimpleText("Осталось: " .. timeText, "ArrestMaster_HUD", w/2 - 150, h - 60, config.SecondaryText)
end

-- Добавляем хук для отрисовки HUD
hook.Add("HUDPaint", "ArrestMaster_HUD", DrawArrestHUD)

-- Добавляем обработчики сетевых сообщений
net.Receive("ArrestMaster_UpdateHUD", function()
    local reason = net.ReadString()
    local time = net.ReadUInt(32)
    
    print("[ArrestMaster] Получено обновление HUD:", reason, time)
    
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply:SetNWString("ArrestMaster_JailReason", reason)
        ply:SetNWInt("ArrestMaster_JailTime", time)
        print("[ArrestMaster] Обновлены сетевые переменные для", ply:Nick())
    end
end)

net.Receive("ArrestMaster_RemoveHUD", function()
    print("[ArrestMaster] Получен сигнал удаления HUD")
    
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply:SetNWString("ArrestMaster_JailReason", "")
        ply:SetNWInt("ArrestMaster_JailTime", 0)
        print("[ArrestMaster] Очищены сетевые переменные для", ply:Nick())
    end
end)

function PANEL:Init()
    local config = ArrestMaster.Config.UI
    
    self:SetSize(1200, 800) -- Увеличенный размер
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(true)
    self:MakePopup()
    
    -- Анимация появления
    self:SetAlpha(0)
    self:AlphaTo(255, 0.3, 0)
    
    -- Современный фон с градиентом
    self.Paint = function(s, w, h)
        -- Основной фон
        draw.RoundedBox(10, 0, 0, w, h, Color(20, 21, 35, 250))
        
        -- Градиентная подсветка сверху
        for i = 0, 100 do
            local alpha = math.Clamp(100 - i, 0, 100)
            surface.SetDrawColor(65, 105, 225, alpha)
            surface.DrawLine(0, i, w, i)
        end
        
        -- Декоративные линии
        surface.SetDrawColor(65, 105, 225, 30)
        for i = 1, 5 do
            surface.DrawLine(0, h * (i/6), w, h * (i/6))
        end
    end
    
    -- Левая панель (навигация)
    self.leftPanel = self:Add("DPanel")
    self.leftPanel:Dock(LEFT)
    self.leftPanel:SetWidth(300)
    self.leftPanel:DockMargin(20, 20, 10, 20)
    self.leftPanel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 26, 45, 250))
        
        -- Декоративный элемент сверху
        draw.RoundedBoxEx(8, 0, 0, w, 4, Color(65, 105, 225), true, true, false, false)
    end
    
    -- Логотип/Заголовок
    self.logo = self.leftPanel:Add("DPanel")
    self.logo:Dock(TOP)
    self.logo:SetHeight(120)
    self.logo.Paint = function(s, w, h)
        -- Градиентный фон для логотипа
        for i = 0, h do
            local alpha = math.Clamp(255 - (i/h) * 255, 0, 255)
            surface.SetDrawColor(65, 105, 225, alpha * 0.2)
            surface.DrawLine(0, i, w, i)
        end
        
        -- Текст логотипа
        draw.SimpleText("СИСТЕМА", "DermaLarge", w/2, h/2-20, Color(65, 105, 225), TEXT_ALIGN_CENTER)
        draw.SimpleText("АРЕСТОВ УСБ", "DermaLarge", w/2, h/2+20, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end
    
    -- Навигационные кнопки
    local navButtons = {
        {name = "АРЕСТ", icon = "icon16/user_red.png", desc = "Арест нарушителей"},
        {name = "ОСВОБОЖДЕНИЕ", icon = "icon16/user_green.png", desc = "Досрочное освобождение"},
        {name = "ЛОГИ", icon = "icon16/table.png", desc = "История арестов"}
    }
    
    self.navButtons = {}
    for i, data in ipairs(navButtons) do
        local btn = self.leftPanel:Add("DButton")
        btn:Dock(TOP)
        btn:SetHeight(70)
        btn:DockMargin(15, 10, 15, 0)
        btn:SetText("")
        
        local icon = vgui.Create("DImage", btn)
        icon:SetSize(24, 24)
        icon:SetImage(data.icon)
        
        btn.Paint = function(s, w, h)
            local isActive = self.activeTab == i
            local isHovered = s:IsHovered()
            
            -- Фон кнопки
            if isActive then
                draw.RoundedBox(6, 0, 0, w, h, Color(65, 105, 225))
                -- Блик сверху
                surface.SetDrawColor(255, 255, 255, 20)
                surface.DrawRect(0, 0, w, 1)
            elseif isHovered then
                draw.RoundedBox(6, 0, 0, w, h, Color(45, 46, 65))
            else
                draw.RoundedBox(6, 0, 0, w, h, Color(35, 36, 55))
            end
            
            -- Иконка
            icon:SetPos(20, h/2-12)
            
            -- Текст
            draw.SimpleText(data.name, "DermaDefaultBold", 55, h/2-10, Color(255, 255, 255))
            draw.SimpleText(data.desc, "DermaDefault", 55, h/2+10, Color(150, 150, 150))
        end
        
        btn.DoClick = function()
            surface.PlaySound("ui/buttonclickrelease.wav")
            self:SwitchTab(i)
        end
        
        self.navButtons[i] = btn
    end
    
    -- Основная панель контента
    self.contentPanel = self:Add("DPanel")
    self.contentPanel:Dock(FILL)
    self.contentPanel:DockMargin(10, 20, 20, 20)
    self.contentPanel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 26, 45, 250))
    end
    
    -- Кнопка закрытия (в правом верхнем углу)
    self.closeBtn = self:Add("DButton")
    self.closeBtn:SetSize(40, 40)
    self.closeBtn:SetPos(self:GetWide() - 60, 20)
    self.closeBtn:SetText("✕")
    self.closeBtn:SetTextColor(Color(255, 255, 255))
    self.closeBtn:SetFont("DermaLarge")
    self.closeBtn.Paint = function(s, w, h)
        if s:IsHovered() then
            draw.RoundedBox(20, 0, 0, w, h, Color(225, 65, 65))
        else
            draw.RoundedBox(20, 0, 0, w, h, Color(45, 46, 65))
        end
    end
    self.closeBtn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        self:Close()
    end
    
    -- Инициализация вкладок
    self:CreateArrestTab()
    self:CreateReleaseTab()
    self:CreateLogsTab()
    self:SwitchTab(1)
end

function PANEL:CreateArrestTab()
    local config = ArrestMaster.Config.UI
    
    print("[ArrestMaster] Создание вкладки ареста...")
    
    local panel = self.contentPanel:Add("DPanel")
    panel:Dock(FILL)
    panel:DockMargin(20, 20, 20, 20)
    panel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, config.CardBackground)
    end

    -- Левая панель со списком игроков
    local playerList = panel:Add("DPanel")
    playerList:Dock(LEFT)
    playerList:SetWidth(300)
    playerList:DockMargin(10, 10, 10, 10)
    playerList.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, config.InputColor)
    end

    -- Заголовок списка игроков
    local listHeader = playerList:Add("DLabel")
    listHeader:Dock(TOP)
    listHeader:SetHeight(40)
    listHeader:SetText("СПИСОК ИГРОКОВ")
    listHeader:SetFont(FONTS.Header)
    listHeader:SetTextColor(config.TextColor or Color(255, 255, 255))
    listHeader:SetContentAlignment(5)

    -- Поле поиска
    local searchBar = playerList:Add("DTextEntry")
    searchBar:Dock(TOP)
    searchBar:SetHeight(40)
    searchBar:DockMargin(5, 5, 5, 5)
    searchBar:SetPlaceholderText("Поиск игрока...")
    searchBar.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, config.ButtonColor)
        s:DrawTextEntryText(config.TextColor, config.AccentColor, config.TextColor)
        
        if s:GetText() == "" then
            draw.SimpleText(s:GetPlaceholderText(), s:GetFont(), 5, h/2, Color(150, 150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    -- Список игроков
    local playerScroll = playerList:Add("DScrollPanel")
    playerScroll:Dock(FILL)
    playerScroll:DockMargin(5, 5, 5, 5)

    -- Функция обновления списка игроков
    local selectedPlayer = nil
    local function UpdatePlayerList(searchText)
        print("[ArrestMaster] Обновление списка игроков...")
        playerScroll:Clear()
        
        for _, ply in pairs(player.GetAll()) do
            print("[ArrestMaster] Проверка игрока:", ply:Nick())
            
            -- Проверяем, находится ли игрок в камере
            local jailTime = ply:GetNWInt("ArrestMaster_JailTime", 0)
            print("[ArrestMaster] Время ареста для", ply:Nick(), ":", jailTime)
            
            -- Проверка поиска
            if searchText and searchText != "" then
                local name = string.lower(ply:Nick())
                if not string.find(name, string.lower(searchText)) then
                    print("[ArrestMaster] Игрок не соответствует поиску:", ply:Nick())
                    continue
                end
            end

            local playerButton = playerScroll:Add("DButton")
            playerButton:Dock(TOP)
            playerButton:SetHeight(50)
            playerButton:DockMargin(2, 2, 2, 2)
            playerButton:SetText("")
            
            -- Проверяем, является ли игрок локальным
            local isLocalPlayer = ply == LocalPlayer()
            
            playerButton.Paint = function(s, w, h)
                local bgColor = selectedPlayer == ply and config.AccentColor or config.ButtonColor
                if s:IsHovered() and not isLocalPlayer then
                    bgColor = Color(bgColor.r + 20, bgColor.g + 20, bgColor.b + 20)
                end
                draw.RoundedBox(6, 0, 0, w, h, bgColor)
                
                -- Имя игрока
                draw.SimpleText(ply:Nick(), FONTS.Normal, 10, h/2-10, config.TextColor)
                -- Оставшееся время
                local timeText = jailTime > 0 and "Осталось: " .. ArrestMaster.Config:FormatTime(jailTime) or "Не арестован"
                draw.SimpleText(timeText, FONTS.Small, 10, h/2+10, config.SecondaryText)
                
                -- Добавляем пометку для локального игрока
                if isLocalPlayer then
                    draw.SimpleText("(Вы)", FONTS.Small, w - 40, h/2, config.SecondaryText, TEXT_ALIGN_RIGHT)
                end
            end
            
            playerButton.DoClick = function()
                if isLocalPlayer then
                    surface.PlaySound("buttons/button11.wav")
                    notification.AddLegacy("Вы не можете арестовать себя!", NOTIFY_ERROR, 3)
                    return
                end
                
                surface.PlaySound("ui/buttonclick.wav")
                selectedPlayer = ply
                print("[ArrestMaster] Выбран игрок:", ply:Nick())
            end
        end
    end

    -- Обновление при вводе в поиск
    searchBar.OnChange = function(self)
        UpdatePlayerList(self:GetText())
    end
    
    -- Начальное заполнение списка
    print("[ArrestMaster] Начальное заполнение списка игроков...")
    UpdatePlayerList()

    -- Правая панель с настройками ареста
    local arrestPanel = panel:Add("DPanel")
    arrestPanel:Dock(FILL)
    arrestPanel:DockMargin(10, 10, 10, 10)
    arrestPanel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, config.InputColor)
    end

    -- Заголовок панели ареста
    local arrestHeader = arrestPanel:Add("DLabel")
    arrestHeader:Dock(TOP)
    arrestHeader:SetHeight(40)
    arrestHeader:SetText("ПАРАМЕТРЫ АРЕСТА")
    arrestHeader:SetFont(FONTS.Header)
    arrestHeader:SetTextColor(config.TextColor)
    arrestHeader:SetContentAlignment(5)

    -- Выбор причины
    local reasonLabel = arrestPanel:Add("DLabel")
    reasonLabel:Dock(TOP)
    reasonLabel:SetHeight(30)
    reasonLabel:DockMargin(10, 10, 10, 0)
    reasonLabel:SetText("Причина ареста:")
    reasonLabel:SetTextColor(config.TextColor)

    -- Поле для ввода причины
    local reasonInput = arrestPanel:Add("DTextEntry")
    reasonInput:Dock(TOP)
    reasonInput:SetHeight(40)
    reasonInput:DockMargin(10, 5, 10, 10)
    reasonInput:SetPlaceholderText("Введите причину ареста")
    reasonInput:SetFont(FONTS.Normal)
    reasonInput:SetDrawBackground(false)
    reasonInput.Paint = function(s, w, h)
        -- Фон поля
        draw.RoundedBox(6, 0, 0, w, h, config.ButtonColor)
        
        -- Подсветка при фокусе
        if s:HasFocus() then
            draw.RoundedBox(6, 0, 0, w, h, Color(config.ButtonColor.r + 20, config.ButtonColor.g + 20, config.ButtonColor.b + 20))
            -- Анимация градиента
            for i = 0, 2 do
                local alpha = math.Clamp(255 - (i * 100), 0, 255)
                surface.SetDrawColor(config.AccentColor.r, config.AccentColor.g, config.AccentColor.b, alpha)
                surface.DrawLine(0, h - i, w, h - i)
            end
        end
        
        -- Текст поля
        s:DrawTextEntryText(
            config.TextColor,
            config.AccentColor,
            config.TextColor
        )
        
        -- Плейсхолдер
        if s:GetText() == "" then
            draw.SimpleText(s:GetPlaceholderText(), FONTS.Normal, 10, h/2, Color(150, 150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        -- Иконка
        surface.SetDrawColor(150, 150, 150, 150)
        surface.SetMaterial(Material("icon16/pencil.png"))
        surface.DrawTexturedRect(w - 25, h/2 - 8, 16, 16)
    end
    
    -- Добавляем эффект при наведении
    reasonInput.OnCursorEntered = function(s)
        surface.PlaySound("ui/buttonhover.wav")
    end
    
    -- Добавляем эффект при фокусе
    reasonInput.OnGetFocus = function(s)
        surface.PlaySound("ui/buttonclick.wav")
    end

    -- Время ареста
    local timeLabel = arrestPanel:Add("DLabel")
    timeLabel:Dock(TOP)
    timeLabel:SetHeight(30)
    timeLabel:DockMargin(10, 10, 10, 0)
    timeLabel:SetText("Время ареста (в минутах):")
    timeLabel:SetTextColor(config.TextColor)

    -- Создаем панель для поля ввода времени
    local timeInputPanel = arrestPanel:Add("DPanel")
    timeInputPanel:Dock(TOP)
    timeInputPanel:SetHeight(80)
    timeInputPanel:DockMargin(10, 5, 10, 10)
    timeInputPanel.Paint = function(s, w, h)
        -- Фон с градиентом
        for i = 0, h do
            local alpha = math.Clamp(255 - (i/h) * 100, 0, 255)
            surface.SetDrawColor(config.ButtonColor.r, config.ButtonColor.g, config.ButtonColor.b, alpha)
            surface.DrawLine(0, i, w, i)
        end
        
        -- Подсветка при наведении
        if s:IsHovered() then
            surface.SetDrawColor(config.AccentColor.r, config.AccentColor.g, config.AccentColor.b, 30)
            surface.DrawRect(0, 0, w, h)
        end
    end

    -- Создаем поле ввода
    local timeInput = timeInputPanel:Add("DTextEntry")
    timeInput:Dock(FILL)
    timeInput:DockMargin(15, 10, 15, 10)
    timeInput:SetFont(FONTS.Header)
    timeInput:SetTextColor(config.TextColor)
    timeInput:SetText("5")
    timeInput:SetDrawBackground(false)
    timeInput:SetNumeric(true)
    
    -- Ограничиваем длину текста и добавляем валидацию
    timeInput.OnChange = function(s)
        local text = s:GetValue()
        if #text > 3 then
            s:SetValue(text:sub(1, 3))
        end
        
        local value = tonumber(s:GetValue())
        if not value then return end
        
        -- Ограничиваем значение
        value = math.Clamp(value, 1, 60)
        s:SetValue(tostring(value))
        
        surface.PlaySound("ui/buttonclick.wav")
    end
    
    -- Добавляем эффект при наведении
    timeInput.OnCursorEntered = function(s)
        surface.PlaySound("ui/buttonhover.wav")
    end
    
    -- Добавляем эффект при фокусе
    timeInput.OnGetFocus = function(s)
        surface.PlaySound("ui/buttonclick.wav")
    end

    -- Добавляем подсказки значений
    local timeHints = timeInputPanel:Add("DPanel")
    timeHints:Dock(BOTTOM)
    timeHints:SetHeight(20)
    timeHints:DockMargin(15, 0, 15, 5)
    timeHints.Paint = function(s, w, h)
        -- Минимальное значение
        draw.SimpleText("1 мин", FONTS.Small, 0, 0, config.SecondaryText)
        -- Максимальное значение
        draw.SimpleText("60 мин", FONTS.Small, w, 0, config.SecondaryText, TEXT_ALIGN_RIGHT)
    end

    -- Добавляем кнопки быстрого выбора времени
    local quickTimeButtons = {
        {text = "5 мин", value = 5},
        {text = "10 мин", value = 10},
        {text = "15 мин", value = 15},
        {text = "30 мин", value = 30},
        {text = "60 мин", value = 60}
    }

    local quickTimePanel = arrestPanel:Add("DPanel")
    quickTimePanel:Dock(TOP)
    quickTimePanel:SetHeight(40)
    quickTimePanel:DockMargin(10, 0, 10, 10)
    quickTimePanel.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, config.ButtonColor)
    end

    local buttonWidth = (quickTimePanel:GetWide() - 60) / #quickTimeButtons
    for i, data in ipairs(quickTimeButtons) do
        local btn = quickTimePanel:Add("DButton")
        btn:Dock(LEFT)
        btn:SetWidth(buttonWidth)
        btn:DockMargin(5, 5, 5, 5)
        btn:SetText(data.text)
        btn:SetFont(FONTS.Small)
        btn:SetTextColor(config.TextColor)
        
        btn.Paint = function(s, w, h)
            if s:IsHovered() then
                draw.RoundedBox(4, 0, 0, w, h, Color(config.ButtonColor.r + 20, config.ButtonColor.g + 20, config.ButtonColor.b + 20))
            end
        end
        
        btn.DoClick = function()
            timeInput:SetValue(tostring(data.value))
            surface.PlaySound("ui/buttonclick.wav")
        end
    end

    -- Кнопка ареста
    local arrestBtn = arrestPanel:Add("DButton")
    arrestBtn:Dock(BOTTOM)
    arrestBtn:SetHeight(50)
    arrestBtn:DockMargin(10, 10, 10, 10)
    arrestBtn:SetText("АРЕСТОВАТЬ")
    arrestBtn:SetFont(FONTS.Header)
    arrestBtn:SetTextColor(config.TextColor)
    
    arrestBtn.Paint = function(s, w, h)
        local bgColor = s:IsHovered() and config.SuccessColor or config.AccentColor
        draw.RoundedBox(6, 0, 0, w, h, bgColor)
    end

    arrestBtn.DoClick = function()
        if not selectedPlayer or not IsValid(selectedPlayer) then
            notification.AddLegacy("Выберите игрока!", NOTIFY_ERROR, 3)
            return
        end

        local reason = reasonInput:GetValue()
        if reason == "" then
            notification.AddLegacy("Введите причину ареста!", NOTIFY_ERROR, 3)
            return
        end

        local time = tonumber(timeInput:GetValue()) or 5
        
        net.Start("ArrestMaster_Arrest")
            net.WriteEntity(selectedPlayer)
            net.WriteString(reason)
            net.WriteUInt(time, 16)
        net.SendToServer()
        
        surface.PlaySound("ui/buttonclickrelease.wav")
        self:Close()
    end

    -- Обновляем все остальные использования шрифтов
    reasonLabel:SetFont(FONTS.Normal)
    reasonLabel:SetTextColor(config.TextColor or Color(255, 255, 255))

    timeLabel:SetFont(FONTS.Normal)
    timeLabel:SetTextColor(config.TextColor or Color(255, 255, 255))

    arrestBtn:SetFont(FONTS.Header)
    arrestBtn:SetTextColor(config.TextColor or Color(255, 255, 255))
    
    self.arrestTab = panel
end

function PANEL:CreateReleaseTab()
    local config = ArrestMaster.Config.UI
    
    local panel = self.contentPanel:Add("DPanel")
    panel:Dock(FILL)
    panel:DockMargin(20, 20, 20, 20)
    panel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, config.CardBackground)
    end

    -- Левая панель со списком игроков
    local playerList = panel:Add("DPanel")
    playerList:Dock(LEFT)
    playerList:SetWidth(300)
    playerList:DockMargin(10, 10, 10, 10)
    playerList.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, config.InputColor)
    end

    -- Заголовок списка игроков
    local listHeader = playerList:Add("DLabel")
    listHeader:Dock(TOP)
    listHeader:SetHeight(40)
    listHeader:SetText("СПИСОК ЗАКЛЮЧЕННЫХ")
    listHeader:SetFont(FONTS.Header)
    listHeader:SetTextColor(config.TextColor or Color(255, 255, 255))
    listHeader:SetContentAlignment(5)

    -- Поле поиска
    local searchBar = playerList:Add("DTextEntry")
    searchBar:Dock(TOP)
    searchBar:SetHeight(40)
    searchBar:DockMargin(5, 5, 5, 5)
    searchBar:SetPlaceholderText("Поиск игрока...")
    searchBar.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, config.ButtonColor)
        s:DrawTextEntryText(config.TextColor, config.AccentColor, config.TextColor)
        
        if s:GetText() == "" then
            draw.SimpleText(s:GetPlaceholderText(), s:GetFont(), 5, h/2, Color(150, 150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    -- Список игроков
    local playerScroll = playerList:Add("DScrollPanel")
    playerScroll:Dock(FILL)
    playerScroll:DockMargin(5, 5, 5, 5)

    -- Функция обновления списка игроков
    local selectedPlayer = nil
    local function UpdatePlayerList(searchText)
        playerScroll:Clear()
        
        for _, ply in pairs(player.GetAll()) do
            if ply == LocalPlayer() then continue end -- Пропускаем самого себя
            
            -- Проверяем, находится ли игрок в камере
            local jailTime = ply:GetNWInt("ArrestMaster_JailTime", 0)
            if jailTime <= 0 then continue end
            
            -- Проверка поиска
            if searchText and searchText != "" then
                local name = string.lower(ply:Nick())
                if not string.find(name, string.lower(searchText)) then
                    continue
                end
            end

            local playerButton = playerScroll:Add("DButton")
            playerButton:Dock(TOP)
            playerButton:SetHeight(50)
            playerButton:DockMargin(2, 2, 2, 2)
            playerButton:SetText("")
            
            playerButton.Paint = function(s, w, h)
                local bgColor = selectedPlayer == ply and config.AccentColor or config.ButtonColor
                if s:IsHovered() then
                    bgColor = Color(bgColor.r + 20, bgColor.g + 20, bgColor.b + 20)
                end
                draw.RoundedBox(6, 0, 0, w, h, bgColor)
                
                -- Имя игрока
                draw.SimpleText(ply:Nick(), FONTS.Normal, 10, h/2-10, config.TextColor)
                -- Оставшееся время
                draw.SimpleText("Осталось: " .. ArrestMaster.Config:FormatTime(jailTime), FONTS.Small, 10, h/2+10, config.SecondaryText)
            end
            
            playerButton.DoClick = function()
                surface.PlaySound("ui/buttonclick.wav")
                selectedPlayer = ply
            end
        end
    end

    -- Обновление при вводе в поиск
    searchBar.OnChange = function(self)
        UpdatePlayerList(self:GetText())
    end
    
    -- Начальное заполнение списка
    UpdatePlayerList()

    -- Правая панель с настройками освобождения
    local releasePanel = panel:Add("DPanel")
    releasePanel:Dock(FILL)
    releasePanel:DockMargin(10, 10, 10, 10)
    releasePanel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, config.InputColor)
    end

    -- Заголовок панели освобождения
    local releaseHeader = releasePanel:Add("DLabel")
    releaseHeader:Dock(TOP)
    releaseHeader:SetHeight(40)
    releaseHeader:SetText("ПАРАМЕТРЫ ОСВОБОЖДЕНИЯ")
    releaseHeader:SetFont(FONTS.Header)
    releaseHeader:SetTextColor(config.TextColor)
    releaseHeader:SetContentAlignment(5)
    
    -- Причина освобождения
    local reasonLabel = releasePanel:Add("DLabel")
    reasonLabel:Dock(TOP)
    reasonLabel:SetHeight(30)
    reasonLabel:DockMargin(10, 10, 10, 0)
    reasonLabel:SetText("Причина освобождения:")
    reasonLabel:SetTextColor(config.TextColor)
    
    -- Поле для ввода причины
    local reasonInput = releasePanel:Add("DTextEntry")
    reasonInput:Dock(TOP)
    reasonInput:SetHeight(40)
    reasonInput:DockMargin(10, 5, 10, 10)
    reasonInput:SetPlaceholderText("Введите причину освобождения")
    reasonInput:SetFont(FONTS.Normal)
    reasonInput:SetDrawBackground(false)
    reasonInput.Paint = function(s, w, h)
        -- Фон поля
        draw.RoundedBox(6, 0, 0, w, h, config.ButtonColor)
        
        -- Подсветка при фокусе
        if s:HasFocus() then
            draw.RoundedBox(6, 0, 0, w, h, Color(config.ButtonColor.r + 20, config.ButtonColor.g + 20, config.ButtonColor.b + 20))
            -- Анимация градиента
            for i = 0, 2 do
                local alpha = math.Clamp(255 - (i * 100), 0, 255)
                surface.SetDrawColor(config.AccentColor.r, config.AccentColor.g, config.AccentColor.b, alpha)
                surface.DrawLine(0, h - i, w, h - i)
            end
        end
        
        -- Текст поля
        s:DrawTextEntryText(
            config.TextColor,
            config.AccentColor,
            config.TextColor
        )
        
        -- Плейсхолдер
        if s:GetText() == "" then
            draw.SimpleText(s:GetPlaceholderText(), FONTS.Normal, 10, h/2, Color(150, 150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        -- Иконка
        surface.SetDrawColor(150, 150, 150, 150)
        surface.SetMaterial(Material("icon16/pencil.png"))
        surface.DrawTexturedRect(w - 25, h/2 - 8, 16, 16)
    end
    
    -- Добавляем эффект при наведении
    reasonInput.OnCursorEntered = function(s)
        surface.PlaySound("ui/buttonhover.wav")
    end
    
    -- Добавляем эффект при фокусе
    reasonInput.OnGetFocus = function(s)
        surface.PlaySound("ui/buttonclick.wav")
    end
    
    -- Кнопка освобождения
    local releaseBtn = releasePanel:Add("DButton")
    releaseBtn:Dock(BOTTOM)
    releaseBtn:SetHeight(50)
    releaseBtn:DockMargin(10, 10, 10, 10)
    releaseBtn:SetText("ОСВОБОДИТЬ")
    releaseBtn:SetFont(FONTS.Header)
    releaseBtn:SetTextColor(config.TextColor)
    
    releaseBtn.Paint = function(s, w, h)
        local bgColor = s:IsHovered() and config.SuccessColor or config.AccentColor
        draw.RoundedBox(6, 0, 0, w, h, bgColor)
    end

    releaseBtn.DoClick = function()
        if not selectedPlayer or not IsValid(selectedPlayer) then
            notification.AddLegacy("Выберите игрока!", NOTIFY_ERROR, 3)
            return
        end

        local reason = reasonInput:GetValue()
        if reason == "" then
            notification.AddLegacy("Введите причину освобождения!", NOTIFY_ERROR, 3)
            return
        end
        
        net.Start("ArrestMaster_EarlyRelease")
            net.WriteEntity(selectedPlayer)
            net.WriteString(reason)
        net.SendToServer()
        
        surface.PlaySound("ui/buttonclickrelease.wav")
        self:Close()
    end
    
    panel.releaseTab = true
    self.releaseTab = panel
end

function PANEL:CreateLogsTab()
    local config = ArrestMaster.Config.UI
    
    local panel = self.contentPanel:Add("DPanel")
    panel:Dock(FILL)
    panel:DockMargin(20, 20, 20, 20)
    panel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, config.CardBackground)
    end

    -- Верхняя панель с фильтрами
    local filterPanel = panel:Add("DPanel")
    filterPanel:Dock(TOP)
    filterPanel:SetHeight(60)
    filterPanel:DockMargin(10, 10, 10, 5)
    filterPanel.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, config.InputColor)
    end

    -- Заголовок
    local header = filterPanel:Add("DLabel")
    header:Dock(LEFT)
    header:SetWidth(200)
    header:SetText("ИСТОРИЯ АРЕСТОВ")
    header:SetFont(FONTS.Header)
    header:SetTextColor(config.TextColor)
    header:SetContentAlignment(5)

    -- Фильтр по типу действия
    local actionFilter = filterPanel:Add("DComboBox")
    actionFilter:Dock(RIGHT)
    actionFilter:SetWidth(200)
    actionFilter:DockMargin(10, 10, 10, 10)
    actionFilter:SetValue("Все действия")
    actionFilter:SetFont(FONTS.Normal)
    actionFilter:AddChoice("Все действия")
    actionFilter:AddChoice("Арест")
    actionFilter:AddChoice("Освобождение")
    actionFilter:AddChoice("Досрочное освобождение")

    -- Поле поиска
    local searchBar = filterPanel:Add("DTextEntry")
    searchBar:Dock(RIGHT)
    searchBar:SetWidth(250)
    searchBar:DockMargin(10, 10, 10, 10)
    searchBar:SetPlaceholderText("Поиск по игроку или причине...")
    searchBar:SetFont(FONTS.Normal)
    searchBar.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, config.ButtonColor)
        s:DrawTextEntryText(config.TextColor, config.AccentColor, config.TextColor)
        
        if s:GetText() == "" then
            draw.SimpleText(s:GetPlaceholderText(), s:GetFont(), 5, h/2, Color(150, 150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    -- Кнопка обновления
    local refreshBtn = filterPanel:Add("DButton")
    refreshBtn:Dock(RIGHT)
    refreshBtn:SetWidth(40)
    refreshBtn:DockMargin(10, 10, 10, 10)
    refreshBtn:SetText("⟳")
    refreshBtn:SetFont("DermaLarge")
    refreshBtn:SetTextColor(config.TextColor)
    refreshBtn.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, config.ButtonColor)
        if s:IsHovered() then
            draw.RoundedBox(6, 0, 0, w, h, Color(config.ButtonColor.r + 20, config.ButtonColor.g + 20, config.ButtonColor.b + 20))
        end
    end

    -- Список логов
    local scroll = panel:Add("DScrollPanel")
    scroll:Dock(FILL)
    scroll:DockMargin(10, 5, 10, 10)
    scroll.Paint = function(s, w, h)
        draw.RoundedBox(8, 0, 0, w, h, config.InputColor)
    end

    -- Функция обновления логов
    local function UpdateLogs(filter, searchText)
        scroll:Clear()
        
        net.Start("ArrestMaster_RequestLogs")
        net.SendToServer()
        
        net.Receive("ArrestMaster_SendLogs", function()
            local logs = net.ReadTable()
            for _, log in ipairs(logs) do
                -- Применяем фильтры
                if filter ~= "Все действия" and not string.find(log.action, filter) then
                    continue
                end
                
                if searchText and searchText != "" then
                    local searchLower = string.lower(searchText)
                    local logText = string.lower(log.details .. log.action)
                    if not string.find(logText, searchLower) then
                        continue
                    end
                end

                local logPanel = scroll:Add("DPanel")
                logPanel:Dock(TOP)
                logPanel:SetHeight(80)
                logPanel:DockMargin(5, 5, 5, 5)
                logPanel.Paint = function(s, w, h)
                    -- Фон
                    draw.RoundedBox(6, 0, 0, w, h, config.ButtonColor)
                    
                    -- Время
                    draw.SimpleText(log.time, FONTS.Small, 10, 10, config.SecondaryText)
                    
                    -- Действие
                    local actionColor = Color(255, 255, 255)
                    if string.find(log.action, "Арест") then
                        actionColor = Color(255, 71, 87)
                    elseif string.find(log.action, "Освобождение") then
                        actionColor = Color(46, 213, 115)
                    elseif string.find(log.action, "Досрочное") then
                        actionColor = Color(255, 193, 7)
                    end
                    draw.SimpleText(log.action, FONTS.Normal, 10, 30, actionColor)
                    
                    -- Детали
                    draw.SimpleText(log.details, FONTS.Small, 10, 55, config.SecondaryText)
                    
                    -- Разделительная линия
                    surface.SetDrawColor(config.SecondaryText.r, config.SecondaryText.g, config.SecondaryText.b, 50)
                    surface.DrawLine(0, h-1, w, h-1)
                end
            end
        end)
    end

    -- Обработчики событий
    actionFilter.OnSelect = function(p, index, value)
        UpdateLogs(value, searchBar:GetText())
    end

    searchBar.OnChange = function(self)
        UpdateLogs(actionFilter:GetValue(), self:GetText())
    end

    refreshBtn.DoClick = function()
        surface.PlaySound("ui/buttonclick.wav")
        UpdateLogs(actionFilter:GetValue(), searchBar:GetText())
    end

    -- Начальная загрузка логов
    UpdateLogs("Все действия", "")
    
    panel.logsTab = true
    self.logsTab = panel
end

function PANEL:SwitchTab(tab)
    self.activeTab = tab
    
    -- Скрываем все вкладки
    if self.arrestTab then self.arrestTab:SetVisible(false) end
    if self.releaseTab then self.releaseTab:SetVisible(false) end
    if self.logsTab then self.logsTab:SetVisible(false) end
    
    -- Показываем нужную вкладку
    if tab == 1 and self.arrestTab then
        self.arrestTab:SetVisible(true)
    elseif tab == 2 and self.releaseTab then
        self.releaseTab:SetVisible(true)
    elseif tab == 3 and self.logsTab then
        self.logsTab:SetVisible(true)
    end
end

function PANEL:Close()
    -- Удаляем меню из списка открытых
    for i, menu in ipairs(ArrestMaster.OpenMenus) do
        if menu == self then
            table.remove(ArrestMaster.OpenMenus, i)
            break
        end
    end
    
    self:AlphaTo(0, 0.2, 0, function()
        self:Remove()
    end)
end

vgui.Register("ArrestMaster_Menu", PANEL, "DFrame")

-- UI для привязки клавиши
hook.Add("PopulateToolMenu", "ArrestMaster_ToolMenu", function()
    spawnmenu.AddToolMenuOption("Опции", "ArrestMaster", "Меню Арестов", "Открыть меню арестов", "", "", function(panel)
        panel:ClearControls()
        panel:Button("Назначить клавишу меню арестов", "arrest_menu")
    end)
end)

-- Обновляем обработчик чат-команд
hook.Add("OnPlayerChat", "ArrestMaster_ChatCommand", function(ply, text, teamChat, isDead)
    local lowerText = text:lower()
    
    -- Проверяем все возможные команды
    for cmd, _ in pairs(ArrestMaster.Config.Commands.ChatCommands) do
        if lowerText:StartsWith(cmd:lower()) then
            if ply == LocalPlayer() then
                -- Запрашиваем открытие меню у сервера
                net.Start("ArrestMaster_RequestMenu")
                net.SendToServer()
            end
            return true
        end
    end
end)

-- Добавляем обработчик для открытия меню
net.Receive("ArrestMaster_OpenMenu", function()
    -- Проверяем, не открыто ли уже меню
    if #ArrestMaster.OpenMenus > 0 then
        return
    end
    
    local frame = vgui.Create("ArrestMaster_Menu")
    if frame then
        table.insert(ArrestMaster.OpenMenus, frame)
        chat.AddText(
            Color(65, 105, 225), "[ArrestMaster] ",
            Color(255, 255, 255), ArrestMaster.Config.Commands.Messages.MenuOpened
        )
    end
end)

-- Удаляем старую функцию CreateMenu, так как она больше не нужна
ArrestMaster.CreateMenu = nil

-- Проверка прав на клиенте (для отладки)
function ArrestMaster.HasPermission(ply)
    if not IsValid(ply) then return false end
    
    local userGroup = ply:GetUserGroup()
    print("[ArrestMaster] Client permission check")
    print("[ArrestMaster] Player:", ply:Nick())
    print("[ArrestMaster] Group:", userGroup)
    
    -- Проверяем специальные группы
    if userGroup == "superadmin" or userGroup == "Dev Leader" then
        print("[ArrestMaster] Access granted: Special group -", userGroup)
        return true
    end
    
    -- Проверяем админ группы
    if ArrestMaster.Config.Access.AdminGroups[userGroup] then
        print("[ArrestMaster] Access granted: Admin group")
        return true
    end
    
    -- Проверяем профессию УСБ
    local job = ply:getDarkRPVar("job")
    if job then
        print("[ArrestMaster] Player job:", job)
        if ArrestMaster.Config.Access.AllowedJobs[job] then
            print("[ArrestMaster] Access granted: USB job -", job)
            return true
        end
    end
    
    print("[ArrestMaster] Access denied")
    return false
end

-- Функция для отображения оповещения
local function ShowEscapeAlert(message, target, distance, attempt)
    local alert = {
        message = message,
        target = target,
        distance = distance,
        attempt = attempt,
        startTime = CurTime(),
        alpha = 255
    }
    
    table.insert(escapeAlerts, alert)
    
    -- Удаляем старые оповещения
    for i = #escapeAlerts, 1, -1 do
        if CurTime() - escapeAlerts[i].startTime > alertDuration then
            table.remove(escapeAlerts, i)
        end
    end
end

-- Обработчик сетевого сообщения о побеге
net.Receive("ArrestMaster_EscapeAlert", function()
    local message = net.ReadString()
    local target = net.ReadEntity()
    local distance = net.ReadFloat()
    local attempt = net.ReadInt(8)
    local type = net.ReadString()
    
    if not IsValid(target) then return end
    
    -- Устанавливаем параметры предупреждения
    escapeWarning.active = true
    escapeWarning.text = string.format("%s\nПопытка: %d/%d\nРасстояние: %.1f", 
        type, attempt, ArrestMaster.Config.Escape.MaxAttempts, distance)
    escapeWarning.startTime = CurTime()
    escapeWarning.fadeTime = CurTime() + ArrestMaster.Config.Escape.WarningTime
    
    -- Проигрываем звук в зависимости от типа предупреждения
    if type == "КРИТИЧЕСКАЯ" then
        surface.PlaySound(ArrestMaster.Config.Escape.Sounds.Alert)
    else
        surface.PlaySound(ArrestMaster.Config.Escape.Sounds.Warning)
    end
end)

-- Добавляем отрисовку оповещений
hook.Add("HUDPaint", "ArrestMaster_EscapeAlerts", function()
    local y = 100
    for i, alert in ipairs(escapeAlerts) do
        -- Вычисляем прозрачность
        local timeLeft = alertDuration - (CurTime() - alert.startTime)
        local alpha = math.Clamp(timeLeft * 25.5, 0, 255)
        
        -- Фон оповещения
        draw.RoundedBox(8, 10, y, 300, 80, Color(0, 0, 0, alpha * 0.8))
        
        -- Иконка тюрьмы
        surface.SetDrawColor(255, 59, 48, alpha)
        surface.SetMaterial(Material("icon16/lock.png"))
        surface.DrawTexturedRect(20, y + 10, 24, 24)
        
        -- Текст оповещения
        draw.SimpleText("ПОПЫТКА ПОБЕГА!", "ArrestMaster_Header", 50, y + 10, Color(255, 59, 48, alpha))
        draw.SimpleText(alert.message, "ArrestMaster_Normal", 20, y + 40, Color(255, 255, 255, alpha))
        
        -- Индикатор расстояния
        local distanceColor = Color(255, 59, 48, alpha)
        if alert.distance < 200 then
            distanceColor = Color(255, 193, 7, alpha)
        elseif alert.distance < 500 then
            distanceColor = Color(255, 149, 0, alpha)
        end
        draw.SimpleText(string.format("Расстояние: %.1f", alert.distance), "ArrestMaster_Small", 20, y + 60, distanceColor)
        
        y = y + 90
    end
end)

-- Добавляем звуковой эффект при получении оповещения
hook.Add("InitPostEntity", "ArrestMaster_LoadSounds", function()
    if not file.Exists("sound/ambient/alarms/klaxon1.wav", "GAME") then
        util.DownloadFile("https://raw.githubusercontent.com/garrynewman/garrysmod/master/garrysmod/sound/ambient/alarms/klaxon1.wav", "sound/ambient/alarms/klaxon1.wav")
    end
end)

-- Функция для отображения предупреждения
local function DrawEscapeWarning()
    if not escapeWarning.active then return end
    
    local alpha = 255
    local timeLeft = escapeWarning.fadeTime - CurTime()
    
    if timeLeft > 0 then
        alpha = math.Clamp(timeLeft * 255 / ArrestMaster.Config.Escape.WarningTime, 0, 255)
    else
        escapeWarning.active = false
        return
    end
    
    local w, h = ScrW(), ScrH()
    local config = ArrestMaster.Config.Escape.UI
    
    -- Рисуем фон
    surface.SetDrawColor(config.BackgroundColor.r, config.BackgroundColor.g, config.BackgroundColor.b, alpha)
    surface.DrawRect(w/2 - 200, h - 150, 400, 100)
    
    -- Рисуем текст
    local text = escapeWarning.text
    surface.SetFont("ArrestMaster_HUD")
    local textW, textH = surface.GetTextSize(text)
    
    draw.SimpleText(text, "ArrestMaster_HUD", w/2, h - 100, 
        Color(config.TextColor.r, config.TextColor.g, config.TextColor.b, alpha), 
        TEXT_ALIGN_CENTER)
end

-- Добавляем хук для отрисовки предупреждений
hook.Add("HUDPaint", "ArrestMaster_EscapeWarning", DrawEscapeWarning)

-- Создание меню мини-игр
local function CreateMinigameMenu()
    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 600)
    frame:SetTitle("Мини-игры")
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:Center()
    frame:MakePopup()
    
    -- Панель с информацией
    local infoPanel = vgui.Create("DPanel", frame)
    infoPanel:SetPos(10, 30)
    infoPanel:SetSize(780, 60)
    infoPanel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
        draw.SimpleText("Выберите мини-игру для уменьшения времени заключения", "DermaLarge", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Сетка мини-игр
    local grid = vgui.Create("DGrid", frame)
    grid:SetPos(10, 100)
    grid:SetSize(780, 480)
    grid:SetCols(2)
    grid:SetColWide(380)
    grid:SetRowHeight(200)
    
    -- Создание карточек мини-игр
    local games = {
        {
            name = "Игра на память",
            desc = "Найдите все пары карточек",
            icon = "icon16/brain.png",
            timeReduction = 5
        },
        {
            name = "Математическая игра",
            desc = "Решите математические примеры",
            icon = "icon16/calculator.png",
            timeReduction = 3
        },
        {
            name = "Игра на набор текста",
            desc = "Наберите текст как можно быстрее",
            icon = "icon16/keyboard.png",
            timeReduction = 2
        },
        {
            name = "Пазл",
            desc = "Соберите картинку из частей",
            icon = "icon16/puzzle.png",
            timeReduction = 4
        }
    }
    
    for _, game in ipairs(games) do
        local card = vgui.Create("DPanel", grid)
        card:SetSize(360, 180)
        card.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
            draw.SimpleText(game.name, "DermaLarge", w/2, 40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(game.desc, "DermaDefault", w/2, 70, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Уменьшение времени: " .. game.timeReduction .. " минут", "DermaDefault", w/2, 90, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Кнопка запуска игры
        local button = vgui.Create("DButton", card)
        button:SetSize(200, 40)
        button:SetPos(80, 120)
        button:SetText("Играть")
        button.DoClick = function()
            net.Start("ArrestMaster_RequestMinigame")
                net.WriteString(game.name)
            net.SendToServer()
        end
        
        grid:AddItem(card)
    end
end

-- Обработчик открытия меню мини-игр
net.Receive("ArrestMaster_OpenMinigameMenu", function()
    CreateMinigameMenu()
end) 