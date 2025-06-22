local addonName, addon = ...

-- Turtle WoW Core für RXPGuides
-- Lua 5.0 kompatibel, WoW 1.12.1 API

-- Nur auf Turtle WoW ausführen
if not addon.isTurtleWoW then return end

addon.isTurtle = true
addon.gameVersion = 11200

-- Basis Setup
addon.version = "1.0.0-turtle"
addon.settings = {}
addon.guides = {}

-- Lua 5.0 Utilities
function addon:Print(msg, ...)
    if arg and table.getn(arg) > 0 then
        msg = string.format(msg, unpack(arg))
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: " .. msg)
end

function addon:Debug(msg, ...)
    if not self.settings.debug then return end
    if arg and table.getn(arg) > 0 then
        msg = string.format(msg, unpack(arg))
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9933RXP Debug|r: " .. msg)
end

-- Event System (Ace3 Ersatz für Turtle)
local frame = CreateFrame("Frame", "RXPGuidesFrame")
addon.frame = frame
addon.events = {}

function addon:RegisterEvent(event, callback)
    if not self.events[event] then
        self.events[event] = {}
        frame:RegisterEvent(event)
    end
    tinsert(self.events[event], callback or function() self:OnEvent(event) end)
end

function addon:UnregisterEvent(event)
    if self.events[event] then
        self.events[event] = nil
        frame:UnregisterEvent(event)
    end
end

-- Event Handler
frame:SetScript("OnEvent", function()
    if not addon.events[event] then return end
    
    local callbacks = addon.events[event]
    for i = 1, table.getn(callbacks) do
        callbacks[i](addon, event, arg1, arg2, arg3, arg4, arg5)
    end
end)

-- Initialisierung
function addon:Initialize()
    -- SavedVariables laden
    RXPData = RXPData or {}
    RXPDB = RXPDB or {}
    RXPSettings = RXPSettings or {}
    
    self.db = RXPData
    self.settings = RXPSettings
    
    -- Standard-Einstellungen
    self:LoadDefaults()
    
    self:Print(self:Localize("Turtle WoW Version") .. " " .. self.version .. " " .. self:Localize("Loaded"))
    
    -- Test-Befehl
    self:SetupSlashCommands()
end

function addon:LoadDefaults()
    local defaults = {
        debug = false,
        showWindow = true,
        windowScale = 1.0,
        autoAcceptQuests = true,
        autoturnin = true,
        showArrow = true,
        lockFrames = false
    }
    
    for key, value in pairs(defaults) do
        if self.settings[key] == nil then
            self.settings[key] = value
        end
    end
end

function addon:OnPlayerLogin()
    self:Debug("Player login detected")
    
    -- Weitere Initialisierung hier
    self:CheckTurtleWoWCompat()
end

function addon:CheckTurtleWoWCompat()
    -- Prüfe ob wir wirklich auf Turtle WoW sind
    local realmName = GetRealmName()
    if realmName and string.find(string.lower(realmName), "turtle") then
        self:Debug(self:Localize("Turtle WoW server detected"))
    end
    
    -- Prüfe auf pfQuest
    if pfQuest then
        self:Print(self:Localize("pfQuest found - Navigation enabled"))
        self.pfQuestAvailable = true
    else
        self:Print(self:Localize("pfQuest not found - Navigation limited"))
    end
end

-- Slash Commands
function addon:SetupSlashCommands()
    SLASH_RXPGUIDES1 = "/rxp"
    SLASH_RXPGUIDES2 = "/rxpguides"
    
    SlashCmdList["RXPGUIDES"] = function(msg)
        local cmd, arg = self:ParseCommand(msg)
        
        if cmd == "test" then
            self:Print(self:Localize("Test successful") .. "! " .. self:Localize("Version") .. ": " .. self.version)
            self:Debug(self:Localize("Debug Mode") .. " " .. (self.settings.debug and self:Localize("ON") or self:Localize("OFF")))
        elseif cmd == "debug" then
            self.settings.debug = not self.settings.debug
            self:Print(self:Localize("Debug Mode") .. ": " .. (self.settings.debug and self:Localize("ON") or self:Localize("OFF")))
        elseif cmd == "version" then
            self:Print(self:Localize("Version") .. ": " .. self.version)
            self:Print("Interface: " .. select(4, GetBuildInfo()))
            self:Print("Lua 5.0 kompatibel")
        elseif cmd == "help" or cmd == "" then
            self:ShowHelp()
        else
            self:Print(self:Localize("Unknown command") .. ": " .. cmd)
        end
    end
end

function addon:ParseCommand(msg)
    local cmd, arg
    local space = string.find(msg, " ")
    if space then
        cmd = string.sub(msg, 1, space - 1)
        arg = string.sub(msg, space + 1)
    else
        cmd = msg
    end
    return string.lower(cmd or ""), arg
end

function addon:ShowHelp()
    self:Print(self:Localize("Available commands") .. ":")
    self:Print("/rxp test - Testet die Installation")
    self:Print("/rxp debug - Debug-Modus umschalten")
    self:Print("/rxp version - Zeigt Version Info")
    self:Print("/rxp help - Diese Hilfe")
end

-- Events registrieren
addon:RegisterEvent("ADDON_LOADED", function(self, event, addonName)
    if addonName == "RXPGuides" then
        self:Initialize()
    end
end)

addon:RegisterEvent("PLAYER_LOGIN", function(self)
    self:OnPlayerLogin()
end)