--- @class Symbol
local Symbol = {}


--- Creates a new symbol named 'name'.
--- @param name string
function Symbol.named(name: string)
	local symbol = newproxy(true)

	getmetatable(symbol).__tostring = function()
		return ("Symbol(%s)"):format(name)
	end

	return symbol
end

--- @type Symbol
local t = newproxy(true)
local mt = getmetatable(t)

mt.__index = Symbol
function mt.__newindex()
   warn("This table is not writable!")
end

return t