-- Guide Format and Parser for Turtle WoW
local addon = RXPGuides or {}

-- Guide metadata structure
addon.guideMetaTags = {
    -- Core tags
    ["#version"] = "version",
    ["#group"] = "group", 
    ["#subgroup"] = "subgroup",
    ["#name"] = "name",
    ["#next"] = "next",
    
    -- Restrictions
    ["#class"] = "class",
    ["#race"] = "race",
    ["#level"] = "level",
    
    -- Features
    ["#hardcore"] = "hardcore",
    ["#classic"] = "classic",
    ["#turtle"] = "turtle"  -- New tag for Turtle WoW specific guides
}

-- Step action types
addon.stepActions = {
    -- Quest actions
    accept = {icon = "Interface\\GossipFrame\\AvailableQuestIcon", color = {1, 0.8, 0}},
    turnin = {icon = "Interface\\GossipFrame\\ActiveQuestIcon", color = {0, 1, 0}},
    complete = {icon = "Interface\\GossipFrame\\HealerGossipIcon", color = {0.8, 0.8, 0.8}},
    
    -- Navigation
    goto = {icon = "Interface\\Minimap\\Vehicle-SilvershardMines-MineCart", color = {0.5, 0.5, 1}},
    fly = {icon = "Interface\\TAXIFRAME\\UI-Taxi-Icon-White", color = {0.8, 0.8, 1}},
    hearth = {icon = "Interface\\Icons\\INV_Misc_Rune_01", color = {0.5, 1, 0.5}},
    
    -- Combat/Interaction
    kill = {icon = "Interface\\Icons\\Ability_DualWield", color = {1, 0.2, 0.2}},
    collect = {icon = "Interface\\Icons\\INV_Misc_Bag_10", color = {0.8, 0.8, 0.2}},
    buy = {icon = "Interface\\Icons\\INV_Misc_Coin_01", color = {1, 1, 0}},
    
    -- Other
    train = {icon = "Interface\\Icons\\INV_Misc_Book_01", color = {0.5, 0.5, 1}},
    vendor = {icon = "Interface\\Icons\\INV_Misc_Coin_02", color = {0.8, 0.8, 0.8}},
    repair = {icon = "Interface\\Icons\\Trade_BlackSmithing", color = {0.8, 0.6, 0.2}}
}

-- Guide structure
function addon:CreateGuide()
    return {
        -- Metadata
        key = "",
        name = "",
        group = "",
        subgroup = "",
        next = nil,
        version = 1,
        
        -- Requirements
        minLevel = 1,
        maxLevel = 60,
        faction = nil,  -- "Alliance" or "Horde"
        class = nil,    -- Single class or table of classes
        race = nil,     -- Single race or table of races
        
        -- Features
        hardcore = false,
        turtle = false,
        
        -- Content
        steps = {},
        
        -- Runtime data
        loaded = false,
        currentStep = 1
    }
end

-- Step structure
function addon:CreateStep()
    return {
        -- Content
        text = "",
        title = "",
        
        -- Position
        x = nil,
        y = nil,
        zone = nil,
        subzone = nil,
        
        -- Actions
        action = nil,       -- Primary action type
        questId = nil,      -- Quest ID if applicable
        npcId = nil,        -- NPC ID if applicable
        itemId = nil,       -- Item ID if applicable
        
        -- Requirements
        requires = {},      -- Required items/quests
        optional = false,   -- Is this step optional?
        
        -- Completion
        complete = {},      -- Completion conditions
        
        -- Display
        icon = nil,
        sticky = false,     -- Sticky steps stay visible
        
        -- Runtime
        completed = false,
        skipped = false
    }
end

-- Parse guide string
function addon:ParseGuide(guideString)
    local guide = self:CreateGuide()
    local lines = self:SplitString(guideString, "\n")
    local currentStep = nil
    local inStep = false
    
    for i = 1, table.getn(lines) do
        local line = strtrim(lines[i])
        
        -- Skip empty lines
        if line == "" then
            -- Empty line
        
        -- Metadata tags
        elseif string.sub(line, 1, 1) == "#" then
            self:ParseMetaTag(guide, line)
        
        -- Step boundary
        elseif line == "step" then
            if currentStep then
                tinsert(guide.steps, currentStep)
            end
            currentStep = self:CreateStep()
            inStep = true
        
        -- Step content
        elseif inStep and currentStep then
            self:ParseStepLine(currentStep, line)
        
        -- Faction restriction
        elseif string.find(line, "^<<") then
            local faction = strtrim(string.sub(line, 3))
            guide.faction = faction
        end
    end
    
    -- Add last step
    if currentStep then
        tinsert(guide.steps, currentStep)
    end
    
    return guide
