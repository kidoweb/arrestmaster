--[[
    ArrestMaster LuaRocks Configuration
    Автор: [Vadim]
    Версия: 1.0.0
    Дата: 2024-03-XX
]]

local rockspec = {
    package = "arrestmaster",
    version = "1.0.0-1",
    source = {
        url = "https://github.com/yourusername/arrestmaster/archive/v1.0.0.tar.gz",
        md5 = "00000000000000000000000000000000"
    },
    description = {
        summary = "Система арестов для Garry's Mod с мини-играми и системой побега",
        detailed = [[
            ArrestMaster - это аддон для Garry's Mod, который добавляет расширенную систему арестов
            с мини-играми, системой побега и другими функциями.
        ]],
        homepage = "https://github.com/yourusername/arrestmaster",
        license = "MIT",
        maintainer = "Vadim"
    },
    dependencies = {
        "lua >= 5.1",
        "darkrp >= 2.6.0",
        "ulx >= 3.70",
        "ulib >= 2.60"
    },
    build = {
        type = "builtin",
        modules = {
            ["arrestmaster"] = "lua/arrestmaster/init.lua",
            ["arrestmaster.config"] = "lua/arrestmaster/config.lua",
            ["arrestmaster.core"] = "lua/arrestmaster/core.lua",
            ["arrestmaster.ui"] = "lua/arrestmaster/ui.lua",
            ["arrestmaster.minigames"] = "lua/arrestmaster/minigames.lua",
            ["arrestmaster.escape"] = "lua/arrestmaster/escape.lua",
            ["arrestmaster.cameras"] = "lua/arrestmaster/cameras.lua",
            ["arrestmaster.logging"] = "lua/arrestmaster/logging.lua",
            ["arrestmaster.notifications"] = "lua/arrestmaster/notifications.lua"
        }
    }
}

-- Функция для создания rockspec файла
local function CreateRockspec()
    local content = [[
package = "arrestmaster"
version = "1.0.0-1"
source = {
    url = "https://github.com/yourusername/arrestmaster/archive/v1.0.0.tar.gz",
    md5 = "00000000000000000000000000000000"
}
description = {
    summary = "Система арестов для Garry's Mod с мини-играми и системой побега",
    detailed = [[
        ArrestMaster - это аддон для Garry's Mod, который добавляет расширенную систему арестов
        с мини-играми, системой побега и другими функциями.
    ]],
    homepage = "https://github.com/yourusername/arrestmaster",
    license = "MIT",
    maintainer = "Vadim"
}
dependencies = {
    "lua >= 5.1",
    "darkrp >= 2.6.0",
    "ulx >= 3.70",
    "ulib >= 2.60"
}
build = {
    type = "builtin",
    modules = {
        ["arrestmaster"] = "lua/arrestmaster/init.lua",
        ["arrestmaster.config"] = "lua/arrestmaster/config.lua",
        ["arrestmaster.core"] = "lua/arrestmaster/core.lua",
        ["arrestmaster.ui"] = "lua/arrestmaster/ui.lua",
        ["arrestmaster.minigames"] = "lua/arrestmaster/minigames.lua",
        ["arrestmaster.escape"] = "lua/arrestmaster/escape.lua",
        ["arrestmaster.cameras"] = "lua/arrestmaster/cameras.lua",
        ["arrestmaster.logging"] = "lua/arrestmaster/logging.lua",
        ["arrestmaster.notifications"] = "lua/arrestmaster/notifications.lua"
    }
}
]]
    
    file.Write("arrestmaster-1.0.0-1.rockspec", content)
end

-- Функция для установки зависимостей
local function InstallDependencies()
    print("Установка зависимостей...")
    
    -- Установка DarkRP
    os.execute("luarocks install darkrp 2.6.0")
    
    -- Установка ULX
    os.execute("luarocks install ulx 3.70")
    
    -- Установка ULib
    os.execute("luarocks install ulib 2.60")
    
    print("Зависимости установлены!")
end

-- Функция для удаления зависимостей
local function RemoveDependencies()
    print("Удаление зависимостей...")
    
    -- Удаление DarkRP
    os.execute("luarocks remove darkrp")
    
    -- Удаление ULX
    os.execute("luarocks remove ulx")
    
    -- Удаление ULib
    os.execute("luarocks remove ulib")
    
    print("Зависимости удалены!")
end

-- Функция для обновления зависимостей
local function UpdateDependencies()
    print("Обновление зависимостей...")
    
    -- Обновление DarkRP
    os.execute("luarocks update darkrp")
    
    -- Обновление ULX
    os.execute("luarocks update ulx")
    
    -- Обновление ULib
    os.execute("luarocks update ulib")
    
    print("Зависимости обновлены!")
end

-- Функция для проверки зависимостей
local function CheckDependencies()
    print("Проверка зависимостей...")
    
    -- Проверка DarkRP
    local darkrp = require("darkrp")
    if not darkrp then
        print("Ошибка: DarkRP не установлен!")
        return false
    end
    
    -- Проверка ULX
    local ulx = require("ulx")
    if not ulx then
        print("Ошибка: ULX не установлен!")
        return false
    end
    
    -- Проверка ULib
    local ulib = require("ulib")
    if not ulib then
        print("Ошибка: ULib не установлен!")
        return false
    end
    
    print("Все зависимости установлены!")
    return true
end

-- Функция для сборки проекта
local function Build()
    print("Сборка проекта...")
    
    -- Создание rockspec
    CreateRockspec()
    
    -- Установка зависимостей
    InstallDependencies()
    
    -- Проверка зависимостей
    if not CheckDependencies() then
        print("Ошибка: Не все зависимости установлены!")
        return false
    end
    
    -- Сборка проекта
    os.execute("luarocks build arrestmaster-1.0.0-1.rockspec")
    
    print("Проект собран!")
    return true
end

-- Функция для очистки проекта
local function Clean()
    print("Очистка проекта...")
    
    -- Удаление rockspec
    file.Delete("arrestmaster-1.0.0-1.rockspec")
    
    -- Удаление зависимостей
    RemoveDependencies()
    
    print("Проект очищен!")
end

-- Экспорт функций
return {
    Build = Build,
    Clean = Clean,
    InstallDependencies = InstallDependencies,
    RemoveDependencies = RemoveDependencies,
    UpdateDependencies = UpdateDependencies,
    CheckDependencies = CheckDependencies
} 