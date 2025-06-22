-- In Lua 5.0 müssen wir die globale Variable nutzen
local addon = _G["RXPGuides"] or {}

-- Utility Funktionen für Turtle WoW / Lua 5.0


-- Lua 5.0 hat kein table.wipe
function addon.wipe(t)
    for k in pairs(t) do
        t[k] = nil
    end
    return t
end

-- Lua 5.0 kompatible table Funktionen
function addon.tContains(table, item)
    for i = 1, table.getn(table) do
        if table[i] == item then
            return true
        end
    end
    return false
end

-- Deep copy für Tables
function addon.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[addon.deepcopy(orig_key)] = addon.deepcopy(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

-- String split (Lua 5.0 hat kein string.split)
function addon.split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    
    while delim_from do
        tinsert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    
    tinsert(result, string.sub(str, from))
    return result
end

-- Timer System (C_Timer Ersatz)
addon.timers = {}
addon.timerFrame = CreateFrame("Frame")
addon.timerFrame:Hide()

local timerElapsed = 0
addon.timerFrame:SetScript("OnUpdate", function()
    timerElapsed = timerElapsed + arg1
    
    for id, timer in pairs(addon.timers) do
        timer.elapsed = timer.elapsed + arg1
        
        if timer.elapsed >= timer.duration then
            timer.callback()
            
            if timer.repeating then
                timer.elapsed = timer.elapsed - timer.duration
            else
                addon.timers[id] = nil
            end
        end
    end
    
    -- Frame verstecken wenn keine Timer aktiv
    if not next(addon.timers) then
        addon.timerFrame:Hide()
    end
end)

local timerId = 0
function addon:ScheduleTimer(callback, duration)
    timerId = timerId + 1
    
    addon.timers[timerId] = {
        callback = callback,
        duration = duration,
        elapsed = 0,
        repeating = false
    }
    
    addon.timerFrame:Show()
    return timerId
end

function addon:ScheduleRepeatingTimer(callback, duration)
    timerId = timerId + 1
    
    addon.timers[timerId] = {
        callback = callback,
        duration = duration,
        elapsed = 0,
        repeating = true
    }
    
    addon.timerFrame:Show()
    return timerId
end

function addon:CancelTimer(id)
    if addon.timers[id] then
        addon.timers[id] = nil
    end
end

-- GetTime Wrapper (falls benötigt)
addon.GetTime = GetTime

-- Koordinaten-Funktionen
function addon:GetPlayerMapPosition()
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then
        -- Spieler ist wahrscheinlich in einer Instanz
        SetMapToCurrentZone()
        x, y = GetPlayerMapPosition("player")
    end
    return x * 100, y * 100 -- In Prozent zurückgeben
end

function addon:GetZoneText()
    return GetRealZoneText() or GetZoneText()
end

function addon:GetSubZoneText()
    return GetSubZoneText()
end

-- Item Link Parser (für Vanilla)
function addon:GetItemInfoFromLink(link)
    if not link then return end
    
    -- Pattern: |cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0|h[Broken Fang]|h|r
    local _, _, color, itemId, name = string.find(link, "|c(%x+)|Hitem:(%d+):.+|h%[(.-)%]|h|r")
    
    if itemId and name then
        return {
            id = tonumber(itemId),
            name = name,
            color = color,
            link = link
        }
    end
end

-- Vanilla-kompatible GetItemInfo
function addon:GetItemInfo(item)
    -- In Vanilla gibt GetItemInfo weniger Werte zurück
    local name, link, quality, level, class, subclass, maxStack, invType, texture = GetItemInfo(item)
    
    return {
        name = name,
        link = link,
        quality = quality,
        level = level,
        class = class,
        subclass = subclass,
        maxStack = maxStack,
        invType = invType,
        texture = texture
    }
end

-- Unit functions
function addon:UnitIsHostile(unit)
    return UnitIsEnemy("player", unit) and UnitCanAttack("player", unit)
end

function addon:PlayerInCombat()
    return UnitAffectingCombat("player") or InCombatLockdown and InCombatLockdown()
end

-- Mathe-Utilities
function addon:Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

function addon:GetDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Color utilities
function addon:RGBToHex(r, g, b)
    return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function addon:HexToRGB(hex)
    local r = tonumber(string.sub(hex, 1, 2), 16) / 255
    local g = tonumber(string.sub(hex, 3, 4), 16) / 255
    local b = tonumber(string.sub(hex, 5, 6), 16) / 255
    return r, g, b
end