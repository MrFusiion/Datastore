local Table = require(script.Parent.Table)
local Settings = require(script.Parent.Settings)


--- @class Util
local Util = {}


--- clone a value.
--- @param value any
function Util.clone(value: any)
    if typeof(value) == "table" then
        return Table.deepCopy(value)
    end
    return value
end


--- prints to the console if setting Verbose is enabled.
--- @vararg any
function Util.info(...: {any})
    if Settings.Verbose then
        print(...)
    end
end


--- @type Util
local t = newproxy(true)
local mt = getmetatable(t)

mt.__index = Util
function mt.__newindex()
   warn("This table is not writable!")
end

return t