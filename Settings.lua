local Type = require(script.Parent.Type)

local TYPES = {
    Boolean = { "boolean" },
    Number =  { "number" },
    Function = { "function" }
}

local Value = { [Type] = "Value" }
local Value_mt = { __index = Value }

function Value.new(initialValue, types)
    local self = {}
    self.Value = initialValue
    self.TypeNames = {}
    self.Types = {}
    for _, v in next, types do
        if not self.Types[v] then
            self.Types[v] = true
            table.insert(self.TypeNames, v)
        end
    end
    return setmetatable(self, Value_mt)
end

function Value:set(value)
    if self:isValidType(Type.of(value)) then
        self.Value = value
    else
        error(("Unvalid Type expexted types { %s } but got %s")
            :format(table.concat(self.TypeNames, ", "), Type.of(value)))
    end
end

function Value:get()
    return self.Value
end

function Value:isValidType(type)
    return self.Types[type]
end


--- @class Settings
local Settings = {}

function Settings.new(settings)
    local self = newproxy(true)
    local self_mt = getmetatable(self)
    local prototype = {}

    local data = {}
    local events = {}

    for k, v in next, settings do
        data[k] = v
    end

    function prototype:set(name, value)
        if Type.of(data[name]) ~= "Settings" then
            if data[name] ~= nil then
                local suc, err = pcall(function()
                    data[name]:set(value)
                    if events[name] then
                        events[name]:Fire(value)
                    end
                end)
                if not suc then
                    warn(("Could not change Setting %s, Error:"):format(name or ""), err)
                end
            else
                warn(("%s is not a valid member of Settings!"):format(name or ""))
            end
        else
            warn(("%s is type of Settings and cannot be overiden!"):format(name or "", name or ""))
        end
    end

    function prototype:get(name)
        if data[name] then
            return data[name]
        else
            warn(("%s is not a valid member of Settings!"):format(name))
        end
    end

    function prototype:configure(t)
        for k, v in next, t do
            if Type.of(data[k]) == "Settings" then
                data[k]:configure(v)
            else
                self:set(k, v)
            end
        end
    end

    function prototype:getSettingChangedSignal(setting)
        if data[setting] then
            if events[setting] then
                return events[setting].Event
            else
                local event = Instance.new("BindableEvent")
                events[setting] = event
                return event.Event
            end
        end
    end

    self_mt[Type] = "Settings"

    self_mt.__newindex = function()
        warn("Table is not writable pls use 'set(name, value)' instead")
    end

    self_mt.__index = setmetatable(prototype, { __index = function(_, key)
        if Type.of(data[key]) == "Value" then
            return data[key]:get()
        end
        return data[key]
    end})

    return self
end

local function newWarnValue()
    return Value.new(true, TYPES.Boolean)
end

return Settings.new({
    SaveInStudio = Value.new(false, TYPES.Boolean),

    GetTries = Value.new(3, TYPES.Number),

    SetTries = Value.new(3, TYPES.Number),
    MaxSaveQueue = Value.new(1, TYPES.Number),
    MinTimeBetweenSaves = Value.new(7, TYPES.Number),

    Verbose = Value.new(false, TYPES.Boolean),

    Warnings = Settings.new({
        SAVE_IN_STUDIO = newWarnValue(),
        SAVE_BACKUP_VALUE = newWarnValue(),
        SAVE_VALUE_NOT_UPDATED = newWarnValue(),
        SAVE_NO_DATA = newWarnValue(),
        SAVE_MAX_QUEUE_SIZE = newWarnValue(),

        SAVE_SERIALIZE_RETURNED_NIL = newWarnValue(),
        SAVE_SERIALIZE_ERROR = newWarnValue(),

        RETRIEVE_FAILED = newWarnValue(),
        RETRIEVE_DESERIALIZE_RETURNED_NIL = newWarnValue(),
        RETRIEVE_DESERIALIZE_ERROR = newWarnValue(),

        UPDATE_RETURNED_NIL = newWarnValue(),
        UPDATE_ERROR = newWarnValue(),

        INCREMENT_ERROR = newWarnValue()
    }),

    Debug = Settings.new({
        PrintCache = Value.new(false, TYPES.Boolean)
    }),

    Autosave = Value.new(true, TYPES.Boolean),
    AutosaveInterval = Value.new(1 * 60, TYPES.Number),
})