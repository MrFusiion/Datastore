local DSS = game:GetService("DataStoreService")
local RS = game:GetService("RunService")

local Settings = require(script.Parent.Settings)
local Signal = require(script.Parent.Signal)
local Type = require(script.Parent.Type)
local Constants = require(script.Parent.Constants)
local warn = require(script.Parent.Warnings)

local Intr = Constants.Internal
local None = Constants.None

local Util = require(script.Parent.Util)
local clone = Util.clone
local info = Util.info


--- @class Datastore
local Datastore = { [Type] = "Datastore" }
local Datastore_mt = { __index = Datastore }


--- @param name string
--- @param scope string
--- @param defaultValue any
--- @param backupValue any
function Datastore.new(name: string, scope: string, defaultValue: any, backupValue: any)
    local self = {}

    self.Name = name

    self[Intr] = {
        Key = name,
        Scope = scope,
        Store = DSS:GetDataStore("DATASTORE", scope),

        Closed = false,

        Value = nil,
        DefaultValue = defaultValue,
        BackupValue = backupValue,

        HasValue = false, --Only save when we got a value
        IsBackup = false, --Don't save when the value is a backup value
        ValueUpdated = false, --Only save when value is updated
        Saving = false, --Avoid multiple saving

        LastSave = nil,
        SaveQueueSize = 0,

        Signals = {
            OnUpdate = Signal.new(),
            OnRemove = Signal.new()
        }
    }

    return setmetatable(self, Datastore_mt)
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
function Datastore:_i(key: string, value: any)
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
function Datastore:_fire(name: string, ...)
    self[Intr].Signals[name]:fire(...)
end


--- [**Private**]\
--- Retrieves a value from the Roblox datastores.
function Datastore:_retrieve()
    local suc, val
    local maxTries = math.max(Settings.GetTries, 1)
    for i=1, maxTries do
        suc, val = pcall(function()
            return self:_i("Store"):GetAsync(self:_i("Key"))
        end)
        if suc then
            break
        else
            warn("RETRIEVE_FAILED", maxTries, i, val)
        end
        task.wait(6)
    end

    if val ~= nil then
        suc, val = pcall(self.deserialize, self, clone(val))
        if suc and val == nil then
            warn("DESERIALIZE_RETURNED_NIL")
            return nil, false
        elseif not suc then
            warn("DESERIALIZE_ERROR")
            return nil, false
        end
    end

    info(("[Datastore.Retrieve][%s]"):format(self:getName()), val)
    --*TODO: print Fetched Value

    return val, suc
end


--- [**Private**]\
--- Returns the current value in the datastore.
--- @return any
function Datastore:_get()
    local val, suc
    if not self:_i("HasValue") then
        --Retrieve value
        val, suc = self:_retrieve()

        local dVal = self:_i("DefaultValue")
        local bVal = self:_i("BackupValue")

        if suc then
            self:_i("HasValue", true)
            self:_i("IsBackup", false)

            if val == nil and dVal then
                val = dVal

                info(("[Datastore.Set][%s]"):format(self:getName()), "DefaultValue:", val)
                --*TODO: print Set Default Value
            end
        elseif bVal then
            self:_i("HasValue", true)
            self:_i("IsBackup", true)
            val = bVal

            info(("[Datastore.Set][%s]"):format(self:getName()), "BackupValue:", val)
            --*TODO: print Set Backup Backup Value
        end

        self:_i("Value", val)

        info(("[Datastore.Get][%s]"):format(self:getName()), "Initial:", val)
        --*TODO: print Initial Get

        return val
    else
        val = self:_i("Value")
    end
    return val
end


--- [**Private**]\
--- Sets the value in the datastore.
--- @param value any
function Datastore:_set(value: any)
    self:_i("Value", clone(value))
    self:_i("ValueUpdated", true)
    self:_fire("OnUpdate", value)
end


--- [**Private**]\
--- adds 1 to the queue size.
function Datastore:_addQueue()
    self[Intr].SaveQueueSize += 1
end


--- [**Private**]\
--- removes 1 to the queue size.
function Datastore:_remQueue()
    self[Intr].SaveQueueSize -= 1
end


--[[
    ___________________________________________________________________________________
    Public
    ___________________________________________________________________________________
]]


--- Returns the datastore name.
--- @return string
function Datastore:getName()
    return self.Name
end


--- Should be overiden.
--- Gets called when data gets saved.
--- @return any
function Datastore:serialize(data: any)
    return data
end


--- Should be overiden.
--- Gets called when data gets fetched.
--- @return any
function Datastore:deserialize(data: any)
    return data
end


--[[
--- Sets the backup value for the datastore.
--- @param value any
function Datastore:setBackupValue(value: any)
    self[Intr].BackupValue = value
end]]


--- Returns a boolean that indicates if the value is a backup value.
--- @return boolean
function Datastore:isBackup()
    return self[Intr].IsBackup
