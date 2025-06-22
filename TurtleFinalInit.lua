-- Final initialization for Turtle WoW
-- This file ensures everything is loaded in the correct order

local addon = RXPGuides
if not addon then
    DEFAULT_CHAT_FRAME:AddMessage("ERROR: RXPGuides not found in TurtleFinalInit.lua!")
    return
end

-- Final initialization after all files are loaded
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    -- Small delay to ensure everything is loaded
    addon:ScheduleTimer(function()
        -- Ensure all commands are properly registered
        if addon.SetupAllCommands then
            addon:SetupAllCommands()
            addon:Debug("All commands registered")
        end
    
    -- Verify all systems are loaded
    local systems = {
        {name = "Event System", check = addon.RegisterMessage},
        {name = "Settings System", check = addon.GetSetting},
        {name = "Database System", check = addon.GetDBValue},
        {name = "Guide System", check = addon.ParseGuide},
        {name = "Guide Loader", check = addon.LoadGuide},
        {name = "Command System", check = addon.HandleCommand},
        {name = "Guide Registration", check = addon.RegisterGuide}
    }
    
    addon:Print("System check:")
    addon:Print("- guides table exists: " .. tostring(addon.guides ~= nil))
    addon:Print("- Number of guides: " .. addon:CountTableEntries(addon.guides))
    
    local allLoaded = true
    for i = 1, table.getn(systems) do
        local system = systems[i]
        if not system.check then
            addon:Print("System NOT loaded: " .. system.name)
            allLoaded = false
        else
            addon:Debug("System loaded: " .. system.name)
        end
    end
    
    if allLoaded then
        addon:Debug("All systems loaded successfully")
    end
    
    -- Initialize guides table if not exists
    if not addon.guides then
        addon.guides = {}
    end
    
    -- Auto-load last guide if enabled
    if addon:GetSetting("profile.autoLoadLastGuide") then
        local lastGuide = addon:GetDBValue("profile", "currentGuide")
        if lastGuide and addon.guides[lastGuide] then
            addon:ScheduleTimer(function()
                addon:LoadGuide(lastGuide)
            end, 1)
        end
    end
    end, 0.5)  -- End of timer
end)