-- In Lua 5.0 müssen wir globale Variablen verwenden
local addonName = "RXPGuides"
local addon = {}
-- Direkt als globale Variable setzen
RXPGuides = addon

-- Turtle WoW Core für RXPGuides
-- Lua 5.0 kompatibel, WoW 1.12.1 API

-- Debug print to verify file is loading
DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: TurtleCore.lua loading...")

-- Skip if main addon already loaded (shouldn't happen on Turtle)
if addon.loaded then return end

addon.isTurtle = true
addon.gameVersion = 11200
addon.version = "1.0.0-turtle"

-- Basis Setup
addon.settings = {}
addon.guides = {}

-- Global reference already set above

-- Print function
function addon:Print(msg)
    -- In Lua 5.0 nutzen wir arg für variable Argumente
    if arg and table.getn(arg) > 0 then
        msg = string.format(msg, unpack(arg))
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: " .. msg)
end

function addon:Debug(msg)
    if not self.settings.debug then return end
    -- In Lua 5.0 nutzen wir arg für variable Argumente
    if arg and table.getn(arg) > 0 then
        msg = string.format(msg, unpack(arg))
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9933RXP Debug|r: " .. msg)
end

-- Event System
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
    
    self:Print("Turtle WoW Version " .. self.version .. " loaded")
    self:Debug("Debug mode " .. (self.settings.debug and "ON" or "OFF"))
    
    -- Setup slash commands during initialization
    self:SetupSlashCommands()
    
    addon.loaded = true
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
    
    -- Check for pfQuest
    if pfQuest then
        self:Print("pfQuest found - Navigation enabled")
        self.pfQuestAvailable = true
    else
        self:Print("pfQuest not found - Navigation limited")
    end
end

-- Slash Commands
function addon:SetupSlashCommands()
    SLASH_RXPGUIDES1 = "/rxp"
    SLASH_RXPGUIDES2 = "/rxpguides"
    
    SlashCmdList["RXPGUIDES"] = function(msg)
        local cmd, arg = addon:ParseCommand(msg)
        
        if cmd == "test" then
            addon:Print("Test successful! Version: " .. addon.version)
            addon:Debug("Debug mode is " .. (addon.settings.debug and "ON" or "OFF"))
        elseif cmd == "debug" then
            addon.settings.debug = not addon.settings.debug
            addon:Print("Debug mode: " .. (addon.settings.debug and "ON" or "OFF"))
        elseif cmd == "version" then
            addon:Print("Version: " .. addon.version)
            -- In Vanilla gibt GetBuildInfo nur 3 Werte zurück
            local version, build, date = GetBuildInfo()
            addon:Print("WoW Version: " .. version .. " (Build " .. build .. ")")
            addon:Print("Interface: 11200 (Turtle WoW)")
            addon:Print("Lua 5.0 compatible")
        elseif cmd == "help" or cmd == "" then
            addon:ShowHelp()
        else
            addon:Print("Unknown command: " .. cmd)
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
    self:Print("Available commands:")
    self:Print("/rxp test - Test installation")
    self:Print("/rxp debug - Toggle debug mode")
    self:Print("/rxp version - Show version info")
    self:Print("/rxp help - Show this help")
end

-- Events registrieren
addon:RegisterEvent("ADDON_LOADED", function(self, event, addonName)
    -- In Vanilla/Turtle WoW ist addonName in arg1
    if arg1 == "RXPGuides" then
        self:Initialize()
    end
end)

addon:RegisterEvent("PLAYER_LOGIN", function(self)
    self:OnPlayerLogin()
end)