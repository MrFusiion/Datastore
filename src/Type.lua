local Symbol = require(script.Parent.Symbol)


--- @type Type
local Type = Symbol.named("Type")


--- @class Type
local functions = {}

function functions.of(value)
    if typeof(value) == "table" and value[Type] then
        return value[Type]
    elseif typeof(value) == "userdata" and getmetatable(value)[Type] then
        return getmetatable(value)[Type]
    end
    return typeof(value)
end


local mt = getmetatable(Type)

mt.__index = functions

function mt.__newindex()
   warn("This table is not writable!")
end

return Type