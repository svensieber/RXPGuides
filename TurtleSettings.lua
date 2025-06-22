-- Settings System für Turtle WoW
local addon = RXPGuides or {}

-- Default settings
addon.defaultSettings = {
    profile = {
        -- General
        debug = false,
        enabled = true,
        
        -- Display
        windowScale = 1.0,
        windowAlpha = 1.0,
        windowLocked = false,
        hideInCombat = false,
        hideCompletedSteps = false,
        
        -- Automation
        autoAcceptQuests = true,
        autoTurnIn = true,
        autoSkipCutscenes = false,
        
        -- Navigation
        showArrow = true,
        arrowScale = 1.0,
        arrowAlpha = 1.0,
        
        -- Targeting
        enableTargeting = true,
        targetingDistance = 30,
        markTargets = false,
        
        -- Window positions (saved)
        positions = {}
    }
}

-- Initialize settings
function addon:InitializeSettings()
    -- Create settings table if it doesn't exist
    if not RXPSettings then
        RXPSettings = {}
    end
    
    -- Merge with defaults
    self.settings = self:MergeSettings(RXPSettings, self.defaultSettings)
    
    -- Override the simple debug boolean from TurtleCore
    if type(self.settings) == "table" and type(self.settings.profile) == "table" then
        -- Use the profile debug setting
        self.settings.debug = self.settings.profile.debug
    end
    
    -- Save back to ensure all defaults are present
    RXPSettings = self.settings
end

-- Merge settings with defaults
function addon:MergeSettings(saved, defaults)
    local result = {}
    
    -- Deep copy defaults first
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            result[k] = self:MergeSettings({}, v)
        else
            result[k] = v
        end
    end
    
    -- Override with saved values
    if saved then
        for k, v in pairs(saved) do
            if type(v) == "table" and type(result[k]) == "table" then
                result[k] = self:MergeSettings(v, result[k])
            else
                result[k] = v
            end
        end
    end
    
    return result
end

-- Get setting value
function addon:GetSetting(path)
    -- Ensure settings are properly initialized
    if not self.settings or type(self.settings) ~= "table" then
        self:InitializeSettings()
    end
    
    local current = self.settings
    local keys = self:SplitString(path, ".")
    
    for i = 1, table.getn(keys) do
        if type(current) == "table" and current[keys[i]] ~= nil then
            current = current[keys[i]]
        else
            return nil
        end
    end
    
    return current
end

-- Set setting value
function addon:SetSetting(path, value)
    -- Ensure settings are properly initialized
    if not self.settings or type(self.settings) ~= "table" then
        self:InitializeSettings()
    end
    
    local current = self.settings
    local keys = self:SplitString(path, ".")
    
    -- Navigate to the parent
    for i = 1, table.getn(keys) - 1 do
        if type(current[keys[i]]) ~= "table" then
            current[keys[i]] = {}
        end
        current = current[keys[i]]
    end
    
    -- Set the value
    current[keys[table.getn(keys)]] = value
    
    -- Save to SavedVariables
    RXPSettings = self.settings
    
    -- Fire event
    self:SendMessage("RXP_SETTINGS_CHANGED", path, value)
end

-- String split helper
function addon:SplitString(str, delimiter)
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

-- Save frame positions
function addon:SaveFramePosition(frameName, frame)
    if not frame then return end
    
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    
    if not self.settings.profile.positions then
        self.settings.profile.positions = {}
    end
    
    self.settings.profile.positions[frameName] = {
        point = point,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs
    }
    
    RXPSettings = self.settings
end

-- Restore frame positions
function addon:RestoreFramePosition(frameName, frame)
    if not frame or not self.settings.profile.positions then return end
    
    local pos = self.settings.profile.positions[frameName]
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    end
end

-- Settings commands are now in TurtleCommands.lua

-- Reset settings
function addon:ResetSettings()
    RXPSettings = addon:MergeSettings({}, addon.defaultSettings)
    addon.settings = RXPSettings
    addon:Print("Settings reset to defaults")
    addon:SendMessage("RXP_SETTINGS_RESET")
end

-- Reset positions
function addon:ResetPositions()
    if addon.settings.profile.positions then
        addon.wipe(addon.settings.profile.positions)
    end
    addon:Print("Window positions reset")
    addon:SendMessage("RXP_POSITIONS_RESET")
end

-- Hook into initialization
local oldInit = addon.Initialize
addon.Initialize = function(self)
    -- Call original
    oldInit(self)
    
    -- Initialize settings
    self:InitializeSettings()
    
    self:Debug("Settings system initialized")
end