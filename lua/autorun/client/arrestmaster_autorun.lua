print("[ArrestMaster] Starting autorun initialization...")

-- Базовая инициализация
ArrestMaster = ArrestMaster or {}

-- Загрузка файлов
if CLIENT then
    print("[ArrestMaster] Loading client files...")
    
    -- Загружаем конфиг
    include("arrestmaster/config.lua")
    print("[ArrestMaster] Config loaded:", ArrestMaster.Config ~= nil)
    
    -- Загружаем клиентские файлы
    include("arrestmaster/cl_init.lua")
    
    -- Регистрируем команды
    concommand.Add("am_test", function(ply)
        print("[ArrestMaster] Test command executed by", ply)
        if ArrestMaster and ArrestMaster.CreateMenu then
            ArrestMaster.CreateMenu()
        else
            print("[ArrestMaster] Error: Menu creation failed!")
            print("ArrestMaster table contents:", table.ToString(ArrestMaster))
        end
    end)
    
    -- Добавляем команду перезагрузки
    concommand.Add("am_reload", function()
        print("[ArrestMaster] Reloading addon...")
        include("arrestmaster/config.lua")
        include("arrestmaster/cl_init.lua")
        print("[ArrestMaster] Reload complete!")
    end)
    
    print("[ArrestMaster] Client initialization complete!")
end

if SERVER then
    print("[ArrestMaster] Adding client files...")
    AddCSLuaFile("arrestmaster/config.lua")
    AddCSLuaFile("arrestmaster/cl_init.lua")
    
    -- Загружаем серверные файлы
    include("arrestmaster/init.lua")
    print("[ArrestMaster] Server initialization complete!")
end 