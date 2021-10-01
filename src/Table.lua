--- @class Table
local Table = {}


--- shallow copies an table.
--- @param t table
function Table.shallowCopy(t)
    local out = {}
    for k, v in next, t do
        out[k] = v
    end
    return out
end


--- deep copies an table.
--- @param t table
function Table.deepCopy(t)
    local out = {}
    for k, v in next, t do
        if type(v) == "table" then
            out[k] = Table.deepCopy(v)
        else
            out[k] = v
        end
    end
    return out
end


--- @type Table
local t = newproxy(true)
local mt = getmetatable(t)

mt.__index = Table
function mt.__newindex()
   warn("This table is not writable!")
end

return t