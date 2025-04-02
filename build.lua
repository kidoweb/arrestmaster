--[[
    ArrestMaster Build Script
    Автор: [Vadim]
    Версия: 1.0.0
    Дата: 2024-03-XX
]]

local function CreateBuildDirectory()
    if not file.Exists("build", "DATA") then
        file.CreateDir("build")
    end
end

local function CleanBuildDirectory()
    local files = file.Find("build/*", "DATA")
    for _, f in ipairs(files) do
        file.Delete("build/" .. f)
    end
end

local function CopyFiles()
    -- Копирование Lua файлов
    local luaFiles = file.Find("lua/*", "DATA")
    for _, f in ipairs(luaFiles) do
        file.CreateDir("build/lua")
        file.Copy("lua/" .. f, "build/lua/" .. f)
    end
    
    -- Копирование материалов
    local materialFiles = file.Find("materials/*", "DATA")
    for _, f in ipairs(materialFiles) do
        file.CreateDir("build/materials")
        file.Copy("materials/" .. f, "build/materials/" .. f)
    end
    
    -- Копирование звуков
    local soundFiles = file.Find("sound/*", "DATA")
    for _, f in ipairs(soundFiles) do
        file.CreateDir("build/sound")
        file.Copy("sound/" .. f, "build/sound/" .. f)
    end
end

local function CreateAddonInfo()
    local info = {
        title = "ArrestMaster",
        type = "tool",
        tags = "fun,roleplay,admin",
        ignore = {
            "*.psd",
            "*.vcproj",
            "*.sln",
            "*.git*",
            "*.svn*",
            "*.DS_Store",
            "Thumbs.db",
            "desktop.ini"
        },
        dependencies = {
            "darkrp"
        }
    }
    
    file.Write("build/addon.json", util.TableToJSON(info, true))
end

local function CreateVersionFile()
    file.Write("build/VERSION", "1.0.0")
end

local function CreateChangelog()
    local changelog = [[
# Changelog

## [1.0.0] - 2024-03-XX

### Добавлено
- Система арестов
- Мини-игры
- Система побега
- Система камер
- Система логирования
- Система уведомлений
- Поддержка УСБ
- Система безопасности

### Изменено
- Оптимизация производительности
- Улучшение интерфейса
- Новые настройки

### Исправлено
- Ошибки в системе побега
- Ошибки в мини-играх
- Ошибки в системе логирования

### Удалено
- Устаревшие функции
- Неиспользуемые настройки

### Безопасность
- Проверки доступа
- Улучшенная система анти-чит
- Защита от эксплойтов

### Зависимости
- Поддержка DarkRP
- Обновление зависимостей
]]
    
    file.Write("build/CHANGELOG.md", changelog)
end

local function CreateLicense()
    local license = [[
MIT License

Copyright (c) 2024 Vadim

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
    
    file.Write("build/LICENSE", license)
end

local function CreateReadme()
    local readme = [[
# ArrestMaster

Система арестов для Garry's Mod с мини-играми и системой побега.

## Возможности

- Система арестов
- Мини-игры
- Система побега
- Система камер
- Система логирования
- Система уведомлений
- Поддержка УСБ
- Система безопасности

## Установка

1. Скачайте последнюю версию
2. Распакуйте в папку `garrysmod/addons/arrestmaster/`
3. Перезапустите сервер

## Настройка

1. Откройте `config.lua`
2. Настройте параметры
3. Сохраните файл

## Команды

- `arrest <игрок> <время> <причина>` - Арестовать игрока
- `release <игрок>` - Освободить игрока
- `arrestinfo <игрок>` - Информация об аресте
- `minigame <игрок> <тип>` - Запустить мини-игру
- `escape <игрок>` - Попытка побега
- `camera <add/remove/list>` - Управление камерами

## Мини-игры

- Головоломка
- Реакция
- Память
- Логика

## Требования

- Garry's Mod
- DarkRP (опционально)
- ULX/ULib (опционально)

## Лицензия

MIT License

## Автор

Vadim

## Поддержка

- GitHub Issues
- Steam: [profile]
- Discord: [server]
]]
    
    file.Write("build/README.md", readme)
end

local function Build()
    print("Начало сборки...")
    
    -- Создание директории
    CreateBuildDirectory()
    
    -- Очистка директории
    CleanBuildDirectory()
    
    -- Копирование файлов
    CopyFiles()
    
    -- Создание файлов
    CreateAddonInfo()
    CreateVersionFile()
    CreateChangelog()
    CreateLicense()
    CreateReadme()
    
    print("Сборка завершена!")
end

-- Запуск сборки
Build() 