-- Database System für Turtle WoW
local addon = RXPGuides or {}

-- Database structure
addon.db = {
    global = {},      -- Account-wide data
    profile = {},     -- Profile-specific data
    char = {}         -- Character-specific data
}

-- Initialize database
function addon:InitializeDatabase()
    -- Global (account-wide)
    RXPData = RXPData or {}
    self.db.global = RXPData
    
    -- Profile (we'll use account-wide for now)
    RXPDB = RXPDB or {}
    self.db.profile = RXPDB
    
    -- Character-specific
    RXPCData = RXPCData or {}
    self.db.char = RXPCData
    
    -- Initialize sub-tables
    self:InitializeDatabaseDefaults()
    
    self:Debug("Database initialized")
end

-- Set up default values
function addon:InitializeDatabaseDefaults()
    -- Global defaults
    local globalDefaults = {
        guides = {},
        waypoints = {},
        customSteps = {},
        version = addon.version
    }
    
    -- Profile defaults
    local profileDefaults = {
        currentGuide = nil,
        currentStep = 1,
        completedSteps = {},
        skippedSteps = {},
        notes = {}
    }
    
    -- Character defaults
    local charDefaults = {
        level = UnitLevel("player"),
        class = UnitClass("player"),
        race = UnitRace("player"),
        faction = UnitFactionGroup("player"),
        restedXP = GetXPExhaustion() or 0,
        playedTime = 0,
        guideTimes = {},
        deathCount = 0
    }
    
    -- Merge defaults
    self:MergeDatabaseDefaults(self.db.global, globalDefaults)
    self:MergeDatabaseDefaults(self.db.profile, profileDefaults)
    self:MergeDatabaseDefaults(self.db.char, charDefaults)
end

-- Merge defaults into database
function addon:MergeDatabaseDefaults(db, defaults)
    for key, value in pairs(defaults) do
        if db[key] == nil then
            if type(value) == "table" then
                db[key] = addon.deepcopy(value)
            else
                db[key] = value
            end
        end
    end
end

-- Get database value
function addon:GetDBValue(scope, key)
    if not self.db[scope] then
        self:Debug("Invalid database scope: " .. scope)
        return nil
    end
    
    return self.db[scope][key]
end

-- Set database value
function addon:SetDBValue(scope, key, value)
    if not self.db[scope] then
        self:Debug("Invalid database scope: " .. scope)
        return
    end
    
    self.db[scope][key] = value
    
    -- Trigger save
    self:SaveDatabase()
end

-- Save database (called automatically)
function addon:SaveDatabase()
    -- WoW automatically saves these on logout
    -- But we can force a save by reassigning
    RXPData = self.db.global
    RXPDB = self.db.profile
    RXPCData = self.db.char
end

-- Reset database
function addon:ResetDatabase(scope)
    if scope == "all" then
        self.db.global = {}
        self.db.profile = {}
        self.db.char = {}
        self:InitializeDatabaseDefaults()
        self:Print("All data reset")
    elseif self.db[scope] then
        self.db[scope] = {}
        self:InitializeDatabaseDefaults()
        self:Print(scope .. " data reset")
    else
        self:Print("Invalid scope. Use: global, profile, char, or all")
    end
    
    self:SaveDatabase()
    self:SendMessage("RXP_DATABASE_RESET", scope)
end

-- Guide completion tracking
function addon:MarkStepComplete(guideId, stepIndex)
    if not self.db.profile.completedSteps[guideId] then
        self.db.profile.completedSteps[guideId] = {}
    end
    
    self.db.profile.completedSteps[guideId][stepIndex] = time()
    self:SaveDatabase()
    self:SendMessage("RXP_STEP_COMPLETED", guideId, stepIndex)
end

function addon:IsStepComplete(guideId, stepIndex)
    return self.db.profile.completedSteps[guideId] and 
           self.db.profile.completedSteps[guideId][stepIndex]
end

function addon:MarkStepSkipped(guideId, stepIndex)
    if not self.db.profile.skippedSteps[guideId] then
        self.db.profile.skippedSteps[guideId] = {}
    end
    
    self.db.profile.skippedSteps[guideId][stepIndex] = time()
    self:SaveDatabase()
    self:SendMessage("RXP_STEP_SKIPPED", guideId, stepIndex)
end

-- Character data tracking
function addon:UpdateCharacterData()
    self.db.char.level = UnitLevel("player")
    self.db.char.restedXP = GetXPExhaustion() or 0
    
    -- Update played time
    if self.sessionStartTime then
        self.db.char.playedTime = self.db.char.playedTime + (time() - self.sessionStartTime)
        self.sessionStartTime = time()
    end
    
    self:SaveDatabase()
end

-- Death tracking
function addon:IncrementDeathCount()
    self.db.char.deathCount = (self.db.char.deathCount or 0) + 1
    self:SaveDatabase()
    self:SendMessage("RXP_DEATH_COUNT_UPDATED", self.db.char.deathCount)
end

-- Database commands are now in TurtleCommands.lua

-- Helper function to count table entries
function addon:CountTableEntries(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Hook into initialization
local oldInit = addon.Initialize
addon.Initialize = function(self)
    -- Call original
    oldInit(self)
    
    -- Initialize database
    self:InitializeDatabase()
    
    -- Track session start time
    self.sessionStartTime = time()
    
    -- Register for events
    self:RegisterEvent("PLAYER_LEVEL_UP", function()
        self:UpdateCharacterData()
    end)
    
    self:RegisterEvent("PLAYER_DEAD", function()
        self:IncrementDeathCount()
    end)
    
    self:Debug("Database system initialized")
end