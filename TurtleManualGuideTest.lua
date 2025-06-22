-- Manual test for guide registration
local addon = RXPGuides or {}

-- Add a command to manually test guide registration
SLASH_RXPMANUALTEST1 = "/rxptest"
SlashCmdList["RXPMANUALTEST"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP Manual Test:|r Starting...")
    
    if not addon then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ERROR:|r RXPGuides not found")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("- addon found: " .. tostring(addon ~= nil))
    DEFAULT_CHAT_FRAME:AddMessage("- addon.guides: " .. tostring(addon.guides ~= nil))
    DEFAULT_CHAT_FRAME:AddMessage("- addon.RegisterGuide: " .. tostring(addon.RegisterGuide ~= nil))
    DEFAULT_CHAT_FRAME:AddMessage("- addon.ParseGuide: " .. tostring(addon.ParseGuide ~= nil))
    
    if not addon.RegisterGuide then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ERROR:|r RegisterGuide function missing")
        return
    end
    
    -- Try to register a simple guide
    local success, err = pcall(function()
        addon:RegisterGuide([[
#version 1
#name Manual Test Guide
#group Test
step
>>This is a test step
.goto Test Zone,50,50
]])
    end)
    
    if success then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00SUCCESS:|r Guide registered!")
        
        -- Check if it's in the guides table
        local count = 0
        for k, v in pairs(addon.guides) do
            count = count + 1
            DEFAULT_CHAT_FRAME:AddMessage("Found guide: " .. k)
        end
        DEFAULT_CHAT_FRAME:AddMessage("Total guides: " .. count)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ERROR:|r " .. (err or "unknown"))
    end
end