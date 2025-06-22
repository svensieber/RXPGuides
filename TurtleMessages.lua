-- Message/Event System für Turtle WoW (Ace3 AceEvent Ersatz)
local addon = RXPGuides or {}

-- Message system
addon.messageCallbacks = {}

-- Register for a message
function addon:RegisterMessage(message, callback)
    if not self.messageCallbacks[message] then
        self.messageCallbacks[message] = {}
    end
    
    -- Store callback
    tinsert(self.messageCallbacks[message], callback)
    
    self:Debug("Registered for message: " .. message)
end

-- Unregister from a message
function addon:UnregisterMessage(message, callback)
    if not self.messageCallbacks[message] then return end
    
    if callback then
        -- Remove specific callback
        for i = table.getn(self.messageCallbacks[message]), 1, -1 do
            if self.messageCallbacks[message][i] == callback then
                tremove(self.messageCallbacks[message], i)
            end
        end
    else
        -- Remove all callbacks
        self.messageCallbacks[message] = nil
    end
end

-- Send a message
function addon:SendMessage(message)
    -- Get arguments (everything after message)
    local args = {}
    if arg then
        for i = 1, table.getn(arg) do
            args[i] = arg[i]
        end
    end
    
    self:Debug("Sending message: " .. message)
    
    if not self.messageCallbacks[message] then return end
    
    -- Call all callbacks
    for i = 1, table.getn(self.messageCallbacks[message]) do
        local callback = self.messageCallbacks[message][i]
        
        -- Call with addon as self and pass all arguments
        if type(callback) == "function" then
            callback(self, message, unpack(args))
        elseif type(callback) == "string" and self[callback] then
            self[callback](self, message, unpack(args))
        end
    end
end

-- Bucket system for throttling events
addon.buckets = {}

function addon:RegisterBucketEvent(event, interval, callback)
    if not self.buckets[event] then
        self.buckets[event] = {
            interval = interval,
            callbacks = {},
            timer = nil,
            pending = false
        }
        
        -- Register the actual event
        self:RegisterEvent(event, function()
            self:TriggerBucket(event)
        end)
    end
    
    tinsert(self.buckets[event].callbacks, callback)
end

function addon:TriggerBucket(event)
    local bucket = self.buckets[event]
    if not bucket then return end
    
    bucket.pending = true
    
    -- Cancel existing timer if any
    if bucket.timer then
        self:CancelTimer(bucket.timer)
    end
    
    -- Schedule callback
    bucket.timer = self:ScheduleTimer(function()
        bucket.pending = false
        bucket.timer = nil
        
        -- Call all callbacks
        for i = 1, table.getn(bucket.callbacks) do
            local callback = bucket.callbacks[i]
            if type(callback) == "function" then
                callback(self, event)
            elseif type(callback) == "string" and self[callback] then
                self[callback](self, event)
            end
        end
    end, bucket.interval)
end

-- Module system (simplified)
addon.modules = {}

function addon:NewModule(name)
    local module = {
        name = name,
        enabled = true,
        parent = self
    }
    
    -- Copy core functions (Lua 5.0 compatible)
    module.RegisterEvent = function(m, event, callback) 
        self.RegisterEvent(self, event, callback) 
    end
    module.RegisterMessage = function(m, message, callback) 
        self.RegisterMessage(self, message, callback) 
    end
    module.SendMessage = function(m, message) 
        -- Pass through arg table
        self.SendMessage(self, message, arg and unpack(arg))
    end
    module.Print = function(m, msg) 
        self.Print(self, msg, arg and unpack(arg))
    end
    module.Debug = function(m, msg) 
        self.Debug(self, msg, arg and unpack(arg))
    end
    
    self.modules[name] = module
    return module
end

function addon:GetModule(name)
    return self.modules[name]
end

-- Enable/Disable functionality
addon.enabled = true

function addon:Enable()
    self.enabled = true
    self:SendMessage("RXP_ENABLED")
    
    -- Enable all modules
    for name, module in pairs(self.modules) do
        if module.OnEnable then
            module:OnEnable()
        end
    end
end

function addon:Disable()
    self.enabled = false
    self:SendMessage("RXP_DISABLED")
    
    -- Disable all modules
    for name, module in pairs(self.modules) do
        if module.OnDisable then
            module:OnDisable()
        end
    end
end

function addon:IsEnabled()
    return self.enabled
end

-- Add enable/disable commands
local oldHandler = SlashCmdList["RXPGUIDES"]
SlashCmdList["RXPGUIDES"] = function(msg)
    local cmd = addon:ParseCommand(msg)
    
    if cmd == "enable" then
        addon:Enable()
        addon:Print("Addon enabled")
    elseif cmd == "disable" then
        addon:Disable()
        addon:Print("Addon disabled")
    else
        oldHandler(msg)
    end
end