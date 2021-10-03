local Symbol = require(script.Parent.Symbol)

local Constants = {}

Constants.Internal = Symbol.named("Internal")
Constants.None = Symbol.named("None")

local t = newproxy(true)
local mt = getmetatable(t)

mt.__index = Constants
function mt.__newindex()
   warn("This table is not writable!")
end

return t