-- Guide Loader for Turtle WoW
local addon = RXPGuides or {}

-- Guide loading and management
function addon:LoadGuide(guideKey)
    local guide = self.guides[guideKey]
    if not guide then
        self:Print("Guide not found: " .. (guideKey or "nil"))
        return false
    end
    
    -- Check requirements
    if not self:CheckGuideRequirements(guide) then
        return false
    end
    
    -- Set as current guide
    self.currentGuide = guide
    self.currentGuideKey = guideKey
    
    -- Load saved progress
    local savedStep = self:GetDBValue("profile", "currentStep") or 1
    if savedStep > table.getn(guide.steps) then
        savedStep = 1
    end
    self.currentStep = savedStep
    
    -- Mark guide as loaded
    guide.loaded = true
    
    -- Update database
    self:SetDBValue("profile", "currentGuide", guideKey)
    self:SetDBValue("profile", "currentStep", savedStep)
    
    self:Print("Loaded guide: " .. guide.name)
    self:SendMessage("RXP_GUIDE_LOADED", guideKey)
    
    -- Load first step
    self:LoadStep(savedStep)
    
    return true
end

-- Check if player meets guide requirements
function addon:CheckGuideRequirements(guide)
    -- Level check
    local playerLevel = UnitLevel("player")
    if guide.minLevel and playerLevel < guide.minLevel then
        self:Print("You must be at least level " .. guide.minLevel .. " for this guide")
        return false
    end
    if guide.maxLevel and playerLevel > guide.maxLevel then
        self:Print("This guide is for levels up to " .. guide.maxLevel)
        return false
    end
    
    -- Faction check
    if guide.faction then
        -- In Vanilla, we need to determine faction differently
        local englishFaction = UnitFactionGroup and UnitFactionGroup("player")
        if not englishFaction then
            -- Fallback for Vanilla
            local factionGroup = UnitFactionGroup and UnitFactionGroup("player") or GetRealmName()
            englishFaction = "Alliance" -- Default, we'll detect properly later
            
            -- Simple detection based on race
            local _, race = UnitRace("player")
            if race == "Orc" or race == "Troll" or race == "Tauren" or race == "Undead" then
                englishFaction = "Horde"
            end
        end
        
        if guide.faction ~= englishFaction then
            self:Print("This guide is for " .. guide.faction .. " only")
            return false
        end
    end
    
    -- Class check
    if guide.class then
        local _, playerClass = UnitClass("player")
        if type(guide.class) == "table" then
            local found = false
            for i = 1, table.getn(guide.class) do
                if guide.class[i] == playerClass then
                    found = true
                    break
                end
            end
            if not found then
                self:Print("This guide is not available for your class")
                return false
            end
        elseif guide.class ~= playerClass then
            self:Print("This guide is for " .. guide.class .. " only")
            return false
        end
    end
    
    -- Race check
    if guide.race then
        local _, playerRace = UnitRace("player")
        if type(guide.race) == "table" then
            local found = false
            for i = 1, table.getn(guide.race) do
                if guide.race[i] == playerRace then
                    found = true
                    break
                end
            end
            if not found then
                self:Print("This guide is not available for your race")
                return false
            end
        elseif guide.race ~= playerRace then
            self:Print("This guide is for " .. guide.race .. " only")
            return false
        end
    end
    
    return true
end

-- Load a specific step
function addon:LoadStep(stepIndex)
    if not self.currentGuide then
        self:Debug("No guide loaded")
        return
    end
    
    local guide = self.currentGuide
    if stepIndex < 1 or stepIndex > table.getn(guide.steps) then
        self:Debug("Invalid step index: " .. stepIndex)
        return
    end
    
    self.currentStep = stepIndex
    local step = guide.steps[stepIndex]
    
    -- Check if already completed
    if self:IsStepComplete(self.currentGuideKey, stepIndex) then
        step.completed = true
    end
    
    -- Update display
    self:SendMessage("RXP_STEP_LOADED", stepIndex, step)
    
    -- Set waypoint if available
    if step.x and step.y and step.zone then
        -- TODO: Implement in Phase 5 with pfQuest integration
        self:Debug("Would set waypoint: " .. step.zone .. " " .. step.x .. "," .. step.y)
    end
    
    -- Auto-accept/turnin setup
    if step.action == "accept" and step.questId then
        self.autoAcceptQuest = step.questId
    elseif step.action == "turnin" and step.questId then
        self.autoTurnInQuest = step.questId
    end
    
    -- Save progress
    self:SetDBValue("profile", "currentStep", stepIndex)
