# Переводы ArrestMaster

## Поддерживаемые языки

### Русский (ru)
- Статус: Полный
- Версия: 1.0.0
- Автор: [Vadim]

### English (en)
- Статус: Полный
- Версия: 1.0.0
- Автор: [Vadim]

## Структура переводов

### Основные строки
```lua
arrestmaster.translations = {
    ["ru"] = {
        ["arrest"] = "Арест",
        ["release"] = "Освобождение",
        ["escape"] = "Побег",
        ["minigame"] = "Мини-игра",
        ["camera"] = "Камера",
        ["notification"] = "Уведомление",
        ["log"] = "Лог",
        ["settings"] = "Настройки"
    },
    ["en"] = {
        ["arrest"] = "Arrest",
        ["release"] = "Release",
        ["escape"] = "Escape",
        ["minigame"] = "Minigame",
        ["camera"] = "Camera",
        ["notification"] = "Notification",
        ["log"] = "Log",
        ["settings"] = "Settings"
    }
}
```

### Системные сообщения
```lua
arrestmaster.messages = {
    ["ru"] = {
        ["player_arrested"] = "Игрок %s был арестован на %d секунд",
        ["player_released"] = "Игрок %s был освобожден",
        ["player_escaped"] = "Игрок %s сбежал из тюрьмы",
        ["minigame_completed"] = "Мини-игра завершена! Награда: %d секунд",
        ["camera_added"] = "Камера добавлена",
        ["camera_removed"] = "Камера удалена",
        ["notification_sent"] = "Уведомление отправлено",
        ["log_created"] = "Лог создан"
    },
    ["en"] = {
        ["player_arrested"] = "Player %s was arrested for %d seconds",
        ["player_released"] = "Player %s was released",
        ["player_escaped"] = "Player %s escaped from jail",
        ["minigame_completed"] = "Minigame completed! Reward: %d seconds",
        ["camera_added"] = "Camera added",
        ["camera_removed"] = "Camera removed",
        ["notification_sent"] = "Notification sent",
        ["log_created"] = "Log created"
    }
}
```

### Ошибки
```lua
arrestmaster.errors = {
    ["ru"] = {
        ["player_not_found"] = "Игрок не найден",
        ["invalid_time"] = "Неверное время",
        ["invalid_reason"] = "Неверная причина",
        ["player_already_arrested"] = "Игрок уже арестован",
        ["player_not_arrested"] = "Игрок не арестован",
        ["minigame_not_found"] = "Мини-игра не найдена",
        ["camera_not_found"] = "Камера не найдена",
        ["notification_failed"] = "Ошибка отправки уведомления",
        ["log_failed"] = "Ошибка создания лога"
    },
    ["en"] = {
        ["player_not_found"] = "Player not found",
        ["invalid_time"] = "Invalid time",
        ["invalid_reason"] = "Invalid reason",
        ["player_already_arrested"] = "Player is already arrested",
        ["player_not_arrested"] = "Player is not arrested",
        ["minigame_not_found"] = "Minigame not found",
        ["camera_not_found"] = "Camera not found",
        ["notification_failed"] = "Failed to send notification",
        ["log_failed"] = "Failed to create log"
    }
}
```

## Добавление нового языка

### Создание файла перевода
```lua
-- lua/arrestmaster/languages/de.lua
arrestmaster.translations["de"] = {
    ["arrest"] = "Verhaftung",
    ["release"] = "Freilassung",
    ["escape"] = "Flucht",
    ["minigame"] = "Minispiel",
    ["camera"] = "Kamera",
    ["notification"] = "Benachrichtigung",
    ["log"] = "Protokoll",
    ["settings"] = "Einstellungen"
}
```

### Регистрация языка
```lua
-- lua/arrestmaster/shared.lua
arrestmaster.RegisterLanguage("de", "Deutsch")
```

## Использование переводов

### Получение перевода
```lua
local translation = arrestmaster.GetTranslation("arrest", "ru")
```

### Форматирование сообщения
```lua
local message = arrestmaster.FormatMessage("player_arrested", "ru", {name = "Player", time = 60})
```

### Проверка языка
```lua
if arrestmaster.IsLanguageSupported("ru") then
    -- Код для русского языка
end
```

## Планируемые языки

### Высокий приоритет
- Украинский (uk)
- Белорусский (be)
- Казахский (kk)

### Средний приоритет
- Немецкий (de)
- Французский (fr)
- Испанский (es)

### Низкий приоритет
- Китайский (zh)
- Японский (ja)
- Корейский (ko)

## Контакты

Для вопросов по переводам:
- GitHub Issues
- Steam: [profile]
- Discord: [server] 