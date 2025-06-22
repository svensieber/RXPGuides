-- Centralized command handling for Turtle WoW
local addon = RXPGuides or {}

-- Command handlers table
addon.commandHandlers = {}

-- Register a command handler
function addon:RegisterCommand(command, handler, description)
    self.commandHandlers[command] = {
        handler = handler,
        description = description or "No description"
    }
end

-- Setup all commands
function addon:SetupAllCommands()
    -- Core commands
    self:RegisterCommand("test", function(self, args)
        self:Print("Test successful! Version: " .. self.version)
        self:Debug("Debug mode is " .. (self.settings.debug and "ON" or "OFF"))
    end, "Test installation")
    
    self:RegisterCommand("test2", function(self, args)
        self:Print("Testing Phase 2 systems...")
        
        -- Test settings
        self:SetSetting("profile.debug", true)
        self:Print("Debug setting: " .. tostring(self:GetSetting("profile.debug")))
        
        -- Test messages
        self:RegisterMessage("TEST_MESSAGE", function(self, msg, data)
            self:Print("Received message: " .. msg .. " with data: " .. (data or "none"))
        end)
        self:SendMessage("TEST_MESSAGE", "test data")
        
        -- Test database
        self:SetDBValue("profile", "testKey", "testValue")
        self:Print("DB test value: " .. (self:GetDBValue("profile", "testKey") or "nil"))
        
        self:Print("Phase 2 test complete!")
    end, "Test Phase 2 systems")
    
    self:RegisterCommand("debug", function(self, args)
        -- Toggle debug in profile settings
        local currentDebug = self:GetSetting("profile.debug")
        self:SetSetting("profile.debug", not currentDebug)
        self.settings.debug = not currentDebug  -- Also update the shortcut
        self:Print("Debug mode: " .. (self.settings.debug and "ON" or "OFF"))
    end, "Toggle debug mode")
    
    self:RegisterCommand("version", function(self, args)
        self:Print("Version: " .. self.version)
        local version, build, date = GetBuildInfo()
        self:Print("WoW Version: " .. version .. " (Build " .. build .. ")")
        self:Print("Interface: 11200 (Turtle WoW)")
        self:Print("Lua 5.0 compatible")
    end, "Show version info")
    
    self:RegisterCommand("help", function(self, args)
        self:ShowHelp()
    end, "Show this help")
    
    -- Manual test command
    self:RegisterCommand("manualtest", function(self, args)
        self:Print("Manual Guide Test...")
        
        -- Check functions
        self:Print("Functions available:")
        self:Print("- RegisterGuide: " .. tostring(self.RegisterGuide ~= nil))
        self:Print("- ParseGuide: " .. tostring(self.ParseGuide ~= nil))
        self:Print("- guides table: " .. tostring(self.guides ~= nil))
        
        if self.RegisterGuide then
            -- Try to register a test guide
            local testGuide = [[
#version 1
#name Manual Test Guide
step
>>Test step
.goto Test,50,50
]]
            self:Print("Attempting to register test guide...")
            local success, result = pcall(function()
                return self:RegisterGuide(testGuide)
            end)
            
            if success then
                self:Print("Registration call successful!")
                self:Print("RegisterGuide returned: " .. tostring(result))
                
                -- Count guides
                local count = 0
                for k, v in pairs(self.guides or {}) do
                    count = count + 1
                    self:Print("- Found guide key: " .. k)
                end
                self:Print("Total guides now: " .. count)
                
                -- Also check with different methods
                local directCount = 0
                for k in pairs(addon.guides or {}) do
                    directCount = directCount + 1
                end
                self:Print("Direct count of addon.guides: " .. directCount)
            else
                self:Print("Registration failed: " .. tostring(err))
            end
        else
            self:Print("RegisterGuide function not found!")
        end
    end, "Manually test guide registration")
    
    -- Settings commands
    self:RegisterCommand("settings", function(self, args)
        self:Print("Settings panel not yet implemented")
    end, "Open settings panel")
    
    self:RegisterCommand("config", function(self, args)
        self:Print("Settings panel not yet implemented")
    end, "Open settings panel")
    
    self:RegisterCommand("scale", function(self, args)
        local scale = tonumber(args)
        if scale and scale >= 0.5 and scale <= 2.0 then
            self:SetSetting("profile.windowScale", scale)
            self:Print("Window scale set to: " .. scale)
        else
            self:Print("Scale must be between 0.5 and 2.0")
        end
    end, "Set window scale")
    
    self:RegisterCommand("reset", function(self, args)
        if args == "settings" then
            self:ResetSettings()
        elseif args == "positions" then
            self:ResetPositions()
        else
            self:Print("Usage: /rxp reset [settings|positions]")
        end
    end, "Reset settings or positions")
    
    -- Database commands
    self:RegisterCommand("resetdb", function(self, args)
        if args and (args == "global" or args == "profile" or args == "char" or args == "all") then
            self:ResetDatabase(args)
        else
            self:Print("Usage: /rxp resetdb [global|profile|char|all]")
        end
    end, "Reset database")
    
    self:RegisterCommand("db", function(self, args)
        self:Print("Database info:")
        self:Print("- Global entries: " .. self:CountTableEntries(self.db.global))
        self:Print("- Profile entries: " .. self:CountTableEntries(self.db.profile))
        self:Print("- Character entries: " .. self:CountTableEntries(self.db.char))
    end, "Show database info")
    
    -- Enable/Disable commands
    self:RegisterCommand("enable", function(self, args)
        self:Enable()
        self:Print("Addon enabled")
    end, "Enable addon")
    
    self:RegisterCommand("disable", function(self, args)
        self:Disable()
        self:Print("Addon disabled")
    end, "Disable addon")
    
    -- Phase 3 test command
    self:RegisterCommand("test3", function(self, args)
        self:Print("Testing Phase 3 - Guide System...")
        
        -- Debug: Check if guides table exists
        if not self.guides then
            self:Print("ERROR: self.guides is nil in test3!")
            self.guides = {}
        else
            self:Print("self.guides exists")
        end
        
        -- Also check addon.guides vs self.guides
        self:Print("addon.guides == self.guides: " .. tostring(addon.guides == self.guides))
        self:Print("Type of self: " .. type(self))
        self:Print("Type of addon: " .. type(addon))
        
        -- Test guide registration
        local testGuideCount = 0
        for key, guide in pairs(self.guides) do
            testGuideCount = testGuideCount + 1
            self:Print("Found guide: " .. guide.name .. " (" .. key .. ")")
        end
        self:Print("Total guides registered: " .. testGuideCount)
        
        -- Also check addon.guides directly
        local addonGuideCount = 0
        for key, guide in pairs(addon.guides) do
            addonGuideCount = addonGuideCount + 1
        end
        self:Print("Total in addon.guides: " .. addonGuideCount)
        
        -- Test guide parsing
        local simpleGuide = [[
#version 1
#name Simple Test
step
>>Talk to Test NPC
.goto Test Zone,50,50
.accept 123
]]
        -- Check if ParseGuide is available
        if self.ParseGuide then
            local parsed = self:ParseGuide(simpleGuide)
            if parsed then
                self:Print("Guide parsing: OK")
                self:Print("- Name: " .. (parsed.name or "none"))
                self:Print("- Steps: " .. table.getn(parsed.steps or {}))
            else
                self:Print("Guide parsing: FAILED")
            end
        else
            self:Print("ParseGuide function not available yet")
        end
        
        self:Print("Phase 3 test complete!")
    end, "Test Phase 3 guide system")
    
    -- Command to manually register test guides
    self:RegisterCommand("loadguides", function(self, args)
        if self.RegisterTestGuides then
            self:RegisterTestGuides()
        else
            self:Print("RegisterTestGuides function not found!")
        end
    end, "Load test guides")
end

-- Main command handler
function addon:HandleCommand(msg)
    local cmd, args = self:ParseCommand(msg)
    
    if not cmd or cmd == "" then
        cmd = "help"
    end
    
    local handler = self.commandHandlers[cmd]
    if handler then
        handler.handler(self, args)
    else
        self:Print("Unknown command: " .. cmd)
        self:Print("Type /rxp help for available commands")
    end
end

-- Show help
function addon:ShowHelp()
    self:Print("Available commands:")
    
    -- Sort commands alphabetically
    local sortedCmds = {}
    for cmd, _ in pairs(self.commandHandlers) do
        tinsert(sortedCmds, cmd)
    end
    table.sort(sortedCmds)
    
    -- Display commands
    for i = 1, table.getn(sortedCmds) do
        local cmd = sortedCmds[i]
        local info = self.commandHandlers[cmd]
        self:Print("/rxp " .. cmd .. " - " .. info.description)
    end
end