end

-- Next step
function addon:NextStep()
    if not self.currentGuide then return end
    
    local nextIndex = self.currentStep + 1
    if nextIndex <= table.getn(self.currentGuide.steps) then
        self:LoadStep(nextIndex)
    else
        -- Guide complete
        self:CompleteGuide()
    end
end

-- Previous step
function addon:PreviousStep()
    if not self.currentGuide then return end
    
    local prevIndex = self.currentStep - 1
    if prevIndex >= 1 then
        self:LoadStep(prevIndex)
    end
end

-- Skip current step
function addon:SkipStep()
    if not self.currentGuide or not self.currentStep then return end
    
    self:MarkStepSkipped(self.currentGuideKey, self.currentStep)
    self:NextStep()
end

-- Complete current step
function addon:CompleteStep()
    if not self.currentGuide or not self.currentStep then return end
    
    local step = self.currentGuide.steps[self.currentStep]
    step.completed = true
    
    self:MarkStepComplete(self.currentGuideKey, self.currentStep)
    self:SendMessage("RXP_STEP_COMPLETED", self.currentGuideKey, self.currentStep)
    
    -- Auto advance if enabled
    if self:GetSetting("profile.autoAdvance") then
        self:ScheduleTimer(function()
            self:NextStep()
        end, 0.5)
    end
end

-- Complete guide
function addon:CompleteGuide()
    if not self.currentGuide then return end
    
    self:Print("Guide complete: " .. self.currentGuide.name)
    self:SendMessage("RXP_GUIDE_COMPLETED", self.currentGuideKey)
    
    -- Check for next guide
    if self.currentGuide.next then
        self:Print("Next guide: " .. self.currentGuide.next)
        -- Auto-load next guide if enabled
        if self:GetSetting("profile.autoLoadNext") then
            self:ScheduleTimer(function()
                self:LoadGuide(self.currentGuide.next)
            end, 2)
        end
    end
end

-- Get available guides
function addon:GetAvailableGuides()
    local available = {}
    
    for key, guide in pairs(self.guides) do
        if self:CheckGuideRequirements(guide) then
            tinsert(available, {
                key = key,
                name = guide.name,
                group = guide.group or "Ungrouped",
                minLevel = guide.minLevel,
                maxLevel = guide.maxLevel
            })
        end
    end
    
    -- Sort by level
    table.sort(available, function(a, b)
        if a.minLevel == b.minLevel then
            return a.name < b.name
        end
        return a.minLevel < b.minLevel
    end)
    
    return available
end

-- Guide commands
function addon:RegisterGuideCommands()
    self:RegisterCommand("guide", function(self, args)
        if not args or args == "" then
            -- List available guides
            local guides = self:GetAvailableGuides()
            self:Print("Available guides:")
            for i = 1, table.getn(guides) do
                local g = guides[i]
                self:Print(string.format("  %s (%d-%d) - /rxp guide %s", 
                    g.name, g.minLevel, g.maxLevel, g.key))
            end
        else
            -- Load specific guide
            self:LoadGuide(args)
        end
    end, "Load a guide or list available guides")
    
    self:RegisterCommand("next", function(self, args)
        self:NextStep()
    end, "Go to next step")
    
    self:RegisterCommand("prev", function(self, args)
        self:PreviousStep()
    end, "Go to previous step")
    
    self:RegisterCommand("skip", function(self, args)
        self:SkipStep()
        self:Print("Step skipped")
    end, "Skip current step")
    
    self:RegisterCommand("complete", function(self, args)
        self:CompleteStep()
        self:Print("Step completed")
    end, "Complete current step")
end

-- Hook into initialization
local oldInit = addon.Initialize
addon.Initialize = function(self)
    -- Call original
    oldInit(self)
    
    -- Register guide commands
    self:RegisterGuideCommands()
    
    -- Setup commands must be called after all commands are registered
    if self.SetupAllCommands then
        self:SetupAllCommands()
    end
    
    self:Debug("Guide loader initialized")
end