end


--- Returns a boolean that indicates if the datastore is closed.
--- @return boolean
function Datastore:isClosed()
    return self[Intr].Closed
end


--- Returns the current value in the datastore.
--- @return any
function Datastore:get()
    local val = self:_get()
    info(("[Datastore.Get][%s]"):format(self:getName()), val)
    --*TODO: print Get Value
    return val
end


--- Sets the current value in the datstore
--- @param value any
function Datastore:set(value: any)
    self:_set(value)
    info(("[Datastore.Set][%s]"):format(self:getName()), value)
    --*TODO: print Set Value
end


--- Update the value in the datastore
--- @param f thread
function Datastore:update(f: thread)
    assert(typeof(f) == "function", "'f' needs to be a function!")

    local suc, val = pcall(f, clone(self:_get()))
    if suc and val ~= nil then
        val = val ~= None and val or nil
        self:_set(clone(val))
        info(("[Datastore.Update][%s]"):format(self:getName()), val)
        --*TODO: print Update value
    elseif suc and  val == nil then
        warn("UPDATE_RETURNED_NIL")
    elseif not suc then
        warn("UPDATE_ERROR", val)
    end
end


--- Increments the value in the datastore.
--- @param value any
function Datastore:increment(value: any)
    local curVal = self:_get()
    local suc, newVal = pcall(function()
        return curVal + value
    end)

    if suc then
        self:_set(newVal)
        info(("[Datastore.Increment][%s]"):format(self:getName()), newVal)
        --*TODO: print Increment Value
    else
        warn("INCREMENT_ERROR", newVal)
    end
end


--- Saves the current value to the Roblox datastores
function Datastore:save()
    if self:isClosed() then
        return false, warn("SAVE_CLOSED")
    end

    local qSize = self:_i("SaveQueueSize")
    if qSize >= Settings.MaxSaveQueue then
        warn("SAVE_MAX_QUEUE_SIZE", qSize)
        return
    end

    local val = self:_get()
    if RS:IsStudio() and not Settings.SaveInStudio then-- If studio check if we are allowed to safe.
        return false, warn("SAVE_IN_STUDIO")
    elseif self:isBackup() then-- Don't save when the value is a backup value.
        return false, warn("SAVE_BACKUP_VALUE")
    elseif not self:_i("ValueUpdated") then-- Don't save if the value was never updated.
        return false, warn("SAVE_VALUE_NOT_UPDATED")
    elseif val == nil then-- Don't save a nil value.
        return false, warn("SAVE_NO_DATA")
    end

    local suc, val = pcall(self.serialize, self, clone(val))
    if suc and val == nil then
        return false, warn("SERIALIZE_RETURNED_NIL")
    elseif not suc then
        return false, warn("SERIALIZE_ERROR")
    end

    if self:_i("Saving") then
        info("[Datastore.Save] Allready saving leaving this save thread!")
        return
    end

    self:_addQueue()
    local lastSave = self:_i("LastSave")
    if lastSave then
        local diff = tick() - lastSave
        if diff < Settings.MinTimeBetweenSaves then
            qSize = self:_i("SaveQueueSize") + 1
            print("|||", qSize, Settings.MinTimeBetweenSaves, diff, "|||")
            local waitTime = Settings.MinTimeBetweenSaves * qSize - diff
            info(("[Datastore.Save.Queue][%s]"):format(self:getName()),
                "Size:", qSize, "Wait Time:", ("%.3f s"):format(waitTime))
            --*TODO: print Save Queue Add
            task.wait(waitTime)
        end
    end

    self:_i("Saving", true)
    local maxTries = Settings.SetTries
    local sSuc, sErr
    for i=1, maxTries do
        sSuc, sErr = pcall(function()
            self:_i("Store"):SetAsync(self:_i("Key"), val)
        end)
        if sSuc then
            info(("[Datastore.Save][%s]"):format(self:getName()), val)
            --*TODO: print Save Value
            break
        else
            warn("SAVE_FAILED", maxTries, i, sErr)
        end
        task.wait(6)
    end

    self:_i("Saving", false)
    self:_i("LastSave", tick())
    self:_i("ValueUpdated", false)
    self:_remQueue()
    return sSuc, sErr
end


--- Disconnect all Events and disables saving.
function Datastore:close()
    self:_fire("OnRemove")
    self:_i("Signals").OnRemove:destroy()
    self:_i("Signals").OnUpdate:destroy()
end


--- Connects 'f' to the OnRemove event.
--- @param f thread
function Datastore:onRemove(f: thread)
    self:_i("Signals").OnRemove:connect(f)
end


--- Connects 'f' to the OnUpdate event.
--- @param f thread
function Datastore:onUpdate(f: thread)
    self:_i("Signals").OnUpdate:connect(f)
end


return Datastore