-- Turtle WoW Detection and Loading
-- This file loads first to check if we're running on Turtle WoW

local addonName, addon = ...

-- Check if we're on Turtle WoW (Interface 11200)
local _, _, _, interfaceVersion = GetBuildInfo()

if interfaceVersion == 11200 then
    -- We're on Turtle WoW, load our compatibility layer
    addon.isTurtleWoW = true
    
    -- Load Turtle WoW specific files
    local function LoadTurtleFiles()
        -- These files provide Turtle WoW compatibility
        if not IsAddOnLoaded("RXPGuides") then return end
        
        -- Load our Turtle WoW core files
        local files = {
            "TurtleCore.lua",
            "TurtleUtils.lua", 
            "TurtleLocale.lua"
        }
        
        -- Since we can't dynamically load files in WoW, we'll set a flag
        -- and handle the differences in the main addon files
        addon.TURTLE_WOW = true
        addon.gameVersion = 11200
    end
    
    -- Set up a frame to load our files after ADDON_LOADED
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function()
        if arg1 == "RXPGuides" then
            LoadTurtleFiles()
            frame:UnregisterEvent("ADDON_LOADED")
        end
    end)
else
    -- Not Turtle WoW
    addon.isTurtleWoW = false
end