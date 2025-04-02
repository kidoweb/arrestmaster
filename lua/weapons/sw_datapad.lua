if ( SERVER ) then
	AddCSLuaFile( "sw_datapad.lua" )
	SWEP.HoldType = "slam"
end

if ( CLIENT ) then
	SWEP.PrintName = "Датапад УСБ"
	SWEP.Author = "StellarisTECH"
	SWEP.Contact = ""
	SWEP.Purpose = "Система управления арестами"
	SWEP.Instructions = "ЛКМ - Открыть меню арестов"
	SWEP.Slot = 1
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	
	-- Добавляем иконку для оружия
	SWEP.Icon = "vgui/ttt/icon_datapad"
	
	-- Добавляем описание
	SWEP.Description = "Специальное устройство для управления системой арестов УСБ"
end

SWEP.Category = "УСБ"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = false

SWEP.ViewModelFOV = 50
SWEP.ViewModel = "models/swcw_items/sw_datapad_v.mdl" 
SWEP.WorldModel = "models/swcw_items/sw_datapad.mdl"
SWEP.ViewModelFlip = false

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false

SWEP.UseHands = true

SWEP.HoldType = "slam" 

SWEP.FiresUnderwater = true

SWEP.DrawCrosshair = true

SWEP.DrawAmmo = false

SWEP.Base = "weapon_base"

-- Настройки основного огня
SWEP.Primary = {
	Damage = 0,
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none"
}

-- Настройки вторичного огня
SWEP.Secondary = {
	ClipSize = -1,
	DefaultClip = -1,
	Damage = 0,
	Automatic = false,
	Ammo = "none"
}

-- Звуки
SWEP.Sounds = {
	Open = "buttons/button15.wav",
	Close = "buttons/button16.wav",
	Error = "buttons/button11.wav"
}

-- Анимации
SWEP.Animations = {
	Idle = "idle",
	Open = "open",
	Close = "close"
}

function SWEP:Initialize() 
	self:SetWeaponHoldType("slam")
	
	if CLIENT then
		-- Создаем шрифт для HUD
		surface.CreateFont("Datapad_HUD", {
			font = "Roboto",
			size = 24,
			weight = 500,
			antialias = true
		})
	end
end 

function SWEP:PrimaryAttack()
	if CLIENT then
		-- Проверяем, не слишком ли быстро нажимается кнопка
		if CurTime() < (self.NextSoundTime or 0) then return end
		
		-- Отправляем запрос на открытие меню
		net.Start("ArrestMaster_RequestMenu")
		net.SendToServer()
		
		-- Проигрываем звук для обратной связи
		surface.PlaySound("buttons/button15.wav")
		
		-- Устанавливаем время следующего возможного воспроизведения звука
		self.NextSoundTime = CurTime() + 0.5
	end
	
	-- Устанавливаем задержку между использованиями
	self:SetNextPrimaryFire(CurTime() + 0.5)
end

function SWEP:SecondaryAttack()
	return false
end

function SWEP:Reload()
	return false
end

-- Добавляем отрисовку HUD
if CLIENT then
	function SWEP:DrawHUD()
		local x, y = ScrW() * 0.5, ScrH() * 0.5
		
		-- Рисуем прицел
		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawCircle(x, y, 5, 255, 255, 255, 200)
		surface.DrawCircle(x, y, 10, 255, 255, 255, 100)
		
		-- Рисуем подсказку
		local text = "ЛКМ - Меню арестов"
		surface.SetFont("Datapad_HUD")
		local w, h = surface.GetTextSize(text)
		draw.SimpleText(text, "Datapad_HUD", x - w/2, y + 30, Color(255, 255, 255, 200), TEXT_ALIGN_CENTER)
	end
end

