local PANEL = {}

-- Colors
local COLORS = {
    background = Color(0, 0, 0, 200),
    header = Color(40, 40, 40, 255),
    button = Color(60, 60, 60, 255),
    buttonHover = Color(80, 80, 80, 255),
    text = Color(255, 255, 255, 255),
    accent = Color(255, 59, 48, 255),
    success = Color(52, 199, 89, 255)
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

function PANEL:Init()
    self:SetSize(400, 500)
    self:Center()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.2, 0)
    
    -- Заголовок
    self.header = self:Add("DPanel")
    self.header:Dock(TOP)
    self.header:SetHeight(40)
    self.header.Paint = function(p, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COLORS.header)
        draw.SimpleText("Система Ареста", "DermaLarge", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Кнопка закрытия
    self.closeBtn = self.header:Add("DButton")
    self.closeBtn:SetSize(30, 30)
    self.closeBtn:Dock(RIGHT)
    self.closeBtn:DockMargin(5, 5, 5, 5)
    self.closeBtn:SetText("")
    self.closeBtn.Paint = function(p, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.button)
        draw.SimpleText("X", "DermaLarge", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    self.closeBtn.DoClick = function()
        self:Close()
    end
    
    -- Панель контента
    self.content = self:Add("DPanel")
    self.content:Dock(FILL)
    self.content:DockMargin(10, 10, 10, 10)
    self.content.Paint = function(p, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.background)
    end
    
    -- Выпадающий список причин
    self.reasonLabel = self.content:Add("DLabel")
    self.reasonLabel:Dock(TOP)
    self.reasonLabel:SetHeight(30)
    self.reasonLabel:DockMargin(10, 10, 10, 0)
    self.reasonLabel:SetText("Причина:")
    self.reasonLabel:SetTextColor(COLORS.text)
    
    self.reasonCombo = self.content:Add("DComboBox")
    self.reasonCombo:Dock(TOP)
    self.reasonCombo:SetHeight(30)
    self.reasonCombo:DockMargin(10, 5, 10, 10)
    self.reasonCombo:SetValue("Выберите причину")
    
    for _, reason in ipairs(ARREST_REASONS) do
        self.reasonCombo:AddChoice(reason)
    end
    
    -- Поле для ввода своей причины
    self.customReason = self.content:Add("DTextEntry")
    self.customReason:Dock(TOP)
    self.customReason:SetHeight(30)
    self.customReason:DockMargin(10, 5, 10, 10)
    self.customReason:SetPlaceholderText("Введите свою причину")
    self.customReason:SetVisible(false)
    
    -- Ввод времени
    self.timeLabel = self.content:Add("DLabel")
    self.timeLabel:Dock(TOP)
    self.timeLabel:SetHeight(30)
    self.timeLabel:DockMargin(10, 10, 10, 0)
    self.timeLabel:SetText("Время заключения (минуты):")
    self.timeLabel:SetTextColor(COLORS.text)
    
    self.timeEntry = self.content:Add("DNumberWang")
    self.timeEntry:Dock(TOP)
    self.timeEntry:SetHeight(30)
    self.timeEntry:DockMargin(10, 5, 10, 10)
    self.timeEntry:SetMinMax(1, 1440) -- от 1 минуты до 24 часов
    
    -- Кнопка ареста
    self.arrestBtn = self.content:Add("DButton")
    self.arrestBtn:Dock(TOP)
    self.arrestBtn:SetHeight(40)
    self.arrestBtn:DockMargin(10, 20, 10, 10)
    self.arrestBtn:SetText("АРЕСТОВАТЬ")
    self.arrestBtn:SetTextColor(COLORS.text)
    self.arrestBtn.Paint = function(p, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.button)
        if p:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, COLORS.buttonHover)
        end
    end
    self.arrestBtn.DoClick = function()
        local reason = self.reasonCombo:GetValue()
        if reason == "Другое" then
            reason = self.customReason:GetValue()
        end
        local time = self.timeEntry:GetValue()
        
        if reason == "Выберите причину" then
            notification.AddLegacy("Пожалуйста, выберите причину!", NOTIFY_ERROR, 3)
            return
        end
        
        net.Start("ArrestMaster_Arrest")
            net.WriteString(reason)
            net.WriteUInt(time, 16)
        net.SendToServer()
        
        self:Close()
    end
    
    -- Хук для изменений в выпадающем списке
    self.reasonCombo.OnSelect = function(p, index, value)
        self.customReason:SetVisible(value == "Другое")
    end
end

function PANEL:Close()
    self:AlphaTo(0, 0.2, 0, function()
        self:Remove()
    end)
end

vgui.Register("ArrestMaster_Menu", PANEL, "DFrame")

-- 3D Меню
local function Create3DMenu()
    local frame = vgui.Create("ArrestMaster_Menu")
    frame:SetPos(ScrW()/2 - 200, ScrH()/2 - 250)
end

-- Привязка клавиши
hook.Add("Initialize", "ArrestMaster_Init", function()
    bind.Register("arrest_menu", function()
        local tr = LocalPlayer():GetEyeTrace()
        local ent = tr.Entity
        
        if IsValid(ent) and ent:IsPlayer() and ent:GetPos():Distance(LocalPlayer():GetPos()) <= 100 then
            Create3DMenu()
        else
            notification.AddLegacy("Нет подходящего игрока для ареста!", NOTIFY_ERROR, 3)
        end
    end)
end)

-- UI для привязки клавиши
hook.Add("PopulateToolMenu", "ArrestMaster_ToolMenu", function()
    spawnmenu.AddToolMenuOption("Опции", "ArrestMaster", "Меню Ареста", "Открыть меню ареста", "", "", function(panel)
        panel:ClearControls()
        panel:Button("Назначить клавишу меню ареста", "arrest_menu")
    end)
end)

-- Добавляем новую функцию для создания меню досрочного освобождения
local function CreateReleaseMenu(target)
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 300)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.2, 0)
    
    -- Заголовок
    local header = frame:Add("DPanel")
    header:Dock(TOP)
    header:SetHeight(40)
    header.Paint = function(p, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COLORS.header)
        draw.SimpleText("Досрочное Освобождение", "DermaLarge", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Кнопка закрытия
    local closeBtn = header:Add("DButton")
    closeBtn:SetSize(30, 30)
    closeBtn:Dock(RIGHT)
    closeBtn:DockMargin(5, 5, 5, 5)
    closeBtn:SetText("")
    closeBtn.Paint = function(p, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.button)
        draw.SimpleText("X", "DermaLarge", w/2, h/2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        frame:Close()
    end
    
    -- Контент
    local content = frame:Add("DPanel")
    content:Dock(FILL)
    content:DockMargin(10, 10, 10, 10)
    content.Paint = function(p, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.background)
    end
    
    -- Причина освобождения
    local reasonLabel = content:Add("DLabel")
    reasonLabel:Dock(TOP)
    reasonLabel:SetHeight(30)
    reasonLabel:DockMargin(10, 10, 10, 0)
    reasonLabel:SetText("Причина освобождения:")
    reasonLabel:SetTextColor(COLORS.text)
    
    local reasonCombo = content:Add("DComboBox")
    reasonCombo:Dock(TOP)
    reasonCombo:SetHeight(30)
    reasonCombo:DockMargin(10, 5, 10, 10)
    reasonCombo:SetValue("Выберите причину")
    
    for _, reason in ipairs(RELEASE_REASONS) do
        reasonCombo:AddChoice(reason)
    end
    
    -- Поле для ввода своей причины
    local customReason = content:Add("DTextEntry")
    customReason:Dock(TOP)
    customReason:SetHeight(30)
    customReason:DockMargin(10, 5, 10, 10)
    customReason:SetPlaceholderText("Введите свою причину")
    customReason:SetVisible(false)
    
    -- Кнопка освобождения
    local releaseBtn = content:Add("DButton")
    releaseBtn:Dock(TOP)
    releaseBtn:SetHeight(40)
    releaseBtn:DockMargin(10, 20, 10, 10)
    releaseBtn:SetText("ОСВОБОДИТЬ")
    releaseBtn:SetTextColor(COLORS.text)
    releaseBtn.Paint = function(p, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COLORS.success)
        if p:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(COLORS.success.r + 20, COLORS.success.g + 20, COLORS.success.b + 20, 255))
        end
    end
    releaseBtn.DoClick = function()
        local reason = reasonCombo:GetValue()
        if reason == "Другое" then
            reason = customReason:GetValue()
        end
        
        if reason == "Выберите причину" then
            notification.AddLegacy("Пожалуйста, выберите причину!", NOTIFY_ERROR, 3)
            return
        end
        
        net.Start("ArrestMaster_EarlyRelease")
            net.WriteEntity(target)
            net.WriteString(reason)
        net.SendToServer()
        
        frame:Close()
    end
    
    -- Хук для изменений в выпадающем списке
    reasonCombo.OnSelect = function(p, index, value)
        customReason:SetVisible(value == "Другое")
    end
    
    function frame:Close()
        self:AlphaTo(0, 0.2, 0, function()
            self:Remove()
        end)
    end
end

-- Добавляем проверку на возможность освобождения при наведении на игрока
hook.Add("HUDPaint", "ArrestMaster_ReleaseCheck", function()
    local tr = LocalPlayer():GetEyeTrace()
    local ent = tr.Entity
    
    if IsValid(ent) and ent:IsPlayer() and ent:GetPos():Distance(LocalPlayer():GetPos()) <= 100 then
        if ent:GetNWInt("ArrestMaster_JailTime", 0) > 0 then
            draw.SimpleText("Нажмите F4 для досрочного освобождения", "Default", ScrW()/2, ScrH() - 100, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
        end
    end
end)

-- Добавляем привязку клавиши для освобождения
hook.Add("Initialize", "ArrestMaster_ReleaseInit", function()
    bind.Register("release_menu", function()
        local tr = LocalPlayer():GetEyeTrace()
        local ent = tr.Entity
        
        if IsValid(ent) and ent:IsPlayer() and ent:GetPos():Distance(LocalPlayer():GetPos()) <= 100 then
            if ent:GetNWInt("ArrestMaster_JailTime", 0) > 0 then
                CreateReleaseMenu(ent)
            else
                notification.AddLegacy("Этот игрок не находится в камере!", NOTIFY_ERROR, 3)
            end
        else
            notification.AddLegacy("Нет подходящего игрока для освобождения!", NOTIFY_ERROR, 3)
        end
    end)
end)

-- Добавляем опцию в меню настроек
hook.Add("PopulateToolMenu", "ArrestMaster_ReleaseMenu", function()
    spawnmenu.AddToolMenuOption("Опции", "ArrestMaster", "Меню Освобождения", "Открыть меню досрочного освобождения", "", "", function(panel)
        panel:ClearControls()
        panel:Button("Назначить клавишу освобождения", "release_menu")
    end)
end) 