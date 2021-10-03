local Symbol = require(script.Parent.Symbol)

local Event = Symbol.named("Event")
local Conn = Symbol.named("Connections")


--- @class Signal
local Signal = {}
local Singal_mt = { __index = Signal }


function Signal.new()
    return setmetatable({
        [Event] = Instance.new("BindableEvent"),
        [Conn] = {}
    }, Singal_mt)
end


--- Connects an thread to this event.
--- @param f thread
function Signal:connect(f: thread)
    assert(typeof(f) == "function" and "'f' needs to be a function!")

    local conn = self[Event].Event:Connect(f)
    table.insert(self[Conn], conn)
    return conn
end


--- Fires all the connected functions.
--- @vararg any
function Signal:fire(...: {any})
    self[Event]:Fire(...)
end


--- Disconnects all connections and destroys the Instance.
function Signal:destroy()
    for _, conn in next, self[Conn] do--should be done automaticly if object gets destroyed just for beeing safe disconnect all
        conn:Disconnect()
    end
    self[Event]:Destroy()
end


--- @type Signal
local t = newproxy(true)
local mt = getmetatable(t)

mt.__index = Signal
function mt.__newindex()
   warn("This table is not writable!")
end

return t