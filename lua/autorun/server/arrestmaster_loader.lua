if SERVER then
    -- Загружаем серверные файлы
    include("arrestmaster/init.lua")
    include("arrestmaster/config.lua")
    
    -- Добавляем клиентские файлы
    AddCSLuaFile("arrestmaster/cl_init.lua")
    AddCSLuaFile("arrestmaster/config.lua")
    
    -- Сетевые строки
    util.AddNetworkString("ArrestMaster_OpenMenu")
    util.AddNetworkString("ArrestMaster_CheckPermission")
    
    -- Обработчик проверки прав
    net.Receive("ArrestMaster_CheckPermission", function(len, ply)
        if ArrestMaster.HasPermission(ply) then
            net.Start("ArrestMaster_OpenMenu")
            net.Send(ply)
        else
            ply:ChatPrint("[ArrestMaster] У вас нет прав для использования этой команды!")
        end
    end)
end

if CLIENT then
    -- Загружаем клиентские файлы
    include("arrestmaster/config.lua")
    include("arrestmaster/cl_init.lua")
end 