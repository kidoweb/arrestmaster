if SERVER then
    -- Серверные файлы
    AddCSLuaFile("arrestmaster/config.lua")
    AddCSLuaFile("arrestmaster/cl_init.lua")
    
    -- Загружаем конфиг и серверные файлы
    include("arrestmaster/config.lua")
    include("arrestmaster/init.lua")
    
    print("[ArrestMaster] Server files loaded!")
end

if CLIENT then
    -- Клиентские файлы
    include("arrestmaster/config.lua")
    include("arrestmaster/cl_init.lua")
    
    print("[ArrestMaster] Client files loaded!")
end

print("[ArrestMaster] Loader executed!") 