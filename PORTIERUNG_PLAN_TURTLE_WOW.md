# RXPGuides Portierungsplan für Turtle WoW (1.12.1)

## Übersicht
Portierung von RXPGuides Classic Era auf Turtle WoW mit Lua 5.0 und WoW 1.12.1 APIs.

## Wichtige Einschränkungen
- **Lua 5.0** statt 5.1+ (kein #-Operator, kein ..., table.getn statt #table)
- **Keine modernen C_* APIs** (C_Timer, C_QuestLog, C_NamePlate etc.)
- **Kein GetPlayerFacing()** - Pfeil-Navigation nicht möglich
- **Keine HereBeDragons** - Nur Zone-basierte Koordinaten
- **Nameplate-Reichweite** nur 20 Yards

## Phase 1: Projekt-Setup und Basis-Struktur (Tag 1-2)

### 1.1 Neues Addon-Verzeichnis erstellen
```
RXPGuides_TurtleWoW/
├── RXPGuides_TurtleWoW.toc
├── Core.lua
├── Locale.lua
├── Utils.lua
└── libs/
```

### 1.2 TOC-Datei (Interface: 11200)
```toc
## Interface: 11200
## Title: RXPGuides Turtle WoW
## Version: 1.0.0
## Author: RXPGuides (Turtle Port)
## SavedVariables: RXPTurtleDB
## SavedVariablesPerCharacter: RXPTurtleCharDB

Core.lua
Locale.lua
Utils.lua
```

### 1.3 Basis Core.lua
```lua
RXPTurtle = {}
local addon = RXPTurtle

-- Lua 5.0 kompatible Utilities
function addon:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: " .. msg)
end

-- Event Frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "RXPGuides_TurtleWoW" then
        addon:Initialize()
    elseif event == "PLAYER_LOGIN" then
        addon:OnPlayerLogin()
    end
end)

function addon:Initialize()
    RXPTurtleDB = RXPTurtleDB or {}
    self.db = RXPTurtleDB
    self:Print("Loaded v1.0.0")
end

function addon:OnPlayerLogin()
    -- Testbar mit /rxp test
    SLASH_RXPTURTLE1 = "/rxp"
    SlashCmdList["RXPTURTLE"] = function(msg)
        if msg == "test" then
            self:Print("Test erfolgreich!")
        end
    end
end
```

### 1.4 Commit und Test
- Commit: "Initial addon structure for Turtle WoW"
- **TEST**: Addon lädt in Turtle WoW, `/rxp test` funktioniert

## Phase 2: Core-System ohne Ace3 (Tag 3-5)

### 2.1 Event-System (Ace3 Ersatz)
```lua
-- Events.lua
addon.events = {}
addon.callbacks = {}

function addon:RegisterEvent(event, callback)
    if not self.callbacks[event] then
        self.callbacks[event] = {}
        frame:RegisterEvent(event)
    end
    tinsert(self.callbacks[event], callback)
end

function addon:FireEvent(event, ...)
    if self.callbacks[event] then
        for i = 1, table.getn(self.callbacks[event]) do
            self.callbacks[event][i](...)
        end
    end
end
```

### 2.2 Settings-System
```lua
-- Settings.lua
addon.defaults = {
    profile = {
        debug = false,
        autoAcceptQuests = true,
        showArrow = true,
        windowScale = 1.0
    }
}

function addon:LoadSettings()
    self.settings = self.db.settings or self.defaults
    -- Lua 5.0: Manuelle deep copy
    if not self.db.settings then
        self.db.settings = {}
        for k,v in pairs(self.defaults.profile) do
            self.db.settings[k] = v
        end
    end
end
```

### 2.3 Commit und Test
- Commit: "Add event system and settings framework"
- **TEST**: Events feuern korrekt, Settings werden gespeichert

## Phase 3: Guide-Loader und Datenstrukturen (Tag 6-8)

### 3.1 Guide-Format definieren
```lua
-- GuideFormat.lua
addon.guides = {}

-- Beispiel-Guide
local testGuide = {
    key = "human-1-10",
    name = "Human 1-10",
    faction = "Alliance",
    startLevel = 1,
    endLevel = 10,
    steps = {
        {
            text = "Accept [A Threat Within] from Deputy Willem",
            questId = 783,
            action = "accept",
            x = 48.2,
            y = 42.1,
            zone = "Elwynn Forest"
        }
    }
}

function addon:RegisterGuide(guide)
    self.guides[guide.key] = guide
end
```

### 3.2 Guide-Parser (vereinfacht)
```lua
-- GuideParser.lua
function addon:ParseGuideStep(step)
    -- Quest-Pattern erkennen
    local questPattern = "%[(.-)%]"
    local questName = string.find(step.text, questPattern)
    
    if questName then
        step.questName = questName
    end
    
    return step
end
```

### 3.3 Commit und Test
- Commit: "Add guide system and basic parser"
- **TEST**: Guide wird geladen, Steps werden geparst

## Phase 4: Quest-Tracking System (Tag 9-12)

### 4.1 Quest-Detection für 1.12
```lua
-- QuestTracking.lua
function addon:GetQuestInfo(questId)
    -- Vanilla: Durch Quest Log iterieren
    for i = 1, GetNumQuestLogEntries() do
        local title, level, tag, header, collapsed, complete = GetQuestLogTitle(i)
        if not header then
            SelectQuestLogEntry(i)
            -- Kein GetQuestID in Vanilla!
            local description, objectives = GetQuestLogQuestText()
            -- Quest ID aus Datenbank matchen
            if self:MatchQuestByTitle(title, questId) then
                return {
                    title = title,
                    complete = complete,
                    objectives = self:ParseObjectives(i)
                }
            end
        end
    end
end

function addon:ParseObjectives(questIndex)
    local objectives = {}
    local numObjectives = GetNumQuestLeaderBoards(questIndex)
    
    for i = 1, numObjectives do
        local text, type, finished = GetQuestLogLeaderBoard(i, questIndex)
        tinsert(objectives, {
            text = text,
            type = type,
            finished = finished
        })
    end
    
    return objectives
end
```

### 4.2 Quest-Events
```lua
function addon:SetupQuestEvents()
    self:RegisterEvent("QUEST_LOG_UPDATE", function()
        self:CheckQuestProgress()
    end)
    
    self:RegisterEvent("QUEST_COMPLETE", function()
        self:OnQuestComplete()
    end)
end
```

### 4.3 Commit und Test
- Commit: "Implement quest tracking for vanilla API"
- **TEST**: Quests werden erkannt, Progress wird getrackt

## Phase 5: pfQuest Integration für Navigation (Tag 13-15)

### 5.1 pfQuest Hook
```lua
-- Navigation.lua
function addon:SetupNavigation()
    if not pfQuest or not pfMap then
        self:Print("pfQuest nicht gefunden - Navigation deaktiviert")
        return
    end
    
    self.navigationAvailable = true
end

function addon:SetWaypoint(x, y, zone, title)
    if not self.navigationAvailable then return end
    
    -- pfQuest erwartet Koordinaten als 0-1
    pfMap:AddNode("RXPGuide", zone, x/100, y/100, {
        title = title or "RXP Waypoint",
        layer = 5,
        color = {1, 0.8, 0},
        texture = pfQuestConfig.path.."\\img\\icon_circle"
    })
end

function addon:ClearWaypoints()
    if not self.navigationAvailable then return end
    pfMap:DeleteNode("RXPGuide")
end
```

### 5.2 Koordinaten-Anzeige
```lua
function addon:GetPlayerCoords()
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then
        SetMapToCurrentZone()
        x, y = GetPlayerMapPosition("player")
    end
    return x * 100, y * 100
end
```

### 5.3 Commit und Test
- Commit: "Add pfQuest integration for waypoints"
- **TEST**: Waypoints erscheinen auf Karte und Minimap

## Phase 6: NPC-Targeting und Combat (Tag 16-18)

### 6.1 Target-System für 1.12
```lua
-- Targeting.lua
function addon:SetupTargeting()
    -- Target-Makros erstellen
    self.targetMacros = {}
end

function addon:TargetNPC(npcName)
    -- Vanilla: Nur /target möglich
    local macro = "/target " .. npcName
    
    -- Temporäres Makro erstellen
    if not GetMacroInfo("RXPTarget") then
        CreateMacro("RXPTarget", "INV_Misc_QuestionMark", macro, nil)
    else
        EditMacro("RXPTarget", "RXPTarget", "INV_Misc_QuestionMark", macro)
    end
    
    -- Makro ausführen
    RunMacro("RXPTarget")
end

-- Mob-Warnung System
function addon:SetupCombatWarnings()
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        self:CheckDangerousMob()
    end)
end

function addon:CheckDangerousMob()
    if not UnitExists("target") or UnitIsFriend("player", "target") then
        return
    end
    
    local name = UnitName("target")
    if self:IsDangerousMob(name) then
        UIErrorsFrame:AddMessage("GEFAHR: " .. name .. "!", 1, 0, 0)
        PlaySound("RaidWarning")
    end
end
```

### 6.2 Commit und Test
- Commit: "Add NPC targeting and combat warnings"
- **TEST**: NPCs werden per Makro anvisiert, Warnungen funktionieren

## Phase 7: Inventory Management (Tag 19-21)

### 7.1 Item-Management für 1.12
```lua
-- Inventory.lua
function addon:SetupInventory()
    self.vendorItems = {} -- Items zum Verkaufen
    self.keepItems = {}   -- Items behalten
end

function addon:ScanBags()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local name = self:GetItemName(link)
                local quality = self:GetItemQuality(link)
                
                if quality == 0 then -- Grau
                    tinsert(self.vendorItems, {bag = bag, slot = slot})
                end
            end
        end
    end
end

function addon:GetItemName(link)
    -- Vanilla: Aus Link parsen
    local _, _, name = string.find(link, "%[(.-)%]")
    return name
end
```

### 7.2 Auto-Vendor
```lua
function addon:AutoVendor()
    if not MerchantFrame:IsVisible() then return end
    
    for i = 1, table.getn(self.vendorItems) do
        local item = self.vendorItems[i]
        UseContainerItem(item.bag, item.slot)
    end
    
    self.vendorItems = {}
end
```

### 7.3 Commit und Test
- Commit: "Add inventory management system"
- **TEST**: Graue Items werden automatisch verkauft

## Phase 8: UI und Settings (Tag 22-24)

### 8.1 Guide-Fenster (XML)
```xml
<!-- GuideWindow.xml -->
<Frame name="RXPGuideFrame" parent="UIParent" movable="true">
    <Size x="300" y="150"/>
    <Anchors>
        <Anchor point="CENTER"/>
    </Anchors>
    <Backdrop bgFile="Interface\DialogFrame\UI-DialogBox-Background" 
              edgeFile="Interface\DialogFrame\UI-DialogBox-Border">
        <EdgeSize val="16"/>
        <TileSize val="32"/>
        <BackgroundInsets left="5" right="5" top="5" bottom="5"/>
    </Backdrop>
    <Layers>
        <Layer level="OVERLAY">
            <FontString name="$parentTitle" inherits="GameFontNormal">
                <Anchors>
                    <Anchor point="TOP" y="-10"/>
                </Anchors>
            </FontString>
            <FontString name="$parentText" inherits="GameFontWhite">
                <Anchors>
                    <Anchor point="TOPLEFT" x="10" y="-30"/>
                    <Anchor point="BOTTOMRIGHT" x="-10" y="30"/>
                </Anchors>
            </FontString>
        </Layer>
    </Layers>
    <Frames>
        <Button name="$parentNext" inherits="UIPanelButtonTemplate">
            <Size x="60" y="20"/>
            <Anchors>
                <Anchor point="BOTTOMRIGHT" x="-10" y="10"/>
            </Anchors>
            <Scripts>
                <OnClick>
                    RXPTurtle:NextStep()
                </OnClick>
            </Scripts>
        </Button>
    </Frames>
</Frame>
```

### 8.2 Settings Panel
```lua
-- SettingsPanel.lua
function addon:CreateSettingsPanel()
    -- Vanilla: Eigenes Panel ohne Interface Options
    local panel = CreateFrame("Frame", "RXPSettingsFrame", UIParent)
    panel:SetWidth(400)
    panel:SetHeight(300)
    panel:SetPoint("CENTER")
    panel:Hide()
    
    -- Checkboxes für Optionen
    local autoAccept = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    autoAccept:SetPoint("TOPLEFT", 20, -20)
    autoAccept.text = autoAccept:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoAccept.text:SetPoint("LEFT", autoAccept, "RIGHT", 5, 0)
    autoAccept.text:SetText("Auto-Accept Quests")
    
    autoAccept:SetScript("OnClick", function()
        addon.settings.autoAcceptQuests = this:GetChecked()
    end)
    
    self.settingsPanel = panel
end
```

### 8.3 Commit und Test
- Commit: "Add UI windows and settings panel"
- **TEST**: Guide-Fenster zeigt Steps an, Settings funktionieren

## Phase 9: Testing und Optimierung (Tag 25-30)

### 9.1 Test-Suite erstellen
```lua
-- Tests.lua
function addon:RunTests()
    self:Print("Running tests...")
    
    -- Test 1: Quest Detection
    local quests = self:GetAllQuests()
    self:Print("Found " .. table.getn(quests) .. " quests")
    
    -- Test 2: Koordinaten
    local x, y = self:GetPlayerCoords()
    self:Print("Position: " .. string.format("%.1f, %.1f", x, y))
    
    -- Test 3: Memory Usage
    UpdateAddOnMemoryUsage()
    local memory = GetAddOnMemoryUsage("RXPGuides_TurtleWoW")
    self:Print("Memory: " .. string.format("%.2f KB", memory))
end

SLASH_RXPTEST1 = "/rxptest"
SlashCmdList["RXPTEST"] = function()
    addon:RunTests()
end
```

### 9.2 Performance Optimierung
```lua
-- Lua 5.0 Optimierungen
-- String Concat vermeiden
local cache = {}
function addon:CachedFormat(fmt, ...)
    local key = fmt .. table.concat(arg, ":")
    if not cache[key] then
        cache[key] = string.format(fmt, unpack(arg))
    end
    return cache[key]
end

-- Table Recycling
local tablePool = {}
function addon:GetTable()
    return tremove(tablePool) or {}
end

function addon:ReleaseTable(t)
    for k in pairs(t) do t[k] = nil end
    tinsert(tablePool, t)
end
```

### 9.3 Finale Tests
- Memory Leaks prüfen
- Alle Features in verschiedenen Zonen testen
- Performance bei vielen Quests testen
- Kompatibilität mit pfUI/pfQuest sicherstellen

### 9.4 Final Commit
- Commit: "Complete Turtle WoW port v1.0"

## Commit-Strategie

Jeder Commit sollte:
1. Eine funktionierende Version hinterlassen
2. Klar beschreiben was geändert wurde
3. Testbar sein

Beispiel-Commits:
```
Initial addon structure for Turtle WoW
Add event system and settings framework
Add guide system and basic parser
Implement quest tracking for vanilla API
Add pfQuest integration for waypoints
Add NPC targeting and combat warnings
Add inventory management system
Add UI windows and settings panel
Add test suite and performance optimizations
Complete Turtle WoW port v1.0
```

## Wichtige Test-Checkpoints

Nach jeder Phase:
1. Addon lädt ohne Fehler
2. Neue Features funktionieren
3. Keine Lua-Errors im Chat
4. Memory Usage bleibt stabil
5. Integration mit pfQuest funktioniert

## Bekannte Einschränkungen

- Kein drehender Pfeil (GetPlayerFacing fehlt)
- Nameplate-Scanning nur 20 yards
- Keine automatische Quest-ID Erkennung
- Performance bei vielen Waypoints beachten
- UI muss manuell positioniert werden (kein modernes Layout)