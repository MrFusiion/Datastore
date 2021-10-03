local Signal = require(script.Parent.Signal)
local Type = require(script.Parent.Type)
local warn = require(script.Parent.Warnings)

local Util = require(script.Parent.Util)
local clone = Util.clone
local info = Util.info

local Constants = require(script.Parent.Constants)

local Intr = Constants.Internal
local None = Constants.None


--- @class CombinedDatastore
local CombinedDatastore = { [Type] = "CombinedDatastore" }
local CombinedDatastore_mt = { __index = CombinedDatastore }


--- @param mainstore table
--- @param name string
--- @param defaultValue any
--- @param backupValue any
--- @param profile table
function CombinedDatastore.new(mainstore: table, name: string, defaultValue: any, backupValue: any, profile: table)
    local self = {}

    self.Name = ("%s.%s"):format(mainstore:getName(), name)

    self[Intr] = {
        Key = name,
        Mainstore = mainstore,

        Closed = false,
        InitialGet = true,

        DefaultValue = defaultValue,
        BackupValue = backupValue,

        Signals = {
            OnUpdate = Signal.new(),
            OnRemove = Signal.new()
        }
    }

    if profile then
        return setmetatable(self, profile.CombinedDatastore)
    end
    return setmetatable(self, CombinedDatastore_mt)
end


--[[
    ___________________________________________________________________________________
    Private
    ___________________________________________________________________________________
]]


--- [**Private**]\
--- Sets or Gets an internal value.
--- @param key string
--- @param value any | nil
function CombinedDatastore:_i(key: string, value: any)
    if value ~= nil then
        self[Intr][key] = value
    else
        return self[Intr][key]
    end
end


--- [**Private**]\
--- Fires an event.
--- @param name string
--- @vararg any
function CombinedDatastore:_fire(name: string, ...)
    self[Intr].Signals[name]:fire(...)
end


--- [**Private**]\
--- Sets the value in the datastore.
--- @param value any
function CombinedDatastore:_set(value: any)
    self:_i("Mainstore"):update(function(data)
        data[self:_i("Key")] = value
        return data
    end)
    self:_fire("OnUpdate", value)
end


--- [**Private**]\
--- Returns the current value in the datastore.
--- @return any
function CombinedDatastore:_get()
    local mStore: DataStore = self:_i("Mainstore")
    local key = self:_i("Key")
    local t = mStore:_get()
    local val = t[key]

    local bVal = self:GetBackupValue()
    local dVal = self:GetDefaultValue()

    if mStore:isBackup() and bVal then
        val = bVal
        t[key] = val
        mStore:_set(t)

        info(("[CombinedDatastore.Set][%s]"):format(self:getName()), "BackupValue:", val)
        --*TODO print Set Backup Value
    elseif val == nil and dVal then
        val = dVal
        t[key] = val
        mStore:_set(t)

        info(("[CombinedDatastore.Set][%s]"):format(self:getName()), "DefaultValue:", val)
        --*TODO print Set Default Value
    elseif self:_i("InitialGet") then
        local suc, newVal = pcall(self.deserialize, self, clone(val))
        if suc then
            if newVal == nil then
                warn("DESERIALIZE_RETURNED_NIL")
            else
                val = newVal
                t[key] = val
                mStore:_set(t)
            end
        else
            warn("DESERIALIZE_ERROR", newVal)
        end

        self:_i("InitialGet", false)
        info(("[Datastore.Get][%s]"):format(self:getName()), "Initial:", val)
        --*TODO print Initial Get
    end

    return val
end


--[[
    ___________________________________________________________________________________
    Public
    ___________________________________________________________________________________
]]


--- Returns the datastore name.
--- @return string
function CombinedDatastore:getName()
    return self.Name
end


--- Returns the datastore scope.
--- @return string | number
function CombinedDatastore:getScope()
    return self:_i("Mainstore"):getScope()
end


--- Should be overiden.
--- Gets called when data gets saved.
--- @return any
function CombinedDatastore:serialize(data: any)
    return data
end


--- Should be overiden.
--- Gets called when data gets fetched.
--- @return any
function CombinedDatastore:deserialize(data: any)
    return data
end


--- Get backup value.
function CombinedDatastore:GetDefaultValue()
    return self.DefaultValue or self[Intr].DefaultValue
end


--- Get backup value.
function CombinedDatastore:GetBackupValue()
    return self.BackupValue or self[Intr].BackupValue
end


--- Returns a boolean that indicates if the value is a backup value.
--- @return boolean
function CombinedDatastore:isBackup()
    return self:_i("Mainstore"):isBackup()
end


--- Returns a boolean that indicates if the datastore is closed.
--- @return boolean
function CombinedDatastore:isClosed()
    return self[Intr].Closed
end


--- Returns the current value in the datastore.
--- @return any
function CombinedDatastore:get()
    local val = self:_get()
    info(("[CombinedDatastore.Get][%s]"):format(self:getName()), val)
    --*TODO print Get Value
    return val
end


--- Sets the current value in the datstore
--- @param value any
function CombinedDatastore:set(value: any)
    self:_set(value)
    info(("[CombinedDatastore.Set][%s]"):format(self:getName()), value)
    --*TODO print Set Value
end


--- Update the value in the datastore
--- @param f thread
function CombinedDatastore:update(f: thread)
    assert(typeof(f) == "function", "'f' needs to be a function!")

    local suc, val = pcall(f, clone(self:_get()))
    if suc and val ~= nil then
        val = val ~= None and val or nil
        self:_set(clone(val))
        info(("[CombinedDatastore.Update][%s]"):format(self:getName()), val)
        --*TODO print Update value
    elseif suc and  val == nil then
        warn("UPDATE_RETURNED_NIL")
    elseif not suc then
        warn("UPDATE_ERROR", val)
    end
end


--- Increments the value in the datastore.
--- @param value any
function CombinedDatastore:increment(value: any)
    local curVal = self:_get()
    local suc, newVal = pcall(function()
        return curVal + value
    end)

    if suc then
        self:_set(newVal)

        info(("[CombinedDatastore.Increment][%s]"):format(self:getName()), newVal)
        --*TODO print Increment Value
    else
        warn("INCREMENT_ERROR", newVal)
    end
end


--- Disconnect all Events and disables saving.
function CombinedDatastore:close()
    self:_fire("OnRemove")
    self:_i("Signals").OnRemove:destroy()
    self:_i("Signals").OnUpdate:destroy()
end


--- Connects 'f' to the OnRemove event.
--- @param f thread
function CombinedDatastore:onRemove(f: thread)
    self:_i("Signals").OnRemove:connect(f)
end


--- Connects 'f' to the OnUpdate event.
--- @param f thread
function CombinedDatastore:onUpdate(f: thread)
    self:_i("Signals").OnUpdate:connect(f)
end


return CombinedDatastore