end

-- Parse metadata tag
function addon:ParseMetaTag(guide, line)
    local tag, value = string.match(line, "^(#%w+)%s*(.*)$")
    if not tag then return end
    
    local field = self.guideMetaTags[tag]
    if not field then return end
    
    -- Handle different tag types
    if tag == "#version" then
        guide.version = tonumber(value) or 1
    elseif tag == "#hardcore" or tag == "#classic" or tag == "#turtle" then
        guide[field] = true
    elseif tag == "#level" then
        local min, max = string.match(value, "(%d+)%-(%d+)")
        if min and max then
            guide.minLevel = tonumber(min)
            guide.maxLevel = tonumber(max)
        end
    else
        guide[field] = value
    end
end

-- Parse step line
function addon:ParseStepLine(step, line)
    -- Skip comments
    if string.sub(line, 1, 2) == ">>" then
        -- Extract text content
        local text = string.match(line, ">>(.+)$")
        if text then
            step.text = strtrim(text)
            -- Remove color codes and icons for title
            step.title = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
            step.title = string.gsub(step.title, "|r", "")
            step.title = string.gsub(step.title, "|T.-|t", "")
        end
        return
    end
    
    -- Parse dot commands
    if string.sub(line, 1, 1) == "." then
        local cmd, args = string.match(line, "^%.(%w+)%s*(.*)$")
        if cmd then
            self:ParseStepCommand(step, cmd, args)
        end
    end
end

-- Parse step command
function addon:ParseStepCommand(step, cmd, args)
    if cmd == "goto" then
        -- Parse coordinates
        local zone, x, y = string.match(args, "([^,]+),([%d%.]+),([%d%.]+)")
        if x and y then
            step.x = tonumber(x)
            step.y = tonumber(y)
            step.zone = zone
            step.action = "goto"
        end
    
    elseif cmd == "accept" or cmd == "turnin" or cmd == "complete" then
        -- Parse quest ID
        local questId = string.match(args, "(%d+)")
        if questId then
            step.questId = tonumber(questId)
            step.action = cmd
        end
    
    elseif cmd == "target" then
        -- Parse NPC name
        step.npcName = args
    
    elseif cmd == "collect" then
        -- Parse item requirements
        local itemId, count = string.match(args, "(%d+),(%d+)")
        if itemId then
            step.itemId = tonumber(itemId)
            step.itemCount = tonumber(count) or 1
            step.action = "collect"
        end
    
    elseif cmd == "sticky" then
        step.sticky = true
    
    elseif cmd == "optional" then
        step.optional = true
    end
end

-- Register a guide
function addon:RegisterGuide(guideString)
    self:Debug("RegisterGuide called")
    
    local guide = self:ParseGuide(guideString)
    
    if not guide.name or guide.name == "" then
        self:Debug("Guide has no name, skipping registration")
        return
    end
    
    self:Debug("Registering guide: " .. guide.name)
    
    -- Generate key if not provided
    if not guide.key or guide.key == "" then
        guide.key = string.lower(string.gsub(guide.name, "%s+", "-"))
    end
    
    -- Store in database
    if not self.guides then
        self:Print("ERROR: self.guides is nil in RegisterGuide!")
        self.guides = {}
    end
    
    self.guides[guide.key] = guide
    self:Print("Guide stored with key: " .. guide.key)
    
    -- Group organization
    if not self.guideGroups then
        self.guideGroups = {}
    end
    
    local group = guide.group or "Ungrouped"
    if not self.guideGroups[group] then
        self.guideGroups[group] = {}
    end
    
    tinsert(self.guideGroups[group], guide.key)
    
    self:Print("Successfully registered guide: " .. guide.name)
    self:SendMessage("RXP_GUIDE_REGISTERED", guide.key)
    
    return guide
end