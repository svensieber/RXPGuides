local _, addon = ...

-- Locale System für Turtle WoW
-- Basiert auf GetLocale() das auch in 1.12 verfügbar ist

-- Nur auf Turtle WoW ausführen
if not addon.isTurtleWoW then return end

addon.L = {}
local L = addon.L

-- Sprache erkennen
addon.locale = GetLocale()

-- Fallback auf Englisch
setmetatable(L, {
    __index = function(self, key)
        return key
    end
})

-- Deutsche Übersetzungen
if addon.locale == "deDE" then
    L["Loaded"] = "Geladen"
    L["Debug Mode"] = "Debug-Modus"
    L["Version"] = "Version"
    L["Help"] = "Hilfe"
    L["Unknown command"] = "Unbekannter Befehl"
    L["Available commands"] = "Verfügbare Befehle"
    L["Test successful"] = "Test erfolgreich"
    L["ON"] = "AN"
    L["OFF"] = "AUS"
    L["Turtle WoW Version"] = "Turtle WoW Version"
    L["pfQuest found - Navigation enabled"] = "pfQuest gefunden - Navigation wird aktiviert"
    L["pfQuest not found - Navigation limited"] = "pfQuest nicht gefunden - Navigation eingeschränkt"
    L["Turtle WoW server detected"] = "Turtle WoW Server erkannt"
    
    -- Guide-bezogene Strings
    L["Accept"] = "Annehmen"
    L["Turn in"] = "Abgeben"
    L["Kill"] = "Töte"
    L["Collect"] = "Sammle"
    L["Go to"] = "Gehe zu"
    L["Speak with"] = "Sprich mit"
    L["Use"] = "Benutze"
    L["Buy"] = "Kaufe"
    L["Fly to"] = "Fliege nach"
    L["Set Hearthstone"] = "Setze Ruhestein"
    L["Use Hearthstone"] = "Benutze Ruhestein"
    L["Train"] = "Trainiere"
    L["Learn"] = "Lerne"
    L["Grind to level"] = "Grinde bis Level"
    
    -- UI Strings
    L["Next Step"] = "Nächster Schritt"
    L["Previous Step"] = "Vorheriger Schritt"
    L["Current Step"] = "Aktueller Schritt"
    L["Guide Window"] = "Guide Fenster"
    L["Settings"] = "Einstellungen"
    L["Close"] = "Schließen"
    L["Reset Position"] = "Position zurücksetzen"
    
    -- Fehler und Warnungen
    L["No guide loaded"] = "Kein Guide geladen"
    L["Guide not found"] = "Guide nicht gefunden"
    L["Invalid step"] = "Ungültiger Schritt"
    L["Quest not found in log"] = "Quest nicht im Log gefunden"
    L["Target not found"] = "Ziel nicht gefunden"
    L["You must be level %d"] = "Du musst Level %d sein"
end

-- Französische Übersetzungen
if addon.locale == "frFR" then
    L["Loaded"] = "Chargé"
    L["Debug Mode"] = "Mode Debug"
    L["Version"] = "Version"
    L["Help"] = "Aide"
    L["Unknown command"] = "Commande inconnue"
    L["Available commands"] = "Commandes disponibles"
    L["Test successful"] = "Test réussi"
    L["ON"] = "ACTIVÉ"
    L["OFF"] = "DÉSACTIVÉ"
end

-- Spanische Übersetzungen
if addon.locale == "esES" then
    L["Loaded"] = "Cargado"
    L["Debug Mode"] = "Modo Depuración"
    L["Version"] = "Versión"
    L["Help"] = "Ayuda"
    L["Unknown command"] = "Comando desconocido"
    L["Available commands"] = "Comandos disponibles"
    L["Test successful"] = "Prueba exitosa"
    L["ON"] = "ACTIVADO"
    L["OFF"] = "DESACTIVADO"
end

-- Russische Übersetzungen
if addon.locale == "ruRU" then
    L["Loaded"] = "Загружено"
    L["Debug Mode"] = "Режим отладки"
    L["Version"] = "Версия"
    L["Help"] = "Помощь"
    L["Unknown command"] = "Неизвестная команда"
    L["Available commands"] = "Доступные команды"
    L["Test successful"] = "Тест успешен"
    L["ON"] = "ВКЛ"
    L["OFF"] = "ВЫКЛ"
end

-- Chinesische Übersetzungen (Simplified)
if addon.locale == "zhCN" then
    L["Loaded"] = "已加载"
    L["Debug Mode"] = "调试模式"
    L["Version"] = "版本"
    L["Help"] = "帮助"
    L["Unknown command"] = "未知命令"
    L["Available commands"] = "可用命令"
    L["Test successful"] = "测试成功"
    L["ON"] = "开"
    L["OFF"] = "关"
end

-- Utility-Funktion für formatierte Übersetzungen
function addon:Localize(key, ...)
    local str = L[key] or key
    if arg and table.getn(arg) > 0 then
        return string.format(str, unpack(arg))
    end
    return str
end