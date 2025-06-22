-- Test Guide for Turtle WoW
local addon = RXPGuides or {}

-- Register test guide after addon loads
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    -- Debug output
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: TurtleTestGuide.lua loading...")
    
    -- Make sure we use the global RXPGuides
    local addon = RXPGuides
    if not addon then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: ERROR - RXPGuides global not found!")
        return
    end
    
    if not addon.RegisterGuide then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: ERROR - RegisterGuide not found!")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: Registering test guides...")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: addon.guides exists: " .. tostring(addon.guides ~= nil))
    
    -- Human Starting Zone Test Guide
    addon:RegisterGuide([[
#version 1
#group Test Guides
#subgroup Turtle WoW
#name Human 1-6 Test
#next human-6-10-test
#level 1-6
#turtle
<< Alliance

step
>>Talk to |cRXP_FRIENDLY_Deputy Willem|r
.target Deputy Willem
.goto Elwynn Forest,48.17,42.94
.accept 783 >> Accept A Threat Within

step
>>Kill |cRXP_ENEMY_Young Wolves|r
.goto Elwynn Forest,48.5,40.0,40,0
.goto Elwynn Forest,47.0,39.0,40,0
.complete 783,1
.mob Young Wolf

step
>>Talk to |cRXP_FRIENDLY_Deputy Willem|r
.target Deputy Willem  
.goto Elwynn Forest,48.17,42.94
.turnin 783 >> Turn in A Threat Within
.accept 7 >> Accept Kobold Camp Cleanup

step
>>Kill |cRXP_ENEMY_Kobold Vermin|r
.goto Elwynn Forest,47.6,35.8,40,0
.goto Elwynn Forest,49.5,35.5,40,0
.complete 7,1
.mob Kobold Vermin

step
>>Talk to |cRXP_FRIENDLY_Deputy Willem|r
.target Deputy Willem
.goto Elwynn Forest,48.17,42.94
.turnin 7 >> Turn in Kobold Camp Cleanup
]])

    -- Undead Starting Zone Test Guide  
    addon:RegisterGuide([[
#version 1
#group Test Guides
#subgroup Turtle WoW
#name Undead 1-6 Test
#next undead-6-10-test
#level 1-6
#turtle
<< Horde

step
>>Talk to |cRXP_FRIENDLY_Undertaker Mordo|r
.target Undertaker Mordo
.goto Tirisfal Glades,30.22,71.65
.accept 363 >> Accept Rude Awakening

step
>>Talk to |cRXP_FRIENDLY_Shadow Priest Sarvis|r
.target Shadow Priest Sarvis
.goto Tirisfal Glades,30.84,66.20
.turnin 363 >> Turn in Rude Awakening
.accept 364 >> Accept The Mindless Ones

step
>>Kill |cRXP_ENEMY_Mindless Zombies|r and |cRXP_ENEMY_Wretched Zombies|r
.goto Tirisfal Glades,32.4,63.2,40,0
.goto Tirisfal Glades,31.0,64.8,40,0
.complete 364,1
.complete 364,2
.mob Mindless Zombie
.mob Wretched Zombie

step
>>Talk to |cRXP_FRIENDLY_Shadow Priest Sarvis|r
.target Shadow Priest Sarvis
.goto Tirisfal Glades,30.84,66.20
.turnin 364 >> Turn in The Mindless Ones
]])

    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RXP|r: Test guides registered successfully!")
    addon:Print("Test guides loaded. Use /rxp guide to see them.")
end)