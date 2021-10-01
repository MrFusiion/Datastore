local RS = game:GetService("RunService")

local function format(str, t)
    if not t then
        t = str
        str = t[1]
    end
    local out = string.gsub(str, "({([^}]+)})", function(whole, i)
        if tonumber(str) ~= nil then
            return t[tonumber(i)] or whole
        end
        return t[i] or whole
    end)
    return out
end



--- Returns a table containing info about a tread.
--- @param level thread | number
local function getInfo(level: (thread | number))
    local env = getfenv(level + 1)
    local s, l, n, ac, av, f = debug.info(level + 1, "slnaf")
    return {
        s = s, l = l, n = n, ac = ac, av = av, f = f,
        script = env and env["script"] and env["script"].Name or "",
        side = RS:IsServer() and "Server" or "Client"
    }
end


--- @class Debug
local Debug = {}


--- Gets info over the thread formated by str.
--- @param level thread | number
--- @param str string
function Debug.info(level: (thread | number), str: string)
    level += 2
    local suc, info
    while true do
        suc = pcall(function()
            info = format(str, getInfo(level))
        end)
        if suc then
            return info
        elseif level == 0 then
            return nil
        end
        level -= 1
    end
end


--- Gets the script name of the thread.
--- @param level thread | number
function Debug.scriptName(level: (thread | number))
    return Debug.info(level + 1, "{script}")
end


--- Gets the script name of the thread.
--- @param level thread | number
function Debug.getFullName(level: (thread | number))
    return Debug.info(level + 1, "{s}.{n}")
end


--- Gets the script name and func name of the thread.
--- @param level thread | number
function Debug.getScriptAndFuncName(level: (thread | number))
    return Debug.info(level + 1, "{script}.{n}")
end


--- Gets the script name of the thread.
--- @param level thread | number
function Debug.getSriptAndFuncLoc(level: (thread | number))
    return Debug.info(level + 1, "[{script}| {n}:{l}]: ")
end



--- @type Debug
local t = newproxy(true)
local mt = getmetatable(t)

mt.__index = Debug
function mt.__newindex()
   warn("This table is not writable!")
end

return t